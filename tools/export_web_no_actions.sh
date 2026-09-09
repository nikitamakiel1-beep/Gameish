#!/usr/bin/env bash
set -euo pipefail

# EDEN//FALL — Codespaces/local Web export, explicitly without GitHub Actions.
# Builds the production feature branch with exact Godot 4.7.1 and fails closed
# through audit -> counteraudit -> mutation countercounteraudit before an artifact
# can be marked playable/qualified.

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
VALIDATION_DIR="$ROOT/validation/no-actions-art4"
PRODUCT_REVISION="0.6.4-authored-art4"
FULL_QUALIFICATION="all-gdscript+release-integrity+live-binding+art4+legacy+boot+web+counteraudit+mutation-countercounteraudit"
SOURCE_BRANCH="godmode/production-assets-v6-rebuild"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: required command not found: $1" >&2; exit 2; }
}
for tool in bash curl unzip git python3 timeout tee grep find sha256sum basename; do
  need "$tool"
done

# Counteraudit the helpers and the audit wiring before any expensive engine work.
python3 "$ROOT/tools/static_tooling_audit.py"
python3 "$ROOT/tools/audit_source_counteraudit.py"

cd "$ROOT"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "ERROR: refusing to build from main. Use $SOURCE_BRANCH." >&2
  exit 6
fi
if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "HEAD" && "$CURRENT_BRANCH" != "$SOURCE_BRANCH" ]]; then
  echo "ERROR: refusing to build unexpected branch: $CURRENT_BRANCH" >&2
  exit 6
fi
# Provenance must describe the exact bytes being built. Untracked Godot-generated
# .uid/.import metadata is tolerated, but tracked or staged edits are not.
if ! git diff --quiet --ignore-submodules -- || ! git diff --cached --quiet --ignore-submodules --; then
  echo "ERROR: tracked source is dirty; commit/stash tracked edits before qualification" >&2
  git status --short >&2
  exit 6
fi
SOURCE_SHA="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
if [[ ! "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR: source commit is not a full Git SHA: $SOURCE_SHA" >&2
  exit 6
fi
echo "[eden] source: ${CURRENT_BRANCH:-detached} @ $SOURCE_SHA"

# Invalidate any previous preview immediately. A failed new qualification must
# never leave an older qualified build available under build/web.
mkdir -p "$ROOT/.codespaces"
rm -f "$ROOT/.codespaces/build-ok"
touch "$ROOT/.codespaces/build-failed"
printf '%s\n' "$SOURCE_SHA" > "$ROOT/.codespaces/build-in-progress"
rm -rf "$VALIDATION_DIR" "$BUILD_DIR"
mkdir -p "$GODOT_DIR" "$DOWNLOAD_DIR" "$BUILD_DIR" "$VALIDATION_DIR"
python3 "$ROOT/tools/static_tooling_audit.py" | tee "$VALIDATION_DIR/tooling-audit.log"
python3 "$ROOT/tools/audit_source_counteraudit.py" | tee "$VALIDATION_DIR/audit-source-counteraudit.log"
printf '%s\n' "$SOURCE_SHA" > "$VALIDATION_DIR/source-commit.txt"

if [[ ! -x "$GODOT_DIR/godot" ]]; then
  echo "[eden] downloading Godot ${GODOT_VERSION} Linux editor"
  curl --fail --location --retry 3 --retry-delay 2 --output "$GODOT_ZIP" "$GODOT_URL"
  rm -rf "$GODOT_DIR/unpacked"
  mkdir -p "$GODOT_DIR/unpacked"
  unzip -q -o "$GODOT_ZIP" -d "$GODOT_DIR/unpacked"
  GODOT_BIN="$(find "$GODOT_DIR/unpacked" -maxdepth 1 -type f -name 'Godot_v*-stable_linux.x86_64' | head -n1)"
  [[ -n "$GODOT_BIN" ]] || { echo "ERROR: Godot executable missing from archive" >&2; exit 3; }
  mv "$GODOT_BIN" "$GODOT_DIR/godot"
  chmod +x "$GODOT_DIR/godot"
fi

GODOT="$GODOT_DIR/godot"
ENGINE_VERSION="$($GODOT --version | head -n1)"
case "$ENGINE_VERSION" in
  4.7.1.stable*) ;;
  *) echo "ERROR: expected Godot 4.7.1.stable, got $ENGINE_VERSION" >&2; exit 4 ;;
esac
printf '%s\n' "$ENGINE_VERSION" | tee "$VALIDATION_DIR/engine-version.log"

