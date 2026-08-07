extends "res://scripts/edenfall_v6_godmode_verified_runtime.gd"

const MASTERPIECE_VERSION := "0.6.1-rc7"
const EncounterComposerScript: Script = preload("res://scripts/v7/encounter_composer.gd")
const RelicPoolDirectorScript: Script = preload("res://scripts/v7/relic_pool_director.gd")

var encounter_composer: RefCounted = EncounterComposerScript.new()
var relic_pool_director: RefCounted = RelicPoolDirectorScript.new()
var encounter_signature := ""
var encounter_signature_id := ""

func spawn_room(room: Dictionary) -> void:
	var kind := String(room.get("kind", "combat"))
	if kind not in ["combat", "trial", "contract"]:
		super.spawn_room(room)
		return
	var saved_seed := rng.seed
	var saved_state := rng.state
	var depth := int(room.get("depth", 0))
	var count := clampi(3 + int(depth / 2) + biome_index, 4, 8)
	if active_mode == "training":
		count = maxi(3, count - 1)
	elif active_mode == "daily":
		count = mini(8, count + 1)
	if kind == "trial":
		count = mini(9, count + 2)
	elif kind == "contract":
		count = mini(9, count + 1)
	var composition_seed := int(godmode_director.call("room_seed", run_seed, current_room, biome_index, depth, 7071))
	var pool: Array = enemy_pool_for_biome()
	var composition: Dictionary = encounter_composer.call("compose", pool, count, composition_seed, kind, String(room.get("modifier", "none")))
	var ids: Array = composition.get("ids", [])
	var formation := String(composition.get("formation", "ring"))
	var positions: Array = encounter_composer.call("positions", arena_rect(), ids.size(), formation, composition_seed ^ 0x45ED)
	rng.seed = composition_seed
	for index in range(ids.size()):
		var position := Vector2(positions[index]) if index < positions.size() else random_arena_position(105.0)
		spawn_enemy(String(ids[index]), position, index)
	if kind == "trial" and not enemies.is_empty():
		promote_enemy_to_elite(0, "armored")
	elif kind == "contract" and not enemies.is_empty():
		promote_enemy_to_elite(0, "armored")
		if enemies.size() > 2:
			promote_enemy_to_elite(2, "swift")
	_spawn_rc7_faction_retaliation(room, composition_seed ^ 0x1337)
	rng.seed = saved_seed
	rng.state = saved_state
	encounter_signature = String(composition.get("name", "MIXED HOST CELL"))
	encounter_signature_id = String(composition.get("id", "mixed"))
	room["encounter_signature"] = encounter_signature
	room["encounter_signature_id"] = encounter_signature_id

func enter_room(coord: Vector2i, movement_direction: Vector2i) -> void:
	encounter_signature = ""
	encounter_signature_id = ""
	super.enter_room(coord, movement_direction)
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	encounter_signature = String(room.get("encounter_signature", ""))
	encounter_signature_id = String(room.get("encounter_signature_id", ""))

func _spawn_rc7_faction_retaliation(room: Dictionary, seed_value: int) -> void:
	if enemies.is_empty() or enemies.size() >= 9:
		return
	var faction := String(godmode_director.call("faction_for", biome_index, current_room, run_seed))
	var reps: Dictionary = profile.get("faction_reputation", {})
	var reputation := int(reps.get(faction, 0))
	if reputation > -4:
		return
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed_value
	var chance := clampf(0.16 + float(absi(reputation) - 4) * 0.045, 0.16, 0.52)
	if local_rng.randf() > chance:
		return
	var id := "caravan_outlaw" if local_rng.randf() < 0.56 else "outlaw_gunner"
	var positions: Array = encounter_composer.call("positions", arena_rect(), 8, "pincer", seed_value ^ 0xBEEF)
	var position := Vector2(positions[local_rng.randi_range(0, positions.size() - 1)]) if not positions.is_empty() else arena_rect().get_center()
	spawn_enemy(id, position, _enemy_uid_counter)
	if reputation <= -8 and not enemies.is_empty():
		promote_enemy_to_elite(enemies.size() - 1, "swift")

