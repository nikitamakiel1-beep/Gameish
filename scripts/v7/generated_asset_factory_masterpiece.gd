extends RefCounted

const VERSION := "0.6.1-rc7"
const ActorFactoryScript = preload("res://scripts/v7/actor_asset_factory_masterpiece.gd")
const SupportFactoryScript = preload("res://scripts/v6/support_asset_factory.gd")
const AudioFactoryScript = preload("res://scripts/v7/audio_asset_factory_masterpiece.gd")

var actors = null
var support = null
var sound = null

func _init() -> void:
	actors = ActorFactoryScript.new()
	support = SupportFactoryScript.new()
	sound = AudioFactoryScript.new()

func _require_factory(factory: Variant, label: String) -> bool:
	if factory == null:
		push_error("EDEN//FALL RC7 factory failed to instantiate: " + label)
		return false
	return true

func build_hero_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_hero_sheet", id) as Image

func build_enemy_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_enemy_sheet", id) as Image

func build_boss_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_boss_sheet", id) as Image

func build_portrait(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_portrait", id) as Image

func build_biome(id: String, kind: String) -> Image:
	if not _require_factory(support, "support"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return support.call("build_biome", id, kind) as Image

func build_utility(id: String) -> Image:
	if not _require_factory(support, "support"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return support.call("build_utility", id) as Image

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	if not _require_factory(sound, "audio"):
		return AudioStreamWAV.new()
	return sound.call("synth_loop", index, ambience) as AudioStreamWAV

func synth_sfx(id: String) -> AudioStreamWAV:
	if not _require_factory(sound, "audio"):
		return AudioStreamWAV.new()
	return sound.call("synth_sfx", id) as AudioStreamWAV
