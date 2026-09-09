# EDEN//FALL — GitHub Pages without custom Actions

This is the canonical browser-test and direct branch-publish path for EDEN//FALL Art4.

## Non-negotiable branch policy

- Game source: `godmode/production-assets-v6-rebuild`.
- Static browser build: `gh-pages` at `/(root)`.
- The repository default branch is not part of build or publish.
- No custom GitHub Actions workflow is invoked or edited by this process.
- Codespaces creation/rebuild never publishes automatically; publication is an explicit action after preview review.

GitHub Pages may show its own internal deployment record after a `gh-pages` push. That is GitHub hosting behavior, not an EDEN//FALL custom build workflow.

## Web channel

The iterative Pages channel deliberately uses:

- `variant/thread_support=false`;
- `progressive_web_app/enabled=false`;
- no generated service worker or offline page;
- `.nojekyll` at the published root;
- a one-shot `purge.html` helper for retiring caches from historical PWA builds.

The qualified payload is always `index.html`, `index.js`, `index.wasm` and `index.pck` plus qualification metadata/evidence.

## Exact local/Codespaces qualification

Run from `godmode/production-assets-v6-rebuild` on Linux, WSL or Codespaces:

```bash
bash tools/export_web_no_actions.sh
```

The exporter is fail-closed and performs, in order:

1. static tooling audit and independent source counteraudit;
2. branch/clean-tree/source-SHA checks;
3. SHA-256 verification of the official Godot 4.7.1 Linux x86_64 archive;
4. reconstruction of the editor from that verified archive;
5. SHA-256 verification of the official 4.7.1 export-template TPZ;
6. derivation of the exact `web_nothreads_release.zip` member digest from the verified TPZ and comparison with the installed template;
7. exact `4.7.1.stable` engine check and clean editor import;
8. complete GDScript compile-chain probes;
9. release-integrity, live-binding, Art4 reference/pixel, systems-stress and expressive-range gates;
10. presentation, compatibility, input-lifecycle, entropy and sprite-streaming gates;
11. bounded real headless game boot; any nonzero exit, including timeout, fails;
12. non-threaded/non-PWA Web export and structural verification;
13. SHA-256 capture of all four core Web payload files;
14. independent qualification counteraudit, including a fresh toolchain recomputation;
15. 15-case qualification mutation countercounteraudit, including two complete toolchain recomputations;
16. provisional proof creation while the artifact remains explicitly unqualified;
17. pre-final verifier;
18. 13-case final-artifact mutation countercounteraudit, including semantic forgeries with correctly rebound report hashes;
19. final promotion to `playable=true`, `qualified=true`, `qualification_stage=final`;
20. strict portable verifier.

Official pinned SHA-256 values for Godot 4.7.1:

- Linux x86_64 editor archive: `c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba`
- export-template TPZ: `86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72`

## Exact qualification contract

A publishable Art4 artifact must declare:

```text
all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+systems-stress+expressive-range+input-lifecycle+legacy+boot+web+counteraudit+mutation-countercounteraudit+final-artifact-countercounteraudit
```

Portable evidence must attest exactly:

- product revision `0.6.4-authored-art4`;
- source branch `godmode/production-assets-v6-rebuild`;
- full lowercase 40-character source commit equal to the qualified HEAD;
- Godot `4.7.1`;
- `pwa=false`, `threads=false`;
- 17 Godot audit logs;
- 24 required logs total;
- 21 exact PASS markers;
- 15 rejected qualification mutations;
- 2 full toolchain recomputations inside the mutation countercounteraudit;
- 13 rejected final-artifact mutations;
- SHA-256 binding of `index.html`, `index.js`, `index.wasm` and `index.pck`;
- independently recomputed editor/template member/install digests;
- passing hashes for all portable counteraudit reports.

The final `build-info.json` must contain `playable=true`, `qualified=true` and `qualification_stage=final`.

## Preview first

In Codespaces, prefer:

```bash
bash tools/codespaces_sync_preview.sh
```

This fast-forwards the feature branch, rebuilds/qualifies the exact HEAD and serves only that strict artifact on forwarded port 8000. Preview serving refuses stale source provenance or incomplete qualification.

Review the fresh port-8000 build before publishing.

## Explicit publish to GitHub Pages

Only after qualification and visual review:

```bash
bash tools/codespaces_publish.sh --use-existing
```

or directly:

```bash
bash tools/publish_gh_pages_no_actions.sh
```

The publisher:

1. refuses `main` and any unexpected source branch;
2. refuses tracked source changes;
3. requires all three portable qualification reports and proof metadata;
4. runs the strict verifier again;
5. proves build/proof/final-report provenance against current HEAD;
6. creates a temporary worktree from `gh-pages`;
7. copies only the qualified static build plus cache-retirement helper;
8. verifies the copied artifact again;
9. commits and pushes directly to `gh-pages`;
10. confirms the remote branch tip equals the commit just pushed.

GitHub Pages must remain configured as:

- Source: **Deploy from a branch**
- Branch: **gh-pages**
- Folder: **/(root)**

## Browser cache reset

Historical builds used `index.service.worker.js`. If a browser visibly serves an obsolete build, open the Pages site's `/purge.html` once. It unregisters the old EDEN//FALL service worker and clears its Cache Storage entries without deleting game save data.

New qualified Art4 exports do not recreate a service worker.

## Qualification status rule

Source implementation alone is never described as a qualified release. Qualification applies only to the exact source HEAD whose native Godot 4.7.1 run produced a strict passing artifact. The PR remains draft/unmerged until that run and fresh browser visual review are complete.
