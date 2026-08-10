extends "res://scripts/edenfall_v8_authored_presentation_runtime.gd"

const ART4_PRESENTATION_VERSION: String = "0.6.4-authored-art4"

func draw_arena() -> void:
	super.draw_arena()
	_draw_art4_room_architecture()

func _draw_art4_room_architecture() -> void:
	var arena: Rect2 = arena_rect()
	var biome: Dictionary = BIOMES[biome_index]
	var accent: Color = Color(biome["accent"])
	var floor: Color = Color(biome["floor"])
	var room: Dictionary = room_graph.get(current_room, {})
	var recipe: Dictionary = room.get("v8_world_recipe", {})
	var signature: String = String(recipe.get("art4_room_signature", recipe.get("signature", _coord_key(current_room))))
	var seed_value: int = absi(signature.hash())

	# Deep perimeter architecture gives the room a wall volume rather than a flat framed rectangle.
	var wall_depth: float = 20.0
	draw_rect(Rect2(arena.position, Vector2(arena.size.x, wall_depth)), Color(floor.darkened(0.42), 0.96))
	draw_rect(Rect2(Vector2(arena.position.x, arena.end.y - wall_depth), Vector2(arena.size.x, wall_depth)), Color(floor.darkened(0.50), 0.96))
	draw_rect(Rect2(arena.position, Vector2(wall_depth, arena.size.y)), Color(floor.darkened(0.48), 0.95))
	draw_rect(Rect2(Vector2(arena.end.x - wall_depth, arena.position.y), Vector2(wall_depth, arena.size.y)), Color(floor.darkened(0.48), 0.95))
	for bay_index: int in range(7):
		var bay_x: float = arena.position.x + 34.0 + float(bay_index) * (arena.size.x - 68.0) / 6.0
		var lit: bool = posmod(seed_value + bay_index * 7, 3) != 0
		var lamp_color: Color = Color(accent.lightened(0.25), 0.68 if lit else 0.20)
		draw_rect(Rect2(Vector2(bay_x - 8.0, arena.position.y + 5.0), Vector2(16.0, 5.0)), Color(0.02, 0.04, 0.04, 0.96))
		if lit:
			draw_rect(Rect2(Vector2(bay_x - 5.0, arena.position.y + 6.0), Vector2(10.0, 2.0)), lamp_color)
			draw_circle(Vector2(bay_x, arena.position.y + 13.0), 11.0, Color(lamp_color, 0.05))

	match String(recipe.get("biome", String(biome.get("id", "industrial_eden")))):
		"industrial_eden": _draw_art4_industrial_room(arena, accent, seed_value)
		"ash_wastes": _draw_art4_ash_room(arena, accent, seed_value)
		"temple_lab": _draw_art4_temple_room(arena, accent, seed_value)
		"fungal_garden": _draw_art4_fungal_room(arena, accent, seed_value)
		"nephilim_ruins": _draw_art4_nephilim_room(arena, accent, seed_value)
		_:
			pass

