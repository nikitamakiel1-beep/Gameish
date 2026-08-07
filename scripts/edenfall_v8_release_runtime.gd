extends "res://scripts/edenfall_v8_streaming_runtime.gd"

const V8_RELEASE_VERSION := "0.6.2-entropy"

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["v8_release_version"] = V8_RELEASE_VERSION
	report["generation_mode"] = "stochastic_condition_driven"
	report["fixed_seed_replay"] = false
	return report

func audit_godmode_contract() -> Dictionary:
	var report: Dictionary = super.audit_godmode_contract()
	report["version"] = V8_RELEASE_VERSION
	report["deterministic_floor_graph"] = false
	report["deterministic_special_rooms"] = false
	report["fixed_seed_replay"] = false
	report["entropy_floor_graph"] = true
	report["entropy_special_rooms"] = true
	report["active_run_recipe_persistence"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["version"] = V8_RELEASE_VERSION
	report["release_root"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = V8_RELEASE_VERSION
	report["release_root"] = true
	return report
