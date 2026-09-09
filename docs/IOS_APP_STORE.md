# EDEN//FALL — iOS and App Store release runbook

Last reviewed: 9 September 2026.

This document is operational guidance for turning the qualified EDEN//FALL Godot project into a signed iPhone/iPad build. Apple/Xcode requirements change; verify the official Apple and Godot documentation before every submission.

## 1. Current prerequisites

Required for App Store distribution:

- A Mac running a macOS release supported by the required Xcode version.
- Xcode 26 or later with an iOS 26 SDK. Apple has required App Store Connect uploads to use Xcode 26+ and the iOS 26/iPadOS 26 SDK family since 28 April 2026.
- Godot **4.7.1 stable** and matching 4.7.1 export templates.
- Apple Developer Program membership.
- An App Store Connect app record.
- A unique reverse-DNS bundle identifier controlled by the publisher.
- A valid Apple Team ID and signing/provisioning configuration.
- App metadata, screenshots, privacy disclosures, age-rating answers, support URL and privacy-policy URL.

Official references:

- Godot iOS export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Apple upcoming requirements: https://developer.apple.com/news/upcoming-requirements/
- App Store submission: https://developer.apple.com/app-store/submitting/
- App Store screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

Godot's iOS exporter must run on macOS with Xcode installed. Matching export templates are required. The App Store Team ID and Bundle Identifier are required export fields; leaving them empty causes the exporter to fail.

## 2. EDEN//FALL product identity

Current development identity:

- Product: `EDEN//FALL`.
- Repository/product family: `Gameish`.
- Current development version: `0.6.4` / `0.6.4-authored-art4`.
- Godot engine: `4.7.1 stable`.
- Renderer: GL Compatibility.
- Bundle identifier in the repository export preset: `com.gameish.edenfall` as a development placeholder/working identifier; confirm publisher ownership and App Store registration before signing.
- Primary category: Games.

The repository does not contain release signing credentials. Team ID, signing identities, provisioning profiles and private keys are release-environment data.

## 3. Qualification before iOS export

Do not begin store signing from an unqualified source commit.

The source commit should first pass the normal feature-branch qualification path in Codespaces or an equivalent exact-Godot environment:

```bash
bash tools/codespaces_sync_preview.sh
```

At minimum, require:

```text
EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS
EDEN_COMPILE_CHAIN=PASS
EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS
EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS
```

and all inherited product/runtime/entropy/streaming gates. Browser success is not evidence that iOS lifecycle, touch, safe areas, thermals or signing are correct; it only establishes a known-good gameplay/source baseline.

## 4. Prepare the Godot iOS project

1. Install Godot 4.7.1 Standard on macOS.
2. Install the exact matching 4.7.1 export templates.
3. Checkout the exact qualified source commit.
4. Open/import `project.godot` and resolve any platform-specific import/export errors.
5. Open `Project > Export` and inspect the existing `iOS Xcode` preset.
6. Supply/verify:
   - Apple Team ID;
   - final registered bundle identifier;
   - short version/build number appropriate for the App Store record;
   - target device family;
   - landscape orientation policy;
   - production icon/launch assets;
   - required privacy usage strings for any capability actually used.
7. Export to a clean folder outside generated repository state where practical.

Godot exports an Xcode project. Signing, physical-device installation, archiving and App Store upload then happen through Xcode.

The iOS simulator supports Godot's Compatibility renderer; EDEN//FALL already targets GL Compatibility, which keeps the rendering path aligned with that constraint.

## 5. Xcode checks

Open the exported Xcode project and verify:

- the correct Apple development team;
- exact registered bundle identifier;
- automatic or manual signing resolves without errors;
- marketing version/build number match the intended App Store Connect version;
- deployment target matches the supported/tested device matrix;
- landscape orientations are correct;
- app icons contain no unsupported transparency and required slots are valid;
- no unsupported capabilities are enabled;
- Release scheme is used for archives;
- no privacy-manifest/required-reason API issue is reported for Godot or any future plugin;
- the exact qualified source revision can be traced from release records.

Never commit certificates, `.p12` files, provisioning profiles, Apple private keys or App Store Connect API keys.

## 6. Physical-device test matrix

Before TestFlight, test on real hardware. At minimum:

- one recent large-screen iPhone;
- one smaller supported iPhone;
- one older supported iPhone near the performance floor;
- one iPad if iPad distribution remains enabled.

Test:

- first launch and save creation;
- all five canonical lineage selection screens;
- winning and losing excursions;
- traversal in every door direction;
- dense projectile encounters;
- trader/relic/faction interactions;
- simultaneous move/aim/dash touches;
- safe-area/home-indicator overlap;
- background/resume during combat, pause, menus and save transitions;
- interruptions and focus changes;
- low-power/thermal behavior;
- offline/airplane-mode launch;
- reinstall/save-loss expectations before cloud sync;
- audio through speaker/Bluetooth and interruption behavior;
- reduced-flash/reduced-motion/control settings;
- sustained 60 FPS target and any lower-power frame cap.

A desktop or Web pass is not evidence that touch, safe-area, lifecycle or thermal behavior is correct on iOS.

## 7. TestFlight

1. Archive the qualified Release build in Xcode.
2. Validate the archive.
3. Distribute to App Store Connect.
4. Wait for Apple processing.
5. Use internal testers first.
6. Expand to external testers only after the initial build is stable enough for beta review.
7. Capture crash logs, device model, OS version, lineage, biome/room, source revision and reproduction steps.

Every uploaded build must use a unique build number.

## 8. Screenshots and product page

Apple currently permits one to ten screenshots per supported display class and requires image files without alpha/transparency.

For 6.9-inch iPhone landscape screenshots, currently accepted native sizes include:

- 2736 x 1260;
- 2796 x 1290;
- 2868 x 1320.

If the app runs on iPad, provide the required iPad screenshot class as specified by App Store Connect. Current 13-inch iPad landscape sizes include 2752 x 2064 and 2732 x 2048.

Use screenshots from the submitted build. Recommended EDEN//FALL coverage:

1. canonical lineage selection;
2. readable combat in Industrial Eden;
3. devastated Ash Wastes/environmental storytelling;
4. trader/relic or unusual build interaction;
5. Fungal Garden or Nephilim Ruins landmark room;
6. guardian/boss encounter;
7. Archive/settings/accessibility if those screens are included in the submitted build.

Do not use competitor art, comparison captions or concept-only graphics that imply content absent from the submitted build.

## 9. Privacy position

The product architecture remains local-first. If the submitted build has no analytics, advertising SDK, account system, cloud save or purchase SDK, App Store privacy answers should reflect that exact submitted behavior.

Re-evaluate disclosures immediately when any network/plugin layer is added. Potential future transmitted data may include account identifiers, cloud-save content, leaderboard records, diagnostics or purchase data.

A public privacy-policy URL and in-app accessible privacy information should exist before commercial submission.

## 10. Age rating

Apple introduced an updated age-rating system in 2026. Complete the current App Store Connect questionnaire based on the exact submitted build rather than an old assumed rating.

EDEN//FALL contains stylized weapon combat, mutants and horror/fear themes. Final rating depends on the implemented intensity and questionnaire answers. Preserve the intended stylized presentation if targeting a lower teen classification:

- avoid realistic dismemberment/gore;
- avoid prolonged detailed suffering;
- avoid simulated gambling/paid randomized functional loot boxes;
- describe religious/biotechnological horror accurately in rating answers.

## 11. Accessibility release gate

Implement and physically verify before claiming support:

- adjustable UI/control scale;
- left-handed touch layout;
- adjustable stick opacity/dead zone;
- aim assistance option;
- reduced screen shake;
- reduced flash;
- color-independent projectile/pickup silhouettes;
- subtitles for spoken narrative if voice is present;
- independent master/music/effects volume;
- haptic intensity/off setting;
- large/reliable pause target;
- readable text/contrast across supported screens.

Only declare App Store accessibility features that are actually tested in the submitted build.

## 12. App Review preparation

Before submission:

- select the correct processed build;
- complete all required metadata;
- add real screenshots;
- complete privacy answers;
- complete current age-rating answers;
- provide support/privacy-policy URLs;
- answer export-compliance questions accurately;
- provide reviewer notes explaining offline single-player operation and controls;
- provide a practical route to representative gameplay content;
- confirm no executable code or external game content is downloaded dynamically unless explicitly designed/reviewed;
- verify ownership/licensing for all art, audio, fonts and trademarks;
- test the exact archived build, not only the Godot editor/Web build;
- record the source Git SHA used for the archive.

## 13. Public-release gate

Do not treat Art4 qualification alone as a 1.0 commercial-release guarantee. Before public App Store release, require:

- final visual/audio review on physical devices;
- stable progression/save migration;
- complete accessibility/settings pass;
- robust lifecycle suspend/resume;
- representative content depth/balance;
- sustained performance on the oldest supported device;
- privacy/support pages online;
- TestFlight regression/balancing cohort;
- no known progression-loss, generation blocker, input blocker or crash;
- a signed release archive built with the Apple-required Xcode/SDK generation current at submission time.
