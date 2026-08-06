extends RefCounted

const VERSION := "0.6.0"
const FactoryScript: Script = preload("res://scripts/v6/generated_asset_factory.gd")
const HERO_IDS := ["adam", "abel", "cain", "seth", "naamah"]
const ENEMY_IDS := [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const BOSS_IDS := ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]
const BIOME_IDS := ["industrial_eden", "ash_wastes", "temple_lab", "fungal_garden", "nephilim_ruins"]
const UTILITY_SIZES := {
	"pickups": Vector2i(288, 144),
	"relics": Vector2i(384, 160),
	"projectiles": Vector2i(128, 128),
	"effects": Vector2i(256, 256),
	"hud_panel": Vector2i(512, 96),
	"menu_panel": Vector2i(512, 512),
	"joystick_base": Vector2i(192, 192),
	"joystick_thumb": Vector2i(96, 96),
	"touch_dash": Vector2i(128, 128),
	"touch_interact": Vector2i(112, 112),
	"touch_pause": Vector2i(72, 72),
}
const ALIASES := {
	"ritual_gunner": "outlaw_gunner",
	"biotech_pilgrim": "biomech_pilgrim",
	"horned_nephilim_berserker": "horned_berserker",
	"serpent_blood_spawn": "serpent_spawn",
	"tower_of_enoch": "tower_enoch",
}

var factory: RefCounted = FactoryScript.new()
var textures: Dictionary = {}
var audio: Dictionary = {}
var last_error := ""

func index() -> Dictionary:
	return {
		"version": VERSION,
		"godot": "4.7.1",
		"concept_policy": "Generated atlas posters are reference-only. Runtime sheets are rebuilt as transparent production assets.",
		"directions": ["n", "ne", "e", "se", "s", "sw", "w", "nw"],
		"actions": ["idle", "walk", "attack", "dash", "hurt", "death"],
		"frames_per_animation": 8,
		"hero_ids": HERO_IDS,
		"enemy_ids": ENEMY_IDS,
		"boss_ids": BOSS_IDS,
		"biome_ids": BIOME_IDS,
	}

func hero_sheet(id: String) -> Texture2D:
	var key := id.to_lower()
	if key not in HERO_IDS:
		return fail_texture("Unknown hero: %s" % id)
	return generated_texture("hero:" + key, "build_hero_sheet", [key])

func hero_portrait(id: String) -> Texture2D:
	var key := id.to_lower()
	if key not in HERO_IDS:
		return fail_texture("Unknown hero portrait: %s" % id)
	return generated_texture("portrait:" + key, "build_portrait", [key])

func enemy_sheet(id: String) -> Texture2D:
	var key := String(ALIASES.get(id.to_lower(), id.to_lower()))
	if key not in ENEMY_IDS:
		return fail_texture("Unknown enemy: %s" % id)
	return generated_texture("enemy:" + key, "build_enemy_sheet", [key])

func boss_sheet(id: String) -> Texture2D:
	var key := String(ALIASES.get(id.to_lower(), id.to_lower()))
	if key not in BOSS_IDS:
		return fail_texture("Unknown boss: %s" % id)
	return generated_texture("boss:" + key, "build_boss_sheet", [key])

func biome_texture(id: String, kind: String) -> Texture2D:
	var key := id.to_lower()
	if key not in BIOME_IDS or kind not in ["tiles", "props", "background"]:
		return fail_texture("Unknown biome texture: %s/%s" % [id, kind])
	return generated_texture("biome:%s:%s" % [key, kind], "build_biome", [key, kind])

func utility_texture(id: String) -> Texture2D:
	if not UTILITY_SIZES.has(id):
		return fail_texture("Unknown utility texture: %s" % id)
	return generated_texture("utility:" + id, "build_utility", [id])

func biome_audio(id: String, kind: String) -> AudioStreamWAV:
	var key := id.to_lower()
	if key not in BIOME_IDS or kind not in ["music", "ambience"]:
		return null
	var cache_key := "audio:%s:%s" % [key, kind]
	if audio.has(cache_key):
		return audio[cache_key]
	var stream: AudioStreamWAV = factory.call("synth_loop", BIOME_IDS.find(key), kind == "ambience")
	audio[cache_key] = stream
	return stream

func sfx(id: String) -> AudioStreamWAV:
	var cache_key := "sfx:" + id
	if audio.has(cache_key):
		return audio[cache_key]
	var stream: AudioStreamWAV = factory.call("synth_sfx", id)
	audio[cache_key] = stream
	return stream

