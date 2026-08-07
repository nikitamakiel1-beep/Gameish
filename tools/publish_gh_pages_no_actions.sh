#!/usr/bin/env bash
set -euo pipefail

# Publish an already-verified Godot Web export directly to gh-pages.
# This script never uses or edits GitHub Actions and refuses to operate from main.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build/web"
SOURCE_BRANCH="godmode/production-assets-v6-rebuild"
PUBLISH_BRANCH="gh-pages"
TMP_BRANCH="__eden_pages_publish"

command -v git >/dev/null 2>&1 || { echo "ERROR: git is required" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required" >&2; exit 2; }

cd "$ROOT"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "ERROR: refusing to publish from main" >&2
  exit 3
fi
if [[ "$CURRENT_BRANCH" != "$SOURCE_BRANCH" ]]; then
  echo "ERROR: expected source branch $SOURCE_BRANCH, got ${CURRENT_BRANCH:-detached}" >&2
  exit 4
fi

python3 "$ROOT/tools/verify_web_export.py" "$BUILD_DIR"

EMAIL="$(git config user.email || true)"
NAME="$(git config user.name || true)"
if [[ -z "$EMAIL" || -z "$NAME" ]]; then
  echo "ERROR: git user.name and user.email must be configured before publishing." >&2
  echo "GitHub Pages branch publishing requires an administrator/maintainer push; use a GitHub-verified email." >&2
  exit 5
fi

SOURCE_SHA="$(git rev-parse HEAD)"
BUILD_SHA="$(python3 - "$BUILD_DIR/build-info.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8')).get('source_commit',''))
PY
)"
if [[ "$BUILD_SHA" != "$SOURCE_SHA" ]]; then
  echo "ERROR: build was produced from $BUILD_SHA but branch head is $SOURCE_SHA; rebuild before publishing" >&2
  exit 6
fi

echo "[eden] publishing $SOURCE_SHA to $PUBLISH_BRANCH without custom Actions"
git fetch origin "$PUBLISH_BRANCH"
TMP_DIR="$(mktemp -d)"
cleanup() {
  git worktree remove --force "$TMP_DIR" >/dev/null 2>&1 || true
  git branch -D "$TMP_BRANCH" >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

git branch -D "$TMP_BRANCH" >/dev/null 2>&1 || true
git worktree add -B "$TMP_BRANCH" "$TMP_DIR" "origin/$PUBLISH_BRANCH"

# Delete the previous generated site while preserving the worktree's .git file.
find "$TMP_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -a "$BUILD_DIR"/. "$TMP_DIR"/

# A direct network-only cache reset entry point remains available for browsers
# that still hold the obsolete v0.6.0 PWA worker. Cleanup is deliberately
# limited to the Gameish service-worker scope and EDEN//FALL cache prefix so it
# cannot disturb another project hosted on the same username.github.io origin.
cat > "$TMP_DIR/purge.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>EDEN//FALL cache reset</title></head><body style="background:#050b0c;color:#e9dfbf;font-family:system-ui;padding:2rem"><h1>EDEN//FALL WEB CACHE RESET</h1><p id="s">Removing obsolete EDEN//FALL cached build…</p><script>(async()=>{const scope=new URL('./',location.href).pathname;const prefix='Gameish: EDEN//F-sw-cache-';try{if('serviceWorker'in navigator){const r=await navigator.serviceWorker.getRegistrations();await Promise.all(r.filter(x=>new URL(x.scope).pathname.startsWith(scope)).map(x=>x.unregister()));}if('caches'in window){const k=await caches.keys();await Promise.all(k.filter(x=>x.startsWith(prefix)).map(x=>caches.delete(x)));}}finally{document.getElementById('s').textContent='EDEN//FALL cache cleared. Loading current network build…';setTimeout(()=>location.replace('./?v='+Date.now()),350);}})();</script></body></html>
HTML

git -C "$TMP_DIR" add -A
if git -C "$TMP_DIR" diff --cached --quiet; then
  echo "[eden] gh-pages already matches this export"
  exit 0
fi

git -C "$TMP_DIR" commit -m "Publish EDEN FALL V8 Web $SOURCE_SHA"
git -C "$TMP_DIR" push origin HEAD:"$PUBLISH_BRANCH"
echo "[eden] published to $PUBLISH_BRANCH"
echo "[eden] GitHub Pages branch source should remain: gh-pages / (root)"