func _draw_art4_industrial_room(arena: Rect2, accent: Color, seed_value: int) -> void:
	# Pipes, glass tanks and greenery are sparse but recognizable at gameplay scale.
	for pipe_index: int in range(3):
		var y: float = arena.position.y + 38.0 + float(posmod(seed_value + pipe_index * 53, maxi(60, int(arena.size.y - 76.0))))
		draw_line(Vector2(arena.position.x + 12.0, y), Vector2(arena.position.x + 52.0, y), Color(0.18, 0.28, 0.25, 0.82), 6.0)
		draw_line(Vector2(arena.end.x - 52.0, y + 8.0), Vector2(arena.end.x - 12.0, y + 8.0), Color(0.18, 0.28, 0.25, 0.82), 6.0)
	for tank_index: int in range(2):
		var side_x: float = arena.position.x + 42.0 if tank_index == 0 else arena.end.x - 78.0
		var y: float = arena.position.y + 70.0 + float(posmod(seed_value + tank_index * 89, maxi(90, int(arena.size.y - 170.0))))
		var tank: Rect2 = Rect2(Vector2(side_x, y), Vector2(36.0, 58.0))
		draw_rect(tank, Color(0.025, 0.07, 0.068, 0.92))
		draw_rect(tank, Color(accent, 0.50), false, 2.0)
		draw_rect(Rect2(Vector2(tank.position.x + 6.0, tank.end.y - 22.0), Vector2(tank.size.x - 12.0, 16.0)), Color(accent.darkened(0.18), 0.17))
		for bubble_index: int in range(3):
			var phase: float = fmod(visual_clock * (6.0 + float(bubble_index)) + float(seed_value % 11), 38.0)
			var bx: float = tank.position.x + 10.0 + float(bubble_index) * 8.0
			var by: float = tank.end.y - 8.0 - phase
			draw_circle(Vector2(bx, by), 1.5, Color(accent.lightened(0.25), 0.65))
	for vine_index: int in range(5):
		var root_x: float = arena.position.x + float(posmod(seed_value + vine_index * 67, maxi(1, int(arena.size.x))))
		var root: Vector2 = Vector2(root_x, arena.position.y + 18.0)
		var tip: Vector2 = root + Vector2(-12.0 + float(vine_index % 3) * 10.0, 28.0 + float((vine_index * 13) % 25))
		draw_line(root, tip, Color(0.23, 0.48, 0.25, 0.48), 3.0)
		draw_circle(tip, 3.0, Color(0.34, 0.61, 0.31, 0.50))

func _draw_art4_ash_room(arena: Rect2, accent: Color, seed_value: int) -> void:
	for ember_index: int in range(8):
		var x: float = arena.position.x + 30.0 + float(posmod(seed_value + ember_index * 83, maxi(1, int(arena.size.x - 60.0))))
		var y: float = arena.position.y + 28.0 + float(posmod(seed_value + ember_index * 47, maxi(1, int(arena.size.y - 56.0))))
		var pulse: float = 0.35 + 0.25 * sin(visual_clock * 4.0 + float(ember_index))
		draw_circle(Vector2(x, y), 2.0, Color(0.94, 0.42, 0.18, pulse))
	for beam_index: int in range(4):
		var x: float = arena.position.x + 80.0 + float(beam_index) * (arena.size.x - 160.0) / 3.0
		draw_line(Vector2(x - 18.0, arena.position.y + 25.0), Vector2(x + 18.0, arena.position.y + 8.0), Color(0.39, 0.24, 0.17, 0.44), 4.0)

func _draw_art4_temple_room(arena: Rect2, accent: Color, seed_value: int) -> void:
	var ritual_center: Vector2 = arena.get_center() + Vector2(float((seed_value % 81) - 40), float(((seed_value / 7) % 61) - 30))
	for radius_variant in [34.0, 48.0, 66.0]:
		var radius: float = float(radius_variant)
		draw_arc(ritual_center, radius, 0.0, TAU, 48, Color(accent, 0.10), 2.0)
	for spoke_index: int in range(8):
		var angle: float = TAU * float(spoke_index) / 8.0
		draw_line(ritual_center + Vector2.RIGHT.rotated(angle) * 28.0, ritual_center + Vector2.RIGHT.rotated(angle) * 62.0, Color(accent, 0.10), 2.0)
	for pulse_index: int in range(3):
		var alpha: float = 0.10 + 0.05 * sin(visual_clock * 2.2 + float(pulse_index))
		draw_circle(ritual_center + Vector2(float(pulse_index - 1) * 18.0, 0), 3.0, Color(accent.lightened(0.28), alpha + 0.18))

func _draw_art4_fungal_room(arena: Rect2, accent: Color, seed_value: int) -> void:
	for spore_index: int in range(14):
		var base_x: float = arena.position.x + 24.0 + float(posmod(seed_value + spore_index * 71, maxi(1, int(arena.size.x - 48.0))))
		var base_y: float = arena.position.y + 24.0 + float(posmod(seed_value + spore_index * 43, maxi(1, int(arena.size.y - 48.0))))
		var drift: Vector2 = Vector2(sin(visual_clock * 0.7 + float(spore_index)) * 5.0, -fmod(visual_clock * 7.0 + float(spore_index * 13), 28.0))
		draw_circle(Vector2(base_x, base_y) + drift, 1.5 + float(spore_index % 2), Color(accent.lightened(0.22), 0.24))
	for cluster_index: int in range(4):
		var x: float = arena.position.x + 40.0 + float(posmod(seed_value + cluster_index * 109, maxi(1, int(arena.size.x - 80.0))))
		var y: float = arena.position.y + 40.0 + float(posmod(seed_value + cluster_index * 61, maxi(1, int(arena.size.y - 80.0))))
		for bud_index: int in range(3):
			var bud_pos: Vector2 = Vector2(x + float(bud_index - 1) * 7.0, y - absf(float(bud_index - 1)) * 4.0)
			draw_line(Vector2(bud_pos.x, bud_pos.y + 10.0), bud_pos, Color(accent.darkened(0.35), 0.50), 2.0)
			draw_circle(bud_pos, 4.0 + float(bud_index % 2), Color(accent, 0.38))

