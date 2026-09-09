extends SceneTree

const SaveScript: Script = preload("res://scripts/v5/save_repository.gd")
const PerformanceScript: Script = preload("res://scripts/v6/performance_budget.gd")
const LifecycleScript: Script = preload("res://scripts/v6/platform_lifecycle.gd")
const FairnessScript: Script = preload("res://scripts/v7/combat_fairness_director.gd")
const EncounterScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const EntropyScript: Script = preload("res://scripts/v8/entropy_director.gd")
const WorldScript: Script = preload("res://scripts/v8/procedural_world_director_art4.gd")

const REVISION: String = "0.6.4-authored-art4"
const TEMP_SAVE: String = "user://edenfall-counteraudit-save.json"
const TEMP_LEGACY: String = "user://edenfall-counteraudit-legacy.json"
const ENEMY_POOL: Array[String] = [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter",
	"scrap_cultist", "caravan_outlaw", "cherub_drone", "fallen_angel",
	"watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd",
	"grafted_colossus", "serpent_spawn",
]
const BIOMES: Array[String] = ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]

func _append_error(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)

func _test_save_repository(errors: Array[String]) -> Dictionary:
	var saves: RefCounted = SaveScript.new()
	saves.call("remove_with_backup", TEMP_SAVE)
	saves.call("remove_with_backup", TEMP_LEGACY)
	var contract: Dictionary = saves.call("audit_contract")
	for flag: String in ["atomic_write", "backup_recovery", "sha256_integrity", "valid_json_tamper_detection", "prepromotion_readback", "preserve_good_backup_on_bad_primary", "legacy_read_compatibility"]:
		_append_error(errors, bool(contract.get(flag, false)), "Save repository contract missing: " + flag)

	var first: Dictionary = {"genome": 11, "lineage": "adam", "nested": {"rooms": 3}}
	var second: Dictionary = {"genome": 22, "lineage": "naamah", "nested": {"rooms": 7}}
	var third: Dictionary = {"genome": 33, "lineage": "seth", "nested": {"rooms": 9}}
	_append_error(errors, bool(saves.call("write_json_atomic", TEMP_SAVE, first)), "Save repository failed first atomic write")
	_append_error(errors, bool(saves.call("write_json_atomic", TEMP_SAVE, second)), "Save repository failed second atomic write")
	var second_read: Dictionary = saves.call("read_json", TEMP_SAVE, {})
	_append_error(errors, int(second_read.get("schema_version", -1)) == 5, "Save repository did not retain schema version 5")
	_append_error(errors, int(second_read.get("genome", -1)) == 22, "Save repository second roundtrip changed payload")
	_append_error(errors, FileAccess.file_exists(TEMP_SAVE + ".bak"), "Save repository did not retain previous-good backup")

	# Parseable tampering is more dangerous than malformed JSON because a parser-only
	# guard would accept it. Preserve the original checksum and mutate game state.
	var primary_file := FileAccess.open(TEMP_SAVE, FileAccess.READ)
	if primary_file == null:
		errors.append("Could not open counteraudit primary for valid-JSON tamper test")
	else:
		var tampered_variant = JSON.parse_string(primary_file.get_as_text())
		primary_file.close()
		if not tampered_variant is Dictionary:
			errors.append("Counteraudit primary was not valid JSON before tamper test")
		else:
			var tampered := Dictionary(tampered_variant)
			tampered["genome"] = 999999
			var writer := FileAccess.open(TEMP_SAVE, FileAccess.WRITE)
			if writer == null:
				errors.append("Could not reopen counteraudit primary for tamper write")
			else:
				writer.store_string(JSON.stringify(tampered))
				writer.flush()
				writer.close()
				var recovered: Dictionary = saves.call("read_json", TEMP_SAVE, {"fallback": true})
				_append_error(errors, int(recovered.get("genome", -1)) == 11, "SHA-256 integrity did not reject parseable tampering and recover backup")
				_append_error(errors, not bool(recovered.get("fallback", false)), "Save repository fell through despite valid backup after parseable tamper")

	# Writing after a corrupt primary must not overwrite the still-good backup with
	# corrupted bytes. The new primary is promoted only after readback verification.
	_append_error(errors, bool(saves.call("write_json_atomic", TEMP_SAVE, third)), "Save repository could not replace a corrupt primary safely")
	var third_read: Dictionary = saves.call("read_json", TEMP_SAVE, {})
	_append_error(errors, int(third_read.get("genome", -1)) == 33, "Verified replacement save did not become primary")
	var backup_read: Dictionary = saves.call("read_json", TEMP_SAVE + ".bak", {})
	_append_error(errors, int(backup_read.get("genome", -1)) == 11, "Corrupt primary overwrote the previous-good backup during recovery write")

	# Legacy schema-v5 JSON without an integrity extension remains readable so the
	# hardening does not destroy pre-hardening local saves.
	var legacy := FileAccess.open(TEMP_LEGACY, FileAccess.WRITE)
	if legacy == null:
		errors.append("Could not create legacy compatibility fixture")
	else:
		legacy.store_string(JSON.stringify({"schema_version": 5, "genome": 44, "lineage": "abel"}))
		legacy.close()
		var legacy_read: Dictionary = saves.call("read_json", TEMP_LEGACY, {})
		_append_error(errors, int(legacy_read.get("genome", -1)) == 44, "Legacy schema-v5 save compatibility regressed")

	# Malformed primary still falls back as before.
	var corrupt := FileAccess.open(TEMP_SAVE, FileAccess.WRITE)
	if corrupt == null:
		errors.append("Could not open counteraudit save for malformed corruption test")
	else:
		corrupt.store_string("{ definitely-not-json")
		corrupt.close()
		var malformed_recovery: Dictionary = saves.call("read_json", TEMP_SAVE, {"fallback": true})
		_append_error(errors, int(malformed_recovery.get("genome", -1)) == 11, "Save repository did not recover backup after malformed primary")

	saves.call("remove_with_backup", TEMP_SAVE)
	saves.call("remove_with_backup", TEMP_LEGACY)
	return {
		"roundtrip": true,
		"backup_corruption_recovery": true,
		"valid_json_tamper_recovery": true,
		"legacy_compatibility": true,
		"contract": contract,
	}

