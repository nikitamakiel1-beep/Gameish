# iOS and App Store Release Runbook

Last reviewed: 3 August 2026.

This document is operational guidance for turning the Godot project into a signed iPhone/iPad build. Apple and Godot requirements change, so verify the linked official documentation before every release.

## 1. Current prerequisites

Required for App Store distribution:

- A Mac capable of running the current Xcode release.
- Xcode 26 or later and an iOS 26 SDK for App Store uploads under Apple's requirements effective 28 April 2026.
- Godot 4.6.3 Standard and matching export templates.
- Apple Developer Program membership.
- An App Store Connect app record.
- A unique bundle identifier.
- Apple signing certificates and provisioning managed by Xcode or the developer account.
- App metadata, screenshots, privacy disclosures, age-rating answers, support URL, and privacy-policy URL.

Apple Developer Program membership is currently 99 USD per membership year, charged in local currency where available.

Official references:

- Godot iOS export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Apple upcoming requirements: https://developer.apple.com/news/upcoming-requirements/
- Apple enrollment: https://developer.apple.com/programs/enroll/
- App Store submission: https://developer.apple.com/app-store/submitting/

## 2. Product identity decisions

Resolve these before creating the App Store Connect record:

- App Store name: recommended working name `EDEN//FALL`.
- Repository/product family name: `Gameish`.
- Bundle identifier: replace `com.yourstudio.gameish.edenfall` with a unique reverse-DNS identifier controlled by the publisher.
- SKU: internal value such as `GAMEISH-EDENFALL-IOS-001`.
- Primary category: Games.
- Secondary category: Action or Role Playing, after reviewing the final feature set.
- Monetization: recommended initial model is premium paid download, or a free demo with a non-consumable full-game unlock.

Do not create paid randomized functional loot boxes. They complicate balance, age-rating disclosures, purchase design, and review.

## 3. Prepare the Godot project

1. Install Godot 4.6.3 Standard on macOS.
2. Open the project and allow it to import all files.
3. Install matching export templates from `Editor > Manage Export Templates`.
4. Run the project on desktop and resolve all parser/runtime errors.
5. Open `Project > Export` and add an iOS preset.
6. Configure at minimum:
   - App Store Team ID.
   - Bundle identifier.
   - Version `0.1.0` for internal testing, then `1.0.0` for launch.
   - Incrementing build number for every upload.
   - Landscape orientations.
   - App icon assets.
   - Required device family: iPhone; enable iPad only after iPad layout testing.
7. Export to a new folder outside the repository, for example `build/ios/EDENFALL`.

Godot exports an Xcode project. App Store signing, archiving, device installation, and upload are then performed through Xcode.

## 4. Xcode configuration

Open the generated Xcode project and check:

- The correct Apple development team is selected.
- The bundle identifier exactly matches the identifier registered with Apple and the App Store Connect record.
- Automatic signing resolves without errors, or manually managed profiles are valid.
- Marketing version and build number are correct.
- The deployment target matches the tested device matrix.
- Supported orientations are landscape left and landscape right.
- The app icon has no transparency and all required icon slots are valid.
- No unsupported capabilities are enabled.
- The Release scheme is used for archives.
- Xcode reports no privacy-manifest or required-reason API issue from Godot or third-party plugins.

Do not commit certificates, `.p12` files, provisioning profiles, Apple private keys, or App Store Connect API keys.

## 5. Device test matrix

Before TestFlight, test on physical hardware. At minimum:

- One recent large-screen iPhone.
- One smaller supported iPhone.
- One older supported iPhone with weaker GPU/CPU.
- One iPad if iPad distribution is enabled.

Test:

- First launch and save creation.
- Character selection for all five lineages.
- Full winning and losing runs.
- Every room transition direction.
- Trader purchases with touch.
- Multiple simultaneous touches.
- Home indicator and safe-area overlap.
- App backgrounding during combat, pause, menus, and save operations.
- Incoming-call or audio-interruption behavior.
- Low battery mode and thermal pressure.
- Airplane mode and no-network launch.
- Reinstall behavior and expected local-save loss before cloud sync exists.
- Audio routing through speaker, Bluetooth, and silent-mode decisions.
- 30 FPS and 60 FPS modes when implemented.

A desktop-successful build is not evidence that touch, safe area, thermal behavior, or lifecycle handling is correct on iOS.

## 6. TestFlight

1. In Xcode, select a generic iOS device or supported connected device as the destination.
2. Use `Product > Archive`.
3. Validate the archive.
4. Distribute to App Store Connect.
5. Wait for Apple to process the build.
6. Add internal testers first.
7. Add external testers after beta review when appropriate.
8. Collect crash logs, device model, OS version, run seed, lineage, room, and reproduction steps.

Every uploaded build must have a unique build number. App Store Connect associates the upload with the app record using the bundle ID and version information.

Official upload reference:

https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/

## 7. Screenshots and product page