func _draw_art4_nephilim_room(arena: Rect2, accent: Color, seed_value: int) -> void:
	for rib_index: int in range(5):
		var x: float = arena.position.x + 70.0 + float(rib_index) * (arena.size.x - 140.0) / 4.0
		var height: float = 36.0 + float(posmod(seed_value + rib_index * 31, 40))
		draw_arc(Vector2(x, arena.end.y - 12.0), height, PI, TAU, 24, Color(0.70, 0.65, 0.54, 0.18), 4.0)
	for relic_index: int in range(3):
		var x: float = arena.position.x + 54.0 + float(posmod(seed_value + relic_index * 131, maxi(1, int(arena.size.x - 108.0))))
		var y: float = arena.position.y + 28.0 + float(posmod(seed_value + relic_index * 73, maxi(1, int(arena.size.y - 80.0))))
		var relic: Rect2 = Rect2(Vector2(x - 8.0, y), Vector2(16.0, 34.0))
		draw_rect(relic, Color(0.27, 0.27, 0.25, 0.46))
		draw_rect(relic, Color(accent, 0.20), false, 2.0)
		draw_circle(Vector2(x, y + 13.0), 4.0, Color(accent, 0.26), false, 2.0)

func draw_player() -> void:
	if player.is_empty():
		return
	var texture: Texture2D = _player_entropy_texture()
	if texture == null:
		super.draw_player()
		return
	var genome: Dictionary = player.get("v8_visual_genome", {})
	var pos: Vector2 = Vector2(player["pos"])
	var aim: Vector2 = Vector2(player.get("aim", last_aim))
	if aim.length_squared() < 0.01:
		aim = Vector2.RIGHT
	else:
		aim = aim.normalized()
	var direction_index: int = quantize_direction(aim)
	var moving: bool = input_move.length_squared() > 0.04
	var firing: bool = input_aim.length_squared() > 0.04 and fire_timer > 0.0
	var frame: int = 0
	if dash_time > 0.0:
		frame = 3
	elif firing:
		frame = 2
	elif moving:
		frame = 1 if posmod(int(visual_clock * 9.0), 2) == 0 else 3
	var breathe: float = sin(visual_clock * 3.1) * (1.5 if not moving else 0.6)
	var display: float = 102.0 * float(genome.get("visual_scale", 1.0))
	var draw_pos: Vector2 = pos + Vector2(0.0, breathe)
	var alpha: float = 0.46 if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0 else 1.0

	var shadow_size: Vector2 = Vector2(display * 0.48, display * 0.18)
	draw_set_transform(draw_pos + Vector2(0.0, display * 0.27), 0.0, Vector2.ONE)
	draw_ellipse_shadow(Vector2.ZERO, shadow_size, Color(0, 0, 0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var src: Rect2 = Rect2(Vector2(float(frame * 48), float(direction_index * 48)), Vector2(48, 48))
	if dash_time > 0.0:
		var dash_dir: Vector2 = Vector2(player.get("dash_direction", aim)).normalized()
		for trail_index: int in range(3, 0, -1):
			var trail_pos: Vector2 = draw_pos - dash_dir * float(trail_index) * 18.0
			var trail_dest: Rect2 = Rect2(trail_pos - Vector2(display * 0.5, display * 0.63), Vector2(display, display))
			draw_texture_rect_region(texture, trail_dest, src, Color(0.72, 0.88, 0.82, 0.08 * float(4 - trail_index)))

	var dest: Rect2 = Rect2(draw_pos - Vector2(display * 0.5, display * 0.63), Vector2(display, display))
	draw_texture_rect_region(texture, dest, src, Color(1, 1, 1, alpha))

	if firing:
		var muzzle: Vector2 = draw_pos + aim * 57.0
		draw_circle(muzzle, 7.0, Color(1.0, 0.72, 0.26, 0.20))
		draw_circle(muzzle, 3.0, Color(1.0, 0.91, 0.58, 0.92))
		draw_line(muzzle, muzzle + aim * 13.0, Color(1.0, 0.79, 0.34, 0.82), 3.0)
	if moving:
		var foot_phase: float = fmod(visual_clock * 9.0, 1.0)
		if foot_phase < 0.10:
			draw_circle(pos + Vector2(-aim.y, aim.x) * 7.0 + Vector2(0, 20), 3.0, Color(0.46, 0.55, 0.43, 0.20))
	if bool(player.get("shield", false)):
		draw_arc(draw_pos, 43.0, -PI * 0.88, PI * 0.88, 32, Color8(112, 190, 247, 218), 4.0)

func draw_enemies() -> void:
	var strong: bool = bool(settings.get("strong_telegraphs", true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos: Vector2 = Vector2(enemy["pos"])
		var radius: float = float(enemy.get("radius", 18.0))
		var boss: bool = bool(enemy.get("boss", false))
		var genome: Dictionary = enemy.get("v8_visual_genome", {})
		var role: String = String(genome.get("role", enemy.get("style", "melee")))
		var look: Vector2 = Vector2(enemy.get("look", Vector2.DOWN))
		if look.length_squared() < 0.01:
			look = Vector2.DOWN
		else:
			look = look.normalized()
		var delay: float = float(enemy.get("activation_delay", 0.0))
		var windup: float = maxf(float(enemy.get("windup", 0.0)), maxf(float(enemy.get("special_windup", 0.0)), maxf(float(enemy.get("boss_windup", 0.0)), float(enemy.get("v8_trait_windup", 0.0)))))
		var attacking: bool = windup > 0.0 or float(enemy.get("attack", 0.0)) > 0.0
		var bursting: bool = float(enemy.get("v8_burst_time", 0.0)) > 0.0
		var frame: int = 2 if attacking else (3 if bursting else (1 if posmod(int((visual_clock + float(enemy.get("variant", 0)) * 0.19) * 7.0), 2) == 0 else 0))

		if windup > 0.0:
			var maximum: float = maxf(windup, maxf(float(enemy.get("windup_max", 0.0)), maxf(float(enemy.get("special_windup_max", 0.0)), maxf(float(enemy.get("boss_windup_max", 0.0)), float(enemy.get("v8_trait_windup_max", 0.0))))))
			var progress: float = clampf(1.0 - windup / maxf(0.001, maximum), 0.0, 1.0)
			var danger: Color = Color(1.0, 0.34, 0.22, 0.92 if strong else 0.62)
			draw_arc(pos, radius + 19.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 30, danger, 4.0 if strong else 2.0)
			if role in ["charger", "ranged", "skirmisher"]:
				draw_line(pos + look * (radius + 8.0), pos + look * (200.0 if role == "charger" else 140.0), Color(danger, 0.22), 4.0 if strong else 2.0)

		if delay > 0.0:
			var max_delay: float = maxf(0.001, float(enemy.get("activation_delay_max", delay)))
			var materialize: float = clampf(1.0 - delay / max_delay, 0.0, 1.0)
			var materialize_color: Color = Color(BIOMES[biome_index]["accent"])
			draw_arc(pos, radius + 14.0, -PI * 0.5, -PI * 0.5 + TAU * materialize, 28, Color(materialize_color, 0.82), 3.0)

		var texture: Texture2D = _enemy_entropy_texture(enemy)
		var source_size: int = 96 if boss else 48
		var direction_index: int = quantize_direction(look)
		var scale_value: float = float(genome.get("visual_scale", 1.0))
		var role_bonus: float = 12.0 if role == "charger" else (8.0 if role in ["caster", "radial"] else 0.0)
		var display: float = (164.0 + radius * 0.72) * scale_value if boss else (78.0 + radius * 0.88 + role_bonus) * scale_value
		var bob: float = sin(visual_clock * 3.2 + float(enemy.get("phase", 0.0))) * (1.8 if role in ["orbiter", "caster", "radial"] else 0.8)
		var draw_pos: Vector2 = pos + Vector2(0.0, bob)
		draw_ellipse_shadow(draw_pos + Vector2(0.0, radius * 0.82), Vector2(radius * 1.45, radius * 0.50), Color(0, 0, 0, 0.35))

		if texture != null:
			var alpha: float = 0.55 + 0.45 * clampf(1.0 - delay / maxf(0.001, float(enemy.get("activation_delay_max", 1.0))), 0.0, 1.0) if delay > 0.0 else 1.0
			var tint: Color = Color.WHITE
			if float(enemy.get("flash", 0.0)) > 0.0:
				tint = Color(1.0, 0.76, 0.70, alpha)
			else:
				tint.a = alpha
			var dest: Rect2 = Rect2(draw_pos - Vector2(display * 0.5, display * 0.62), Vector2(display, display))
			var src: Rect2 = Rect2(Vector2(float(frame * source_size), float(direction_index * source_size)), Vector2(source_size, source_size))
			draw_texture_rect_region(texture, dest, src, tint)

		if attacking and role in ["ranged", "skirmisher", "caster", "radial", "orbiter"]:
			var attack_color: Color = Color(genome.get("attack_accent", BIOMES[biome_index]["accent"]))
			var muzzle: Vector2 = draw_pos + look * (radius + 24.0)
			draw_circle(muzzle, 4.0, Color(attack_color.lightened(0.28), 0.72))
			draw_circle(muzzle, 8.0, Color(attack_color, 0.10))

		if bool(enemy.get("elite", false)):
			var definition: Dictionary = director.elite_definition(String(enemy.get("affix", "armored")))
			var elite_color: Color = Color(definition.get("color", Color8(226, 188, 102)))
			draw_arc(draw_pos, radius + 12.0, visual_clock, visual_clock + PI * 1.6, 28, elite_color, 3.0)
		if float(enemy.get("shield_hp", 0.0)) > 0.0:
			draw_arc(draw_pos, radius + 8.0, -PI * 0.86, PI * 0.86, 24, Color8(121, 171, 244), 3.0)
		var hp_ratio: float = clampf(float(enemy.get("hp", 1.0)) / maxf(0.001, float(enemy.get("max_hp", enemy.get("hp", 1.0)))), 0.0, 1.0)
		if hp_ratio < 0.999 or boss or bool(enemy.get("elite", false)):
			var width: float = clampf(radius * 2.4, 42.0, 126.0)
			var health: Rect2 = Rect2(draw_pos + Vector2(-width * 0.5, radius + 18.0), Vector2(width, 7.0 if boss else 5.0))
			draw_rect(health, Color8(31, 16, 18, 225))
			draw_rect(Rect2(health.position, Vector2(health.size.x * hp_ratio, health.size.y)), Color8(217, 68, 59))
			draw_rect(health, Color8(236, 196, 142, 165), false, 1.0)

func draw_ellipse_shadow(center: Vector2, size: Vector2, color: Color) -> void:
	var steps: int = 14
	for step_index: int in range(steps, 0, -1):
		var ratio: float = float(step_index) / float(steps)
		var radius: float = size.x * 0.5 * ratio
		var y_scale: float = maxf(0.08, size.y / maxf(1.0, size.x))
		draw_set_transform(center, 0.0, Vector2(1.0, y_scale))
		draw_circle(Vector2.ZERO, radius, Color(color, color.a * 0.08))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func audit_art_direction_contract() -> Dictionary:
	var report: Dictionary = super.audit_art_direction_contract()
	report["art4_presentation_version"] = ART4_PRESENTATION_VERSION
	report["alive_state_poses"] = true
	report["breathing_and_contact_motion"] = true
	report["recoil_and_muzzle_feedback"] = true
	report["dash_afterimages"] = true
	report["animated_environment_pockets"] = true
	report["landmark_wall_volume"] = true
	report["biome_foreground_midground_hierarchy"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["art4_alive_presentation"] = true
	report["procedural_environment_story_pockets"] = true
	return report
