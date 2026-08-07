extends "res://scripts/edenfall_v6_godmode_release_runtime.gd"

const VERIFIED_GODMODE_VERSION := "0.6.1-rc6"

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	if not _restoring_rc6:
		_delete_pending_ending()
	super.start_new_run(lineage_index, seed_override)

func generate_floor() -> void:
	var saved_seed := rng.seed
	var saved_state := rng.state
	rng.seed = _floor_graph_seed()
	super.generate_floor()
	rng.seed = saved_seed
	rng.state = saved_state

func _floor_graph_seed() -> int:
	return hash("EDEN_FLOOR:%d:%d:%d" % [run_seed, biome_index, floor_number])

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["verified_godmode_version"] = VERIFIED_GODMODE_VERSION
	report["floor_graph_seed"] = _floor_graph_seed()
	return report

func audit_godmode_contract() -> Dictionary:
	var report: Dictionary = super.audit_godmode_contract()
	report["version"] = VERIFIED_GODMODE_VERSION
	report["deterministic_floor_graph"] = true
	report["manual_new_run_clears_stale_ending"] = true
	return report
