#!/usr/bin/env bash
set -euo pipefail

# EDEN//FALL — Codespaces/local Web export, explicitly without GitHub Actions.
# Qualification is staged and fail-closed:
# source/tooling -> verified toolchain -> Godot audits -> Web structure ->
# evidence counteraudit -> mutation countercounteraudit -> provisional proof ->
# final-artifact mutation countercounteraudit -> strict publishable verifier.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${EDEN_TOOLS_DIR:-$ROOT/.tools}"
GODOT_VERSION="4.7.1"
GODOT_DIR="$TOOLS_DIR/godot-$GODOT_VERSION"
DOWNLOAD_DIR="$TOOLS_DIR/downloads"
GODOT_ZIP="$DOWNLOAD_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
TEMPLATES_TPZ="$DOWNLOAD_DIR/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
GODOT_URL="https://downloads.godotengine.org/?flavor=stable&platform=linux.64&slug=linux.x86_64.zip&version=${GODOT_VERSION}"
TEMPLATES_URL="https://downloads.godotengine.org/?flavor=stable&platform=templates&slug=export_templates.tpz&version=${GODOT_VERSION}"
# Pinned from the official godotengine/godot-builds 4.7.1-stable release assets.
GODOT_ZIP_SHA256="c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"
TEMPLATES_TPZ_SHA256="86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
TEMPLATE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
TEMPLATE_STAMP="$TEMPLATE_HOME/.eden-verified-template"
BUILD_DIR="$ROOT/build/web"
VALIDATION_DIR="$ROOT/validation/no-actions-art4"
TOOLCHAIN_LOG="$VALIDATION_DIR/toolchain-provenance.log"
PRODUCT_REVISION="0.6.4-authored-art4"
FULL_QUALIFICATION="all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+systems-stress+input-lifecycle+legacy+boot+web+counteraudit+mutation-countercounteraudit+final-artifact-countercounteraudit"
SOURCE_BRANCH="godmode/production-assets-v6-rebuild"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: required command not found: $1" >&2; exit 2; }
}
for tool in bash curl unzip git python3 timeout tee grep find sha256sum basename cp mkdir rm mv chmod; do
  need "$tool"
done

sha256_of() {
  local file="$1"
  local line
  line="$(sha256sum "$file")"
  printf '%s' "${line%% *}"
}

ensure_verified_archive() {
  local file="$1"
  local url="$2"
  local expected="$3"
  local label="$4"
  local actual=""
  if [[ -s "$file" ]]; then
    actual="$(sha256_of "$file")"
    if [[ "$actual" != "$expected" ]]; then
      echo "[eden] cached $label checksum mismatch; discarding cached archive" >&2
      rm -f "$file"
    fi
  fi
  if [[ ! -s "$file" ]]; then
    echo "[eden] downloading verified $label" >&2
    curl --fail --location --retry 3 --retry-delay 2 --output "$file" "$url"
  fi
  actual="$(sha256_of "$file")"
  if [[ "$actual" != "$expected" ]]; then
    rm -f "$file"
    echo "ERROR: $label SHA-256 mismatch: got $actual expected $expected" >&2
    exit 3
  fi
  printf '%s\n' "$actual"
}

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

mkdir -p "$ROOT/.codespaces"
rm -f "$ROOT/.codespaces/build-ok"
touch "$ROOT/.codespaces/build-failed"
printf '%s\n' "$SOURCE_SHA" > "$ROOT/.codespaces/build-in-progress"
rm -rf "$VALIDATION_DIR" "$BUILD_DIR"
mkdir -p "$GODOT_DIR" "$DOWNLOAD_DIR" "$BUILD_DIR" "$VALIDATION_DIR"
python3 "$ROOT/tools/static_tooling_audit.py" | tee "$VALIDATION_DIR/tooling-audit.log"
python3 "$ROOT/tools/audit_source_counteraudit.py" | tee "$VALIDATION_DIR/audit-source-counteraudit.log"
printf '%s\n' "$SOURCE_SHA" > "$VALIDATION_DIR/source-commit.txt"
: > "$TOOLCHAIN_LOG"

