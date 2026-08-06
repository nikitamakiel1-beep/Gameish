extends RefCounted

const PROFILES := {
	"desktop": {
		"target_fps": 120,
		"max_bullets": 900,
		"max_effects": 320,
		"max_damage_numbers": 180,
		"max_pickups": 80,
		"trim_interval": 8.0,
	},
	"web": {
		"target_fps": 60,
		"max_bullets": 560,
		"max_effects": 200,
		"max_damage_numbers": 120,
		"max_pickups": 60,
		"trim_interval": 6.0,
	},
	"mobile": {
		"target_fps": 60,
		"max_bullets": 420,
		"max_effects": 150,
		"max_damage_numbers": 90,
		"max_pickups": 48,
		"trim_interval": 4.0,
	},
}

var profile_name := "desktop"
var profile: Dictionary = PROFILES["desktop"].duplicate(true)
var dropped_enemy_bullets := 0
var recycled_enemy_bullets := 0
var dropped_effects := 0
var trimmed_damage_numbers := 0
var trimmed_pickups := 0

func configure() -> Dictionary:
	profile_name = "mobile" if OS.has_feature("mobile") else ("web" if OS.has_feature("web") else "desktop")
	profile = Dictionary(PROFILES[profile_name]).duplicate(true)
	if profile_name != "desktop":
		Engine.max_fps = int(profile["target_fps"])
	return report()

func admit_bullet(bullets: Array, owner: String) -> bool:
	var maximum := int(profile["max_bullets"])
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
	var maximum := int(profile["max_effects"])
	if effects.size() < maximum:
		return true
	var victim := _shortest_lived_entry(effects)
	if victim >= 0:
		effects.remove_at(victim)
		dropped_effects += 1
		return true
	return false

func enforce_post_frame(damage_numbers: Array, pickups: Array) -> void:
	var damage_limit := int(profile["max_damage_numbers"])
	while damage_numbers.size() > damage_limit:
		damage_numbers.remove_at(0)
		trimmed_damage_numbers += 1
	var pickup_limit := int(profile["max_pickups"])
	while pickups.size() > pickup_limit:
		pickups.remove_at(0)
		trimmed_pickups += 1

func trim_interval() -> float:
	return float(profile["trim_interval"])

func report() -> Dictionary:
	return {
		"profile": profile_name,
		"limits": profile.duplicate(true),
		"dropped_enemy_bullets": dropped_enemy_bullets,
		"recycled_enemy_bullets": recycled_enemy_bullets,
		"dropped_effects": dropped_effects,
		"trimmed_damage_numbers": trimmed_damage_numbers,
		"trimmed_pickups": trimmed_pickups,
	}

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
