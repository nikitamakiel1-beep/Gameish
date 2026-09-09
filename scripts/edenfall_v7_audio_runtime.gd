extends "res://scripts/edenfall_v7_fairness_runtime.gd"

const AUDIO_RUNTIME_VERSION := "0.6.1-rc7"

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var before := float(enemy.get("windup", 0.0))
	var velocity := super.update_enemy_style(enemy, direction, distance, delta)
	var after := float(enemy.get("windup", 0.0))
	if before <= 0.0 and after > 0.0:
		_play_warning_for_style(String(enemy.get("style", "ranged")))
	return velocity

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var before := float(enemy.get("boss_windup", 0.0))
	var velocity := super.update_boss(enemy, direction, distance, delta)
	var after := float(enemy.get("boss_windup", 0.0))
	if before <= 0.0 and after > 0.0:
		play_sfx("warning_phase", -5.0, 120)
	return velocity

func _update_enemy_specials(delta: float) -> void:
	var before: Dictionary = {}
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var uid := int(enemy.get("spawn_uid", -1))
		if uid >= 0:
			before[uid] = float(enemy.get("special_windup", 0.0))
	super._update_enemy_specials(delta)
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("boss", false)):
			continue
		var uid := int(enemy.get("spawn_uid", -1))
		var previous := float(before.get(uid, 0.0))
		var current := float(enemy.get("special_windup", 0.0))
		if previous <= 0.0 and current > 0.0:
			_play_warning_for_style(String(enemy.get("style", "radial")))

func _play_warning_for_style(style: String) -> void:
	match style:
		"charger", "melee":
			play_sfx("warning_melee", -7.0, 100)
		"ranged", "skirmisher":
			play_sfx("warning_aimed", -8.0, 100)
		_:
			play_sfx("warning_radial", -8.0, 120)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["audio_runtime_version"] = AUDIO_RUNTIME_VERSION
	report["semantic_warning_audio"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = AUDIO_RUNTIME_VERSION
	report["semantic_warning_audio"] = true
	report["aimed_warning_family"] = true
	report["radial_warning_family"] = true
	report["phase_warning_family"] = true
	return report
