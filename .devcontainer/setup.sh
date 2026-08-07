#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" == "main" ]]; then
  echo "ERROR: EDEN//FALL Codespaces must be created from godmode/production-assets-v6-rebuild, never main." >&2
  exit 2
fi
if [[ "$BRANCH" != "godmode/production-assets-v6-rebuild" ]]; then
  echo "ERROR: create this Codespace from godmode/production-assets-v6-rebuild; current branch: ${BRANCH:-unknown}" >&2
  exit 2
fi

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip python3 git \
  libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libgl1 libasound2t64 libpulse0 libdbus-1-3 libudev1

chmod +x tools/export_web_no_actions.sh tools/publish_gh_pages_no_actions.sh || true
chmod +x tools/codespaces_serve.sh tools/codespaces_preview.sh tools/codespaces_publish.sh 2>/dev/null || true

mkdir -p .codespaces
rm -f .codespaces/build-ok .codespaces/build-failed .codespaces/publish-ok .codespaces/publish-failed

echo "[codespaces] Preparing exact Godot 4.7.1 and V8 Web build in the cloud..."
set +e
bash tools/export_web_no_actions.sh 2>&1 | tee .codespaces/build.log
BUILD_CODE=${PIPESTATUS[0]}
set -e

if [[ $BUILD_CODE -eq 0 ]]; then
  touch .codespaces/build-ok
  echo "[codespaces] V8 Web build is qualified. Port 8000 will open as an online preview."

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "[codespaces] GitHub authentication detected; publishing this exact verified build to gh-pages..."
    set +e
    bash tools/codespaces_publish.sh --use-existing 2>&1 | tee .codespaces/publish.log
    PUBLISH_CODE=${PIPESTATUS[0]}
    set -e
    if [[ $PUBLISH_CODE -eq 0 ]]; then
      touch .codespaces/publish-ok
      echo "[codespaces] V8 is published to gh-pages."
    else
      touch .codespaces/publish-failed
      echo "[codespaces] Automatic gh-pages publish failed, but the online port-8000 preview is valid." >&2
      echo "[codespaces] See .codespaces/publish.log, then retry: bash tools/codespaces_publish.sh --use-existing" >&2
    fi
  else
    touch .codespaces/publish-failed
    echo "[codespaces] GitHub CLI authentication is unavailable; the browser preview is still ready." >&2
    echo "[codespaces] Once authenticated, publish with: bash tools/codespaces_publish.sh --use-existing" >&2
  fi
else
  touch .codespaces/build-failed
  echo "[codespaces] Native Godot qualification/export failed. The Codespace remains usable for fixing the reported error." >&2
  echo "[codespaces] Read .codespaces/build.log, then rerun: bash tools/codespaces_preview.sh" >&2
fi

# Do not make Codespace creation itself unusable on a game-build failure; all
# qualification/publish failures are retained in .codespaces/*.log.
exit 0
