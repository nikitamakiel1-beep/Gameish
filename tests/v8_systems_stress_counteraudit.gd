extends SceneTree

const SaveScript: Script = preload("res://scripts/v5/save_repository.gd")
const PerformanceScript: Script = preload("res://scripts/v6/performance_budget.gd")
const LifecycleScript: Script = preload("res://scripts/v6/platform_lifecycle.gd")
const FairnessScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EncounterScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const EntropyScript: Script = preload("res://scripts/v8/entropy_director.gd")

const REVISION: String = "0.6.4-authored-art4"
const TEMP_SAVE: String = "user://edenfall-counteraudit-save.json"
const ENEMY_POOL: Array[String] = [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter",
	"scrap_cultist", "caravan_outlaw", "cherub_drone", "fallen_angel",
	"watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd",
	"grafted_colossus", "serpent_spawn",
]

func _append_error(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _test_save_repository(errors: Array[String]) -> Dictionary:
	var saves: RefCounted = SaveScript.new()
	saves.call("remove_with_backup", TEMP_SAVE)
	var first: Dictionary = {"genome": 11, "lineage": "adam", "nested": {"rooms": 3}}
	var second: Dictionary = {"genome": 22, "lineage": "naamah", "nested": {"rooms": 7}}
	_append_error(errors, bool(saves.call("write_json_atomic", TEMP_SAVE, first)), "Save repository failed first atomic write")
	var first_read: Dictionary = saves.call("read_json", TEMP_SAVE, {})
	_append_error(errors, int(first_read.get("schema_version", -1)) == 5, "Save repository did not stamp schema version 5")
	_append_error(errors, int(first_read.get("genome", -1)) == 11, "Save repository first roundtrip changed payload")

	_append_error(errors, bool(saves.call("write_json_atomic", TEMP_SAVE, second)), "Save repository failed second atomic write")
	var second_read: Dictionary = saves.call("read_json", TEMP_SAVE, {})
	_append_error(errors, int(second_read.get("genome", -1)) == 22, "Save repository second roundtrip changed payload")
	_append_error(errors, FileAccess.file_exists(TEMP_SAVE + ".bak"), "Save repository did not retain previous-good backup")

	# Corrupt only this dedicated counteraudit primary file. read_json() must reject
	# it and recover the previous valid backup rather than returning malformed data.
	var corrupt: FileAccess = FileAccess.open(TEMP_SAVE, FileAccess.WRITE)
	if corrupt == null:
		errors.append("Could not open counteraudit save for corruption test")
	else:
		corrupt.store_string("{ definitely-not-json")
		corrupt.flush()
		corrupt = null
		var recovered: Dictionary = saves.call("read_json", TEMP_SAVE, {"fallback": true})
		_append_error(errors, int(recovered.get("genome", -1)) == 11, "Save repository did not recover previous-good backup after primary corruption")
		_append_error(errors, not bool(recovered.get("fallback", false)), "Save repository fell through to fallback despite valid backup")

	saves.call("remove_with_backup", TEMP_SAVE)
	_append_error(errors, not FileAccess.file_exists(TEMP_SAVE), "Counteraudit primary save was not cleaned up")
	_append_error(errors, not FileAccess.file_exists(TEMP_SAVE + ".bak"), "Counteraudit backup save was not cleaned up")
	_append_error(errors, not FileAccess.file_exists(TEMP_SAVE + ".tmp"), "Counteraudit temporary save was not cleaned up")
	return {"roundtrip": true, "backup_corruption_recovery": true, "isolated_test_path": TEMP_SAVE}

func _test_performance_budget(errors: Array[String]) -> Dictionary:
	var budget: RefCounted = PerformanceScript.new()
	var initial: Dictionary = budget.call("configure")
	var limits: Dictionary = initial.get("limits", {})
	var bullet_limit: int = int(limits.get("max_bullets", 0))
	var effect_limit: int = int(limits.get("max_effects", 0))
	var damage_limit: int = int(limits.get("max_damage_numbers", 0))
	var pickup_limit: int = int(limits.get("max_pickups", 0))
	_append_error(errors, bullet_limit > 0 and effect_limit > 0 and damage_limit > 0 and pickup_limit > 0, "Performance budget configured non-positive limits")

	var bullets: Array = []
	for index: int in range(bullet_limit):
		bullets.append({"owner": "enemy", "life": float(index + 1)})
	_append_error(errors, not bool(budget.call("admit_bullet", bullets, "enemy")), "Enemy bullet saturation was not rejected")
	_append_error(errors, bool(budget.call("admit_bullet", bullets, "player")), "Player bullet could not recycle an enemy bullet at saturation")
	_append_error(errors, bullets.size() == maxi(0, bullet_limit - 1), "Player bullet recycle did not remove exactly one enemy bullet")

	var effects: Array = []
	for index: int in range(effect_limit):
		effects.append({"life": float(index + 1)})
	_append_error(errors, bool(budget.call("admit_effect", effects)), "Effect saturation could not recycle a transient effect")
	_append_error(errors, effects.size() == maxi(0, effect_limit - 1), "Effect recycle did not remove exactly one transient effect")

	var damage_numbers: Array = []
	for index: int in range(damage_limit + 7):
		damage_numbers.append({"value": index})
	var pickups: Array = []
	for index: int in range(pickup_limit + 5):
		pickups.append({"id": index})
	budget.call("enforce_post_frame", damage_numbers, pickups)
	_append_error(errors, damage_numbers.size() == damage_limit, "Damage-number budget enforcement missed its exact cap")
	_append_error(errors, pickups.size() == pickup_limit, "Pickup budget enforcement missed its exact cap")
	var final: Dictionary = budget.call("report")
	_append_error(errors, int(final.get("dropped_enemy_bullets", 0)) >= 1, "Performance budget did not record dropped enemy bullet")
	_append_error(errors, int(final.get("recycled_enemy_bullets", 0)) >= 1, "Performance budget did not record recycled enemy bullet")
	_append_error(errors, int(final.get("dropped_effects", 0)) >= 1, "Performance budget did not record recycled/dropped effect")
	_append_error(errors, int(final.get("trimmed_damage_numbers", 0)) == 7, "Damage-number trim accounting mismatch")
	_append_error(errors, int(final.get("trimmed_pickups", 0)) == 5, "Pickup trim accounting mismatch")
	return final

func _test_lifecycle(errors: Array[String]) -> Dictionary:
	var lifecycle: RefCounted = LifecycleScript.new()
	var background_run: Dictionary = lifecycle.call("background", "run", false)
	_append_error(errors, bool(background_run.get("save", false)), "Backgrounding an active run does not request a save")
	_append_error(errors, bool(background_run.get("pause", false)), "Backgrounding an active unpaused run does not request automatic pause")
	_append_error(errors, bool(background_run.get("reset_input", false)), "Background transition does not reset input")
	var foreground: Dictionary = lifecycle.call("foreground")
	_append_error(errors, bool(foreground.get("resume", false)), "Foreground transition did not remember automatic pause")
	_append_error(errors, bool(foreground.get("redraw", false)), "Foreground transition does not request redraw")
	var memory: Dictionary = lifecycle.call("memory_warning")
	_append_error(errors, bool(memory.get("release_transient_assets", false)), "Memory warning does not request transient asset release")
	var settings_back: Dictionary = lifecycle.call("back_request", "run", false, true, false)
	_append_error(errors, String(settings_back.get("action", "")) == "close_settings", "Back request does not prioritize closing settings")
	var run_back: Dictionary = lifecycle.call("back_request", "run", false, false, false)
	_append_error(errors, String(run_back.get("action", "")) == "pause", "Back request during active run does not pause")
	lifecycle.call("controller_changed", true)
	lifecycle.call("controller_changed", false)
	var report: Dictionary = lifecycle.call("report")
	_append_error(errors, int(report.get("background_events", 0)) == 1, "Lifecycle background counter mismatch")
	_append_error(errors, int(report.get("foreground_events", 0)) == 1, "Lifecycle foreground counter mismatch")
	_append_error(errors, int(report.get("memory_warnings", 0)) == 1, "Lifecycle memory-warning counter mismatch")
	_append_error(errors, int(report.get("controller_connections", 0)) == 1 and int(report.get("controller_disconnections", 0)) == 1, "Lifecycle controller counters mismatch")
	return report

func _test_fairness(errors: Array[String]) -> Dictionary:
	var fairness: RefCounted = FairnessScript.new()
	var previous: float = -1.0
	var delays: Array[float] = []
	for index: int in range(16):
		var delay: float = float(fairness.call("materialize_delay", index, false))
		delays.append(delay)
		_append_error(errors, delay >= previous, "Enemy materialization delay decreased with later spawn index")
		_append_error(errors, delay <= 0.7601, "Enemy materialization delay exceeded declared cap")
		previous = delay
	var boss_delay: float = float(fairness.call("materialize_delay", 0, true))
	_append_error(errors, boss_delay >= 0.8, "Boss materialization window is unexpectedly short")
	_append_error(errors, float(fairness.call("clearance", true)) > float(fairness.call("clearance", false)), "Boss spawn clearance is not larger than standard enemy clearance")
	var contract: Dictionary = fairness.call("audit_contract")
	_append_error(errors, float(contract.get("room_grace", 0.0)) > 0.5, "Room entry grace is below the safety floor")
	return {"delays": delays, "boss_delay": boss_delay, "contract": contract}

func _test_encounters(errors: Array[String]) -> Dictionary:
	var composer: RefCounted = EncounterScript.new()
	var pool: Array = []
	for id: String in ENEMY_POOL:
		pool.append(id)
	var signatures: Dictionary = {}
	var formations: Dictionary = {}
	var arena: Rect2 = Rect2(0, 0, 1280, 720)
	var safe: Rect2 = arena.grow(-82.0)
	for seed_value: int in range(1000, 1128):
		var first: Dictionary = composer.call("compose", pool, 8, seed_value, "combat", "none")
		var second: Dictionary = composer.call("compose", pool, 8, seed_value, "combat", "none")
		_append_error(errors, JSON.stringify(first) == JSON.stringify(second), "Encounter composition is not deterministic for its local seed: %d" % seed_value)
		var ids: Array = first.get("ids", [])
		_append_error(errors, ids.size() == 8, "Encounter composer returned wrong enemy count at seed %d" % seed_value)
		for id_variant in ids:
			_append_error(errors, String(id_variant) in ENEMY_POOL, "Encounter composer emitted enemy outside supplied pool")
		var role_counts: Dictionary = first.get("role_counts", {})
		_append_error(errors, int(role_counts.get("caster", 0)) <= 2, "Encounter composer exceeded caster cap")
		_append_error(errors, int(role_counts.get("radial", 0)) <= 2, "Encounter composer exceeded radial cap")
		var signature: String = String(first.get("id", ""))
		var formation: String = String(first.get("formation", ""))
		signatures[signature] = true
		formations[formation] = true
		var positions: Array = composer.call("positions", arena, ids.size(), formation, seed_value)
		_append_error(errors, positions.size() == ids.size(), "Encounter position count mismatch")
		var coordinate_hashes: Dictionary = {}
		for position_variant in positions:
			var position: Vector2 = Vector2(position_variant)
			_append_error(errors, position.x >= safe.position.x - 0.01 and position.x <= safe.end.x + 0.01 and position.y >= safe.position.y - 0.01 and position.y <= safe.end.y + 0.01, "Encounter position escaped safe arena")
			coordinate_hashes["%.3f:%.3f" % [position.x, position.y]] = true
		_append_error(errors, coordinate_hashes.size() == positions.size(), "Encounter formation produced exact overlapping spawn coordinates")
	_append_error(errors, signatures.size() >= 4, "Encounter stress run produced insufficient signature diversity")
	_append_error(errors, formations.size() >= 4, "Encounter stress run produced insufficient formation diversity")
	return {"seeds": 128, "signature_diversity": signatures.size(), "formation_diversity": formations.size()}

func _test_entropy(errors: Array[String]) -> Dictionary:
	var entropy: RefCounted = EntropyScript.new()
	var tokens: Dictionary = {}
	for index: int in range(128):
		var token: int = int(entropy.call("token", "counteraudit:%d" % index))
		tokens[token] = true
	_append_error(errors, tokens.size() == 128, "Entropy director produced duplicate context tokens in 128-sample stress test")
	for _index: int in range(32):
		_append_error(errors, not bool(entropy.call("chance", 0.0)), "Entropy chance(0.0) returned true")
		_append_error(errors, bool(entropy.call("chance", 1.0)), "Entropy chance(1.0) returned false")
	_append_error(errors, String(entropy.call("pick", [], "fallback")) == "fallback", "Entropy pick() failed empty-array fallback")
	var source: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	var shuffled: Array = entropy.call("shuffled", source)
	_append_error(errors, shuffled.size() == source.size(), "Entropy shuffle changed array cardinality")
	for value in source:
		_append_error(errors, value in shuffled, "Entropy shuffle lost source value")
	var contract: Dictionary = entropy.call("audit_contract")
	_append_error(errors, bool(contract.get("crypto_mixed_at_reseed", false)), "Entropy contract lost crypto-mixed reseed")
	_append_error(errors, not bool(contract.get("fixed_seed_replay", true)), "Entropy contract unexpectedly re-enabled fixed-seed replay")
	return {"unique_tokens": tokens.size(), "contract": contract}

func _init() -> void:
	var errors: Array[String] = []
	var report: Dictionary = {
		"revision": REVISION,
		"save": _test_save_repository(errors),
		"performance": _test_performance_budget(errors),
		"lifecycle": _test_lifecycle(errors),
		"fairness": _test_fairness(errors),
		"encounters": _test_encounters(errors),
		"entropy": _test_entropy(errors),
	}
	report["errors"] = errors
	report["passed"] = errors.is_empty()
	print("EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT=PASS")
		quit(0)
	else:
		for message: String in errors:
			push_error(message)
		quit(1)
