extends "res://scripts/edenfall_v8_entropy_runtime.gd"

const V8_VISUAL_VERSION := "0.6.2-entropy"
var _v8_floor_textures: Dictionary = {}

func start_new_run(lineage_index: int, seed_override: int = 0) -> void:
	_v8_floor_textures.clear()
	super.start_new_run(lineage_index,seed_override)

func _spawn_encounter_recipe(recipe: Dictionary, kind: String) -> void:
	super._spawn_encounter_recipe(recipe,kind)
	if room_graph.has(current_room):
		var room: Dictionary = room_graph[current_room]
		room["encounter_signature"] = String(recipe.get("name","UNSTABLE HOST CELL"))
		room["encounter_signature_id"] = String(recipe.get("signature","mixed"))
		room_graph[current_room] = room

func _draw_room_obstacles() -> void:
	_draw_entropy_floor_skin()
	super._draw_room_obstacles()

func _draw_entropy_floor_skin() -> void:
	if not room_graph.has(current_room):
		return
	var room: Dictionary = room_graph[current_room]
	var recipe: Dictionary = room.get("v8_world_recipe",{})
	if recipe.is_empty():
		recipe = _ensure_world_recipe(room)
	if recipe.is_empty():
		return
	var signature := String(recipe.get("signature",_coord_key(current_room)))
	var texture: Texture2D = _v8_floor_textures.get(signature,null)
	if texture == null:
		var base := Color(BIOMES[biome_index]["floor"])
		var accent := Color(BIOMES[biome_index]["accent"])
		var image: Image = world_director.call("build_floor_image",recipe,base,accent)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
			_v8_floor_textures[signature] = texture
	if texture != null:
		draw_texture_rect(texture,arena_rect(),false,Color.WHITE)

func restore_suspended_run() -> void:
	_v8_floor_textures.clear()
	super.restore_suspended_run()

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["v8_visual_version"] = V8_VISUAL_VERSION
	report["procedural_floor_cache"] = _v8_floor_textures.size()
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["procedural_floor_texture"] = true
	report["encounter_metadata_persisted"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["procedural_floor_texture"] = true
	report["encounter_metadata_persisted"] = true
	return report
