extends "res://scripts/edenfall_v6.gd"

const PerformanceBudgetScript: Script = preload("res://scripts/v6/performance_budget.gd")

var performance_budget: RefCounted = PerformanceBudgetScript.new()
var performance_profile: Dictionary = {}
var _asset_trim_clock := 0.0

func _ready() -> void:
	performance_profile = performance_budget.call("configure")
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	performance_budget.call("enforce_post_frame", damage_numbers, pickups)
	_asset_trim_clock += delta
	if _asset_trim_clock >= float(performance_budget.call("trim_interval")):
		_asset_trim_clock = 0.0
		_trim_runtime_assets()

func spawn_bullet(
	position: Vector2,
	velocity: Vector2,
	damage: float,
	owner: String,
	radius: float,
	color: Color,
	pierce: int,
	critical: bool
) -> void:
	if not bool(performance_budget.call("admit_bullet", bullets, owner)):
		return
	super.spawn_bullet(position, velocity, damage, owner, radius, color, pierce, critical)

func spawn_effect(id: String, position: Vector2, color: Color, angle: float) -> void:
	if not bool(performance_budget.call("admit_effect", effects)):
		return
	super.spawn_effect(id, position, color, angle)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["performance_budget"] = performance_budget.call("report")
	report["asset_cache"] = production_assets.call("cache_report")
	return report

func _trim_runtime_assets() -> void:
	if biome_index < 0 or biome_index >= BIOMES.size():
		return
	var active_enemy_ids: Array = []
	for enemy in enemies:
		var enemy_id := String(enemy.get("id", ""))
		if not enemy_id.is_empty() and enemy_id not in active_enemy_ids:
			active_enemy_ids.append(enemy_id)
	var active_boss := ""
	if biome_index < BOSS_IDS.size():
		active_boss = String(BOSS_IDS[biome_index])
	production_assets.call(
		"trim_runtime_cache",
		String(BIOMES[biome_index]["id"]),
		active_enemy_ids,
		active_boss
	)