Apple currently accepts one to ten screenshots per display class. For a landscape iPhone game, prepare a primary 6.9-inch set without transparency. Accepted 6.9-inch landscape dimensions include:

- 2736 × 1260 pixels.
- 2796 × 1290 pixels.
- 2868 × 1320 pixels.

Use consistent screenshots showing real gameplay:

1. Lineage selection with the five bodies.
2. Dense but readable combat.
3. Preadamic trader room.
4. Item synergy or unusual projectile pattern.
5. Watcher Engine boss.
6. Genome Archive or run-results screen when implemented.

Do not use screenshots that imply features absent from the submitted build. Avoid direct visual comparison to commercial reference games in store assets.

Official screenshot specifications:

https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

## 8. Suggested launch metadata

Working subtitle:

`Escape the industrial Garden`

Working description structure:

- One-sentence premise.
- Five engineered lineages.
- Procedural rooms and permadeath.
- Twin-stick shooting and dodge combat.
- Pre-Adamite traders, outlaws, Nephilim, and fallen custodians.
- Run-only relic synergies.
- Offline play and no mandatory account.

Potential keywords should describe actual mechanics rather than competitor names: roguelike, twin-stick, dungeon, bullet hell, post-apocalyptic, action, procedural, offline.

A public support page and public privacy-policy page are required before submission. The privacy policy must also be easily accessible inside the app before launch.

## 9. Privacy position

### Current vertical slice

The current repository:

- Has no network code.
- Has no analytics or advertising SDK.
- Has no account system.
- Has no in-app purchase SDK.
- Saves progression locally on the device.

Data processed only on-device and never transmitted is not considered collected under Apple's App Privacy definition. A privacy-policy URL is still required for an iOS App Store listing, and App Review Guidelines require an accessible in-app privacy-policy link.

### After Nakama integration

Re-evaluate and declare all transmitted data, including third-party SDK behavior. Depending on the implementation, declarations may include:

- User ID or device-linked identifier.
- Gameplay Content for cloud saves and leaderboard records.
- Product interaction or diagnostics if telemetry is added.
- Purchase history if server-side receipt validation is added.

Use a local-first design and avoid collecting data that is not necessary for account restoration, security, purchases, or explicitly chosen competitive features.

Official privacy references:

- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/app-store/review/guidelines/

## 10. Expected age rating

The final rating is determined from the App Store Connect questionnaire and regional rules. Based on the intended content, the likely global target is **13+**, because the design includes frequent fantasy violence, weapons, mutants, and horror/fear themes while avoiding realistic gore and prolonged graphic violence.

Keep the visual presentation stylized if 13+ is the target:

- No realistic dismemberment.
- No prolonged suffering.
- No detailed realistic wounds.
- No sexualized religious imagery.
- No paid loot boxes.
- No simulated gambling.

Answer based on the submitted build, not the intended future roadmap.

Official definitions:

https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/

## 11. Accessibility before submission

Implement and verify:

- Adjustable UI/control scale.
- Left-handed touch layout.
- Adjustable stick opacity and dead zone.
- Aim assistance option.
- Reduced screen shake.
- Reduced flash.
- Color-independent projectile and pickup silhouettes.
- Subtitles for all spoken narrative.
- Independent master, music, and effects volume.
- Haptic intensity and off setting.
- Pause accessible without a precision tap.
- Text legible without depending on background contrast alone.

App Store Connect now supports accessibility feature declarations. Only declare a capability after it is tested in the submitted build.

## 12. App Review preparation

Before clicking Submit for Review:

- Select the correct processed build.
- Complete all required metadata.
- Add screenshots.
- Complete privacy answers.
- Complete the updated age-rating questionnaire.
- Provide the support URL and privacy-policy URL.
- Complete export-compliance questions accurately.
- Add reviewer notes explaining that the build is an offline single-player roguelike with no login.
- Explain controls and how to reach representative content.
- Provide any hidden gesture or test path needed to evaluate the full build.
- Confirm the game does not download executable code or external game content.
- Confirm all art, audio, fonts, and trademarks are owned or properly licensed.
- Test the exact archive submitted, not only an editor build.

Submission flow in App Store Connect:

1. Add the app version/build to a draft submission.
2. Click `Add for Review`.
3. Review the submission contents.
4. Click `Submit for Review`.

Official submission reference:

https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/

## 13. Release recommendation

Do not submit the current procedural-art vertical slice as version 1.0. Use it for mechanics validation and TestFlight only after the CI and physical-device tests pass.

Recommended gates before public release:

- Production visual and audio pass.
- At least three biomes and three bosses.
- 40–60 meaningful items with tested synergies.
- Settings and accessibility screens.
- Robust suspend/resume and atomic saves.
- Tutorialization without long text.
- Stable performance on the oldest supported iPhone.
- Privacy and support pages online.
- Closed TestFlight balancing cohort.
- No known progression-loss or room-generation blocker.
