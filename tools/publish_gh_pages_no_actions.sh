#!/usr/bin/env bash
set -euo pipefail

# Publish an already-qualified Godot Web export directly to gh-pages.
# This script never invokes GitHub Actions and refuses to operate from main.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build/web"
SOURCE_BRANCH="godmode/production-assets-v6-rebuild"
PUBLISH_BRANCH="gh-pages"
TMP_BRANCH="__eden_pages_publish"
PRODUCT_REVISION="0.6.4-authored-art4"

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
  echo "GitHub Pages branch publishing requires an authenticated maintainer push." >&2
  exit 5
fi

SOURCE_SHA="$(git rev-parse HEAD)"
BUILD_SHA="$(python3 - "$BUILD_DIR/build-info.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8')).get('source_commit',''))
PY
)"
BUILD_REVISION="$(python3 - "$BUILD_DIR/build-info.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1],encoding='utf-8')).get('version',''))
PY
)"
if [[ "$BUILD_SHA" != "$SOURCE_SHA" ]]; then
  echo "ERROR: build was produced from $BUILD_SHA but branch head is $SOURCE_SHA; rebuild before publishing" >&2
  exit 6
fi
if [[ "$BUILD_REVISION" != "$PRODUCT_REVISION" ]]; then
  echo "ERROR: refusing stale product revision: $BUILD_REVISION" >&2
  exit 6
fi

echo "[eden] publishing $PRODUCT_REVISION / $SOURCE_SHA to $PUBLISH_BRANCH without Actions"
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
cp "$TMP_DIR/index.html" "$TMP_DIR/404.html"

# Direct network-only cache reset for browsers that still hold an obsolete PWA
# worker. Cleanup is limited to this Gameish scope and EDEN cache prefix; Web
# save data in IndexedDB/localStorage is intentionally preserved.
cat > "$TMP_DIR/purge.html" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>EDEN//FALL cache reset</title></head><body style="background:#050b0c;color:#e9dfbf;font-family:system-ui;padding:2rem"><h1>EDEN//FALL WEB CACHE RESET</h1><p id="s">Removing obsolete EDEN//FALL cached build…</p><script>(async()=>{const scope=new URL('./',location.href).pathname;const prefix='Gameish: EDEN//F-sw-cache-';try{if('serviceWorker'in navigator){const r=await navigator.serviceWorker.getRegistrations();await Promise.all(r.filter(x=>new URL(x.scope).pathname.startsWith(scope)).map(x=>x.unregister()));}if('caches'in window){const k=await caches.keys();await Promise.all(k.filter(x=>x.startsWith(prefix)).map(x=>caches.delete(x)));}}finally{document.getElementById('s').textContent='EDEN//FALL cache cleared. Loading current network build…';setTimeout(()=>location.replace('./?v='+Date.now()),350);}})();</script></body></html>
HTML

# Re-run static verification from the exact directory that will become gh-pages.
python3 "$ROOT/tools/verify_web_export.py" "$TMP_DIR"

git -C "$TMP_DIR" add -A
if git -C "$TMP_DIR" diff --cached --quiet; then
  echo "[eden] gh-pages already matches this qualified export"
  exit 0
fi

git -C "$TMP_DIR" commit -m "Publish EDEN FALL $PRODUCT_REVISION $SOURCE_SHA"
PUBLISH_SHA="$(git -C "$TMP_DIR" rev-parse HEAD)"
git -C "$TMP_DIR" push origin HEAD:"$PUBLISH_BRANCH"

REMOTE_SHA="$(git ls-remote origin "refs/heads/$PUBLISH_BRANCH" | awk '{print $1}')"
if [[ "$REMOTE_SHA" != "$PUBLISH_SHA" ]]; then
  echo "ERROR: remote gh-pages tip $REMOTE_SHA does not match published commit $PUBLISH_SHA" >&2
  exit 7
fi

echo "[eden] published and verified remote $PUBLISH_BRANCH @ $REMOTE_SHA"
echo "[eden] GitHub Pages branch source should remain: gh-pages / (root)"
