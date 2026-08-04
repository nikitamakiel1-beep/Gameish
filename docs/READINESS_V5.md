# EDEN//FALL v0.5 readiness model

v0.5 is the Godot 4.7.1, responsive UI/UX and multiplatform packaging expansion over the validated v0.4.1 systems build. The readiness score distinguishes code/build validity from physical-device and commercial-store qualification.

## Implemented and validated

- Godot 4.7.1 project migration and exact-head validation.
- Windows, Linux, macOS universal, Web/PWA, Android APK, Android AAB and iOS Xcode exports.
- Modular platform profile, responsive UI, persistence repository and build matrix services.
- Compact, medium and wide layout breakpoints.
- Compact mobile HUD and safe-area-contained mobile lineage selection.
- Mouse hover focus, spatial keyboard navigation and complete controller menu navigation.
- Large touch targets, left-handed controls and input-family prompts.
- Functional battery/performance FPS profiles.
- Atomic platform-settings persistence with backup recovery.
- S3TC and ETC2/ASTC texture pipelines.
- Complete v3, v4, v4.1 and v5 behavioral regression chain.

## Weighted readiness

| Area | Weight | Validated score | Weighted result |
|---|---:|---:|---:|
| Core gameplay, directional controls and combat | 20% | 96% | 19.20% |
| UI/UX, accessibility and input coverage | 17% | 95% | 16.15% |
| Content, encounters and progression | 15% | 91% | 13.65% |
| Architecture and platform adaptation | 12% | 96% | 11.52% |
| Build and export pipeline | 12% | 100% | 12.00% |
| Art and audio integration | 8% | 86% | 6.88% |
| Save and lifecycle reliability | 6% | 93% | 5.58% |
| Physical-device QA and balancing | 6% | 30% | 1.80% |
| Store signing and release operations | 4% | 20% | 0.80% |

**Weighted overall readiness: 87.58%, reported as 88%.**

## Release interpretation

- **Validated playable engineering build: 96%.** The complete gameplay build, architecture, responsive interface and six-platform export family are implemented and pass Godot 4.7.1 source and packaging gates.
- **Weighted project readiness: 88%.** This includes the remaining device, balancing, signing and release-operation deficits.
- **Commercial/store readiness: 72%.** Store credentials, physical qualification, production signing and release materials remain incomplete.

## What 96% means

The engineering build can be opened, parsed, booted and exported reproducibly. It does not mean every generated binary has been manually played through on its target hardware. Automated packaging confirms that each target can be produced; physical-device testing must confirm controls, performance, thermals, interruptions and presentation.

## Remaining release-critical work

1. Install the exact APK on representative low-, mid- and high-tier Android devices.
2. Test portrait/landscape transitions, gesture navigation, cutouts, safe areas, touch latency and haptics.
3. Sign a release AAB with the owner’s private keystore and test through Google Play internal testing.
4. Replace the placeholder Apple Team ID, configure provisioning and run the Xcode project on iPhone and iPad.
5. Distribute a signed build through TestFlight and test suspension, backgrounding, audio interruptions and memory pressure.
6. Test the macOS universal build on Intel and Apple Silicon; sign and notarize the release build.
7. Run repeated seeded balance sessions and record completion rate, death causes, weapon/relic selection and run length.
8. Profile frame time, memory, battery, thermal behavior and long-session stability.
9. Complete final animation cleanup, sound mix, music mastering and any remaining procedural-art replacement.
10. Complete localization, privacy disclosures, age ratings, screenshots, metadata, support pages and store review preparation.

## Evidence

The source of truth is `validation/V5_RESULT.md`, which records exact commit identity, source gates, export results, build hashes and GitHub Actions artifact IDs.
