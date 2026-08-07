extends "res://scripts/edenfall_v6_godmode_runtime.gd"

const STABLE_GODMODE_VERSION := "0.6.1-rc6"
const SPECIAL_INTERACT_RADIUS := 116.0

func spawn_room(room: Dictionary) -> void:
	var saved_seed := rng.seed
	var saved_state := rng.state
	super.spawn_room(room)
	rng.seed = saved_seed
	rng.state = saved_state

func restore_suspended_run() -> void:
	_restoring_rc6 = true
	super.restore_suspended_run()
	_restoring_rc6 = false
	if state == "run":
		_refresh_build_synergies(false)

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	super.enter_room(coord, movement_direction)
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room.get("kind", ""))
	if kind in SPECIAL_ROOM_KINDS and not bool(room.get("rc6_used", false)):
		room["cleared"] = false
		room_graph[current_room] = room
		objective = objective_for_room(room)
		save_suspended_run()

func interact() -> void:
	if state == "run" and not choice_open and room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		var kind := String(room.get("kind", ""))
		if kind in SPECIAL_ROOM_KINDS and not bool(room.get("rc6_used", false)):
			var point := _special_interaction_point()
			if Vector2(player.get("pos", point)).distance_to(point) > SPECIAL_INTERACT_RADIUS:
				notify("APPROACH THE %s INTERFACE" % _special_room_device_name(kind))
				return
	super.interact()

func _confirm_room_choice() -> void:
	var room_was_special := room_graph.has(current_room) and String(Dictionary(room_graph[current_room]).get("kind", "")) in SPECIAL_ROOM_KINDS
	super._confirm_room_choice()
	if not room_was_special or choice_open or not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	if bool(room.get("rc6_used", false)):
		room["cleared"] = true
		room_graph[current_room] = room
		objective = "Choose an open gate"
		play_sfx("door")
		notify("DECISION RECORDED // GATES RELEASED")
		save_suspended_run()

func draw_arena() -> void:
	super.draw_arena()
	if state != "run" or not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room.get("kind", ""))
	if kind in SPECIAL_ROOM_KINDS:
		_draw_special_room_focus(kind, bool(room.get("rc6_used", false)))

func draw_run() -> void:
	super.draw_run()
	if state != "run" or choice_open or not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var kind := String(room.get("kind", ""))
	if kind not in SPECIAL_ROOM_KINDS or bool(room.get("rc6_used", false)):
		return
	var point := _special_interaction_point()
	var distance := Vector2(player.get("pos", point)).distance_to(point)
	if distance <= SPECIAL_INTERACT_RADIUS:
		draw_text_centered("E / USE // %s" % _special_room_device_name(kind), point + Vector2(0, 58), 8, Color8(242, 215, 154))

func _special_interaction_point() -> Vector2:
	return arena_rect().get_center()

func _special_room_device_name(kind: String) -> String:
	match kind:
		"settlement": return "SETTLEMENT PARLEY"
		"sacrifice": return "SACRIFICE BIOREACTOR"
		"memory": return "MEMORY CRADLE"
		"maintenance": return "SERVICE CACHE"
		"serpent_terminal": return "SERPENT TERMINAL"
		_: return "ROOM SYSTEM"

