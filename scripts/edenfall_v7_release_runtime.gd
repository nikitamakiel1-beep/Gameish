extends "res://scripts/edenfall_v7_progression_runtime.gd"

const RC7_RELEASE_VERSION := "0.6.1-rc7"

func _ready() -> void:
	if not profile.has("adaptations_discovered"):
		profile["adaptations_discovered"] = []
	super._ready()

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["rc7_release_version"] = RC7_RELEASE_VERSION
	report["adaptations_discovered"] = Array(profile.get("adaptations_discovered", [])).size()
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = RC7_RELEASE_VERSION
	report["profile_schema_preseed"] = true
	return report
