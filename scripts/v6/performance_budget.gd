extends RefCounted

const PROFILES := {
	"desktop": {
		"target_fps": 120,
		"adaptive_target_fps": 60,
		"min_scale": 0.80,
		"max_bullets": 900,
		"max_effects": 320,
		"max_damage_numbers": 180,
		"max_pickups": 80,
		"trim_interval": 8.0,
	},
	"web": {
		"target_fps": 60,
		"adaptive_target_fps": 60,
		"min_scale": 0.62,
		"max_bullets": 560,
		"max_effects": 200,
		"max_damage_numbers": 120,
		"max_pickups": 60,
		"trim_interval": 6.0,
	},
	"mobile": {
		"target_fps": 60,
		"adaptive_target_fps": 60,
		"min_scale": 0.55,
		"max_bullets": 420,
		"max_effects": 150,
		"max_damage_numbers": 90,
		"max_pickups": 48,
		"trim_interval": 4.0,
	},
}
const MINIMUM_LIMITS := {
	"max_bullets": 240,
	"max_effects": 80,
	"max_damage_numbers": 50,
	"max_pickups": 32,
}
const EMA_ALPHA := 0.08
const PRESSURE_THRESHOLD := 1.18
const RECOVERY_THRESHOLD := 0.88
const PRESSURE_SAMPLES := 24
const RECOVERY_SAMPLES := 180
const SCALE_DOWN_STEP := 0.08
const SCALE_UP_STEP := 0.04

var profile_name := "desktop"
var profile: Dictionary = PROFILES["desktop"].duplicate(true)
var adaptive_scale := 1.0
var ema_frame_ms := 0.0
var observed_frames := 0
var pressure_streak := 0
var recovery_streak := 0
var quality_reductions := 0
var quality_recoveries := 0
var dropped_enemy_bullets := 0
var recycled_enemy_bullets := 0
var dropped_effects := 0
var trimmed_damage_numbers := 0
var trimmed_pickups := 0
var _last_post_frame_usec := 0

func configure() -> Dictionary:
	profile_name = "mobile" if OS.has_feature("mobile") else ("web" if OS.has_feature("web") else "desktop")
	profile = Dictionary(PROFILES[profile_name]).duplicate(true)
	adaptive_scale = 1.0
	ema_frame_ms = 0.0
	observed_frames = 0
	pressure_streak = 0
	recovery_streak = 0
	quality_reductions = 0
	quality_recoveries = 0
	_last_post_frame_usec = 0
	if profile_name != "desktop":
		Engine.max_fps = int(profile["target_fps"])
	return report()

func observe_frame(delta: float, active_gameplay: bool = true) -> void:
	if not active_gameplay or delta <= 0.0 or delta > 0.25:
		return
	var frame_ms := delta * 1000.0
	var target_ms := 1000.0 / maxf(1.0, float(profile.get("adaptive_target_fps", 60)))
	ema_frame_ms = frame_ms if ema_frame_ms <= 0.0 else lerpf(ema_frame_ms, frame_ms, EMA_ALPHA)
	observed_frames += 1
	if ema_frame_ms > target_ms * PRESSURE_THRESHOLD:
		pressure_streak += 1
		recovery_streak = maxi(0, recovery_streak - 2)
	elif ema_frame_ms < target_ms * RECOVERY_THRESHOLD:
		recovery_streak += 1
		pressure_streak = maxi(0, pressure_streak - 1)
	else:
		pressure_streak = maxi(0, pressure_streak - 1)
		recovery_streak = maxi(0, recovery_streak - 1)

	if pressure_streak >= PRESSURE_SAMPLES:
		var previous := adaptive_scale
		adaptive_scale = maxf(float(profile.get("min_scale", 0.6)), adaptive_scale - SCALE_DOWN_STEP)
		if adaptive_scale < previous:
			quality_reductions += 1
		pressure_streak = 0
	elif recovery_streak >= RECOVERY_SAMPLES:
		var previous := adaptive_scale
		adaptive_scale = minf(1.0, adaptive_scale + SCALE_UP_STEP)
		if adaptive_scale > previous:
			quality_recoveries += 1
		recovery_streak = 0

