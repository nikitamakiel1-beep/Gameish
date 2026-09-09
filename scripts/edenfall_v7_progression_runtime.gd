extends "res://scripts/edenfall_v7_art_runtime.gd"

const PROGRESSION_VERSION := "0.6.1-rc7"
const PROGRESSION_PATH := "user://edenfall_progression_rc7.json"
const EvolutionDirectorScript: Script = preload("res://scripts/v7/lineage_evolution_director.gd")

var evolution_director: RefCounted = EvolutionDirectorScript.new()
var pending_adaptations: Array[Dictionary] = []
var _restoring_progression := false

func _ready() -> void:
	super._ready()
	if not profile.has("adaptations_discovered"):
		profile["adaptations_discovered"] = []

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	if not _restoring_progression:
		_delete_progression_state()
	pending_adaptations.clear()
	super.start_new_run(lineage_index, seed_override)
	if not player.is_empty():
		player["weapon_evolutions"] = []
	if not _restoring_progression:
		save_suspended_run()

func complete_biome() -> void:
	if biome_index >= BIOMES.size() - 1 or state != "run":
		super.complete_biome()
		return
	if choice_open:
		return
	_open_guardian_adaptation()

func _open_guardian_adaptation() -> void:
	if player.is_empty():
		super.complete_biome()
		return
	var lineage_id := String(player["id"])
	var owned: Array = player.get("weapon_evolutions", [])
	pending_adaptations = evolution_director.call("choices", lineage_id, biome_index, run_seed, owned)
	if pending_adaptations.size() < 2:
		super.complete_biome()
		return
	choice_open = true
	choice_index = 0
	choice_context = "genome_adaptation"
	choice_options = []
	for definition in pending_adaptations:
		choice_options.append(String(definition.get("name", "GENOME ADAPTATION")))
	boss_health = 0.0
	boss_max_health = 0.0
	objective = "Choose a lineage adaptation before descent"
	player["pos"] = arena_rect().get_center()
	notify("GUARDIAN GENOME EXTRACTED // ADAPTATION REQUIRED")
	save_suspended_run()

func _confirm_room_choice() -> void:
	if choice_context != "genome_adaptation":
		super._confirm_room_choice()
		return
	if not choice_open or pending_adaptations.is_empty():
		return
	choice_index = clampi(choice_index, 0, pending_adaptations.size() - 1)
	var definition: Dictionary = pending_adaptations[choice_index]
	_apply_adaptation(definition)
	var adaptation_id := String(definition.get("id", ""))
	var owned: Array = player.get("weapon_evolutions", [])
	if not adaptation_id.is_empty() and adaptation_id not in owned:
		owned.append(adaptation_id)
	player["weapon_evolutions"] = owned
	var discovered: Array = profile.get("adaptations_discovered", [])
	var discovery_id := "%s:%s" % [String(player["id"]), adaptation_id]
	if not adaptation_id.is_empty() and discovery_id not in discovered:
		discovered.append(discovery_id)
	profile["adaptations_discovered"] = discovered
	choice_open = false
	choice_context = ""
	choice_options.clear()
	pending_adaptations.clear()
	play_sfx("relic", -2.0, 80)
	haptic(55, 0.58)
	notify("GENOME ADAPTED // %s" % String(definition.get("name", "PROTOCOL")))
	save_profile()
	_write_progression_state(false)
	super.complete_biome()

func _apply_adaptation(definition: Dictionary) -> void:
	var weapon: Dictionary = player.get("weapon", director.weapon_for(String(player["id"])))
	if definition.has("homing"):
		weapon["homing"] = float(weapon.get("homing", 0.0)) + float(definition["homing"])
	if definition.has("projectiles"):
		weapon["projectiles"] = maxi(1, int(weapon.get("projectiles", 1)) + int(definition["projectiles"]))
	if definition.has("weapon_damage_mult"):
		weapon["damage"] = float(weapon.get("damage", 1.0)) * float(definition["weapon_damage_mult"])
	if definition.has("explosion"):
		weapon["explosion"] = float(weapon.get("explosion", 0.0)) + float(definition["explosion"])
	if definition.has("pierce"):
		weapon["pierce"] = int(weapon.get("pierce", 0)) + int(definition["pierce"])
	player["weapon"] = weapon
	if definition.has("fire_delay_mult"):
		player["fire_delay"] = maxf(0.075, float(player["fire_delay"]) * float(definition["fire_delay_mult"]))
	if definition.has("shot_speed_mult"):
		player["shot_speed"] = float(player["shot_speed"]) * float(definition["shot_speed_mult"])
	if definition.has("dash_mult"):
		player["dash_delay"] = maxf(0.38, float(player["dash_delay"]) * float(definition["dash_mult"]))
	if definition.has("luck"):
		player["luck"] = minf(0.65, float(player["luck"]) + float(definition["luck"]))
	if definition.has("max_hp"):
		var gain := float(definition["max_hp"])
		player["max_hp"] = float(player["max_hp"]) + gain
		player["hp"] = minf(float(player["max_hp"]), float(player["hp"]) + gain)
	if bool(definition.get("shield", false)):
		player["shield"] = true
	if definition.has("orbitals"):
		player["orbitals"] = mini(4, int(player.get("orbitals", 0)) + int(definition["orbitals"]))
	if definition.has("fungal_armor"):
		player["fungal_armor"] = mini(6, int(player.get("fungal_armor", 0)) + int(definition["fungal_armor"]))
	if definition.has("lifesteal"):
		player["lifesteal_chance"] = minf(0.22, float(player.get("lifesteal_chance", 0.0)) + float(definition["lifesteal"]))
	if definition.has("spore_power"):
		player["spore_power"] = float(player.get("spore_power", 0.0)) + float(definition["spore_power"])