# Reconstruct the editor from the verified official archive on every qualification
# so a stale/tampered cached executable can never inherit trust from --version alone.
GODOT_ARCHIVE_HASH="$(ensure_verified_archive "$GODOT_ZIP" "$GODOT_URL" "$GODOT_ZIP_SHA256" "Godot ${GODOT_VERSION} Linux x86_64 editor")"
printf 'EDEN_TOOLCHAIN_GODOT_ARCHIVE_SHA256=%s\n' "$GODOT_ARCHIVE_HASH" | tee -a "$TOOLCHAIN_LOG"
rm -rf "$GODOT_DIR/unpacked"
mkdir -p "$GODOT_DIR/unpacked"
unzip -q -o "$GODOT_ZIP" -d "$GODOT_DIR/unpacked"
GODOT_BIN="$(find "$GODOT_DIR/unpacked" -maxdepth 1 -type f -name 'Godot_v*-stable_linux.x86_64' | head -n1)"
[[ -n "$GODOT_BIN" ]] || { echo "ERROR: Godot executable missing from verified archive" >&2; exit 3; }
rm -f "$GODOT_DIR/godot"
mv "$GODOT_BIN" "$GODOT_DIR/godot"
chmod +x "$GODOT_DIR/godot"

GODOT="$GODOT_DIR/godot"
ENGINE_VERSION="$($GODOT --version | head -n1)"
case "$ENGINE_VERSION" in
  4.7.1.stable*) ;;
  *) echo "ERROR: expected Godot 4.7.1.stable, got $ENGINE_VERSION" >&2; exit 4 ;;
esac
printf '%s\n' "$ENGINE_VERSION" | tee "$VALIDATION_DIR/engine-version.log"

# The 1.2+ GiB template archive does not need to be re-unpacked every run. The
# first verified installation records both the official TPZ digest and the inner
# Web no-threads template digest; subsequent runs re-hash the installed template.
TEMPLATE_OK=0
if [[ -s "$TEMPLATE_HOME/web_nothreads_release.zip" && -s "$TEMPLATE_STAMP" ]]; then
  mapfile -t STAMP_LINES < "$TEMPLATE_STAMP"
  if [[ "${STAMP_LINES[0]:-}" == "$TEMPLATES_TPZ_SHA256" && "${STAMP_LINES[1]:-}" =~ ^[0-9a-f]{64}$ ]]; then
    INSTALLED_TEMPLATE_HASH="$(sha256_of "$TEMPLATE_HOME/web_nothreads_release.zip")"
    if [[ "$INSTALLED_TEMPLATE_HASH" == "${STAMP_LINES[1]}" ]]; then
      TEMPLATE_OK=1
    fi
  fi
fi
if [[ $TEMPLATE_OK -ne 1 ]]; then
  TEMPLATES_ARCHIVE_HASH="$(ensure_verified_archive "$TEMPLATES_TPZ" "$TEMPLATES_URL" "$TEMPLATES_TPZ_SHA256" "Godot ${GODOT_VERSION} export templates")"
  TMP_TEMPLATES="$(mktemp -d)"
  unzip -q -o "$TEMPLATES_TPZ" -d "$TMP_TEMPLATES"
  SRC_TEMPLATES="$(find "$TMP_TEMPLATES" -type f -name 'web_nothreads_release.zip' -printf '%h\n' | head -n1)"
  [[ -n "$SRC_TEMPLATES" ]] || { rm -rf "$TMP_TEMPLATES"; echo "ERROR: Web no-threads export template not found" >&2; exit 5; }
  mkdir -p "$TEMPLATE_HOME"
  cp -a "$SRC_TEMPLATES"/. "$TEMPLATE_HOME"/
  rm -rf "$TMP_TEMPLATES"
  INSTALLED_TEMPLATE_HASH="$(sha256_of "$TEMPLATE_HOME/web_nothreads_release.zip")"
  printf '%s\n%s\n' "$TEMPLATES_ARCHIVE_HASH" "$INSTALLED_TEMPLATE_HASH" > "$TEMPLATE_STAMP"
else
  TEMPLATES_ARCHIVE_HASH="$TEMPLATES_TPZ_SHA256"
fi
INSTALLED_TEMPLATE_HASH="$(sha256_of "$TEMPLATE_HOME/web_nothreads_release.zip")"
printf 'EDEN_TOOLCHAIN_TEMPLATES_ARCHIVE_SHA256=%s\n' "$TEMPLATES_ARCHIVE_HASH" | tee -a "$TOOLCHAIN_LOG"
printf 'EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=%s\n' "$INSTALLED_TEMPLATE_HASH" | tee -a "$TOOLCHAIN_LOG"
printf 'EDEN_TOOLCHAIN_ENGINE_VERSION=%s\n' "$ENGINE_VERSION" | tee -a "$TOOLCHAIN_LOG"
printf 'EDEN_TOOLCHAIN_PROVENANCE=PASS\n' | tee -a "$TOOLCHAIN_LOG"

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