func _test_performance_budget(errors: Array[String]) -> Dictionary:
	var budget: RefCounted = PerformanceScript.new()
	var initial: Dictionary = budget.call("configure")
	var limits: Dictionary = initial.get("limits", {})
	var contract: Dictionary = budget.call("audit_contract")
	for flag: String in ["frame_time_feedback", "post_frame_auto_observation", "ema_smoothing", "hysteresis", "bounded_quality_floor", "player_bullet_priority"]:
		_append_error(errors, bool(contract.get(flag, false)), "Performance budget contract missing: " + flag)

	for _sample: int in range(240):
		budget.call("observe_frame", 1.0 / 30.0, true)
	var pressured: Dictionary = budget.call("report")
	var pressure_scale := float(pressured.get("adaptive_scale", 1.0))
	_append_error(errors, pressure_scale < 0.999, "Sustained 30 FPS pressure did not reduce adaptive load")
	_append_error(errors, int(pressured.get("quality_reductions", 0)) > 0, "Adaptive budget did not record quality reductions")
	var pressured_limits: Dictionary = pressured.get("effective_limits", {})
	for key: String in ["max_bullets", "max_effects", "max_damage_numbers", "max_pickups"]:
		_append_error(errors, int(pressured_limits.get(key, 0)) > 0, "Adaptive performance floor collapsed for " + key)
		_append_error(errors, int(pressured_limits.get(key, 0)) <= int(limits.get(key, 0)), "Adaptive performance exceeded configured base cap for " + key)

	for _sample: int in range(1200):
		budget.call("observe_frame", 1.0 / 120.0, true)
	var recovered: Dictionary = budget.call("report")
	_append_error(errors, float(recovered.get("adaptive_scale", 0.0)) > pressure_scale, "Sustained headroom did not recover adaptive quality")
	_append_error(errors, int(recovered.get("quality_recoveries", 0)) > 0, "Adaptive budget did not record quality recovery")

	# Reset to the platform base profile for exact saturation accounting.
	initial = budget.call("configure")
	limits = initial.get("limits", {})
	var bullet_limit := int(limits.get("max_bullets", 0))
	var effect_limit := int(limits.get("max_effects", 0))
	var damage_limit := int(limits.get("max_damage_numbers", 0))
	var pickup_limit := int(limits.get("max_pickups", 0))
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
	# Use direct limits here; the first auto-observation has no prior timestamp and
	# therefore cannot alter the configured cap during this exact accounting check.
	budget.call("enforce_post_frame", damage_numbers, pickups)
	_append_error(errors, damage_numbers.size() == damage_limit, "Damage-number budget enforcement missed its exact cap")
	_append_error(errors, pickups.size() == pickup_limit, "Pickup budget enforcement missed its exact cap")
	var final: Dictionary = budget.call("report")
	_append_error(errors, int(final.get("dropped_enemy_bullets", 0)) >= 1, "Performance budget did not record dropped enemy bullet")
	_append_error(errors, int(final.get("recycled_enemy_bullets", 0)) >= 1, "Performance budget did not record recycled enemy bullet")
	_append_error(errors, int(final.get("dropped_effects", 0)) >= 1, "Performance budget did not record recycled/dropped effect")
	_append_error(errors, int(final.get("trimmed_damage_numbers", 0)) == 7, "Damage-number trim accounting mismatch")
	_append_error(errors, int(final.get("trimmed_pickups", 0)) == 5, "Pickup trim accounting mismatch")
	final["pressure_scale_observed"] = pressure_scale
	final["recovery_scale_observed"] = float(recovered.get("adaptive_scale", 0.0))
	return final