func effective_limit(key: String) -> int:
	var base := int(profile.get(key, 0))
	var floor_value := int(MINIMUM_LIMITS.get(key, 1))
	return mini(base, maxi(floor_value, int(floor(float(base) * adaptive_scale))))

func admit_bullet(bullets: Array, owner: String) -> bool:
	var maximum := effective_limit("max_bullets")
	if bullets.size() < maximum:
		return true
	if owner != "player":
		dropped_enemy_bullets += 1
		return false
	var victim := _oldest_enemy_bullet(bullets)
	if victim < 0:
		return false
	bullets.remove_at(victim)
	recycled_enemy_bullets += 1
	return true

func admit_effect(effects: Array) -> bool:
	var maximum := effective_limit("max_effects")
	if effects.size() < maximum:
		return true
	var victim := _shortest_lived_entry(effects)
	if victim >= 0:
		effects.remove_at(victim)
		dropped_effects += 1
		return true
	return false

func enforce_post_frame(damage_numbers: Array, pickups: Array) -> void:
	var now_usec := Time.get_ticks_usec()
	if _last_post_frame_usec > 0:
		observe_frame(float(now_usec - _last_post_frame_usec) / 1000000.0, true)
	_last_post_frame_usec = now_usec
	var damage_limit := effective_limit("max_damage_numbers")
	while damage_numbers.size() > damage_limit:
		damage_numbers.remove_at(0)
		trimmed_damage_numbers += 1
	var pickup_limit := effective_limit("max_pickups")
	while pickups.size() > pickup_limit:
		pickups.remove_at(0)
		trimmed_pickups += 1

func trim_interval() -> float:
	return float(profile["trim_interval"])

func report() -> Dictionary:
	return {
		"profile": profile_name,
		"limits": profile.duplicate(true),
		"effective_limits": {
			"max_bullets": effective_limit("max_bullets"),
			"max_effects": effective_limit("max_effects"),
			"max_damage_numbers": effective_limit("max_damage_numbers"),
			"max_pickups": effective_limit("max_pickups"),
		},
		"adaptive_scale": adaptive_scale,
		"ema_frame_ms": ema_frame_ms,
		"observed_frames": observed_frames,
		"quality_tier": _quality_tier(),
		"quality_reductions": quality_reductions,
		"quality_recoveries": quality_recoveries,
		"dropped_enemy_bullets": dropped_enemy_bullets,
		"recycled_enemy_bullets": recycled_enemy_bullets,
		"dropped_effects": dropped_effects,
		"trimmed_damage_numbers": trimmed_damage_numbers,
		"trimmed_pickups": trimmed_pickups,
	}

func audit_contract() -> Dictionary:
	return {
		"frame_time_feedback": true,
		"post_frame_auto_observation": true,
		"ema_smoothing": true,
		"hysteresis": true,
		"bounded_quality_floor": true,
		"player_bullet_priority": true,
		"platform_profiles": PROFILES.size(),
	}

func _quality_tier() -> String:
	if adaptive_scale >= 0.92:
		return "full"
	if adaptive_scale >= 0.76:
		return "balanced"
	return "protected"

func _oldest_enemy_bullet(bullets: Array) -> int:
	var victim := -1
	var shortest_life := INF
	for index in range(bullets.size()):
		var bullet: Dictionary = bullets[index]
		if String(bullet.get("owner", "enemy")) == "player":
			continue
		var life := float(bullet.get("life", 0.0))
		if life < shortest_life:
			shortest_life = life
			victim = index
	return victim

func _shortest_lived_entry(entries: Array) -> int:
	var victim := -1
	var shortest_life := INF
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var life := float(entry.get("life", 0.0))
		if life < shortest_life:
			shortest_life = life
			victim = index
	return victim
