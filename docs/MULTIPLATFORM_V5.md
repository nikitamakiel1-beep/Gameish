# EDEN//FALL v0.5.0 multiplatform targets

This branch migrates the project runtime and validation contract to Godot 4.7.1 and defines reproducible exports for six platform families.

## Export profiles

| Preset | CI artifact | Local/store use |
|---|---|---|
| Windows Desktop | x86-64 executable archive | Windows playtesting and distribution |
| Linux X11 | x86-64 executable archive | Linux playtesting and distribution |
| macOS Universal | unsigned universal ZIP | Intel and Apple Silicon testing; sign and notarize for release |
| Web | HTML5/PWA archive | browser testing and itch.io-style hosting |
| Android APK | debug ARM64 APK | direct installation on physical Android devices |
| Android AAB | debug ARM64 bundle | pipeline validation; release AAB requires a private keystore |
| iOS Xcode | unsigned Xcode project archive | requires macOS, Xcode, Apple Team ID and provisioning for device/App Store builds |

## Godot and SDK requirements

- Godot editor and export templates: 4.7.1 stable.
- Android: OpenJDK 17, Android SDK Platform 35, Build Tools 35.0.1 and NDK r28b for Gradle/custom builds.
- iOS: macOS with Xcode. A real Team ID and bundle provisioning are required for device or App Store signing.
- Web: Compatibility renderer. Thread support remains disabled for broad hosting compatibility.

## Credential boundary

`export_presets.cfg` contains no release passwords or private keys. Credentials belong in `.godot/export_credentials.cfg`, local environment variables, or repository secrets.

Release variables include:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`
- `GODOT_IOS_PROVISIONING_PROFILE_UUID_DEBUG`
- `GODOT_IOS_PROVISIONING_PROFILE_UUID_RELEASE`

The placeholder iOS Team ID in the unsigned project preset must be replaced with the owner’s actual ten-character Apple Team ID before device signing.

## Testing order

1. Godot 4.7.1 import and complete script parse.
2. v3 directional regression audit.
3. v4 systems and v4.1 quality audits.
4. v5 architecture/UI/export audit.
5. Headless main-scene boot.
6. Desktop/Web/Android export smoke tests.
7. Physical Android APK installation.
8. macOS/iOS export and Xcode device testing.
9. Signed AAB/TestFlight qualification.

## Release limitations

CI-produced artifacts are engineering test builds. Commercial publication still requires platform signing, store metadata, privacy declarations, screenshots, age ratings, physical-device QA and final performance/balance qualification.
