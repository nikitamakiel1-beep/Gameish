extends RefCounted

const VERSION := 5
const GODOT_VERSION := "4.7.1"
const PRESETS := [
	{"name":"Windows Desktop", "platform":"windows", "artifact":"EDEN_FALL-windows-x86_64.zip", "signed":false},
	{"name":"Linux X11", "platform":"linux", "artifact":"EDEN_FALL-linux-x86_64.tar.gz", "signed":false},
	{"name":"macOS Universal", "platform":"macos", "artifact":"EDEN_FALL-macos-universal.zip", "signed":false},
	{"name":"Web", "platform":"web", "artifact":"EDEN_FALL-web.zip", "signed":false},
	{"name":"Android APK", "platform":"android", "artifact":"EDEN_FALL-debug.apk", "signed":false},
	{"name":"Android AAB", "platform":"android", "artifact":"EDEN_FALL-debug.aab", "signed":false},
	{"name":"iOS Xcode", "platform":"ios", "artifact":"EDEN_FALL-ios-xcode.zip", "signed":false},
]

func preset_names() -> Array[String]:
	var names: Array[String] = []
	for preset in PRESETS:
		names.append(String(preset["name"]))
	return names

func platforms() -> Array[String]:
	var result: Array[String] = []
	for preset in PRESETS:
		var platform := String(preset["platform"])
		if not result.has(platform):
			result.append(platform)
	return result

func release_requirements(platform: String) -> Array[String]:
	match platform:
		"android": return ["Google Play Console", "release keystore", "AAB version code", "privacy declaration"]
		"ios": return ["macOS runner", "Xcode", "Apple Team ID", "provisioning profile", "App Store Connect"]
		"macos": return ["Developer ID certificate", "notarization credentials"]
		"windows": return ["optional Authenticode certificate"]
		_: return []

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"godot": GODOT_VERSION,
		"presets": PRESETS.size(),
		"platforms": platforms(),
		"has_apk": preset_names().has("Android APK"),
		"has_aab": preset_names().has("Android AAB"),
		"has_ios": preset_names().has("iOS Xcode"),
	}
