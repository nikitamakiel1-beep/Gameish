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

# The cloud container may set executable bits on shell helpers. Every project
# helper is invoked with `bash`, so file-mode-only differences are irrelevant.
git config core.fileMode false

# Refuse only real edits to tracked source. Godot 4.7 legitimately creates
# untracked .import and .uid metadata during the first import; those must not
# block a fast-forward sync of product fixes.
if ! git diff --quiet --ignore-submodules --; then
  echo "ERROR: Codespace has tracked content edits; refusing to overwrite them." >&2
  git diff --stat >&2
  exit 3
fi

echo "[codespaces] syncing $SOURCE_BRANCH"
git fetch origin "$SOURCE_BRANCH"
git pull --ff-only origin "$SOURCE_BRANCH"
echo "[codespaces] source head: $(git rev-parse HEAD)"

exec bash tools/codespaces_preview.sh
