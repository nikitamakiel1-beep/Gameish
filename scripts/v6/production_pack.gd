extends RefCounted
class_name EdenFallProductionPack

const VERSION := "0.6.0"
const CHUNK_ROOT := "res://assets/production_v6_pack"
const METADATA_PATH := CHUNK_ROOT + "/pack_metadata.json"
const CACHE_PATH := "user://edenfall_production_v6.zip"
const REGISTRY_PATH := "res://assets/production_v6/registry.json"
const MANIFEST_PATH := "res://assets/production_v6/manifest.json"

var mounted := false
var registry: Dictionary = {}
var manifest: Dictionary = {}
var texture_cache: Dictionary = {}
var audio_cache: Dictionary = {}
var errors: Array[String] = []

func mount() -> bool:
	if mounted:
		return true
	errors.clear()
	var metadata := _read_json(METADATA_PATH)
	if metadata.is_empty():
		_error("Pack metadata is missing or invalid.")
		return false
	var expected_hash := String(metadata.get("zip_sha256", ""))
	var expected_size := int(metadata.get("zip_bytes", 0))
	var cache_valid := FileAccess.file_exists(CACHE_PATH)
	if cache_valid:
		cache_valid = _file_size(CACHE_PATH) == expected_size and _file_sha256(CACHE_PATH) == expected_hash
	if not cache_valid:
		var encoded := ""
		var count := int(metadata.get("chunk_count", 0))
		for index in range(count):
			var path := "%s/chunk_%03d.b64" % [CHUNK_ROOT, index]
			if not FileAccess.file_exists(path):
				_error("Missing production pack chunk: %s" % path)
				return false
			encoded += FileAccess.get_file_as_string(path).strip_edges()
		var raw := Marshalls.base64_to_raw(encoded)
		if raw.size() != expected_size:
			_error("Production pack size mismatch: %d != %d" % [raw.size(), expected_size])
			return false
		if _sha256(raw) != expected_hash:
			_error("Production pack SHA-256 mismatch.")
			return false
		var output := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
		if output == null:
			_error("Could not create production pack cache.")
			return false
		output.store_buffer(raw)
		output.close()
	if not ProjectSettings.load_resource_pack(CACHE_PATH, true):
		_error("Godot could not mount the v0.6 production resource pack.")
		return false
	registry = _read_json(REGISTRY_PATH)
	manifest = _read_json(MANIFEST_PATH)
	if registry.is_empty() or manifest.is_empty():
		_error("Mounted pack is missing registry or manifest.")
		return false
	mounted = true
	return true

func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if texture_cache.has(path):
		return texture_cache[path]
	if not mounted and not mount():
		return null
	if not FileAccess.file_exists(path):
		_error("Missing production texture: %s" % path)
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var image := Image.new()
	var status := image.load_png_from_buffer(bytes)
	if status != OK:
		_error("PNG decode failed (%d): %s" % [status, path])
		return null
	var texture := ImageTexture.create_from_image(image)
	texture_cache[path] = texture
	return texture

func load_wav(path: String, looped: bool = false) -> AudioStreamWAV:
	var cache_key := "%s|%s" % [path, looped]
	if audio_cache.has(cache_key):
		return audio_cache[cache_key]
	if not mounted and not mount():
		return null
	if not FileAccess.file_exists(path):
		_error("Missing production audio: %s" % path)
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44 or _ascii(bytes, 0, 4) != "RIFF" or _ascii(bytes, 8, 4) != "WAVE":
		_error("Unsupported WAV header: %s" % path)
		return null
	var channels := _u16(bytes, 22)
	var sample_rate := _u32(bytes, 24)
	var bits := _u16(bytes, 34)
	var offset := 12
	var data_start := -1
	var data_size := 0
	while offset + 8 <= bytes.size():
		var chunk_id := _ascii(bytes, offset, 4)
		var chunk_size := _u32(bytes, offset + 4)
		if chunk_id == "data":
			data_start = offset + 8
			data_size = mini(chunk_size, bytes.size() - data_start)
			break
		offset += 8 + chunk_size + (chunk_size % 2)
	if data_start < 0 or data_size <= 0:
		_error("WAV data chunk is missing: %s" % path)
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS if bits == 16 else AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = channels == 2
	stream.data = bytes.slice(data_start, data_start + data_size)
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		var bytes_per_sample := maxi(1, int(bits / 8))
		var bytes_per_frame := maxi(1, channels * bytes_per_sample)
		stream.loop_end = int(data_size / bytes_per_frame)
	audio_cache[cache_key] = stream
	return stream

