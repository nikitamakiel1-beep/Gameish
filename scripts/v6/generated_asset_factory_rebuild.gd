extends RefCounted

# Compatibility substrate for the inherited RC6 registry.
# V8 active actor rendering is provided by the premium procedural forge, but
# the historical RC6 registry is still exercised by release audits and UI
# fallback paths. Keep this layer deliberately conservative and instantiate
# only the known-stable base factories so a compile failure in an obsolete
# visual wrapper cannot null the entire registry.
const VERSION := "0.6.2-compat"
const ActorFactoryScript = preload("res://scripts/v6/actor_asset_factory.gd")
const SupportFactoryScript = preload("res://scripts/v6/support_asset_factory.gd")
const AudioFactoryScript = preload("res://scripts/v6/audio_asset_factory.gd")

var actors = null
var support = null
var sound = null

func _init() -> void:
	actors = ActorFactoryScript.new()
	support = SupportFactoryScript.new()
	sound = AudioFactoryScript.new()

func _require_factory(factory: Variant, label: String) -> bool:
	if factory == null:
		push_error("EDEN//FALL compatibility factory failed to instantiate: " + label)
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
