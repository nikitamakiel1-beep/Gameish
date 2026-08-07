#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)" == "main" ]]; then
  echo "ERROR: EDEN//FALL Codespaces must be created from godmode/production-assets-v6-rebuild, never main." >&2
  exit 2
fi

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip python3 git \
  libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libgl1 libasound2t64 libdbus-1-3 libudev1

chmod +x tools/export_web_no_actions.sh tools/publish_gh_pages_no_actions.sh || true
chmod +x tools/codespaces_serve.sh tools/codespaces_publish.sh 2>/dev/null || true

mkdir -p .codespaces
rm -f .codespaces/build-ok .codespaces/build-failed

echo "[codespaces] Preparing exact Godot 4.7.1 and V8 Web build in the cloud..."
set +e
bash tools/export_web_no_actions.sh 2>&1 | tee .codespaces/build.log
BUILD_CODE=${PIPESTATUS[0]}
set -e

if [[ $BUILD_CODE -eq 0 ]]; then
  touch .codespaces/build-ok
  echo "[codespaces] V8 Web build is ready. Port 8000 will open as an online preview."
else
  touch .codespaces/build-failed
  echo "[codespaces] The native Godot qualification/export failed. The Codespace is still usable." >&2
  echo "[codespaces] Read .codespaces/build.log, fix the reported Godot error on this feature branch, then run: bash tools/codespaces_preview.sh" >&2
fi

# Keep container creation usable even when the game fails qualification; the
# failure is preserved in .codespaces/build.log instead of hiding it.
exit 0
