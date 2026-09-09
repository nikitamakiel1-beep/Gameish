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

# Codespaces/Linux can report executable-bit changes for tracked helper scripts even
# though every helper is invoked explicitly through `bash`. Ignore file-mode-only
# differences so cloud setup never dirties the source tree.
git config core.fileMode false

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates curl unzip python3 git \
  libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libgl1 libasound2t64 libpulse0 libdbus-1-3 libudev1

mkdir -p .codespaces
rm -f .codespaces/build-ok .codespaces/build-failed .codespaces/publish-ok .codespaces/publish-failed

echo "[codespaces] Preparing exact Godot 4.7.1 and the qualified Art4 Web preview..."
set +e
bash tools/export_web_no_actions.sh 2>&1 | tee .codespaces/build.log
BUILD_CODE=${PIPESTATUS[0]}
set -e

if [[ $BUILD_CODE -eq 0 ]]; then
  SOURCE_SHA="$(git rev-parse HEAD)"
  printf '%s\n' "$SOURCE_SHA" > .codespaces/build-ok
  rm -f .codespaces/build-failed
  echo "[codespaces] Art4 Web build is qualified for preview. Port 8000 will open after attach."
  echo "[codespaces] Publishing is intentionally NOT automatic. Review the exact preview first."
  echo "[codespaces] After visual review, publish explicitly with: bash tools/codespaces_publish.sh --use-existing"
else
  printf '%s\n' "failed" > .codespaces/build-failed
  echo "[codespaces] Native Godot qualification/export failed. The Codespace remains usable for fixing the reported error." >&2
  echo "[codespaces] Read .codespaces/build.log, then rerun: bash tools/codespaces_preview.sh" >&2
fi

# Do not make Codespace creation itself unusable on a game-build failure; all
# qualification failures are retained in .codespaces/*.log. Publication is a
# separate explicit release action after visual review.
exit 0