func random_relic_id(excluded: Array = []) -> String:
	var catalog := relic_catalog()
	var room_kind := "treasure"
	var depth := 0
	if room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		room_kind = String(room.get("kind", "treasure"))
		depth = int(room.get("depth", 0))
	var context := String(relic_pool_director.call("context_for_room", room_kind))
	var inventory: Array = player.get("inventory", []) if not player.is_empty() else []
	var combined_excluded: Array = excluded.duplicate()
	for id in inventory:
		if id not in combined_excluded:
			combined_excluded.append(id)
	var roll_seed := int(godmode_director.call("room_seed", run_seed, current_room, biome_index, depth, 9700 + combined_excluded.size()))
	var picked := String(relic_pool_director.call("pick", catalog, _archive_relic_tier(), combined_excluded, context, roll_seed))
	return picked if not picked.is_empty() else super.random_relic_id(combined_excluded)

func assisted_aim(current: Vector2) -> Vector2:
	if player.is_empty() or current.length_squared() < 0.001:
		return current
	var origin := Vector2(player["pos"])
	var best := current.normalized()
	var best_score := 0.22
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var delta := Vector2(enemy["pos"]) - origin
		var distance := delta.length()
		if distance <= 0.001 or distance > 560.0:
			continue
		var candidate := delta / distance
		var angle := absf(current.angle_to(candidate))
		if angle >= best_score:
			continue
		if _bullet_hits_obstacle(origin, Vector2(enemy["pos"]), 3.0):
			continue
		best_score = angle
		best = candidate
	return current.normalized().slerp(best, 0.58).normalized()

func draw_enemies() -> void:
	super.draw_enemies()
	var strong := bool(settings.get("strong_telegraphs", true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var windup := maxf(float(enemy.get("windup", 0.0)), maxf(float(enemy.get("special_windup", 0.0)), float(enemy.get("boss_windup", 0.0))))
		if windup <= 0.0:
			continue
		var maximum := maxf(float(enemy.get("windup_max", 0.0)), maxf(float(enemy.get("special_windup_max", 0.0)), float(enemy.get("boss_windup_max", 0.0))))
		maximum = maxf(maximum, windup)
		var progress := clampf(1.0 - windup / maximum, 0.0, 1.0)
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy["radius"]) + (16.0 if strong else 10.0)
		var danger := Color(1.0, 0.35, 0.22, 0.90 if strong else 0.58)
		draw_arc(pos, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 30, danger, 4.0 if strong else 2.0)
		var direction := Vector2(enemy.get("telegraph_dir", enemy.get("look", Vector2.DOWN))).normalized()
		if direction.length_squared() > 0.1 and String(enemy.get("style", "")) in ["charger", "ranged", "skirmisher"]:
			var length := 190.0 if String(enemy.get("style", "")) == "charger" else 128.0
			draw_line(pos + direction * (float(enemy["radius"]) + 5.0), pos + direction * length, Color(danger, 0.26 if strong else 0.14), 5.0 if strong and String(enemy.get("style", "")) == "charger" else 2.0)

func draw_hud() -> void:
	super.draw_hud()
	if encounter_signature.is_empty() or state != "run":
		return
	var safe := safe_rect()
	var rect := Rect2(Vector2(safe.position.x + 8.0, safe.end.y - 70.0), Vector2(minf(240.0, safe.size.x * 0.28), 22.0))
	_draw_beveled_panel(rect, Color(0.015, 0.035, 0.036, 0.78), Color8(74, 105, 94), false)
	draw_text_centered(encounter_signature, rect.get_center() + Vector2(0, 4), 7, Color8(185, 199, 177))

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["masterpiece_version"] = MASTERPIECE_VERSION
	report["encounter_signature"] = encounter_signature
	report["encounter_composer"] = encounter_composer.call("audit_contract")
	report["relic_pool_director"] = relic_pool_director.call("audit_contract")
	return report

func audit_masterpiece_contract() -> Dictionary:
	var encounter_report: Dictionary = encounter_composer.call("audit_contract")
	var relic_report: Dictionary = relic_pool_director.call("audit_contract")
	return {
		"version": MASTERPIECE_VERSION,
		"encounter_signatures": int(encounter_report.get("signatures", 0)),
		"enemy_roles": int(encounter_report.get("enemy_roles", 0)),
		"contextual_relic_pools": bool(relic_report.get("contextual_pools", false)),
		"cover_aware_aim_assist": true,
		"explicit_windup_telegraphs": true,
		"deterministic_composition": true,
		"post_enter_cover_resolution": true,
	}
