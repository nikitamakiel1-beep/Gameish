#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" != "godmode/production-assets-v6-rebuild" ]]; then
  echo "ERROR: online preview must run from godmode/production-assets-v6-rebuild; current branch: ${BRANCH:-unknown}" >&2
  exit 2
fi

mkdir -p .codespaces

echo "[codespaces] Rebuilding and qualifying EDEN//FALL V8 with exact Godot 4.7.1..."
bash tools/export_web_no_actions.sh 2>&1 | tee .codespaces/build.log
touch .codespaces/build-ok
rm -f .codespaces/build-failed

# Codespaces is an iterative preview origin. Older PWA builds may have left a
# service worker/Cache Storage entry behind even though the current export is
# deliberately non-PWA. Publish a one-shot retirement page next to the build;
# it unregisters workers and clears Cache Storage without touching save data.
cp tools/codespaces_purge.html build/web/purge.html

if [[ -f .codespaces/preview.pid ]]; then
  PID="$(cat .codespaces/preview.pid 2>/dev/null || true)"
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" || true
    sleep 0.3
  fi
  rm -f .codespaces/preview.pid
fi

bash tools/codespaces_serve.sh
