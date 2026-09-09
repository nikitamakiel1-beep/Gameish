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
FULL_QUALIFICATION="all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+systems-stress+input-lifecycle+legacy+boot+web+counteraudit+mutation-countercounteraudit"

for tool in git python3 awk find; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool is required" >&2; exit 2; }
done

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
if ! git diff --quiet --ignore-submodules -- || ! git diff --cached --quiet --ignore-submodules --; then
  echo "ERROR: tracked source is dirty; publish only the exact committed source" >&2
  git status --short >&2
  exit 4
fi

[[ -s "$BUILD_DIR/build-info.json" ]] || { echo "ERROR: build-info.json missing" >&2; exit 5; }
[[ -s "$BUILD_DIR/qualification-proof.json" ]] || { echo "ERROR: qualification-proof.json missing; rebuild and complete counteraudits" >&2; exit 5; }
[[ -s "$BUILD_DIR/qualification/counteraudit-report.json" ]] || { echo "ERROR: portable counteraudit report missing" >&2; exit 5; }
[[ -s "$BUILD_DIR/qualification/countercounteraudit-report.json" ]] || { echo "ERROR: portable countercounteraudit report missing" >&2; exit 5; }

# Strict verifier requires the finalized qualification proof and recomputes the
# portable evidence hashes before anything can be copied to gh-pages.
python3 "$ROOT/tools/verify_web_export.py" "$BUILD_DIR"

EMAIL="$(git config user.email || true)"
NAME="$(git config user.name || true)"
if [[ -z "$EMAIL" || -z "$NAME" ]]; then
  echo "ERROR: git user.name and user.email must be configured before publishing." >&2
  echo "GitHub Pages branch publishing requires an authenticated maintainer push." >&2
  exit 5
fi

SOURCE_SHA="$(git rev-parse HEAD)"
python3 - "$BUILD_DIR/build-info.json" "$BUILD_DIR/qualification-proof.json" "$SOURCE_SHA" "$PRODUCT_REVISION" "$FULL_QUALIFICATION" <<'PY'
import json, pathlib, sys
info_path = pathlib.Path(sys.argv[1])
proof_path = pathlib.Path(sys.argv[2])
source_sha = sys.argv[3]
revision = sys.argv[4]
qualification = sys.argv[5]
info = json.loads(info_path.read_text(encoding="utf-8"))
proof = json.loads(proof_path.read_text(encoding="utf-8"))
checks = [
    (info.get("source_commit") == source_sha, "build source commit does not equal current branch HEAD"),
    (info.get("version") == revision, "build product revision is stale"),
    (info.get("qualified") is True and info.get("playable") is True, "build is not finalized as playable/qualified"),
    (info.get("qualification") == qualification, "build qualification contract mismatch"),
    (proof.get("source_commit") == source_sha, "qualification proof source commit mismatch"),
    (proof.get("revision") == revision, "qualification proof revision mismatch"),
    (proof.get("qualification") == qualification, "qualification proof contract mismatch"),
    (proof.get("counteraudit_passed") is True, "qualification proof lacks counteraudit success"),
    (proof.get("countercounteraudit_passed") is True, "qualification proof lacks countercounteraudit success"),
]
errors = [message for ok, message in checks if not ok]
if errors:
    raise SystemExit("ERROR: " + "; ".join(errors))
PY

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

# Re-run strict verification from the exact directory that will become gh-pages.
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
