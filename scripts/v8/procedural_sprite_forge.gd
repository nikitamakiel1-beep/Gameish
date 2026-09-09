extends "res://scripts/v8/procedural_sprite_forge_stable.gd"

const LEGACY_FORGE_SHIM_VERSION: String = "0.6.2-entropy-stable-shim"

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["legacy_shim"] = true
	report["shim_version"] = LEGACY_FORGE_SHIM_VERSION
	return report