if [[ ! -f "$TEMPLATE_HOME/web_nothreads_release.zip" ]]; then
  echo "[eden] downloading Godot ${GODOT_VERSION} export templates"
  curl --fail --location --retry 3 --retry-delay 2 --output "$TEMPLATES_TPZ" "$TEMPLATES_URL"
  TMP_TEMPLATES="$(mktemp -d)"
  trap 'rm -rf "$TMP_TEMPLATES"' EXIT
  unzip -q -o "$TEMPLATES_TPZ" -d "$TMP_TEMPLATES"
  SRC_TEMPLATES="$(find "$TMP_TEMPLATES" -type f -name 'web_nothreads_release.zip' -printf '%h\n' | head -n1)"
  [[ -n "$SRC_TEMPLATES" ]] || { echo "ERROR: Web no-threads export template not found" >&2; exit 5; }
  mkdir -p "$TEMPLATE_HOME"
  cp -a "$SRC_TEMPLATES"/. "$TEMPLATE_HOME"/
fi

fatal_log() {
  local log="$1"
  if grep -Eiq 'SCRIPT ERROR|Parse Error|Parser Error|Compile Error|Invalid call|Invalid get index|Failed to load script|Failed to load resource|Cannot get class|FATAL:|ERROR:.*(script|resource|load|invalid)' "$log"; then
    echo "ERROR: fatal Godot diagnostic detected in $log" >&2
    grep -Ein 'SCRIPT ERROR|Parse Error|Parser Error|Compile Error|Invalid call|Invalid get index|Failed to load script|Failed to load resource|Cannot get class|FATAL:|ERROR:.*(script|resource|load|invalid)' "$log" >&2 || true
    exit 20
  fi
}

run_audit() {
  local audit="$1"
  local name
  name="$(basename "$audit" .gd)"
  local log="$VALIDATION_DIR/${name}.log"
  echo "[eden] audit: $audit"
  "$GODOT" --headless --audio-driver Dummy --path "$ROOT" --script "$audit" 2>&1 | tee "$log"
  fatal_log "$log"
}

echo "[eden] clean editor import / project parse"
IMPORT_LOG="$VALIDATION_DIR/import.log"
"$GODOT" --headless --audio-driver Dummy --path "$ROOT" --editor --quit --verbose 2>&1 | tee "$IMPORT_LOG"
fatal_log "$IMPORT_LOG"

# Audit layer 1: every script and the explicitly ordered production dependency chain.
run_audit "res://tests/all_gdscript_compile_audit.gd"
run_audit "res://tests/v8_compile_chain_probe.gd"

AUDITS=(
  "res://tests/v8_release_integrity_audit.gd"
  "res://tests/v8_live_binding_counteraudit.gd"
  "res://tests/v8_art4_reference_audit.gd"
  "res://tests/v8_art_direction_audit.gd"
  "res://tests/v8_presentation_audit.gd"
  "res://tests/v6_factory_audit.gd"
  "res://tests/v6_product_rebuild_audit.gd"
  "res://tests/v7_masterpiece_audit.gd"
  "res://tests/v7_runtime_quality_audit.gd"
  "res://tests/v8_entropy_audit.gd"
  "res://tests/v8_sprite_streaming_audit.gd"
)
for audit in "${AUDITS[@]}"; do
  run_audit "$audit"
done

echo "[eden] bounded headless game boot"
BOOT_LOG="$VALIDATION_DIR/boot.log"
set +e
timeout 15s "$GODOT" --headless --audio-driver Dummy --path "$ROOT" --quit-after 180 --verbose >"$BOOT_LOG" 2>&1
BOOT_CODE=$?
set -e
cat "$BOOT_LOG"
if [[ $BOOT_CODE -ne 0 && $BOOT_CODE -ne 124 ]]; then
  echo "ERROR: bounded game boot failed with code $BOOT_CODE" >&2
  exit 7
fi
fatal_log "$BOOT_LOG"

echo "[eden] exporting non-threaded Web release"
EXPORT_LOG="$VALIDATION_DIR/export.log"
"$GODOT" --headless --audio-driver Dummy --path "$ROOT" --export-release "Web" "$BUILD_DIR/index.html" 2>&1 | tee "$EXPORT_LOG"
fatal_log "$EXPORT_LOG"

for required in index.html index.js index.wasm index.pck; do
  [[ -s "$BUILD_DIR/$required" ]] || { echo "ERROR: missing Web artifact: $required" >&2; exit 9; }
done
if [[ -e "$BUILD_DIR/index.service.worker.js" || -e "$BUILD_DIR/index.offline.html" ]]; then
  echo "ERROR: Web test export unexpectedly generated PWA-only files" >&2
  exit 10
fi
if grep -q 'serviceWorker.register' "$BUILD_DIR/index.html"; then
  echo "ERROR: index.html still registers a service worker" >&2
  exit 11