func generated_texture(cache_key: String, method: String, arguments: Array) -> Texture2D:
	if textures.has(cache_key):
		return textures[cache_key]
	var image: Image = factory.callv(method, arguments)
	if image == null or image.is_empty():
		return fail_texture("Generated production image is empty: %s" % cache_key)
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = cache_key
	textures[cache_key] = texture
	return texture

func validate_contract(deep: bool = true) -> Dictionary:
	var errors: Array[String] = []
	var decoded := 0
	var metadata := index()
	if String(metadata.get("version", "")) != VERSION:
		errors.append("Version mismatch")
	if String(metadata.get("concept_policy", "")).findn("reference-only") < 0:
		errors.append("Concept exclusion policy missing")
	if Array(metadata.get("directions", [])).size() != 8:
		errors.append("Eight directions required")
	if int(metadata.get("frames_per_animation", 0)) != 8:
		errors.append("Eight temporal frames required")
	for method in ["build_hero_sheet", "build_portrait", "build_enemy_sheet", "build_boss_sheet", "build_biome", "build_utility", "synth_loop", "synth_sfx"]:
		if not factory.has_method(StringName(method)):
			errors.append("Factory method missing: %s" % method)

	if deep:
		for id in HERO_IDS:
			if check_size(hero_sheet(id), Vector2i(384, 2304), "hero:" + id, errors): decoded += 1
			if check_size(hero_portrait(id), Vector2i(256, 320), "portrait:" + id, errors): decoded += 1
		for id in ENEMY_IDS:
			if check_size(enemy_sheet(id), Vector2i(384, 2304), "enemy:" + id, errors): decoded += 1
		for id in BOSS_IDS:
			if check_size(boss_sheet(id), Vector2i(768, 3072), "boss:" + id, errors): decoded += 1
		for id in BIOME_IDS:
			if check_size(biome_texture(id, "tiles"), Vector2i(256, 128), "tiles:" + id, errors): decoded += 1
			if check_size(biome_texture(id, "props"), Vector2i(512, 96), "props:" + id, errors): decoded += 1
			if check_size(biome_texture(id, "background"), Vector2i(640, 360), "background:" + id, errors): decoded += 1
		for id in UTILITY_SIZES.keys():
			var expected_size: Vector2i = UTILITY_SIZES[id]
			if check_size(utility_texture(String(id)), expected_size, "utility:" + String(id), errors): decoded += 1
		for id in BIOME_IDS:
			if biome_audio(id, "music") == null: errors.append("Missing music: " + id)
			if biome_audio(id, "ambience") == null: errors.append("Missing ambience: " + id)
		for id in ["shot_01", "shot_02", "shot_03", "shot_04", "shot_05", "impact_01", "critical", "enemy_shot", "door", "boss_phase", "dash", "pickup", "ui_confirm", "ui_cancel"]:
			if sfx(id) == null: errors.append("Missing SFX: " + id)
	else:
		if check_size(hero_sheet("adam"), Vector2i(384, 2304), "hero:adam", errors): decoded += 1
		if check_size(enemy_sheet("feral_scavenger"), Vector2i(384, 2304), "enemy:feral_scavenger", errors): decoded += 1
		if check_size(boss_sheet("watcher_engine"), Vector2i(768, 3072), "boss:watcher_engine", errors): decoded += 1
		if check_size(biome_texture("industrial_eden", "tiles"), Vector2i(256, 128), "tiles:industrial_eden", errors): decoded += 1
		if check_size(utility_texture("projectiles"), Vector2i(128, 128), "utility:projectiles", errors): decoded += 1

	return {
		"version": VERSION,
		"mode": "deep" if deep else "runtime",
		"decoded_textures": decoded,
		"cached_textures": textures.size(),
		"cached_audio": audio.size(),
		"errors": errors,
		"passed": errors.is_empty(),
	}

func clear_caches() -> void:
	textures.clear()
	audio.clear()

func cache_report() -> Dictionary:
	return {"textures": textures.size(), "audio": audio.size()}

func check_size(texture: Texture2D, expected: Vector2i, label: String, errors: Array[String]) -> bool:
	if texture == null:
		errors.append("Missing texture: " + label)
		return false
	var size := texture.get_size()
	if Vector2i(int(size.x), int(size.y)) != expected:
		errors.append("Wrong size %s: %s expected %s" % [label, size, expected])
		return false
	return true

func fail_texture(message: String) -> Texture2D:
	last_error = message
	push_error(message)
	return null
