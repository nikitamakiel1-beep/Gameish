extends "res://scripts/v8/procedural_world_director.gd"

const ART3_WORLD_VERSION: String = "0.6.3-authored"

const LANDMARKS: Dictionary = {
	"industrial_eden":["containment_spine","coolant_trench","greenhouse_breach","service_grid"],
	"ash_wastes":["broken_road","collapsed_crossing","burned_convoy","rebar_square"],
	"temple_lab":["ritual_circuit","archive_axis","sealed_choir","glass_procession"],
	"fungal_garden":["mycelial_vein","fruiting_ring","spore_marsh","root_nexus"],
	"nephilim_ruins":["monolith_field","rib_procession","buried_gate","bone_causeway"]
}

func make_room_recipe(rng: RandomNumberGenerator, biome_id: String, room_kind: String, threat: float, viewport_hint: Vector2 = Vector2(1600,900)) -> Dictionary:
	var recipe: Dictionary = super.make_room_recipe(rng,biome_id,room_kind,threat,viewport_hint)
	var landmarks: Array = LANDMARKS.get(biome_id,LANDMARKS["industrial_eden"])
	recipe["landmark"] = String(landmarks[rng.randi_range(0,landmarks.size()-1)])
	recipe["macro_density"] = rng.randf_range(0.34,0.68)
	recipe["micro_density"] = rng.randf_range(0.10,0.28)
	recipe["quiet_floor"] = true
	return recipe

