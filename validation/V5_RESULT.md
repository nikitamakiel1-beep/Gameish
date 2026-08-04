# EDEN//FALL v0.5 Godot 4.7.1 validation receipt

## Validated implementation

- Result: **PASS**
- Implementation commit: `30608f43312ea037d21e4ee4d07f82c48d5ade3e`
- Engine: `Godot 4.7.1.stable`
- Exact-head workflow run: `30910219715`
- Exact-build workflow run: `30910219870`
- Legacy validation run: `30910219742`

## Source and behavioral gates

- Complete project import and script parse: `0`
- v3 eight-direction regression: `0`
- v4 systems regression: `0`
- v4.1 quality regression: `0`
- v5 architecture, responsive UI and export contract: `0`
- Main-scene boot: `0`
- Fatal parser/runtime markers: `0`
- Exact branch checkout matched the remote branch SHA.
- Independent legacy parse-and-boot workflow: **PASS**

## Exact export results

| Target | Result | Engineering output |
|---|---:|---|
| Windows x86-64 | PASS | Embedded-PCK executable archive |
| Linux x86-64 | PASS | Executable tarball |
| macOS universal | PASS | Unsigned universal application ZIP |
| Web/PWA | PASS | HTML, JavaScript, PCK, WASM, manifest and service worker |
| Android ARM64 APK | PASS | Debug-signed installable APK |
| Android ARM64 AAB | PASS | Debug-signed Gradle bundle |
| iOS | PASS | Unsigned Xcode project and required XCFrameworks |

## Exact build hashes

```text
2e7b12b609e9dbe9fa6b2986e7bb4f8e459b7e315d26a1b86516a41cddf73d94  EDEN_FALL-windows-x86_64.zip
7c381a66efe6a9254ec18b3b83254df3fa0b05600c76937efb8898cb8052b7c6  EDEN_FALL-linux-x86_64.tar.gz
5f2260f4941e03027008c967a3a81030d045b33052a8f5694f717ff0187179aa  EDEN_FALL-macos.zip
b784b6c41f7204d016718cd691d36bf19b025f9c949b4781f67d426fa8e92a41  web/index.html
69b329e28b6d85a41628fe70f6614486e0f0c6075aeb8602e31bd48e5ec718af  web/index.pck
35116f68540ac41acf7d71ea457added91b5e960a9cca3e2acc72918eaf01277  web/index.wasm
be2a0896863a03db0f30277503f5f77069a860ed2b4bcf6e89b56d4de82a46e9  EDEN_FALL-debug.apk
e5482ee4fb1c5c796a335f52f776575214ce551806c220593d35f6a6ddff979b  EDEN_FALL-debug.aab
ba137d84d0fef28062fbf6cf12c338556d1022454f0d14bbcae6af92251bf717  EDEN_FALL-ios-xcode-project.zip
```

## GitHub Actions artifacts

- Exact desktop/Web/Android builds: artifact `8892845838`
  - Artifact digest: `sha256:1a9783459ab406916192b1b3cb4c8634a4dcb2b43b4e10fe972e9f858a69e274`
- Exact iOS engineering package: artifact `8892760951`
  - Artifact digest: `sha256:e2bf623559a9f070f76748302561682f667f1fe7c8d2793ba8ac13a7c8b7baed`
- Exact-head receipt: artifact `8892742198`
  - Artifact digest: `sha256:43449db6b7597ee6822dba43380acf125cf9603f49ec8e8f486d1e5550668caa`

Artifacts are retained by GitHub Actions for fourteen days. Build hashes remain the durable verification record.

## Validated v5 contracts

- Godot 4.7 project and renderer configuration.
- Eight-direction movement, aiming, shooting, dashing and animation regression.
- Five lineages, five weapon identities, five biomes, eighteen standard enemies, five bosses and sixty relic protocols.
- Daily, standard and training run modes.
- Chamber modifiers, elite affixes, status effects, trials, sanctuaries, combo, score and mastery.
- Responsive compact, medium and wide UI layouts.
- Compact phone HUD and safe-area-contained phone lineage selection.
- Mouse hover focus, spatial keyboard navigation and controller navigation.
- Enlarged touch targets, left-handed layout and device-specific prompts.
- Battery/performance FPS profiles.
- Atomic v5 settings persistence with temporary-file writes and backup recovery.
- Seven export presets spanning six platform families.
- S3TC and ETC2/ASTC texture paths for desktop, mobile and Apple targets.

## Qualification boundary

The APK and AAB use engineering/debug signing. The macOS build is not notarized. The iOS artifact is an unsigned Xcode project because no Apple signing identity or provisioning profile is stored in the repository. These outputs are valid test and integration builds, not store-ready signed submissions.
