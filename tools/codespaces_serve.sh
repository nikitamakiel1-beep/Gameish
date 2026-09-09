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

for required in index.html index.js index.wasm index.pck build-info.json .nojekyll; do
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

python3 "$VERIFY" "$BUILD_DIR" > "$ROOT/.codespaces/serve-verifier.log"

CURRENT_SHA="$(git -C "$ROOT" rev-parse HEAD)"
BUILD_SHA="$(python3 - "$BUILD_DIR/build-info.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8')).get('source_commit',''))
PY
)"
if [[ "$BUILD_SHA" != "$CURRENT_SHA" ]]; then
  echo "ERROR: refusing stale preview. build=$BUILD_SHA current=$CURRENT_SHA" >&2
  echo "[codespaces] Rebuild with: bash tools/codespaces_preview.sh" >&2
  exit 3
fi

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[codespaces] EDEN//FALL preview already running on port $PORT (PID $OLD_PID)."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

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

# Verify the listener from inside Codespaces before telling the user to open it.
if command -v curl >/dev/null 2>&1; then
  if ! curl --fail --silent --show-error --max-time 4 "http://127.0.0.1:${PORT}/build-info.json" >/dev/null; then
    cat "$LOG_FILE" >&2 || true
    kill "$PID" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    echo "ERROR: preview process started but did not serve the qualified build" >&2
    exit 5
  fi
fi

echo "[codespaces] EDEN//FALL Art4 preview serving qualified build/web on port $PORT with no-cache headers."
echo "[codespaces] Source: $CURRENT_SHA"
echo "[codespaces] If an older PWA ever controlled this origin, open /purge.html once before the game."
echo "[codespaces] Open the forwarded port named: EDEN//FALL Web Preview"
