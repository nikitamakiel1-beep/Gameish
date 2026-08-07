# EDEN//FALL — GitHub Pages without custom Actions

This is the canonical browser-test path for EDEN//FALL.

## Non-negotiable branch policy

- Game source: `godmode/production-assets-v6-rebuild`.
- Static browser build: `gh-pages` at `/(root)`.
- The default Git branch is not part of the build or publish path.
- No custom GitHub Actions workflow is required or edited by this process.

GitHub Pages itself may show an internal Pages deployment record after a branch push. That is GitHub's hosting implementation, not an EDEN//FALL custom build workflow. The Godot build happens before the push.

## Why the old browser build looked stale

The v0.6.0 Web preset enabled Godot PWA mode. Godot's generated service worker cached `index.html`, `index.js`, `index.wasm`, `index.pck` and related files under the project scope. During rapid GitHub Pages testing this can keep an obsolete exported PCK alive after the repository has changed.

V8's GitHub Pages test preset therefore uses:

- `variant/thread_support=false`;
- `progressive_web_app/enabled=false`;
- no Web service worker;
- no offline page;
- a small head cleanup that unregisters legacy workers and deletes old browser caches;
- `.nojekyll` at the published root.

A production PWA can be reintroduced later as a separate release preset after browser iteration stabilizes.

## Exact local/Codespaces build

Run from the source branch on Linux, WSL or GitHub Codespaces:

```bash
chmod +x tools/export_web_no_actions.sh tools/publish_gh_pages_no_actions.sh
./tools/export_web_no_actions.sh
```

The exporter:

1. refuses the default branch;
2. downloads exact Godot 4.7.1 from the official Godot download endpoint if missing;
3. downloads and installs official 4.7.1 export templates if missing;
4. checks the exact engine version;
5. runs Godot `--import`;
6. executes the RC6, RC7 and V8 audit scripts;
7. runs a bounded headless game boot and rejects parse/resource errors;
8. exports the non-threaded `Web` release preset;
9. verifies `index.html`, `index.js`, `index.wasm` and `index.pck`;
10. rejects generated PWA/service-worker files;
11. writes `.nojekyll` and `build-info.json`;
12. runs `tools/verify_web_export.py`.

## Publish to GitHub Pages

After a successful export:

```bash
./tools/publish_gh_pages_no_actions.sh
```

The publisher:

1. refuses the default branch;
2. requires the exact source branch;
3. re-verifies the static export;
4. checks that `build-info.json` was produced from the current source commit;
5. requires a configured Git author identity;
6. creates a temporary worktree from `gh-pages`;
7. replaces the old static site with `build/web`;
8. restores `purge.html` for legacy browser-cache cleanup;
9. commits the exported files;
10. pushes directly to `gh-pages`;
11. removes the temporary worktree and branch.

GitHub Pages must remain configured as:

- Source: **Deploy from a branch**
- Branch: **gh-pages**
- Folder: **/(root)**

For branch publishing, use a GitHub account with repository administration/maintenance rights and an email address verified by GitHub.

## Browser cache reset

The old v0.6.0 deployment registered `index.service.worker.js`. The current `gh-pages` branch contains a one-shot retirement version of that worker plus `purge.html`.

When a browser is visibly stuck on an obsolete build, open the site's `/purge.html` once. It unregisters service workers, removes browser Cache Storage entries and returns to a cache-busted network navigation.

New V8 test exports do not recreate the service worker.

## Web compatibility rationale

EDEN//FALL's Pages test channel deliberately disables Godot Web threads. This avoids the cross-origin isolation requirement associated with threaded Web exports and gives the broadest compatibility on GitHub Pages, mobile browsers and embedded browser contexts. Performance-sensitive systems are controlled with projectile/effect budgets, streamed procedural sprite generation and room-scoped caches instead.

## Godot Web Editor fallback

The official Godot Web Editor can be useful for emergency inspection or educational experimentation when no native editor is available, and it can preload project ZIPs. It is not the production build path because the Godot project itself describes the native editor as the recommended environment and the Web Editor has platform/browser limitations.

The supported production-like browser test remains the native/headless 4.7.1 export followed by direct branch publishing.

## Release evidence

A browser build is not considered current unless all of the following agree:

- `build-info.json.version` is `0.6.2-entropy`;
- `build-info.json.source_commit` equals the source branch head used for export;
- `build-info.json.source_branch` is `godmode/production-assets-v6-rebuild`;
- `build-info.json.pwa` is `false`;
- `build-info.json.threads` is `false`;
- `index.service.worker.js` is absent from the newly exported payload;
- the V8 audits pass under exact Godot 4.7.1.