func _test_lifecycle(errors: Array[String]) -> Dictionary:
	var lifecycle: RefCounted = LifecycleScript.new()
	var background_run: Dictionary = lifecycle.call("background", "run", false)
	_append_error(errors, bool(background_run.get("save", false)), "Backgrounding an active run does not request a save")
	_append_error(errors, bool(background_run.get("pause", false)), "Backgrounding an active run does not request pause")
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
	return lifecycle.call("report")

func _test_fairness(errors: Array[String]) -> Dictionary:
	var fairness: RefCounted = FairnessScript.new()
	var previous := -1.0
	var delays: Array[float] = []
	for index: int in range(16):
		var delay := float(fairness.call("materialize_delay", index, false))
		delays.append(delay)
		_append_error(errors, delay >= previous, "Enemy materialization delay decreased with later spawn index")
		_append_error(errors, delay <= 0.7601, "Enemy materialization delay exceeded declared cap")
		previous = delay
	var boss_delay := float(fairness.call("materialize_delay", 0, true))
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
	var arena := Rect2(0, 0, 1280, 720)
	var safe := arena.grow(-82.0)
	for seed_value: int in range(1000, 1128):
		var first: Dictionary = composer.call("compose", pool, 8, seed_value, "combat", "none")
		var second: Dictionary = composer.call("compose", pool, 8, seed_value, "combat", "none")
		_append_error(errors, JSON.stringify(first) == JSON.stringify(second), "Encounter composition is not deterministic for local seed %d" % seed_value)
		var ids: Array = first.get("ids", [])
		_append_error(errors, ids.size() == 8, "Encounter composer returned wrong enemy count")
		var role_counts: Dictionary = first.get("role_counts", {})
		_append_error(errors, int(role_counts.get("caster", 0)) <= 2, "Encounter composer exceeded caster cap")
		_append_error(errors, int(role_counts.get("radial", 0)) <= 2, "Encounter composer exceeded radial cap")
		var signature := String(first.get("id", ""))
		var formation := String(first.get("formation", ""))
		signatures[signature] = true
		formations[formation] = true
		var positions: Array = composer.call("positions", arena, ids.size(), formation, seed_value)
		var coordinate_hashes: Dictionary = {}
		for position_variant in positions:
			var position := Vector2(position_variant)
			_append_error(errors, safe.has_point(position), "Encounter position escaped safe arena")
			coordinate_hashes["%.3f:%.3f" % [position.x, position.y]] = true
		_append_error(errors, coordinate_hashes.size() == positions.size(), "Encounter formation produced exact overlaps")
	_append_error(errors, signatures.size() >= 4, "Encounter stress run produced insufficient signature diversity")
	_append_error(errors, formations.size() >= 4, "Encounter stress run produced insufficient formation diversity")
	return {"seeds": 128, "signature_diversity": signatures.size(), "formation_diversity": formations.size()}

