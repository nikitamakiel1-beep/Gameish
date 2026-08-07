extends "res://scripts/edenfall_v7_audio_runtime.gd"

const ART_RUNTIME_VERSION := "0.6.1-rc7"
const MasterpieceRegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")

func _ready() -> void:
	super._ready()
	production_assets = MasterpieceRegistryScript.new()
	v6_asset_report = audit_v6_readiness()
	readiness = float(v6_asset_report.get("readiness", 0.0))
	if state == "run":
		play_biome_audio(true)
	queue_redraw()

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["art_runtime_version"] = ART_RUNTIME_VERSION
	report["art_registry"] = production_assets.call("index")
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = ART_RUNTIME_VERSION
	report["masterpiece_asset_registry"] = true
	report["pixel_finish"] = true
	return report
