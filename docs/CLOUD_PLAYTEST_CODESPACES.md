# EDEN//FALL — browser-only Godot playtest and GitHub Pages publish

This is the canonical no-local-machine, no-custom-GitHub-Actions workflow for EDEN//FALL V8.

## Constraints

- Never use the repository default branch for the game build.
- Create the Codespace from `godmode/production-assets-v6-rebuild`.
- Do not invoke or edit custom GitHub Actions.
- GitHub Pages remains configured as `Deploy from a branch` → `gh-pages` → `/(root)`.
- The Web test preset is non-threaded and non-PWA.

## Why Codespaces

GitHub Codespaces provides a native Linux development VM/container accessible entirely in a web browser. Unlike Godot's Web editor, a Codespace can run the native Godot binary and export the project.

The repository contains `.devcontainer/devcontainer.json`, so a Codespace created from the production branch automatically:

1. provisions Ubuntu;
2. installs Godot's native runtime libraries;
3. downloads exact Godot 4.7.1 and its official export templates;
4. imports the project;
5. executes the RC6/RC7/V8 audit stack;
6. performs a bounded native game boot;
7. exports the non-threaded, non-PWA Web build;
8. verifies HTML/JS/WASM/PCK and build metadata;
9. attempts an authenticated direct push of the verified static build to `gh-pages`;
10. serves the same build on forwarded port `8000` as a private browser preview.

No custom workflow runner is involved.

## Create the cloud environment

In GitHub's repository UI:

1. Switch the branch selector to `godmode/production-assets-v6-rebuild`.
2. Select **Code**.
3. Select **Codespaces**.
4. Choose **Create codespace on godmode/production-assets-v6-rebuild**. If GitHub shows advanced options, keep this branch and the repository's `.devcontainer/devcontainer.json` configuration.

The first creation takes longer because exact Godot 4.7.1 and export templates are downloaded into the cloud environment.

## Browser preview

When qualification succeeds, the devcontainer forwards port `8000` and labels it:

`EDEN//FALL Web Preview`

GitHub Codespaces should open the forwarded preview automatically. If it does not, open the **Ports** panel and select the URL for port `8000`.

The preview is served from the exact `build/web` directory that passed the export verifier.

## GitHub Pages publication

The setup attempts publication automatically after a successful build when the Codespace has GitHub CLI authentication.

Publication is direct static branch publishing:

`godmode/production-assets-v6-rebuild` source → native Godot Web export inside Codespaces → verified `build/web` → direct Git push → `gh-pages`

There is no intermediate `main` branch and no custom GitHub Actions job.

If automatic publication is unavailable, use the browser terminal:

```bash
bash tools/codespaces_publish.sh --use-existing
```

That command refuses to operate unless the checked-out branch is `godmode/production-assets-v6-rebuild` and the existing verified build belongs to the current Git commit.

## Rebuild after code changes

From the browser terminal:

```bash
bash tools/codespaces_preview.sh
```

This reruns import, all audits, bounded boot, Web export and verification, then restarts the forwarded preview server.

To publish the newly verified build:

```bash
bash tools/codespaces_publish.sh --use-existing
```

## Failure evidence

Build output is preserved at:

- `.codespaces/build.log`
- `.codespaces/publish.log`
- `.codespaces/preview.log`

The transient `.tools`, `.codespaces` and `build` directories are ignored by Git.

## Old GitHub Pages cache

The historical v0.6.0 Web export enabled Godot PWA caching. The current Web test channel disables PWA generation and includes scoped cleanup for the old `/Gameish/` worker/cache.

If a browser still presents the old v0.6.0 build, open the repository Pages site's `/purge.html` once. It removes only the EDEN//FALL `/Gameish/` service-worker scope/cache and returns to the network build.

## Why not the Godot Web editor

Godot's browser editor can import and run source projects, but its documented limitations include no project exporting. It is useful as an emergency source-level browser test, but it cannot replace the native Web export required for GitHub Pages. Codespaces supplies the native engine/export step while remaining fully online.