func _test_entropy(errors: Array[String]) -> Dictionary:
	var entropy: RefCounted = EntropyScript.new()
	var contract: Dictionary = entropy.call("audit_contract")
	for flag: String in ["crypto_mixed_at_reseed", "fresh_context_tokens", "context_isolated_forks", "sha256_substream_derivation", "rng_algorithm_not_persistence_abi", "context_occurrence_counters"]:
		_append_error(errors, bool(contract.get(flag, false)), "Entropy contract missing: " + flag)
	_append_error(errors, not bool(contract.get("fixed_seed_replay", true)), "Entropy contract unexpectedly re-enabled fixed-seed replay")

	var stable_seed_before := int(entropy.call("derive_seed", "isolated-alpha", 1))
	for index: int in range(64):
		var noise_rng: RandomNumberGenerator = entropy.call("fork", "unrelated-%d" % index)
		noise_rng.randi()
	var stable_seed_after := int(entropy.call("derive_seed", "isolated-alpha", 1))
	_append_error(errors, stable_seed_before == stable_seed_after, "Unrelated RNG consumption perturbed an isolated substream seed")
	_append_error(errors, stable_seed_before != int(entropy.call("derive_seed", "isolated-alpha", 2)), "Context occurrence did not create a distinct substream")

	var tokens: Dictionary = {}
	for index: int in range(256):
		var token := int(entropy.call("token", "counteraudit:%d" % index))
		tokens[token] = true
	_append_error(errors, tokens.size() == 256, "Entropy director produced duplicate context tokens in 256-sample stress test")
	for _index: int in range(32):
		_append_error(errors, not bool(entropy.call("chance", 0.0)), "Entropy chance(0.0) returned true")
		_append_error(errors, bool(entropy.call("chance", 1.0)), "Entropy chance(1.0) returned false")
	_append_error(errors, String(entropy.call("pick", [], "fallback")) == "fallback", "Entropy pick() failed empty-array fallback")
	return {"unique_tokens": tokens.size(), "isolated_seed": stable_seed_before, "contract": contract}

func _test_world_generation(errors: Array[String]) -> Dictionary:
	var world: RefCounted = WorldScript.new()
	var story_beats: Dictionary = {}
	var landmarks: Dictionary = {}
	var signatures: Dictionary = {}
	for biome_index: int in range(BIOMES.size()):
		var biome_id := BIOMES[biome_index]
		var local_story: Dictionary = {}
		var local_landmarks: Dictionary = {}
		for sample: int in range(48):
			var rng := RandomNumberGenerator.new()
			rng.seed = 50000 + biome_index * 1000 + sample * 37
			var recipe: Dictionary = world.call("make_room_recipe", rng, biome_id, "combat", 1.35, Vector2(1280, 720))
			var story := String(recipe.get("story_beat", ""))
			var landmark := String(recipe.get("landmark", ""))
			var signature := String(recipe.get("art4_room_signature", ""))
			_append_error(errors, not story.is_empty(), "Art4 recipe missing story beat: " + biome_id)
			_append_error(errors, not landmark.is_empty(), "Art4 recipe missing landmark: " + biome_id)
			_append_error(errors, not signature.is_empty(), "Art4 recipe missing signature: " + biome_id)
			local_story[story] = true
			local_landmarks[landmark] = true
			signatures[signature] = true
		story_beats[biome_id] = local_story.size()
		landmarks[biome_id] = local_landmarks.size()
		_append_error(errors, local_story.size() >= 3, "Art4 biome collapsed to too few story beats: " + biome_id)
		_append_error(errors, local_landmarks.size() >= 3, "Art4 biome collapsed to too few landmarks: " + biome_id)
	_append_error(errors, signatures.size() >= 220, "Art4 240-room stress sample produced excessive signature collisions")
	return {"samples": 240, "story_beat_diversity": story_beats, "landmark_diversity": landmarks, "signature_diversity": signatures.size()}

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
		"world": _test_world_generation(errors),
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
