extends "res://scripts/game_runtime.gd"

func _active_weapon_index() -> int:
	var lineage_index: int = clampi(selected_lineage, 0, 4)
	var upgraded: bool = rooms_cleared >= 4 or int(player.get("inventory", []).size()) >= 2
	return lineage_index * 2 + (1 if upgraded else 0)

func _weapon_frame() -> int:
	if player_shoot_timer <= 0.0:
		return 0
	var progress: float = clampf(1.0 - player_shoot_timer / 0.13, 0.0, 1.0)
	return clampi(int(floor(progress * 8.0)), 0, 7)

func _draw_active_weapon(position: Vector2, aim: Vector2, scale: float = 1.0) -> void:
	var weapon_texture: Texture2D = asset_catalog.weapon(_active_weapon_index())
	if weapon_texture == null:
		return
	var direction: Vector2 = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	var frame: int = _weapon_frame()
	var source := Rect2(Vector2(float(frame) * 32.0, 0.0), Vector2(32.0, 32.0))
	var weapon_position := position + direction * 13.0
	draw_set_transform(weapon_position, direction.angle(), Vector2.ONE * scale)
	draw_texture_rect_region(weapon_texture, Rect2(Vector2(-10.0, -16.0), Vector2(32.0, 32.0)), source, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_player() -> void:
	super.draw_player()
	if state != "run" or player.is_empty():
		return
	var aim: Vector2 = player.get("aim", Vector2.RIGHT)
	_draw_active_weapon(player["pos"], aim, 1.12)

func draw_lineage_select() -> void:
	super.draw_lineage_select()
	if not asset_catalog.available():
		return
	for index in range(lineages.size()):
		var weapon_texture: Texture2D = asset_catalog.weapon(index * 2)
		if weapon_texture == null:
			continue
		var rect: Rect2 = lineage_card_rect(index)
		var source := Rect2(Vector2.ZERO, Vector2(32.0, 32.0))
		var destination := Rect2(Vector2(rect.get_center().x - 24.0, rect.position.y + 99.0), Vector2(48.0, 48.0))
		draw_texture_rect_region(weapon_texture, destination, source, Color.WHITE)

func fire_player_weapon() -> void:
	var first_new_bullet: int = bullets.size()
	super.fire_player_weapon()
	for index in range(first_new_bullet, bullets.size()):
		if bool(bullets[index].get("critical", false)):
			_sfx("critical", randf_range(0.97, 1.06), -1.0, 70)
			break

func update_pickups(delta: float) -> void:
	var count_before: int = pickups.size()
	var hp_before: float = float(player.get("hp", 0.0)) if not player.is_empty() else 0.0
	var scraps_before: int = scraps
	var inventory_before: int = int(player.get("inventory", []).size()) if not player.is_empty() else 0
	super.update_pickups(delta)
	if pickups.size() >= count_before:
		return
	var hp_after: float = float(player.get("hp", hp_before))
	var inventory_after: int = int(player.get("inventory", []).size())
	if hp_after > hp_before:
		_sfx("heal", 1.0 + minf(0.12, (hp_after - hp_before) * 0.03), -1.0, 90)
	elif scraps > scraps_before:
		_sfx("pickup", randf_range(0.97, 1.05), -3.0, 65)
	elif inventory_after == inventory_before:
		_sfx("pickup", 1.1, -4.0, 65)
