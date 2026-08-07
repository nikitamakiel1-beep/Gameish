extends RefCounted

const VERSION := 7

const ROLE_BY_ENEMY := {
	"feral_scavenger":"pressure",
	"outlaw_gunner":"ranged",
	"raider_brute":"charger",
	"wasteland_hunter":"ranged",
	"scrap_cultist":"caster",
	"caravan_outlaw":"skirmisher",
	"cherub_drone":"orbiter",
	"fallen_angel":"skirmisher",
	"watcher_acolyte":"caster",
	"halo_sentinel":"charger",
	"biomech_pilgrim":"ranged",
	"ophanim_scout":"orbiter",
	"nephilim_husk":"pressure",
	"nephilim_giant":"charger",
	"horned_berserker":"skirmisher",
	"bone_shepherd":"caster",
	"grafted_colossus":"radial",
	"serpent_spawn":"orbiter",
}

const SIGNATURES := {
	"pressure": {"name":"PRESSURE PACK", "roles":["pressure","charger","pressure","ranged"], "formation":"pincer"},
	"crossfire": {"name":"CROSSFIRE CELL", "roles":["ranged","skirmisher","ranged","pressure"], "formation":"crossfire"},
	"anchor": {"name":"ANCHOR & ESCORT", "roles":["radial","caster","pressure","ranged"], "formation":"anchor"},
	"orbit": {"name":"ORBITAL HUNT", "roles":["orbiter","skirmisher","orbiter","pressure"], "formation":"orbit"},
	"ritual": {"name":"RITUAL BATTERY", "roles":["caster","pressure","ranged","charger"], "formation":"diamond"},
	"mixed": {"name":"MIXED HOST CELL", "roles":["pressure","ranged","skirmisher","caster"], "formation":"ring"},
}

func compose(pool: Array, count: int, seed_value: int, room_kind: String, modifier: String) -> Dictionary:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed_value
	var available_signatures: Array[String] = ["pressure", "crossfire", "mixed"]
	if _pool_has_role(pool, "caster"):
		available_signatures.append("ritual")
	if _pool_has_role(pool, "orbiter"):
		available_signatures.append("orbit")
	if _pool_has_role(pool, "radial"):
		available_signatures.append("anchor")
	if room_kind in ["trial", "contract"]:
		available_signatures.erase("mixed")
	if modifier == "bullet_storm" and "crossfire" in available_signatures:
		available_signatures.erase("crossfire")
	if available_signatures.is_empty():
		available_signatures.append("mixed")
	var signature_id := available_signatures[local_rng.randi_range(0, available_signatures.size() - 1)]
	var definition: Dictionary = SIGNATURES[signature_id]
	var requested_roles: Array = definition.get("roles", [])
	var ids: Array[String] = []
	var role_counts: Dictionary = {}
	for index in range(maxi(1, count)):
		var requested := String(requested_roles[index % requested_roles.size()]) if not requested_roles.is_empty() else "pressure"
		var id := _choose_for_role(pool, requested, role_counts, local_rng)
		if id.is_empty():
			id = String(pool[local_rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else "feral_scavenger"
		ids.append(id)
		var role := String(ROLE_BY_ENEMY.get(id, "pressure"))
		role_counts[role] = int(role_counts.get(role, 0)) + 1
	return {
		"id": signature_id,
		"name": String(definition.get("name", signature_id.to_upper())),
		"formation": String(definition.get("formation", "ring")),
		"ids": ids,
		"role_counts": role_counts,
	}

func positions(arena: Rect2, count: int, formation: String, seed_value: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 0:
		return result
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = seed_value
	var safe := arena.grow(-82.0)
	var center := safe.get_center()
	var radius_x := maxf(105.0, safe.size.x * 0.34)
	var radius_y := maxf(78.0, safe.size.y * 0.31)
	var phase := local_rng.randf_range(0.0, TAU)
	for index in range(count):
		var point := center
		match formation:
			"pincer":
				var side := -1.0 if index % 2 == 0 else 1.0
				var row := float(index / 2)
				point = center + Vector2(side * radius_x * (0.72 + row * 0.08), (row - float(count) * 0.12) * 62.0)
			"crossfire":
				var quadrant := index % 4
				var spread := 0.72 + float(index / 4) * 0.12
				match quadrant:
					0: point = center + Vector2(-radius_x * spread, -radius_y * 0.42)
					1: point = center + Vector2(radius_x * spread, radius_y * 0.42)
					2: point = center + Vector2(-radius_x * 0.35, radius_y * spread)
					_: point = center + Vector2(radius_x * 0.35, -radius_y * spread)
			"anchor":
				if index == 0:
					point = center + Vector2(0, -radius_y * 0.35)
				else:
					var angle := phase + TAU * float(index - 1) / float(maxi(1, count - 1))
					point = center + Vector2(cos(angle) * radius_x * 0.86, sin(angle) * radius_y * 0.86)
			"orbit":
				var angle := phase + TAU * float(index) / float(count)
				var ring := 0.66 if index % 2 == 0 else 0.94
				point = center + Vector2(cos(angle) * radius_x * ring, sin(angle) * radius_y * ring)
			"diamond":
				var directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
				var direction: Vector2 = directions[index % 4]
				var ring := 0.60 + float(index / 4) * 0.18
				point = center + Vector2(direction.x * radius_x * ring, direction.y * radius_y * ring)
			_:
				var angle := phase + TAU * float(index) / float(count)
				var ring := 0.72 + float(index % 3) * 0.10
				point = center + Vector2(cos(angle) * radius_x * ring, sin(angle) * radius_y * ring)
		point += Vector2(local_rng.randf_range(-12.0, 12.0), local_rng.randf_range(-10.0, 10.0))
		point.x = clampf(point.x, safe.position.x, safe.end.x)
		point.y = clampf(point.y, safe.position.y, safe.end.y)
		result.append(point)
	return result

func _choose_for_role(pool: Array, requested_role: String, role_counts: Dictionary, local_rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = []
	for value in pool:
		var id := String(value)
		var role := String(ROLE_BY_ENEMY.get(id, "pressure"))
		if role != requested_role:
			continue
		if role in ["caster", "radial"] and int(role_counts.get(role, 0)) >= 2:
			continue
		candidates.append(id)
	if candidates.is_empty():
		for value in pool:
			var id := String(value)
			var role := String(ROLE_BY_ENEMY.get(id, "pressure"))
			if role in ["caster", "radial"] and int(role_counts.get(role, 0)) >= 2:
				continue
			candidates.append(id)
	if candidates.is_empty():
		return ""
	return candidates[local_rng.randi_range(0, candidates.size() - 1)]

func _pool_has_role(pool: Array, role: String) -> bool:
	for value in pool:
		if String(ROLE_BY_ENEMY.get(String(value), "pressure")) == role:
			return true
	return false

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"enemy_roles": ROLE_BY_ENEMY.size(),
		"signatures": SIGNATURES.size(),
		"formations": 6,
		"role_caps": true,
		"deterministic": true,
	}
