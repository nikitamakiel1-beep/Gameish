#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

USE_EXISTING=false
if [[ "${1:-}" == "--use-existing" ]]; then
  USE_EXISTING=true
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$BRANCH" != "godmode/production-assets-v6-rebuild" ]]; then
  echo "ERROR: cloud publish must run from godmode/production-assets-v6-rebuild; current branch: ${BRANCH:-unknown}" >&2
  exit 2
fi

command -v gh >/dev/null 2>&1 || { echo "ERROR: GitHub CLI is required in Codespaces" >&2; exit 3; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: this Codespace is not authenticated to GitHub" >&2; exit 4; }

LOGIN="$(gh api user --jq .login)"
USER_ID="$(gh api user --jq .id)"
if [[ -z "$(git config user.name || true)" ]]; then
  git config user.name "$LOGIN"
fi
if [[ -z "$(git config user.email || true)" ]]; then
  git config user.email "${USER_ID}+${LOGIN}@users.noreply.github.com"
fi

if [[ "$USE_EXISTING" == false ]]; then
  echo "[codespaces] Building and qualifying current feature-branch head before publish..."
  bash tools/export_web_no_actions.sh
else
  echo "[codespaces] Reusing the already-qualified Codespaces Web build."
  python3 tools/verify_web_export.py build/web
  CURRENT_SHA="$(git rev-parse HEAD)"
  BUILD_SHA="$(python3 - <<'PY'
import json
print(json.load(open('build/web/build-info.json',encoding='utf-8')).get('source_commit',''))
PY
)"
  if [[ "$CURRENT_SHA" != "$BUILD_SHA" ]]; then
    echo "ERROR: existing Web build belongs to $BUILD_SHA but branch head is $CURRENT_SHA" >&2
    exit 5
  fi
fi

echo "[codespaces] Publishing the verified static Web export directly to gh-pages..."
bash tools/publish_gh_pages_no_actions.sh

echo "[codespaces] Publish complete. GitHub Pages source remains gh-pages / (root)."
echo "[codespaces] If the browser ever shows the old v0.6.0 build, open /Gameish/purge.html once."
