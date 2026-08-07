#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SOURCE_BRANCH="godmode/production-assets-v6-rebuild"

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" != "$SOURCE_BRANCH" ]]; then
  echo "ERROR: expected $SOURCE_BRANCH, got ${BRANCH:-unknown}" >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Codespace working tree has uncommitted changes; refusing to overwrite them." >&2
  git status --short >&2
  exit 3
fi

echo "[codespaces] syncing $SOURCE_BRANCH"
git fetch origin "$SOURCE_BRANCH"
git pull --ff-only origin "$SOURCE_BRANCH"
echo "[codespaces] source head: $(git rev-parse HEAD)"

chmod +x tools/export_web_no_actions.sh tools/codespaces_preview.sh tools/codespaces_serve.sh || true
exec bash tools/codespaces_preview.sh