fi
if ! grep -Fq "$PRODUCT_REVISION" "$BUILD_DIR/index.html"; then
  echo "ERROR: index.html does not contain the Art4 build marker $PRODUCT_REVISION" >&2
  exit 12
fi

touch "$BUILD_DIR/.nojekyll"
# Deliberately pending: no failed run may leave a publishable metadata claim.
python3 - "$BUILD_DIR/build-info.json" "$SOURCE_SHA" "$PRODUCT_REVISION" <<'PY'
import datetime, json, pathlib, sys
path = pathlib.Path(sys.argv[1])
sha = sys.argv[2]
revision = sys.argv[3]
data = {
    "project": "EDEN//FALL",
    "version": revision,
    "channel": "github-pages-test-no-actions",
    "godot": "4.7.1",
    "source_commit": sha,
    "source_branch": "godmode/production-assets-v6-rebuild",
    "published_branch": "gh-pages",
    "pwa": False,
    "threads": False,
    "playable": False,
    "qualified": False,
    "qualification": "pending-counteraudits",
    "built_at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
}
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

# Structural verification is allowed before qualification; strict verification is not.
python3 "$ROOT/tools/verify_web_export.py" --structural "$BUILD_DIR" | tee "$VALIDATION_DIR/structural-verifier.log"
sha256sum "$BUILD_DIR/index.html" "$BUILD_DIR/index.js" "$BUILD_DIR/index.wasm" "$BUILD_DIR/index.pck" > "$VALIDATION_DIR/web-sha256.txt"

# Audit layer 2: independently re-read raw logs, PASS markers, provenance and hashes.
COUNTER_REPORT="$VALIDATION_DIR/qualification-counteraudit-report.json"
python3 "$ROOT/tools/qualification_counteraudit.py" \
  --build "$BUILD_DIR" --validation "$VALIDATION_DIR" --report "$COUNTER_REPORT" \
  | tee "$VALIDATION_DIR/qualification-counteraudit.log"

# Audit layer 3: mutation-test both the structural verifier and layer-2 counteraudit.
COUNTERCOUNTER_REPORT="$VALIDATION_DIR/qualification-countercounteraudit-report.json"
python3 "$ROOT/tools/qualification_countercounteraudit.py" \
  --build "$BUILD_DIR" --validation "$VALIDATION_DIR" --report "$COUNTERCOUNTER_REPORT" \
  | tee "$VALIDATION_DIR/qualification-countercounteraudit.log"

# Only now promote the artifact to playable/qualified and bind the two independent
# reports into a publishable qualification proof.
python3 - "$BUILD_DIR/build-info.json" "$BUILD_DIR/qualification-proof.json" \
  "$COUNTER_REPORT" "$COUNTERCOUNTER_REPORT" "$SOURCE_SHA" "$PRODUCT_REVISION" "$FULL_QUALIFICATION" <<'PY'
import hashlib, json, pathlib, sys
info_path = pathlib.Path(sys.argv[1])
proof_path = pathlib.Path(sys.argv[2])
counter_path = pathlib.Path(sys.argv[3])
countercounter_path = pathlib.Path(sys.argv[4])
source_sha = sys.argv[5]
revision = sys.argv[6]
qualification = sys.argv[7]

def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

counter = json.loads(counter_path.read_text(encoding="utf-8"))
countercounter = json.loads(countercounter_path.read_text(encoding="utf-8"))
if counter.get("passed") is not True or countercounter.get("passed") is not True:
    raise SystemExit("ERROR: cannot finalize qualification from failing counteraudit report")

info = json.loads(info_path.read_text(encoding="utf-8"))
info["playable"] = True
info["qualified"] = True
info["qualification"] = qualification
info_path.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")

proof = {
    "revision": revision,
    "source_commit": source_sha,
    "qualification": qualification,
    "counteraudit_passed": True,
    "countercounteraudit_passed": True,
    "counteraudit_report_sha256": digest(counter_path),
    "countercounteraudit_report_sha256": digest(countercounter_path),
}
proof_path.write_text(json.dumps(proof, indent=2) + "\n", encoding="utf-8")
PY

# Strict verifier is the only state accepted by the publisher/preview server.
python3 "$ROOT/tools/verify_web_export.py" "$BUILD_DIR" | tee "$VALIDATION_DIR/web-verifier.log"
rm -f "$ROOT/.codespaces/build-failed" "$ROOT/.codespaces/build-in-progress"
touch "$ROOT/.codespaces/build-ok"
echo "[eden] Web export qualified: $BUILD_DIR"
echo "[eden] product revision: $PRODUCT_REVISION"
echo "[eden] qualification: $FULL_QUALIFICATION"
