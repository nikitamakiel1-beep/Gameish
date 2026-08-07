extends "res://scripts/edenfall_v8_streaming_runtime.gd"

const V8_FINAL_VERSION := "0.6.2-entropy"

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["v8_final_version"] = V8_FINAL_VERSION
	report["active_generation_pipeline"] = "entropy -> condition genome -> streamed pixel forge -> procedural biome"
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["version"] = V8_FINAL_VERSION
	report["final_runtime_root"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = V8_FINAL_VERSION
	report["final_runtime_root"] = true
	return report
