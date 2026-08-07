#!/usr/bin/env bash
set -euo pipefail

# EDEN//FALL — local/Codespaces Web export, explicitly without GitHub Actions.
# Builds the current feature branch with exact Godot 4.7.1 and runs the release
# audit stack before writing build/web.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${EDEN_TOOLS_DIR:-$ROOT/.tools}"
GODOT_VERSION="4.7.1"
GODOT_DIR="$TOOLS_DIR/godot-$GODOT_VERSION"
DOWNLOAD_DIR="$TOOLS_DIR/downloads"
GODOT_ZIP="$DOWNLOAD_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
TEMPLATES_TPZ="$DOWNLOAD_DIR/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
GODOT_URL="https://downloads.godotengine.org/?flavor=stable&platform=linux.64&slug=linux.x86_64.zip&version=${GODOT_VERSION}"
TEMPLATES_URL="https://downloads.godotengine.org/?flavor=stable&platform=templates&slug=export_templates.tpz&version=${GODOT_VERSION}"
TEMPLATE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
BUILD_DIR="$ROOT/build/web"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: required command not found: $1" >&2; exit 2; }
}
need curl
need unzip
need git
need python3

mkdir -p "$GODOT_DIR" "$DOWNLOAD_DIR" "$BUILD_DIR"

if [[ ! -x "$GODOT_DIR/godot" ]]; then
  echo "[eden] downloading Godot ${GODOT_VERSION} Linux editor"
  curl --fail --location --retry 3 --output "$GODOT_ZIP" "$GODOT_URL"
  rm -rf "$GODOT_DIR/unpacked"
  mkdir -p "$GODOT_DIR/unpacked"
  unzip -q -o "$GODOT_ZIP" -d "$GODOT_DIR/unpacked"
  GODOT_BIN="$(find "$GODOT_DIR/unpacked" -maxdepth 1 -type f -name 'Godot_v*-stable_linux.x86_64' | head -n1)"
  [[ -n "$GODOT_BIN" ]] || { echo "ERROR: Godot executable missing from archive" >&2; exit 3; }
  mv "$GODOT_BIN" "$GODOT_DIR/godot"
  chmod +x "$GODOT_DIR/godot"
fi

ENGINE_VERSION="$($GODOT_DIR/godot --version | head -n1)"
case "$ENGINE_VERSION" in
  4.7.1.stable*) ;;
  *) echo "ERROR: expected Godot 4.7.1.stable, got $ENGINE_VERSION" >&2; exit 4 ;;
esac

echo "[eden] engine: $ENGINE_VERSION"

if [[ ! -f "$TEMPLATE_HOME/web_nothreads_release.zip" ]]; then
  echo "[eden] downloading Godot ${GODOT_VERSION} export templates"
  curl --fail --location --retry 3 --output "$TEMPLATES_TPZ" "$TEMPLATES_URL"
  TMP_TEMPLATES="$(mktemp -d)"
  trap 'rm -rf "$TMP_TEMPLATES"' EXIT
  unzip -q -o "$TEMPLATES_TPZ" -d "$TMP_TEMPLATES"
  SRC_TEMPLATES="$(find "$TMP_TEMPLATES" -type f -name 'web_nothreads_release.zip' -printf '%h\n' | head -n1)"
  [[ -n "$SRC_TEMPLATES" ]] || { echo "ERROR: Web no-threads export template not found" >&2; exit 5; }
  mkdir -p "$TEMPLATE_HOME"
  cp -a "$SRC_TEMPLATES"/. "$TEMPLATE_HOME"/
fi

cd "$ROOT"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "ERROR: refusing to build from main. Use godmode/production-assets-v6-rebuild." >&2
  exit 6
fi

SOURCE_SHA="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
echo "[eden] source: ${CURRENT_BRANCH:-detached} @ $SOURCE_SHA"

echo "[eden] importing project"
"$GODOT_DIR/godot" --headless --path "$ROOT" --import

AUDITS=(
  "res://tests/v6_product_rebuild_audit.gd"
  "res://tests/v7_masterpiece_audit.gd"
  "res://tests/v7_runtime_quality_audit.gd"
  "res://tests/v8_entropy_audit.gd"
  "res://tests/v8_sprite_streaming_audit.gd"
)
for audit in "${AUDITS[@]}"; do
  echo "[eden] audit: $audit"
  "$GODOT_DIR/godot" --headless --path "$ROOT" --script "$audit"
done

echo "[eden] bounded headless boot"
set +e
timeout 12s "$GODOT_DIR/godot" --headless --path "$ROOT" --editor-pseudolocalization >/tmp/edenfall-boot.log 2>&1
BOOT_CODE=$?
set -e
if [[ $BOOT_CODE -ne 0 && $BOOT_CODE -ne 124 ]]; then
  cat /tmp/edenfall-boot.log >&2
  echo "ERROR: bounded boot failed with code $BOOT_CODE" >&2
  exit 7
fi
if grep -Eiq 'SCRIPT ERROR|Parse Error|Parser Error|Invalid call|ERROR:.*(script|resource)' /tmp/edenfall-boot.log; then
  cat /tmp/edenfall-boot.log >&2
  echo "ERROR: bounded boot emitted a fatal script/resource error" >&2
  exit 8
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
echo "[eden] exporting non-threaded Web release"
"$GODOT_DIR/godot" --headless --path "$ROOT" --export-release "Web" "$BUILD_DIR/index.html"

for required in index.html index.js index.wasm index.pck; do
  [[ -s "$BUILD_DIR/$required" ]] || { echo "ERROR: missing Web artifact: $required" >&2; exit 9; }
done

# The Pages test channel must not register a PWA worker. Old PWA registrations
# are retired by purge.html / the temporary gh-pages retirement worker.
if [[ -e "$BUILD_DIR/index.service.worker.js" ]]; then
  echo "ERROR: Web test export unexpectedly generated a service worker" >&2
  exit 10
fi
if grep -q 'serviceWorker.register' "$BUILD_DIR/index.html"; then
  echo "ERROR: index.html still registers a service worker" >&2
  exit 11
fi

touch "$BUILD_DIR/.nojekyll"
python3 - "$BUILD_DIR/build-info.json" "$SOURCE_SHA" <<'PY'
import datetime, json, pathlib, sys
path = pathlib.Path(sys.argv[1])
sha = sys.argv[2]
data = {
    "project": "EDEN//FALL",
    "version": "0.6.2-entropy",
    "channel": "github-pages-test-no-actions",
    "godot": "4.7.1",
    "source_commit": sha,
    "source_branch": "godmode/production-assets-v6-rebuild",
    "published_branch": "gh-pages",
    "pwa": False,
    "threads": False,
    "playable": True,
    "built_at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
}
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

python3 "$ROOT/tools/verify_web_export.py" "$BUILD_DIR"
echo "[eden] Web export ready: $BUILD_DIR"