run_scene_audit() {
  local scene="$1"
  local name="$2"
  local log="$VALIDATION_DIR/${name}.log"
  echo "[eden] scene audit: $scene"
  set +e
  timeout 30s "$GODOT" --headless --audio-driver Dummy --path "$ROOT" "$scene" >"$log" 2>&1
  local code=$?
  set -e
  cat "$log"
  if [[ $code -ne 0 ]]; then
    echo "ERROR: scene audit $scene failed with code $code" >&2
    exit 21
  fi
  fatal_log "$log"
}

echo "[eden] clean editor import / project parse"
IMPORT_LOG="$VALIDATION_DIR/import.log"
"$GODOT" --headless --audio-driver Dummy --path "$ROOT" --editor --quit --verbose 2>&1 | tee "$IMPORT_LOG"
fatal_log "$IMPORT_LOG"

run_audit "res://tests/all_gdscript_compile_audit.gd"
run_audit "res://tests/v8_compile_chain_probe.gd"

AUDITS=(
  "res://tests/v8_release_integrity_audit.gd"
  "res://tests/v8_live_binding_counteraudit.gd"
  "res://tests/v8_art4_reference_audit.gd"
  "res://tests/v8_art4_pixel_counteraudit.gd"
  "res://tests/v8_systems_stress_counteraudit.gd"
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

run_scene_audit "res://tests/v6_input_lifecycle_audit.tscn" "v6_input_lifecycle_audit"

echo "[eden] bounded headless game boot"
BOOT_LOG="$VALIDATION_DIR/boot.log"
set +e
timeout 15s "$GODOT" --headless --audio-driver Dummy --path "$ROOT" --quit-after 180 --verbose >"$BOOT_LOG" 2>&1
BOOT_CODE=$?
set -e
cat "$BOOT_LOG"
if [[ $BOOT_CODE -ne 0 ]]; then
  echo "ERROR: bounded game boot failed or timed out with code $BOOT_CODE" >&2
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
    "qualification_stage": "pending",
    "built_at": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
}
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

python3 "$ROOT/tools/verify_web_export.py" --structural "$BUILD_DIR" | tee "$VALIDATION_DIR/structural-verifier.log"
sha256sum "$BUILD_DIR/index.html" "$BUILD_DIR/index.js" "$BUILD_DIR/index.wasm" "$BUILD_DIR/index.pck" > "$VALIDATION_DIR/web-sha256.txt"

COUNTER_REPORT="$VALIDATION_DIR/qualification-counteraudit-report.json"
python3 "$ROOT/tools/qualification_counteraudit.py" \
  --build "$BUILD_DIR" --validation "$VALIDATION_DIR" --report "$COUNTER_REPORT" \
  | tee "$VALIDATION_DIR/qualification-counteraudit.log"

COUNTERCOUNTER_REPORT="$VALIDATION_DIR/qualification-countercounteraudit-report.json"
python3 "$ROOT/tools/qualification_countercounteraudit.py" \
  --build "$BUILD_DIR" --validation "$VALIDATION_DIR" --report "$COUNTERCOUNTER_REPORT" \
  | tee "$VALIDATION_DIR/qualification-countercounteraudit.log"

PORTABLE_QUALIFICATION="$BUILD_DIR/qualification"
mkdir -p "$PORTABLE_QUALIFICATION"
PORTABLE_COUNTER="$PORTABLE_QUALIFICATION/counteraudit-report.json"
PORTABLE_COUNTERCOUNTER="$PORTABLE_QUALIFICATION/countercounteraudit-report.json"
cp "$COUNTER_REPORT" "$PORTABLE_COUNTER"
cp "$COUNTERCOUNTER_REPORT" "$PORTABLE_COUNTERCOUNTER"

# Provisional proof: report hashes and exact Web payload hashes are bound before
# the final-artifact mutation stage. Strict publishing is still impossible here.
python3 - "$BUILD_DIR/build-info.json" "$BUILD_DIR/qualification-proof.json" \
  "$PORTABLE_COUNTER" "$PORTABLE_COUNTERCOUNTER" "$SOURCE_SHA" "$PRODUCT_REVISION" "$FULL_QUALIFICATION" <<'PY'
