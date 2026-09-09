#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${EDEN_PREVIEW_PORT:-8000}"
PID_FILE="$ROOT/.codespaces/preview.pid"
LOG_FILE="$ROOT/.codespaces/preview.log"
BUILD_DIR="$ROOT/build/web"
SERVER="$ROOT/tools/codespaces_no_cache_server.py"
VERIFY="$ROOT/tools/verify_web_export.py"

mkdir -p "$ROOT/.codespaces"

if [[ -e "$ROOT/.codespaces/build-failed" ]] || [[ ! -e "$ROOT/.codespaces/build-ok" ]]; then
  echo "ERROR: current Codespaces build is not in a completed qualified state" >&2
  echo "[codespaces] Run: bash tools/codespaces_preview.sh" >&2
  exit 2
fi

for required in \
  index.html index.js index.wasm index.pck build-info.json qualification-proof.json .nojekyll \
  qualification/counteraudit-report.json \
  qualification/countercounteraudit-report.json \
  qualification/final-artifact-countercounteraudit-report.json; do
  if [[ ! -e "$BUILD_DIR/$required" ]] || { [[ "$required" != ".nojekyll" ]] && [[ ! -s "$BUILD_DIR/$required" ]]; }; then
    echo "ERROR: no qualified Web export exists; missing/empty $required" >&2
    echo "[codespaces] Run: bash tools/codespaces_preview.sh" >&2
    exit 2
  fi
done
if [[ ! -s "$SERVER" ]]; then
  echo "ERROR: no-cache preview server helper is missing: $SERVER" >&2
  exit 2
fi
if [[ ! -s "$VERIFY" ]]; then
  echo "ERROR: Web verifier helper is missing: $VERIFY" >&2
  exit 2
fi

# Strict mode recomputes the payload/report hashes and requires the final
# artifact countercounteraudit. Structural/pre-final states are never served.
python3 "$VERIFY" "$BUILD_DIR" > "$ROOT/.codespaces/serve-verifier.log"

CURRENT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
python3 - "$BUILD_DIR/build-info.json" "$BUILD_DIR/qualification-proof.json" \
  "$BUILD_DIR/qualification/final-artifact-countercounteraudit-report.json" "$CURRENT_SHA" <<'PY'
import json, pathlib, sys
info = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
proof = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
final = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
head = sys.argv[4]
errors = []
if info.get("source_commit") != head:
    errors.append(f"build source {info.get('source_commit')} != HEAD {head}")
if proof.get("source_commit") != head:
    errors.append(f"proof source {proof.get('source_commit')} != HEAD {head}")
if final.get("source_commit") != head:
    errors.append(f"final countercounteraudit source {final.get('source_commit')} != HEAD {head}")
if info.get("qualified") is not True or info.get("playable") is not True:
    errors.append("build is not marked qualified/playable")
if proof.get("counteraudit_passed") is not True or proof.get("countercounteraudit_passed") is not True:
    errors.append("qualification proof is incomplete")
if proof.get("final_countercounteraudit_passed") is not True or final.get("passed") is not True:
    errors.append("final-artifact countercounteraudit is incomplete")
if errors:
    raise SystemExit("ERROR: refusing stale/unqualified preview: " + "; ".join(errors))
PY

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[codespaces] EDEN//FALL preview already running on port $PORT (PID $OLD_PID)."
  else
    rm -f "$PID_FILE"
  fi
fi

if [[ ! -f "$PID_FILE" ]]; then
  nohup python3 "$SERVER" --port "$PORT" --bind 0.0.0.0 --directory "$BUILD_DIR" >"$LOG_FILE" 2>&1 &
  PID=$!
  echo "$PID" > "$PID_FILE"
  sleep 0.5

  if ! kill -0 "$PID" 2>/dev/null; then
    cat "$LOG_FILE" >&2 || true
    rm -f "$PID_FILE"
    echo "ERROR: preview server failed to start" >&2
    exit 4
  fi
fi

PID="$(cat "$PID_FILE")"
if command -v curl >/dev/null 2>&1; then
  SERVED_INFO="$(mktemp)"
  SERVED_PROOF="$(mktemp)"
  SERVED_FINAL="$(mktemp)"
  cleanup_http_probe() { rm -f "$SERVED_INFO" "$SERVED_PROOF" "$SERVED_FINAL"; }
  trap cleanup_http_probe EXIT
  if ! curl --fail --silent --show-error --max-time 4 "http://127.0.0.1:${PORT}/build-info.json" -o "$SERVED_INFO" \
    || ! curl --fail --silent --show-error --max-time 4 "http://127.0.0.1:${PORT}/qualification-proof.json" -o "$SERVED_PROOF" \
    || ! curl --fail --silent --show-error --max-time 4 "http://127.0.0.1:${PORT}/qualification/final-artifact-countercounteraudit-report.json" -o "$SERVED_FINAL"; then
    cat "$LOG_FILE" >&2 || true
    kill "$PID" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    echo "ERROR: preview process did not serve final qualification metadata" >&2
    exit 5
  fi
  if ! python3 - "$SERVED_INFO" "$SERVED_PROOF" "$SERVED_FINAL" "$CURRENT_SHA" <<'PY'
import json, pathlib, sys
info = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
proof = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
final = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
head = sys.argv[4]
if info.get("source_commit") != head or proof.get("source_commit") != head or final.get("source_commit") != head:
    raise SystemExit(1)
if info.get("qualified") is not True or proof.get("final_countercounteraudit_passed") is not True or final.get("passed") is not True:
    raise SystemExit(1)
PY
  then
    kill "$PID" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    echo "ERROR: preview listener is serving stale/unqualified metadata" >&2
    exit 6
  fi
fi

echo "[codespaces] EDEN//FALL Art4 preview serving fully qualified build/web on port $PORT with no-cache headers."
echo "[codespaces] Source: $CURRENT_SHA"
echo "[codespaces] Audit chain: audit -> counteraudit -> mutation countercounteraudit -> final-artifact countercounteraudit"
echo "[codespaces] If an older PWA ever controlled this origin, open /purge.html once before the game."
echo "[codespaces] Open the forwarded port named: EDEN//FALL Web Preview"