func _draw_special_room_focus(kind: String, used: bool) -> void:
	var center := _special_interaction_point()
	var accent := Color(BIOMES[biome_index]["accent"])
	var alpha := 0.24 if used else 0.72
	draw_circle(center + Vector2(5, 9), 34.0, Color(0, 0, 0, 0.28))
	match kind:
		"settlement":
			draw_rect(Rect2(center - Vector2(36, 21), Vector2(72, 42)), Color(0.12, 0.08, 0.05, 0.84))
			draw_line(center - Vector2(42, 22), center + Vector2(42, -22), Color8(222, 177, 101), 4.0)
			for side in [-1.0, 1.0]:
				draw_circle(center + Vector2(side * 22.0, 13), 8.0, Color8(71, 54, 43))
		"sacrifice":
			draw_circle(center, 28.0, Color(0.22, 0.035, 0.04, 0.88))
			draw_arc(center, 31.0, 0.0, TAU, 32, Color(0.92, 0.25, 0.20, alpha), 4.0)
			draw_line(center - Vector2(16, 0), center + Vector2(16, 0), Color(0.93, 0.55, 0.36, alpha), 3.0)
		"memory":
			draw_rect(Rect2(center - Vector2(26, 32), Vector2(52, 64)), Color(0.035, 0.09, 0.10, 0.88))
			draw_rect(Rect2(center - Vector2(20, 26), Vector2(40, 52)), Color(accent, alpha * 0.24))
			for line_index in range(4):
				draw_line(center + Vector2(-15, -16 + line_index * 10), center + Vector2(15, -19 + line_index * 10), Color(accent, alpha), 2.0)
		"maintenance":
			draw_rect(Rect2(center - Vector2(34, 24), Vector2(68, 48)), Color(0.055, 0.07, 0.07, 0.94))
			draw_rect(Rect2(center - Vector2(30, 20), Vector2(60, 40)), Color8(73, 91, 84), false, 2.0)
			for bolt in [Vector2(-23,-13), Vector2(23,-13), Vector2(-23,13), Vector2(23,13)]:
				draw_circle(center + bolt, 3.0, Color8(190, 170, 123))
		"serpent_terminal":
			for ring in [30.0, 22.0, 14.0]:
				draw_arc(center, ring, visual_clock * 0.22 * (1.0 if int(ring) % 2 == 0 else -1.0), TAU + visual_clock * 0.22, 30, Color(0.77, 0.37, 0.79, alpha), 3.0)
			var direction := Vector2.RIGHT.rotated(visual_clock * 0.65)
			draw_line(center - direction * 24.0, center + direction * 24.0, Color(0.93, 0.68, 0.86, alpha), 2.0)
	if not used:
		draw_arc(center, 43.0, -PI * 0.5, -PI * 0.5 + TAU * (0.62 + 0.16 * sin(visual_clock * 2.2)), 40, Color(accent, 0.50), 2.0)

func draw_archive() -> void:
	super.draw_archive()
	var safe := safe_rect()
	var reps: Dictionary = profile.get("faction_reputation", {})
	var pieces: Array[String] = []
	for faction_id in ["salt_caravans", "ash_covenant", "tubal_foundries", "enoch_outlaws", "lamech_houses", "unnamed"]:
		var definition: Dictionary = godmode_director.call("faction_definition", faction_id)
		pieces.append("%s %+d" % [String(definition.get("name", faction_id)).get_slice(" ", 0), int(reps.get(faction_id, 0))])
	draw_text_centered("FACTION MEMORY // %s" % "  •  ".join(pieces), Vector2(safe.get_center().x, safe.end.y - 21.0), 6, Color8(153, 175, 158))

func draw_end(victory: bool) -> void:
	super.draw_end(victory)
	var safe := safe_rect()
	draw_text_centered("RC6 // SYNERGIES %d  •  ARCHIVE RECORDS %d  •  GUARDIANS KNOWN %d" % [active_synergies.size(), Array(profile.get("archive_records", [])).size(), Array(profile.get("guardians_defeated", [])).size()], Vector2(safe.get_center().x, safe.end.y - 46.0), 8, Color8(146, 177, 160))

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["godmode_version"] = STABLE_GODMODE_VERSION
	report["active_synergies"] = active_synergies.keys()
	report["room_kind"] = String(Dictionary(room_graph.get(current_room, {})).get("kind", "none"))
	report["faction_reputation"] = Dictionary(profile.get("faction_reputation", {})).duplicate(true)
	report["fungal_armor"] = int(player.get("fungal_armor", 0)) if not player.is_empty() else 0
	report["orbitals"] = int(player.get("orbitals", 0)) if not player.is_empty() else 0
	return report

func audit_godmode_contract() -> Dictionary:
	var director_contract: Dictionary = godmode_director.call("audit_contract")
	var boss_contract: Dictionary = boss_patterns.call("audit_contract")
	return {
		"version": STABLE_GODMODE_VERSION,
		"director": director_contract,
		"boss_patterns": boss_contract,
		"special_rooms": SPECIAL_ROOM_KINDS.size(),
		"combat_room_kinds": COMBAT_ROOM_KINDS.size(),
		"synergy_rules": int(director_contract.get("synergies", 0)),
		"factions": int(director_contract.get("factions", 0)),
		"boss_pattern_count": int(boss_contract.get("patterns", 0)),
		"restore_guard": true,
		"mandatory_special_decisions": true,
		"rng_seed_and_state_restored": true,
	}
