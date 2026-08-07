extends SceneTree

const GameData = preload("res://scripts/game_data.gd")
const ROOT := "res://assets/generated/"

var failures: Array[String] = []

func _init() -> void:
	_validate_game_data()
	_validate_manifest()
	_validate_visual_assets()
	_validate_audio_assets()
	if failures.is_empty():
		print("EDEN//FALL content validation passed")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("EDEN//FALL content validation failed with %d issue(s)" % failures.size())
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _validate_game_data() -> void:
	_expect(GameData.lineages().size() == 5, "Expected five playable lineages")
	_expect(GameData.items().size() == 10, "Expected ten gameplay relic definitions")
	_expect(GameData.enemy_defs().size() == 5, "Expected five active enemy archetypes")
	for lineage in GameData.lineages():
		var id := String(lineage.get("id", ""))
		_expect(not id.is_empty(), "A lineage is missing its ID")
		_expect(FileAccess.file_exists(ROOT + "players/%s.png" % id), "Missing player sprite sheet for %s" % id)

func _validate_manifest() -> void:
	var path := ROOT + "manifest.json"
	_expect(FileAccess.file_exists(path), "Missing generated asset manifest")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "Could not open generated asset manifest")
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_expect(parsed is Dictionary, "Generated asset manifest is not valid JSON")
	if not parsed is Dictionary:
		return
	var manifest: Dictionary = parsed
	_expect(int(manifest.get("version", 0)) == 1, "Unexpected asset manifest version")
	_expect(Dictionary(manifest.get("players", {})).size() == 5, "Manifest must contain five player sheets")
	var enemy_count := 0
	for variants in Dictionary(manifest.get("enemies", {})).values():
		enemy_count += Array(variants).size()
	_expect(enemy_count == 25, "Manifest must contain 25 enemy variant sheets")
	_expect(Dictionary(manifest.get("bosses", {})).size() == 5, "Manifest must contain five boss sheets")
	_expect(Dictionary(manifest.get("weapons", {})).size() == 10, "Manifest must contain ten weapon sheets")
	_expect(Dictionary(manifest.get("music", {})).size() == 5, "Manifest must contain five music loops")
	_expect(Dictionary(manifest.get("ambience", {})).size() == 5, "Manifest must contain five ambience loops")
	_expect(Dictionary(manifest.get("sfx", {})).size() >= 20, "Manifest must contain at least 20 sound effects")
	_expect(Array(manifest.get("files", [])).size() >= 84, "Generated package is incomplete")

func _validate_visual_assets() -> void:
	for id in ["adam", "abel", "cain", "seth", "naamah"]:
		_validate_texture(ROOT + "players/%s.png" % id, Vector2i(384, 288))
	for category in ["feral", "outlaw", "enhanced", "nephilim", "fallen"]:
		for variant in range(1, 6):
			_validate_texture(ROOT + "enemies/%s_%02d.png" % [category, variant], Vector2i(384, 288))
	for id in ["watcher_engine", "seraph_reactor", "nephilim_king", "eden_warden", "void_archon"]:
		_validate_texture(ROOT + "bosses/%s.png" % id, Vector2i(768, 384))
	for id in ["genesis_rifle", "tithe_pistol", "mark_cannon", "continuation_lance", "spore_repeater", "seraph_beam", "salt_shotgun", "watcher_carbine", "marrow_launcher", "eden_arc"]:
		_validate_texture(ROOT + "weapons/%s.png" % id, Vector2i(256, 32))
	_validate_texture(ROOT + "effects/effects.png", Vector2i(256, 320))
	_validate_texture(ROOT + "items/relics.png", Vector2i(128, 320))
	_validate_texture(ROOT + "ui/boot_splash.png", Vector2i(1280, 720))
	for biome in range(1, 6):
		_validate_texture(ROOT + "tiles/biome_%02d.png" % biome, Vector2i(256, 128))

func _validate_texture(path: String, expected_size: Vector2i) -> void:
	_expect(ResourceLoader.exists(path), "Missing texture: %s" % path)
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	_expect(texture != null, "Could not load texture: %s" % path)
	if texture != null:
		_expect(Vector2i(texture.get_width(), texture.get_height()) == expected_size, "Unexpected dimensions for %s" % path)

func _validate_audio_assets() -> void:
	for biome in range(1, 6):
		_validate_audio(ROOT + "audio/music/biome_%02d.wav" % biome, 20.0)
		_validate_audio(ROOT + "audio/ambience/biome_%02d.wav" % biome, 15.0)
	for id in ["shot_01", "shot_02", "shot_03", "enemy_shot", "dash", "impact_01", "impact_02", "hurt", "kill", "pickup", "relic", "shield", "door", "boss_phase", "death", "victory", "ui", "shop", "heal", "critical", "portal"]:
		_validate_audio(ROOT + "audio/sfx/%s.wav" % id, 0.05)

func _validate_audio(path: String, minimum_length: float) -> void:
	_expect(ResourceLoader.exists(path), "Missing audio stream: %s" % path)
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	_expect(stream != null, "Could not load audio stream: %s" % path)
	if stream != null:
		_expect(stream.get_length() >= minimum_length, "Audio stream is too short: %s" % path)
