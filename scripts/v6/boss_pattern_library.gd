extends RefCounted

const VERSION := 8
const BOSS_IDS := [
	"watcher_engine",
	"first_nephilim",
	"gate_cherub",
	"tower_enoch",
	"serpent_interface",
]

func build_pattern(boss_id: String, stage: int, pattern_index: int, target_direction: Vector2, phase: float) -> Dictionary:
	var direction := target_direction
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	else:
		direction = direction.normalized()
	var pattern := posmod(pattern_index, 3)
	if boss_id == "first_nephilim":
		return _first_nephilim(stage, pattern, direction, phase)
	if boss_id == "gate_cherub":
		return _gate_cherub(stage, pattern, direction, phase)
	if boss_id == "tower_enoch":
		return _tower_enoch(stage, pattern, direction, phase)
	if boss_id == "serpent_interface":
		return _serpent_interface(stage, pattern, direction, phase)
	return _watcher_engine(stage, pattern, direction, phase)

func _watcher_engine(stage: int, pattern: int, direction: Vector2, phase: float) -> Dictionary:
	if pattern == 0:
		return _result(_radial_shots(12 + stage * 4, 245.0 + stage * 28.0, phase * 0.12), 0.58, maxf(0.72, 1.18 - stage * 0.08), 0.48)
	if pattern == 1:
		return _result(_fan_shots(direction, [-0.34, -0.17, 0.0, 0.17, 0.34], 405.0 + stage * 32.0), 0.44, 0.94, 0.62)
	var shots: Array = []
	for spoke in range(8):
		var spoke_direction := Vector2.RIGHT.rotated(TAU * float(spoke) / 8.0 + phase * 0.22)
		shots.append(_shot(spoke_direction, 292.0, 1.0))
		shots.append(_shot(spoke_direction.rotated(0.08), 220.0, 1.0))
	return _result(shots, 0.66, 1.26, 0.38)

func _first_nephilim(stage: int, pattern: int, direction: Vector2, phase: float) -> Dictionary:
	if pattern == 0:
		var charge_result := _result([], 0.72, 1.34, 0.08)
		charge_result["charge_duration"] = 0.34 + float(stage) * 0.05
		charge_result["charge_multiplier"] = 4.1 + float(stage) * 0.45
		return charge_result
	if pattern == 1:
		return _result(_radial_shots(14 + stage * 4, 258.0 + stage * 24.0, phase * 0.06), 0.62, 1.20, 0.34)
	return _result(_fan_shots(direction, [-0.42, -0.21, 0.0, 0.21, 0.42], 430.0 + stage * 34.0), 0.52, 1.04, 0.56)

func _gate_cherub(stage: int, pattern: int, direction: Vector2, phase: float) -> Dictionary:
	if pattern == 0:
		var fan: Array = []
		for side in [-1.0, 1.0]:
			for step in range(5 + stage):
				var angle := side * (0.13 + float(step) * 0.12)
				fan.append(_shot(direction.rotated(angle), 330.0 + float(step) * 12.0, 1.0))
		return _result(fan, 0.56, 1.08, 0.48)
	if pattern == 1:
		var axes: Array = []
		for axis in range(4):
			var base := Vector2.RIGHT.rotated(PI * 0.5 * float(axis) + phase * 0.08)
			axes.append(_shot(base, 315.0, 1.0))
			axes.append(_shot(base.rotated(0.12), 265.0, 1.0))
			axes.append(_shot(base.rotated(-0.12), 265.0, 1.0))
		return _result(axes, 0.60, 1.18, 0.28)
	var shield_result := _result(_radial_shots(10 + stage * 2, 280.0, -phase * 0.14), 0.70, 1.32, 0.22)
	shield_result["shield_ratio"] = 0.055 + float(stage) * 0.018
	return shield_result

func _tower_enoch(stage: int, pattern: int, direction: Vector2, phase: float) -> Dictionary:
	if pattern == 0:
		var crossfire: Array = []
		for axis in range(8):
			var base := Vector2.RIGHT.rotated(TAU * float(axis) / 8.0)
			crossfire.append(_shot(base, 305.0 + float(stage) * 18.0, 1.0))
			crossfire.append(_shot(base.rotated(0.07), 235.0, 1.0))
		return _result(crossfire, 0.64, 1.12, 0.12)
	if pattern == 1:
		var spiral: Array = []
		var count := 12 + stage * 4
		for index in range(count):
			var angle := TAU * float(index) / float(count) + phase * 0.28
			spiral.append(_shot(Vector2.RIGHT.rotated(angle), 250.0 + float(index % 3) * 28.0, 1.0))
		return _result(spiral, 0.52, 1.02, 0.22)
	var summon_result := _result(_fan_shots(direction, [-0.48, -0.24, 0.0, 0.24, 0.48], 390.0), 0.78, 1.42, 0.06)
	summon_result["summon_id"] = "cherub_drone"
	summon_result["summon_count"] = 1 + stage
	return summon_result

func _serpent_interface(stage: int, pattern: int, direction: Vector2, phase: float) -> Dictionary:
	if pattern == 0:
		var spiral: Array = []
		var count := 16 + stage * 4
		for index in range(count):
			var spin := TAU * float(index) / float(count) + phase * 0.34
			var speed := 220.0 + float(index % 4) * 36.0
			spiral.append(_shot(Vector2.RIGHT.rotated(spin), speed, 1.0))
		return _result(spiral, 0.60, 1.02, 0.26)
	if pattern == 1:
		var forked: Array = []
		for angle in [-0.56, -0.28, 0.0, 0.28, 0.56]:
			forked.append(_shot(direction.rotated(angle), 420.0, 1.0))
			forked.append(_shot((-direction).rotated(angle * 0.72), 300.0, 1.0))
		return _result(forked, 0.46, 0.92, 0.42)
	var host_result := _result(_radial_shots(12 + stage * 2, 275.0, -phase * 0.26), 0.76, 1.30, 0.18)
	host_result["summon_id"] = "serpent_spawn"
	host_result["summon_count"] = 1 + stage
	return host_result

func _radial_shots(count: int, speed: float, phase: float) -> Array:
	var shots: Array = []
	for index in range(maxi(1, count)):
		var angle := TAU * float(index) / float(maxi(1, count)) + phase
		shots.append(_shot(Vector2.RIGHT.rotated(angle), speed, 1.0))
	return shots

func _fan_shots(direction: Vector2, angles: Array, speed: float) -> Array:
	var shots: Array = []
	for angle_variant in angles:
		shots.append(_shot(direction.rotated(float(angle_variant)), speed, 1.0))
	return shots

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
	var normalized := direction
	if normalized.length_squared() <= 0.001:
		normalized = Vector2.DOWN
	else:
		normalized = normalized.normalized()
	return {"direction": normalized, "speed": speed, "damage": damage}

func audit_contract() -> Dictionary:
	var patterns := 0
	for boss_id_variant in BOSS_IDS:
		var boss_id := String(boss_id_variant)
		for pattern in range(3):
			var built := build_pattern(boss_id, 1, pattern, Vector2.DOWN, 0.5)
			if built.has("shots") and built.has("windup") and built.has("cooldown"):
				patterns += 1
	return {"version": VERSION, "bosses": BOSS_IDS.size(), "patterns": patterns}
