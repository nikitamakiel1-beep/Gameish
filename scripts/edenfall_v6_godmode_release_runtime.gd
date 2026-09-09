extends "res://scripts/edenfall_v6_godmode_complete_runtime.gd"

const RELEASE_GODMODE_VERSION := "0.6.1-rc6"
const ENDING_PENDING_PATH := "user://edenfall_pending_ending_rc6.json"

var last_ending_id := ""

func _ready() -> void:
	if not profile.has("endings"):
		profile["endings"] = []
	if not profile.has("last_ending"):
		profile["last_ending"] = ""
	super._ready()
	last_ending_id = String(profile.get("last_ending", ""))

func spawn_room(room: Dictionary) -> void:
	var saved_seed := rng.seed
	var saved_state := rng.state
	super.spawn_room(room)
	rng.seed = saved_seed
	rng.state = saved_state

func complete_biome() -> void:
	if biome_index >= BIOMES.size() - 1 and state == "run":
		boss_health = 0.0
		boss_max_health = 0.0
		_open_serpent_resolution()
		return
	super.complete_biome()

func _open_serpent_resolution() -> void:
	choice_open = true
	choice_index = 0
	choice_context = "serpent_resolution"
	choice_options = [
		"REJECT THE SERPENT // PRESERVE ADAMIC LIMITS",
		"ACCEPT FORBIDDEN ADAPTATION // OPEN THE GENOME",
	]
	objective = "Resolve the Serpent Interface"
	player["pos"] = arena_rect().get_center()
	atomic_json_write(ENDING_PENDING_PATH, {"seed":run_seed, "pending":true})
	notify("SERPENT INTERFACE // FINAL ADAPTATION REQUEST")

func _confirm_room_choice() -> void:
	if choice_context != "serpent_resolution":
		super._confirm_room_choice()
		return
	if not choice_open:
		return
	var ending_id := "eden_bound" if choice_index == 0 else "serpent_heir"
	last_ending_id = ending_id
	var endings: Array = profile.get("endings", [])
	if ending_id not in endings:
		endings.append(ending_id)
	profile["endings"] = endings
	profile["last_ending"] = ending_id
	if ending_id == "eden_bound":
		_adjust_reputation("ash_covenant", 2)
		_adjust_reputation("unnamed", -1)
		mastery_gained += 140
		run_score += 1800
		notify("ENDING // EDEN BOUNDARY PRESERVED")
	else:
		_adjust_reputation("unnamed", 2)
		_adjust_reputation("ash_covenant", -1)
		var records: Array = profile.get("archive_records", [])
		if "serpent_testament" not in records:
			records.append("serpent_testament")
			profile["archive_records"] = records
		var mutations: Array = player.get("serpent_mutations", [])
		if "forked_aim" not in mutations:
			mutations.append("forked_aim")
			player["serpent_mutations"] = mutations
		mastery_gained += 180
		run_score += 2200
		notify("ENDING // FORBIDDEN GENOME ACCEPTED")
	choice_open = false
	choice_context = ""
	choice_options.clear()
	save_profile()
	_delete_pending_ending()
	finish_run(true)

func check_room_transition() -> void:
	if choice_open:
		return
	super.check_room_transition()

func restore_suspended_run() -> void:
	super.restore_suspended_run()
	if state != "run":
		return
	var pending := read_json_with_backup(ENDING_PENDING_PATH)
	if not pending.is_empty() and bool(pending.get("pending", false)) and int(pending.get("seed", -1)) == run_seed:
		_open_serpent_resolution()

func save_suspended_run() -> void:
	super.save_suspended_run()
	if state == "run" and choice_open and choice_context == "serpent_resolution":
		atomic_json_write(ENDING_PENDING_PATH, {"seed":run_seed, "pending":true})

func finish_run(victory: bool) -> void:
	var was_running := state == "run"
	super.finish_run(victory)
	if was_running:
		_delete_pending_ending()

func _delete_pending_ending() -> void:
	for path in [ENDING_PENDING_PATH, ENDING_PENDING_PATH + ".bak", ENDING_PENDING_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func draw_end(victory: bool) -> void:
	super.draw_end(victory)
	if not victory:
		return
	var safe := safe_rect()
	var ending := last_ending_id if not last_ending_id.is_empty() else String(profile.get("last_ending", ""))
	var label := "EDEN BOUNDARY PRESERVED" if ending == "eden_bound" else ("FORBIDDEN GENOME ACCEPTED" if ending == "serpent_heir" else "SERPENT RESOLUTION RECORDED")
	draw_text_centered(label, Vector2(safe.get_center().x, safe.end.y - 68.0), 10, Color8(230, 199, 128))

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["release_godmode_version"] = RELEASE_GODMODE_VERSION
	report["serpent_resolution"] = last_ending_id
	report["known_endings"] = Array(profile.get("endings", [])).duplicate()
	return report

func audit_godmode_contract() -> Dictionary:
	var report: Dictionary = super.audit_godmode_contract()
	report["version"] = RELEASE_GODMODE_VERSION
	report["all_room_spawns_rng_isolated"] = true
	report["serpent_resolution_choice"] = true
	report["ending_choice_suspend_safe"] = true
	return report