func image_size(path: String) -> Vector2i:
	if not mounted and not mount():
		return Vector2i.ZERO
	if not FileAccess.file_exists(path):
		return Vector2i.ZERO
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())

func image_has_transparency(path: String) -> bool:
	if not mounted and not mount():
		return false
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return false
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var step_y := maxi(1, int(image.get_height() / 24))
	var step_x := maxi(1, int(image.get_width() / 24))
	for y in range(0, image.get_height(), step_y):
		for x in range(0, image.get_width(), step_x):
			if image.get_pixel(x, y).a < 0.02:
				return true
	return false

func audit() -> Dictionary:
	var failures: Array[String] = []
	if not mount():
		failures.append_array(errors)
		return {"ok": false, "failures": failures}
	if String(registry.get("version", "")) != VERSION:
		failures.append("Registry version is not %s." % VERSION)
	if "reference-only" not in String(registry.get("concept_policy", "")).to_lower():
		failures.append("Concept-art exclusion policy is missing.")
	var expected_counts := {"heroes": 5, "enemies": 18, "bosses": 5, "biomes": 5, "elite_overlays": 6}
	for section in expected_counts:
		var section_data: Dictionary = registry.get(section, {})
		if section_data.size() != int(expected_counts[section]):
			failures.append("%s count mismatch." % section)
	for section in ["heroes", "enemies", "bosses", "biomes", "elite_overlays", "ui", "vfx", "items", "audio"]:
		_scan_paths(registry.get(section, {}), failures)
	var hero_registry: Dictionary = registry.get("heroes", {})
	for hero_id in hero_registry:
		var definition: Dictionary = hero_registry[hero_id]
		if image_size(String(definition.get("sheet", ""))) != Vector2i(384, 4224):
			failures.append("Hero sheet dimensions invalid: %s" % hero_id)
		elif not image_has_transparency(String(definition.get("sheet", ""))):
			failures.append("Hero sheet lacks transparent pixels: %s" % hero_id)
	var enemy_registry: Dictionary = registry.get("enemies", {})
	for enemy_id in enemy_registry:
		var definition: Dictionary = enemy_registry[enemy_id]
		if image_size(String(definition.get("sheet", ""))) != Vector2i(256, 1280):
			failures.append("Enemy sheet dimensions invalid: %s" % enemy_id)
	var boss_registry: Dictionary = registry.get("bosses", {})
	for boss_id in boss_registry:
		var definition: Dictionary = boss_registry[boss_id]
		if image_size(String(definition.get("sheet", ""))) != Vector2i(512, 4096):
			failures.append("Boss sheet dimensions invalid: %s" % boss_id)
	var item_registry: Dictionary = registry.get("items", {})
	if image_size(String(item_registry.get("relics", ""))) != Vector2i(640, 384):
		failures.append("Relic atlas dimensions invalid.")
	if int(manifest.get("file_count", 0)) < 120:
		failures.append("Production manifest is unexpectedly small.")
	return {
		"ok": failures.is_empty(),
		"failures": failures,
		"file_count": int(manifest.get("file_count", 0)),
		"bytes": int(manifest.get("total_bytes", 0)),
		"pack_errors": errors.duplicate(),
	}

func _scan_paths(value: Variant, failures: Array[String]) -> void:
	if value is Dictionary:
		for child in value.values():
			_scan_paths(child, failures)
	elif value is Array:
		for child in value:
			_scan_paths(child, failures)
	elif value is String:
		var path := String(value)
		if path.begins_with("res://"):
			if "concept" in path.to_lower():
				failures.append("Runtime registry references concept art: %s" % path)
			elif not FileAccess.file_exists(path):
				failures.append("Registry path does not exist: %s" % path)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed := JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var size := file.get_length()
	file.close()
	return size

func _file_sha256(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return _sha256(FileAccess.get_file_as_bytes(path))

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _ascii(bytes: PackedByteArray, offset: int, count: int) -> String:
	if offset < 0 or offset + count > bytes.size():
		return ""
	return bytes.slice(offset, offset + count).get_string_from_ascii()

func _u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)

func _error(message: String) -> void:
	if message not in errors:
		errors.append(message)
	push_error("[EDEN//FALL v0.6 assets] %s" % message)
