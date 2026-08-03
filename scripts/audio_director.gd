class_name EdenAudioDirector
extends Node

const ROOT := "res://assets/generated/audio/"

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var current_biome := -1
var last_played_ms: Dictionary = {}

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "GeneratedMusic"
	music_player.bus = _safe_bus("Music")
	music_player.volume_db = -7.0
	add_child(music_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "GeneratedAmbience"
	ambience_player.bus = _safe_bus("Ambience")
	ambience_player.volume_db = -13.0
	add_child(ambience_player)

	for index in range(10):
		var player := AudioStreamPlayer.new()
		player.name = "GeneratedSFX%02d" % index
		player.bus = _safe_bus("SFX")
		add_child(player)
		sfx_players.append(player)

func _safe_bus(requested: String) -> StringName:
	if AudioServer.get_bus_index(requested) >= 0:
		return StringName(requested)
	return &"Master"

func _load_loop(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var source := load(path)
	if source is AudioStreamWAV:
		var stream: AudioStreamWAV = source.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return stream
	return source

func play_biome(index: int, force := false) -> void:
	var biome := posmod(index, 5)
	if biome == current_biome and not force:
		return
	current_biome = biome
	var suffix := "%02d" % (biome + 1)
	var music := _load_loop(ROOT + "music/biome_%s.wav" % suffix)
	var ambience := _load_loop(ROOT + "ambience/biome_%s.wav" % suffix)
	if music != null:
		music_player.stream = music
		music_player.play()
	if ambience != null:
		ambience_player.stream = ambience
		ambience_player.play()

func stop_music() -> void:
	music_player.stop()
	ambience_player.stop()
	current_biome = -1

func play_sfx(id: String, pitch := 1.0, volume_db := 0.0, throttle_ms := 0) -> void:
	if sfx_players.is_empty():
		return
	var now := Time.get_ticks_msec()
	if throttle_ms > 0 and now - int(last_played_ms.get(id, -1000000)) < throttle_ms:
		return
	last_played_ms[id] = now
	var path := ROOT + "sfx/%s.wav" % id
	if not ResourceLoader.exists(path):
		return
	var player := sfx_players[sfx_cursor]
	sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
	player.stop()
	player.stream = load(path)
	player.pitch_scale = clampf(pitch, 0.55, 1.85)
	player.volume_db = volume_db
	player.play()
