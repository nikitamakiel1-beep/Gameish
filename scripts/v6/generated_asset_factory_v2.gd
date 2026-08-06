extends RefCounted

const ActorFactoryScript: Script = preload("res://scripts/v6/actor_asset_factory.gd")
const SupportFactoryScript: Script = preload("res://scripts/v6/support_asset_factory.gd")
const AudioFactoryScript: Script = preload("res://scripts/v6/audio_asset_factory.gd")

var actors: RefCounted = ActorFactoryScript.new()
var support: RefCounted = SupportFactoryScript.new()
var sound: RefCounted = AudioFactoryScript.new()

func build_hero_sheet(id: String) -> Image:
	return actors.call("build_hero_sheet", id) as Image

func build_enemy_sheet(id: String) -> Image:
	return actors.call("build_enemy_sheet", id) as Image

func build_boss_sheet(id: String) -> Image:
	return actors.call("build_boss_sheet", id) as Image

func build_portrait(id: String) -> Image:
	return actors.call("build_portrait", id) as Image

func build_biome(id: String, kind: String) -> Image:
	return support.call("build_biome", id, kind) as Image

func build_utility(id: String) -> Image:
	return support.call("build_utility", id) as Image

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	return sound.call("synth_loop", index, ambience) as AudioStreamWAV

func synth_sfx(id: String) -> AudioStreamWAV:
	return sound.call("synth_sfx", id) as AudioStreamWAV