func build_floor_image(recipe: Dictionary, base_color: Color, accent: Color) -> Image:
	var width: int = 320
	var height: int = 180
	var image: Image = Image.create_empty(width,height,false,Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = build_noise(recipe)
	var biome: String = String(recipe.get("biome","industrial_eden"))
	var local_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	local_rng.seed = int(recipe.get("large_form_seed",recipe.get("floor_noise_seed",0)))
	var macro_density: float = float(recipe.get("macro_density",0.50))
	var micro_density: float = float(recipe.get("micro_density",0.18))
	var wet: float = float(recipe.get("wet",0.15))
	var vegetation: float = float(recipe.get("vegetation",0.30))

	# Quiet 4px clusters: texture supports actors instead of competing with them.
	var block: int = 4
	for y: int in range(0,height,block):
		for x: int in range(0,width,block):
			var sample: float = noise.get_noise_2d(float(x)*0.72,float(y)*0.72)
			var delta: float = clampf(sample*0.035,-0.035,0.035)
			var color: Color = base_color.lightened(delta) if delta >= 0.0 else base_color.darkened(-delta)
			image.fill_rect(Rect2i(x,y,block,block),color)

	match biome:
		"industrial_eden": _industrial_art3(image,local_rng,base_color,accent,macro_density,vegetation,wet)
		"ash_wastes": _ash_art3(image,local_rng,base_color,accent,macro_density)
		"temple_lab": _temple_art3(image,local_rng,base_color,accent,macro_density)
		"fungal_garden": _fungal_art3(image,local_rng,base_color,accent,macro_density,vegetation,wet)
		"nephilim_ruins": _nephilim_art3(image,local_rng,base_color,accent,macro_density)
		_:
			pass
	_draw_micro_wear(image,local_rng,base_color,accent,micro_density)
	return image

func _industrial_art3(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float, vegetation: float, wet: float) -> void:
	# Small plate islands and service channels, never room-sized rectangles.
	var plates: int = 3 + int(density*4.0)
	for index: int in range(plates):
		var w: int = rng.randi_range(24,54)
		var h: int = rng.randi_range(16,34)
		var x: int = rng.randi_range(8,image.get_width()-w-8)
		var y: int = rng.randi_range(8,image.get_height()-h-8)
		var rect: Rect2i = Rect2i(x,y,w,h)
		image.fill_rect(rect,base.lightened(0.025))
		_draw_rect_outline(image,rect,base.darkened(0.22),1)
		image.fill_rect(Rect2i(x+5,y+h/2,maxi(4,w-10),1),Color(accent,0.16))
	for channel: int in range(2):
		var y: int = rng.randi_range(24,image.get_height()-25)
		image.fill_rect(Rect2i(0,y,image.get_width(),2),Color(base.darkened(0.30),0.92))
		if wet > 0.30:
			image.fill_rect(Rect2i(0,y+2,image.get_width(),1),Color(accent,0.10))
	if vegetation > 0.36:
		for patch: int in range(6+int(vegetation*6.0)):
			var p: Vector2i = Vector2i(rng.randi_range(7,image.get_width()-8),rng.randi_range(7,image.get_height()-8))
			_circle_pixels(image,p,rng.randi_range(2,4),Color(accent.darkened(0.30),0.34))
			if patch % 2 == 0:
				_line(image,p,p+Vector2i(rng.randi_range(-12,12),rng.randi_range(-8,8)),Color(accent.darkened(0.28),0.25),1)

func _ash_art3(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float) -> void:
	var road_y: int = rng.randi_range(52,image.get_height()-53)
	image.fill_rect(Rect2i(0,road_y-16,image.get_width(),32),base.darkened(0.07))
	for dash: int in range(7):
		var x: int = dash*50+rng.randi_range(-8,6)
		image.fill_rect(Rect2i(x,road_y-1,rng.randi_range(12,24),2),Color(0.68,0.58,0.39,0.22))
	for crack: int in range(7+int(density*8.0)):
		var a: Vector2i = Vector2i(rng.randi_range(4,image.get_width()-5),rng.randi_range(4,image.get_height()-5))
		var b: Vector2i = a+Vector2i(rng.randi_range(-18,18),rng.randi_range(7,24))
		_line(image,a,b,base.darkened(0.34),1)
	for ember: int in range(4):
		_circle_pixels(image,Vector2i(rng.randi_range(6,image.get_width()-7),rng.randi_range(6,image.get_height()-7)),1,Color(accent,0.42))

func _temple_art3(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float) -> void:
	var center: Vector2i = Vector2i(image.get_width()/2,image.get_height()/2)
	for ring: int in range(2):
		_circle_outline_pixels(image,center,28+ring*24,Color(accent,0.11+0.03*float(ring)))
	for arm: int in range(6):
		var angle: float = TAU*float(arm)/6.0
		var a: Vector2i = center+Vector2i(roundi(cos(angle)*18.0),roundi(sin(angle)*18.0))
		var b: Vector2i = center+Vector2i(roundi(cos(angle)*(58.0+density*18.0)),roundi(sin(angle)*(58.0+density*18.0)))
		_line(image,a,b,Color(accent,0.15),1)
		_circle_pixels(image,b,2,Color(accent,0.28))

func _fungal_art3(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float, vegetation: float, wet: float) -> void:
	var colonies: int = 7+int(vegetation*7.0)
	for colony: int in range(colonies):
		var p: Vector2i = Vector2i(rng.randi_range(10,image.get_width()-11),rng.randi_range(10,image.get_height()-11))
		var radius: int = rng.randi_range(3,7)
		_circle_pixels(image,p,radius,Color(accent.darkened(0.25),0.20+density*0.08))
		for branch: int in range(2+rng.randi_range(0,2)):
			_line(image,p,p+Vector2i(rng.randi_range(-22,22),rng.randi_range(-16,16)),Color(accent.darkened(0.28),0.25),1)
	if wet > 0.42:
		for pool: int in range(3):
			_circle_pixels(image,Vector2i(rng.randi_range(14,image.get_width()-15),rng.randi_range(14,image.get_height()-15)),rng.randi_range(5,9),Color(0.06,0.05,0.09,0.22))

func _nephilim_art3(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float) -> void:
	for slab: int in range(4+int(density*4.0)):
		var w: int = rng.randi_range(28,58)
		var h: int = rng.randi_range(18,38)
		var rect: Rect2i = Rect2i(rng.randi_range(-8,image.get_width()-w+8),rng.randi_range(-6,image.get_height()-h+6),w,h)
		image.fill_rect(rect,base.lightened(0.025))
		_draw_rect_outline(image,rect,base.darkened(0.26),1)
	for rib: int in range(5):
		var root: Vector2i = Vector2i(rng.randi_range(8,image.get_width()-9),image.get_height()-1)
		var peak: Vector2i = root+Vector2i(rng.randi_range(-12,12),-rng.randi_range(22,52))
		_line(image,root,peak,Color(accent.darkened(0.34),0.28),2)

func _draw_micro_wear(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, density: float) -> void:
	var marks: int = 8+int(density*20.0)
	for mark: int in range(marks):
		var p: Vector2i = Vector2i(rng.randi_range(4,image.get_width()-5),rng.randi_range(4,image.get_height()-5))
		if mark % 4 == 0:
			_line(image,p,p+Vector2i(rng.randi_range(-7,7),rng.randi_range(-4,4)),base.darkened(0.24),1)
		else:
			_circle_pixels(image,p,1,Color(accent.darkened(0.28),0.18))

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["art3_world_version"] = ART3_WORLD_VERSION
	report["quiet_floor_hierarchy"] = true
	report["authored_landmark_families"] = LANDMARKS.size()
	report["room_sized_wallpaper_panels"] = false
	report["biome_specific_macro_forms"] = true
	return report
