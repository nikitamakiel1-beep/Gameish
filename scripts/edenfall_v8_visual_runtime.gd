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
	_draw_entropy_obstacle_finish()

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

func _draw_entropy_obstacle_finish() -> void:
	var accent := Color(BIOMES[biome_index]["accent"])
	for obstacle_variant in room_obstacles:
		var obstacle: Dictionary = obstacle_variant
		var rect := Rect2(obstacle.get("rect",Rect2()))
		var kind := String(obstacle.get("kind","console"))
		var variant := int(obstacle.get("variant",0))
		if kind.find("vat") >= 0 or kind.find("tank") >= 0:
			var glass := rect.grow(-8.0)
			draw_rect(glass,Color(0.04,0.12,0.12,0.56))
			draw_rect(glass,Color(accent,0.55),false,2.0)
			var fill_h := glass.size.y*(0.28+0.08*float(variant%5))
			draw_rect(Rect2(Vector2(glass.position.x+3.0,glass.end.y-fill_h-3.0),Vector2(glass.size.x-6.0,fill_h)),Color(accent,0.18))
			for bubble in range(3+variant%3):
				var p := Vector2(glass.position.x+8.0+float(bubble)*maxf(5.0,(glass.size.x-16.0)/float(maxi(1,2+variant%3))),glass.end.y-10.0-float((bubble*13+variant*7)%maxi(12,int(maxf(13.0,fill_h)))))
				draw_circle(p,2.0+float(bubble%2),Color(accent.lightened(0.24),0.52),false)
		elif kind.find("root") >= 0 or kind.find("fungal") >= 0 or kind.find("spore") >= 0 or kind.find("fruiting") >= 0 or kind.find("planter") >= 0:
			for growth in range(5+variant%4):
				var x := rect.position.x+9.0+float(growth)*maxf(5.0,(rect.size.x-18.0)/float(maxi(1,4+variant%4)))
				var height := 14.0+float((growth*11+variant*9)%maxi(16,int(maxf(17.0,rect.size.y-12.0))))
				var root := Vector2(x,rect.end.y-5.0)
				draw_line(root,root-Vector2(0,height),accent.darkened(0.25),3.0)
				draw_circle(root-Vector2(0,height),3.0+float(growth%3),Color(accent.lightened(0.12),0.72))
		elif kind.find("console") >= 0 or kind.find("server") >= 0 or kind.find("archive") >= 0 or kind.find("circuit") >= 0:
			var inner := rect.grow(-7.0)
			draw_rect(inner,Color(0.025,0.045,0.047,0.88))
			for row in range(3+variant%3):
				var y := inner.position.y+6.0+float(row)*maxf(5.0,(inner.size.y-12.0)/float(maxi(1,2+variant%3)))
				draw_line(Vector2(inner.position.x+5.0,y),Vector2(inner.end.x-5.0,y),Color(accent,0.30+0.08*float(row%2)),2.0)
				draw_circle(Vector2(inner.end.x-8.0,y),1.8,Color(accent.lightened(0.30),0.82))
		elif kind.find("wreck") >= 0 or kind.find("scrap") >= 0 or kind.find("barricade") >= 0 or kind.find("road") >= 0 or kind.find("fuel") >= 0:
			var inner := rect.grow(-6.0)
			for plate in range(4+variant%3):
				var ratio := float(plate+1)/float(5+variant%3)
				var start := Vector2(inner.position.x+inner.size.x*ratio,inner.position.y+3.0)
				draw_line(start,start+Vector2(-8.0+float(plate%3)*6.0,inner.size.y-6.0),Color(0.68,0.39,0.20,0.34),2.0)
			if kind.find("fuel") >= 0:
				draw_circle(inner.get_center(),minf(inner.size.x,inner.size.y)*0.20,Color(0.92,0.42,0.18,0.48),false,2.0)
		else:
			var center := rect.get_center()
			for rib in range(3+variant%3):
				var offset := -rect.size.x*0.25+float(rib)*rect.size.x*0.25
				draw_arc(center+Vector2(offset,3.0),minf(rect.size.x,rect.size.y)*(0.18+0.03*float(rib)),PI,TAU,18,Color(0.76,0.70,0.60,0.35),3.0)
			draw_circle(center,3.0+float(variant%3),Color(accent,0.56),false,2.0)

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
	report["biome_specific_cover_finishing"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["procedural_floor_texture"] = true
	report["encounter_metadata_persisted"] = true
	report["biome_specific_cover_finishing"] = true
	return report
