#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${EDEN_PREVIEW_PORT:-8000}"
PID_FILE="$ROOT/.codespaces/preview.pid"
LOG_FILE="$ROOT/.codespaces/preview.log"
BUILD_DIR="$ROOT/build/web"
SERVER="$ROOT/tools/codespaces_no_cache_server.py"

mkdir -p "$ROOT/.codespaces"

if [[ ! -s "$BUILD_DIR/index.html" || ! -s "$BUILD_DIR/index.wasm" || ! -s "$BUILD_DIR/index.pck" ]]; then
  echo "[codespaces] No qualified Web export exists yet; preview server not started."
  echo "[codespaces] Run: bash tools/codespaces_preview.sh"
  exit 0
fi
if [[ ! -s "$SERVER" ]]; then
  echo "ERROR: no-cache preview server helper is missing: $SERVER" >&2
  exit 2
fi

if [[ -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[codespaces] EDEN//FALL preview already running on port $PORT (PID $OLD_PID)."
    exit 0
  fi
fi

nohup python3 "$SERVER" --port "$PORT" --bind 0.0.0.0 --directory "$BUILD_DIR" >"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"
sleep 0.4

if ! kill -0 "$PID" 2>/dev/null; then
  cat "$LOG_FILE" >&2 || true
  echo "ERROR: preview server failed to start" >&2
  exit 3
fi

echo "[codespaces] EDEN//FALL V8 preview serving build/web on port $PORT with no-cache headers."
echo "[codespaces] If an older PWA ever controlled this origin, open /purge.html once before the game."
echo "[codespaces] Open the forwarded port named: EDEN//FALL Web Preview"