import hashlib, json, pathlib, sys
info_path = pathlib.Path(sys.argv[1])
proof_path = pathlib.Path(sys.argv[2])
counter_path = pathlib.Path(sys.argv[3])
countercounter_path = pathlib.Path(sys.argv[4])
source_sha = sys.argv[5]
revision = sys.argv[6]
qualification = sys.argv[7]
build = info_path.parent
core_files = ("index.html", "index.js", "index.wasm", "index.pck")

def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

counter = json.loads(counter_path.read_text(encoding="utf-8"))
countercounter = json.loads(countercounter_path.read_text(encoding="utf-8"))
if counter.get("passed") is not True or countercounter.get("passed") is not True:
    raise SystemExit("ERROR: cannot finalize qualification from failing counteraudit report")
if counter.get("source_commit") != source_sha or counter.get("revision") != revision:
    raise SystemExit("ERROR: portable counteraudit report provenance mismatch")
if countercounter.get("source_commit") != source_sha or countercounter.get("revision") != revision:
    raise SystemExit("ERROR: portable countercounteraudit report provenance mismatch")

info = json.loads(info_path.read_text(encoding="utf-8"))
info["playable"] = False
info["qualified"] = False
info["qualification"] = qualification
info["qualification_stage"] = "pre-final"
info_path.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")

proof = {
    "revision": revision,
    "source_commit": source_sha,
    "qualification": qualification,
    "counteraudit_passed": True,
    "countercounteraudit_passed": True,
    "counteraudit_report_sha256": digest(counter_path),
    "countercounteraudit_report_sha256": digest(countercounter_path),
    "payload_sha256": {name: digest(build / name) for name in core_files},
}
proof_path.write_text(json.dumps(proof, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 "$ROOT/tools/verify_web_export.py" --pre-final "$BUILD_DIR" | tee "$VALIDATION_DIR/web-pre-final-verifier.log"

FINAL_REPORT="$VALIDATION_DIR/final-artifact-countercounteraudit-report.json"
python3 "$ROOT/tools/final_artifact_countercounteraudit.py" \
  --build "$BUILD_DIR" --report "$FINAL_REPORT" \
  | tee "$VALIDATION_DIR/final-artifact-countercounteraudit.log"
PORTABLE_FINAL="$PORTABLE_QUALIFICATION/final-artifact-countercounteraudit-report.json"
cp "$FINAL_REPORT" "$PORTABLE_FINAL"

# Finalize the proof only after the final-artifact mutation suite passes.
python3 - "$BUILD_DIR/build-info.json" "$BUILD_DIR/qualification-proof.json" "$PORTABLE_FINAL" "$SOURCE_SHA" "$PRODUCT_REVISION" <<'PY'
import hashlib, json, pathlib, sys
info_path = pathlib.Path(sys.argv[1])
proof_path = pathlib.Path(sys.argv[2])
report_path = pathlib.Path(sys.argv[3])
source_sha = sys.argv[4]
revision = sys.argv[5]
report = json.loads(report_path.read_text(encoding="utf-8"))
if report.get("passed") is not True:
    raise SystemExit("ERROR: final-artifact countercounteraudit did not pass")
if report.get("source_commit") != source_sha or report.get("revision") != revision:
    raise SystemExit("ERROR: final-artifact countercounteraudit provenance mismatch")
info = json.loads(info_path.read_text(encoding="utf-8"))
info["playable"] = True
info["qualified"] = True
info["qualification_stage"] = "final"
info_path.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
proof = json.loads(proof_path.read_text(encoding="utf-8"))
proof["final_countercounteraudit_passed"] = True
proof["final_countercounteraudit_report_sha256"] = hashlib.sha256(report_path.read_bytes()).hexdigest()
proof_path.write_text(json.dumps(proof, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 "$ROOT/tools/verify_web_export.py" "$BUILD_DIR" | tee "$VALIDATION_DIR/web-verifier.log"
rm -f "$ROOT/.codespaces/build-failed" "$ROOT/.codespaces/build-in-progress"
touch "$ROOT/.codespaces/build-ok"
echo "[eden] Web export qualified: $BUILD_DIR"
echo "[eden] product revision: $PRODUCT_REVISION"
echo "[eden] qualification: $FULL_QUALIFICATION"
