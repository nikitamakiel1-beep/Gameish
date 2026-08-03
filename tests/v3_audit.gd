extends SceneTree

const ROOT := "res://assets/generated_v3/"
const HERO_IDS := ["adam", "abel", "cain", "seth", "naamah"]
const ENEMY_IDS := [
	"feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
	"cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
	"nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]
const BOSS_IDS := ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]

var failures: Array[String] = []

func _init() -> void:
	_validate_manifest()
	_validate_assets()
	_validate_runtime_contract()
	if failures.is_empty():
		print("EDEN//FALL v3 audit passed: 8-direction runtime, HUD, UI, assets and lifecycle contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("EDEN//FALL v3 audit failed with %d issue(s)" % failures.size())
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _validate_manifest() -> void:
	var path := ROOT + "manifest_v3.json"
	_expect(FileAccess.file_exists(path), "Missing v3 directional manifest")
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "Cannot open v3 directional manifest")
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_expect(parsed is Dictionary, "v3 directional manifest is invalid JSON")
	if not parsed is Dictionary:
		return
	var manifest: Dictionary = parsed
	_expect(int(manifest.get("version", 0)) == 3, "Expected directional manifest version 3")
	_expect(Array(manifest.get("directions", [])).size() == 8, "Expected eight directions")
	_expect(Array(manifest.get("actions", [])).size() == 6, "Expected six hero action groups")
	_expect(Dictionary(manifest.get("players", {})).size() == 5, "Expected five player directional sheets")
	_expect(Dictionary(manifest.get("enemies", {})).size() == 18, "Expected eighteen enemy directional sheets")
	_expect(Dictionary(manifest.get("bosses", {})).size() == 5, "Expected five boss directional sheets")
	_expect(Array(manifest.get("files", [])).size() == 29, "Expected exactly 29 generated v3 PNG assets")

func _validate_assets() -> void:
	for id in HERO_IDS:
		_validate_texture(ROOT + "players/%s.png" % id, Vector2i(384, 2304))
	for id in ENEMY_IDS:
		_validate_texture(ROOT + "enemies/%s.png" % id, Vector2i(384, 2304))
	for id in BOSS_IDS:
		_validate_texture(ROOT + "bosses/%s.png" % id, Vector2i(768, 3072))
	_validate_texture(ROOT + "ui/hud_icons.png", Vector2i(64, 64))

func _validate_texture(path: String, expected: Vector2i) -> void:
	_expect(ResourceLoader.exists(path), "Missing texture: %s" % path)
	if not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	_expect(texture != null, "Cannot load texture: %s" % path)
	if texture != null:
		_expect(Vector2i(texture.get_width(), texture.get_height()) == expected, "Unexpected dimensions: %s" % path)

func _validate_runtime_contract() -> void:
	var script_path := "res://scripts/edenfall_v3.gd"
	_expect(ResourceLoader.exists(script_path), "Missing self-contained v3 runtime")
	if not ResourceLoader.exists(script_path):
		return
	var runtime_script: Script = load(script_path) as Script
	_expect(runtime_script != null, "Could not load v3 runtime script")
	if runtime_script == null:
		return
	var runtime: Node2D = runtime_script.new() as Node2D
	_expect(runtime != null, "Could not instantiate v3 runtime")
	if runtime == null:
		return
	_expect(runtime.quantize_direction(Vector2.UP) == 0, "Up must quantize to N")
	_expect(runtime.quantize_direction(Vector2(1.0, -1.0)) == 1, "Up-right must quantize to NE")
	_expect(runtime.quantize_direction(Vector2.RIGHT) == 2, "Right must quantize to E")
	_expect(runtime.quantize_direction(Vector2.DOWN) == 4, "Down must quantize to S")
	_expect(runtime.quantize_direction(Vector2.LEFT) == 6, "Left must quantize to W")
	_expect(runtime.directional_row("attack", 0) == 16, "North attack row mismatch")
	_expect(runtime.directional_row("attack", 4) == 20, "South attack row mismatch")
	_expect(runtime.relic_catalog().size() == 60, "Runtime must expose exactly 60 relic protocols")
	_expect(runtime.audit_readiness() >= 88.0, "Runtime contract readiness is below 88 percent")
	runtime.free()
