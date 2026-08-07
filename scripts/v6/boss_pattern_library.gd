extends RefCounted

const VERSION := 6

func build_pattern(boss_id: String, stage: int, pattern_index: int, target_direction: Vector2, phase: float) -> Dictionary:
	var direction := target_direction.normalized() if target_direction.length_squared() > 0.001 else Vector2.DOWN
	match boss_id:
		"first_nephilim":
			return _first_nephilim(stage, pattern_index, direction, phase)
		"gate_cherub":
			return _gate_cherub(stage, pattern_index, direction, phase)
		"tower_enoch":
			return _tower_enoch(stage, pattern_index, direction, phase)
		"serpent_interface":
			return _serpent_interface(stage, pattern_index, direction, phase)
		_:
			return _watcher_engine(stage, pattern_index, direction, phase)

func _watcher_engine(stage: int, pattern_index: int, direction: Vector2, phase: float) -> Dictionary:
	var shots: Array = []
	match posmod(pattern_index, 3):
		0:
			var count := 12 + stage * 4
			for index in range(count):
				shots.append(_shot(Vector2.RIGHT.rotated(TAU * float(index) / float(count) + phase * 0.12), 245.0 + stage * 28.0, 1.0))
			return _result(shots, 0.58, 1.18 - stage * 0.08, 0.48)
		1:
			for angle in [-0.34, -0.17, 0.0, 0.17, 0.34]:
				shots.append(_shot(direction.rotated(angle), 405.0 + stage * 32.0, 1.0))
			return _result(shots, 0.44, 0.94, 0.62)
		_:
			for spoke in range(8):
				var spoke_direction := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0 + phase * 0.22)
				shots.append(_shot(spoke_direction, 292.0, 1.0))
				shots.append(_shot(spoke_direction.rotated(0.08), 220.0, 1.0))
			return _result(shots, 0.66, 1.26, 0.38)

func _first_nephilim(stage: int, pattern_index: int, direction: Vector2, phase: float) -> Dictionary:
	var shots: Array = []
	match posmod(pattern_index, 3):
		0:
			var result := _result(shots, 0.72, 1.34, 0.08)
			result["charge_duration"] = 0.34 + float(stage) * 0.05
			result["charge_multiplier"] = 4.1 + float(stage) * 0.45
			return result
		1:
			var count := 14 + stage * 4
			for index in range(count):
				shots.append(_shot(Vector2.RIGHT.rotated(TAU * float(index) / float(count) + phase * 0.06), 258.0 + stage * 24.0, 1.0))
			return _result(shots, 0.62, 1.20, 0.34)
		_:
			for angle in [-0.42, -0.21, 0.0, 0.21, 0.42]:
				shots.append(_shot(direction.rotated(angle), 430.0 + stage * 34.0, 1.0))
			return _result(shots, 0.52, 1.04, 0.56)

func _gate_cherub(stage: int, pattern_index: int, direction: Vector2, phase: float) -> Dictionary:
	var shots: Array = []
	match posmod(pattern_index, 3):
		0:
			for side in [-1.0, 1.0]:
				for step in range(5 + stage):
					var angle := side * (0.13 + float(step) * 0.12)
					shots.append(_shot(direction.rotated(angle), 330.0 + float(step) * 12.0, 1.0))
			return _result(shots, 0.56, 1.08, 0.48)
		1:
			for axis in range(4):
				var base := Vector2.RIGHT.rotated(PI * 0.5 * float(axis) + phase * 0.08)
				shots.append(_shot(base, 315.0, 1.0))
				shots.append(_shot(base.rotated(0.12), 265.0, 1.0))
				shots.append(_shot(base.rotated(-0.12), 265.0, 1.0))
			return _result(shots, 0.60, 1.18, 0.28)
		_:
			var count := 10 + stage * 2
			for index in range(count):
				shots.append(_shot(Vector2.RIGHT.rotated(TAU * float(index) / float(count) - phase * 0.14), 280.0, 1.0))
			var result := _result(shots, 0.70, 1.32, 0.22)
			result["shield_ratio"] = 0.055 + float(stage) * 0.018
			return result

func _tower_enoch(stage: int, pattern_index: int, direction: Vector2, phase: float) -> Dictionary:
	var shots: Array = []
	match posmod(pattern_index, 3):
		0:
			for axis in range(8):
				var base := Vector2.RIGHT.rotated(TAU * float(axis) / 8.0)
				shots.append(_shot(base, 305.0 + float(stage) * 18.0, 1.0))
				shots.append(_shot(base.rotated(0.07), 235.0, 1.0))
			return _result(shots, 0.64, 1.12, 0.12)
		1:
			var count := 12 + stage * 4
			for index in range(count):
				var angle := TAU * float(index) / float(count) + phase * 0.28
				shots.append(_shot(Vector2.RIGHT.rotated(angle), 250.0 + float(index % 3) * 28.0, 1.0))
			return _result(shots, 0.52, 1.02, 0.22)
		_:
			for angle in [-0.48, -0.24, 0.0, 0.24, 0.48]:
				shots.append(_shot(direction.rotated(angle), 390.0, 1.0))
			var result := _result(shots, 0.78, 1.42, 0.06)
			result["summon_id"] = "cherub_drone"
			result["summon_count"] = 1 + stage
			return result

func _serpent_interface(stage: int, pattern_index: int, direction: Vector2, phase: float) -> Dictionary:
	var shots: Array = []
	match posmod(pattern_index, 3):
		0:
			var count := 16 + stage * 4
			for index in range(count):
				var spin := TAU * float(index) / float(count) + phase * 0.34
				var speed := 220.0 + float(index % 4) * 36.0
				shots.append(_shot(Vector2.RIGHT.rotated(spin), speed, 1.0))
			return _result(shots, 0.60, 1.02, 0.26)
		1:
			for angle in [-0.56, -0.28, 0.0, 0.28, 0.56]:
				shots.append(_shot(direction.rotated(angle), 420.0, 1.0))
				shots.append(_shot((-direction).rotated(angle * 0.72), 300.0, 1.0))
			return _result(shots, 0.46, 0.92, 0.42)
		_:
			var count := 12 + stage * 2
			for index in range(count):
				var angle := TAU * float(index) / float(count) - phase * 0.26
				shots.append(_shot(Vector2.RIGHT.rotated(angle), 275.0, 1.0))
			var result := _result(shots, 0.76, 1.30, 0.18)
			result["summon_id"] = "serpent_spawn"
			result["summon_count"] = 1 + stage
			return result

func _result(shots: Array, windup: float, cooldown: float, move_scale: float) -> Dictionary:
	return {
		"shots": shots,
		"windup": windup,
		"cooldown": cooldown,
		"move_scale": move_scale,
		"charge_duration": 0.0,
		"charge_multiplier": 0.0,
		"summon_id": "",
		"summon_count": 0,
		"shield_ratio": 0.0,
	}

func _shot(direction: Vector2, speed: float, damage: float) -> Dictionary:
	return {"direction": direction.normalized(), "speed": speed, "damage": damage}

func audit_contract() -> Dictionary:
	var ids := ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
	var patterns := 0
	for id in ids:
		for index in range(3):
			var result := build_pattern(id, 1, index, Vector2.DOWN, 0.5)
			if result.has("shots") and result.has("windup") and result.has("cooldown"):
				patterns += 1
	return {"version":VERSION, "bosses":ids.size(), "patterns":patterns}