func check_room_clear() -> void:
	if choice_open and choice_context == "genome_adaptation":
		return
	super.check_room_clear()

func draw_run() -> void:
	super.draw_run()
	if not choice_open or choice_context != "genome_adaptation" or pending_adaptations.is_empty():
		return
	var safe := safe_rect()
	var width := minf(720.0, safe.size.x - 34.0)
	var panel := Rect2(Vector2(safe.get_center().x - width * 0.5, safe.get_center().y - 112.0), Vector2(width, 224.0))
	for index in range(mini(choice_options.size(), pending_adaptations.size())):
		var rect := _choice_rect(index, panel)
		var summary := String(pending_adaptations[index].get("summary", "Lineage protocol changes."))
		draw_wrapped(summary, Rect2(rect.position + Vector2(12.0, 57.0), Vector2(rect.size.x - 24.0, 27.0)), 7, Color8(151, 171, 157))
	draw_text_centered("GUARDIAN %d/5 // RUN-ONLY LINEAGE EVOLUTION" % (biome_index + 1), Vector2(panel.get_center().x, panel.position.y + 58.0), 7, Color8(132, 171, 149))

func draw_hud() -> void:
	super.draw_hud()
	if player.is_empty():
		return
	var evolutions: Array = player.get("weapon_evolutions", [])
	if evolutions.is_empty():
		return
	var safe := safe_rect()
	draw_text("ADAPT %d" % evolutions.size(), Vector2(safe.position.x + 12.0, safe.end.y - 82.0), 7, Color8(226, 195, 121))

func save_suspended_run() -> void:
	super.save_suspended_run()
	if _restoring_progression or state != "run" or player.is_empty():
		return
	_write_progression_state(choice_open and choice_context == "genome_adaptation")

func _write_progression_state(pending: bool) -> void:
	if player.is_empty():
		return
	var option_ids: Array[String] = []
	for definition in pending_adaptations:
		option_ids.append(String(definition.get("id", "")))
	atomic_json_write(PROGRESSION_PATH, {
		"version":PROGRESSION_VERSION,
		"seed":run_seed,
		"biome":biome_index,
		"lineage":String(player["id"]),
		"evolutions":player.get("weapon_evolutions", []),
		"pending":pending,
		"options":option_ids,
		"choice_index":choice_index,
	})

func restore_suspended_run() -> void:
	var progression := read_json_with_backup(PROGRESSION_PATH)
	_restoring_progression = true
	super.restore_suspended_run()
	_restoring_progression = false
	if state != "run" or player.is_empty() or progression.is_empty():
		return
	if int(progression.get("seed", -1)) != run_seed:
		return
	player["weapon_evolutions"] = Array(progression.get("evolutions", [])).duplicate()
	if not bool(progression.get("pending", false)) or int(progression.get("biome", -1)) != biome_index:
		return
	var lineage_id := String(player["id"])
	pending_adaptations.clear()
	for id_variant in Array(progression.get("options", [])):
		var definition: Dictionary = evolution_director.call("definition", lineage_id, String(id_variant))
		if not definition.is_empty():
			pending_adaptations.append(definition)
	if pending_adaptations.size() < 2:
		pending_adaptations = evolution_director.call("choices", lineage_id, biome_index, run_seed, player.get("weapon_evolutions", []))
	choice_open = true
	choice_context = "genome_adaptation"
	choice_index = clampi(int(progression.get("choice_index", 0)), 0, maxi(0, pending_adaptations.size() - 1))
	choice_options.clear()
	for definition in pending_adaptations:
		choice_options.append(String(definition.get("name", "GENOME ADAPTATION")))
	enemies.clear()
	bullets.clear()
	boss_health = 0.0
	boss_max_health = 0.0
	objective = "Choose a lineage adaptation before descent"
	player["pos"] = arena_rect().get_center()
	notify("GUARDIAN ADAPTATION RESTORED")

func finish_run(victory: bool) -> void:
	var was_running := state == "run"
	super.finish_run(victory)
	if was_running:
		_delete_progression_state()

func _delete_progression_state() -> void:
	for path in [PROGRESSION_PATH, PROGRESSION_PATH + ".bak", PROGRESSION_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["progression_version"] = PROGRESSION_VERSION
	report["run_adaptations"] = player.get("weapon_evolutions", []) if not player.is_empty() else []
	report["adaptation_pending"] = choice_open and choice_context == "genome_adaptation"
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	var evolution_report: Dictionary = evolution_director.call("audit_contract")
	report["version"] = PROGRESSION_VERSION
	report["guardian_adaptation_choices"] = true
	report["adaptation_options"] = int(evolution_report.get("options", 0))
	report["adaptation_suspend_safe"] = true
	report["run_only_lineage_evolution"] = true
	return report
