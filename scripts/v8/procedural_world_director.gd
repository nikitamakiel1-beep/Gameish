extends RefCounted

const VERSION: String = "0.6.2-entropy-art2"

const BIOME_RULES: Dictionary = {
	"industrial_eden": {
		"vegetation":[0.35,0.78], "ruin":[0.18,0.48], "tech":[0.66,0.96], "wet":[0.18,0.58],
		"families":["planter","tank","console","root_mass","bio_vat","server_stack"],
		"hazards":["coolant","root_burst","security_laser","spore_vent"],
	},
	"ash_wastes": {
		"vegetation":[0.02,0.18], "ruin":[0.48,0.88], "tech":[0.18,0.52], "wet":[0.0,0.12],
		"families":["wreck","barricade","concrete","scrap_heap","fuel_cell","road_block"],
		"hazards":["dust_front","mine_patch","fuel_fire","scrap_turret"],
	},
	"temple_lab": {
		"vegetation":[0.08,0.30], "ruin":[0.24,0.56], "tech":[0.72,0.98], "wet":[0.02,0.18],
		"families":["column","altar","glass_vat","circuit_pillar","archive_core","ritual_console"],
		"hazards":["liturgy_beam","glass_burst","signal_pulse","watcher_grid"],
	},
	"fungal_garden": {
		"vegetation":[0.74,1.0], "ruin":[0.30,0.66], "tech":[0.20,0.62], "wet":[0.32,0.74],
		"families":["fungal_tower","spore_bed","root_mass","mycelial_vat","collapsed_flat","fruiting_column"],
		"hazards":["spore_bloom","mycelial_snare","acid_pool","chorus_pulse"],
	},
	"nephilim_ruins": {
		"vegetation":[0.18,0.52], "ruin":[0.72,1.0], "tech":[0.34,0.78], "wet":[0.02,0.26],
		"families":["ruin_slab","rib","bone_altar","collapsed_tower","grafted_console","monolith"],
		"hazards":["bone_spike","gravity_pulse","serpent_rift","tower_crossfire"],
	},
}

func make_room_recipe(rng: RandomNumberGenerator, biome_id: String, room_kind: String, threat: float, viewport_hint: Vector2 = Vector2(1600,900)) -> Dictionary:
	var rules: Dictionary = BIOME_RULES.get(biome_id, BIOME_RULES["industrial_eden"])
	var decor_count: int = clampi(16 + int(viewport_hint.length()/180.0) + rng.randi_range(-4,8), 14, 36)
	var decor: Array = []
	for index: int in range(decor_count):
		decor.append({
			"u":rng.randf_range(0.025,0.975),
			"v":rng.randf_range(0.035,0.965),
			"kind":rng.randi_range(0,5),
			"size":rng.randf_range(0.55,1.55),
			"rotation":rng.randf_range(-PI,PI),
			"intensity":rng.randf_range(0.25,0.92),
		})
	var cover_base: int = 2 if room_kind == "boss" else (0 if room_kind in ["start","sanctuary","treasure"] else 3)
	var cover_count: int = clampi(cover_base + rng.randi_range(0,3) + int(maxf(0.0,threat-1.0)*1.5), 0, 7)
	var families: Array = rules["families"]
	var obstacle_families: Array[String] = []
	for index: int in range(maxi(1,cover_count)):
		obstacle_families.append(String(families[rng.randi_range(0,families.size()-1)]))
	var hazards: Array = rules["hazards"]
	return {
		"biome":biome_id,
		"room_kind":room_kind,
		"vegetation":rng.randf_range(float(rules["vegetation"][0]),float(rules["vegetation"][1])),
		"ruin":rng.randf_range(float(rules["ruin"][0]),float(rules["ruin"][1])),
		"tech":rng.randf_range(float(rules["tech"][0]),float(rules["tech"][1])),
		"wet":rng.randf_range(float(rules["wet"][0]),float(rules["wet"][1])),
		"light_temperature":rng.randf_range(-0.28,0.28),
		"contrast":rng.randf_range(0.88,1.16),
		"floor_noise_seed":rng.randi(),
		"large_form_seed":rng.randi(),
		"surface_variant":rng.randi_range(0,4),
		"noise_frequency":rng.randf_range(0.018,0.052),
		"cover_count":cover_count,
		"obstacle_families":obstacle_families,
		"hazard":String(hazards[rng.randi_range(0,hazards.size()-1)]),
		"decor":decor,
		"signature":"%s-%08x" % [biome_id,rng.randi()],
	}

func build_noise(recipe: Dictionary) -> FastNoiseLite:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = int(recipe.get("floor_noise_seed",0))
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = float(recipe.get("noise_frequency",0.035))
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.52
	noise.fractal_lacunarity = 2.0
	return noise

func build_floor_image(recipe: Dictionary, base_color: Color, accent: Color) -> Image:
	var width: int = 320
	var height: int = 180
	var image: Image = Image.create_empty(width,height,false,Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = build_noise(recipe)
	var vegetation: float = float(recipe.get("vegetation",0.3))
	var ruin: float = float(recipe.get("ruin",0.3))
	var tech: float = float(recipe.get("tech",0.5))
	var wet: float = float(recipe.get("wet",0.1))
	var contrast: float = float(recipe.get("contrast",1.0))
	var biome: String = String(recipe.get("biome","industrial_eden"))
	var block: int = 3
	for y: int in range(0,height,block):
		for x: int in range(0,width,block):
			var value: float = noise.get_noise_2d(float(x),float(y))
			var light: float = clampf((value*0.085+0.012)*contrast,-0.11,0.10)
			var color: Color = base_color.lightened(light) if light >= 0.0 else base_color.darkened(-light)
			if wet > 0.2 and value < -0.34:
				color = color.lerp(Color(0.025,0.075,0.075,1.0),wet*0.30)
			if vegetation > 0.25 and value > 0.48:
				color = color.lerp(accent.darkened(0.36),vegetation*0.18)
			image.fill_rect(Rect2i(x,y,block,block),color)
	var local_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	local_rng.seed = int(recipe.get("large_form_seed",recipe.get("floor_noise_seed",0)))
	match biome:
		"industrial_eden": _draw_industrial_surface(image,local_rng,base_color,accent,vegetation,wet,tech)
		"ash_wastes": _draw_ash_surface(image,local_rng,base_color,accent,ruin)
		"temple_lab": _draw_temple_surface(image,local_rng,base_color,accent,tech)
		"fungal_garden": _draw_fungal_surface(image,local_rng,base_color,accent,vegetation,wet)
		"nephilim_ruins": _draw_nephilim_surface(image,local_rng,base_color,accent,ruin)
		_:
			pass
	_draw_scars(image,local_rng,base_color,accent,ruin,vegetation)
	return image

func _draw_industrial_surface(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, vegetation: float, wet: float, tech: float) -> void:
	for plate: int in range(rng.randi_range(5,8)):
		var w: int = rng.randi_range(42,92)
		var h: int = rng.randi_range(28,66)
		var x: int = rng.randi_range(4,maxi(4,image.get_width()-w-4))
		var y: int = rng.randi_range(4,maxi(4,image.get_height()-h-4))
		var rect: Rect2i = Rect2i(x,y,w,h)
		image.fill_rect(rect,Color(base.lightened(0.025),0.96))
		_draw_rect_outline(image,rect,Color(base.darkened(0.30),0.88),2)
		if tech > 0.70:
			var channel_y: int = y + rng.randi_range(7,maxi(7,h-8))
			image.fill_rect(Rect2i(x+5,channel_y,maxi(4,w-10),2),Color(accent,0.20))
	for channel: int in range(2):
		var y: int = rng.randi_range(18,image.get_height()-18)
		image.fill_rect(Rect2i(0,y,image.get_width(),3),Color(0.02,0.06,0.065,0.72))
		if wet > 0.32:
			image.fill_rect(Rect2i(0,y+3,image.get_width(),1),Color(accent,0.13))
	if vegetation > 0.45:
		for patch: int in range(12):
			var p: Vector2i = Vector2i(rng.randi_range(5,image.get_width()-6),rng.randi_range(5,image.get_height()-6))
			_circle_pixels(image,p,rng.randi_range(2,5),Color(accent.darkened(0.26),0.32))

func _draw_ash_surface(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, ruin: float) -> void:
	var road_y: int = rng.randi_range(42,image.get_height()-42)
	image.fill_rect(Rect2i(0,road_y-20,image.get_width(),40),Color(base.darkened(0.08),0.94))
	for stripe: int in range(8):
		var x: int = stripe*44+rng.randi_range(-8,8)
		image.fill_rect(Rect2i(x,road_y-2,rng.randi_range(14,28),3),Color(0.72,0.60,0.39,0.24))
	for crack: int in range(10+int(ruin*10.0)):
		var start: Vector2i = Vector2i(rng.randi_range(0,image.get_width()-1),rng.randi_range(0,image.get_height()-1))
		var finish: Vector2i = start + Vector2i(rng.randi_range(-24,24),rng.randi_range(8,34))
		_line(image,start,finish,Color(base.darkened(0.42),0.90),1)
	for ember: int in range(8):
		var p: Vector2i = Vector2i(rng.randi_range(4,image.get_width()-5),rng.randi_range(4,image.get_height()-5))
		_circle_pixels(image,p,1,Color(accent,0.48))

func _draw_temple_surface(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, tech: float) -> void:
	var center: Vector2i = Vector2i(image.get_width()/2,image.get_height()/2)
	for ring: int in range(3):
		var radius: int = 24+ring*24+rng.randi_range(-3,3)
		_circle_outline_pixels(image,center,radius,Color(accent,0.12+0.04*ring))
	for circuit: int in range(8):
		var a: Vector2i = Vector2i(rng.randi_range(12,image.get_width()-12),rng.randi_range(12,image.get_height()-12))
		var b: Vector2i = Vector2i(center.x,a.y)
		var c: Vector2i = center
		_line(image,a,b,Color(accent,0.15+tech*0.08),1)
		_line(image,b,c,Color(accent,0.12+tech*0.06),1)
		_circle_pixels(image,a,2,Color(accent.lightened(0.20),0.42))

func _draw_fungal_surface(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, vegetation: float, wet: float) -> void:
	for colony: int in range(10+int(vegetation*10.0)):
		var p: Vector2i = Vector2i(rng.randi_range(6,image.get_width()-7),rng.randi_range(6,image.get_height()-7))
		var radius: int = rng.randi_range(3,8)
		_circle_pixels(image,p,radius,Color(accent.darkened(0.24),0.18+vegetation*0.16))
		_circle_pixels(image,p,maxi(1,radius/2),Color(accent.lightened(0.05),0.20))
		for branch: int in range(rng.randi_range(2,5)):
			var finish: Vector2i = p + Vector2i(rng.randi_range(-28,28),rng.randi_range(-22,22))
			_line(image,p,finish,Color(accent.darkened(0.18),0.26),2)
	if wet > 0.40:
		for pool: int in range(5):
			var p: Vector2i = Vector2i(rng.randi_range(12,image.get_width()-13),rng.randi_range(12,image.get_height()-13))
			_circle_pixels(image,p,rng.randi_range(5,12),Color(0.08,0.05,0.12,0.24))

func _draw_nephilim_surface(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, ruin: float) -> void:
	for slab: int in range(6+int(ruin*4.0)):
		var w: int = rng.randi_range(34,88)
		var h: int = rng.randi_range(24,58)
		var x: int = rng.randi_range(-10,maxi(-10,image.get_width()-w+10))
		var y: int = rng.randi_range(-8,maxi(-8,image.get_height()-h+8))
		var rect: Rect2i = Rect2i(x,y,w,h)
		image.fill_rect(rect,Color(base.lightened(rng.randf_range(0.01,0.06)),0.90))
		_draw_rect_outline(image,rect,Color(base.darkened(0.33),0.82),2)
	for rib: int in range(7):
		var root: Vector2i = Vector2i(rng.randi_range(0,image.get_width()-1),image.get_height()-1)
		var peak: Vector2i = root + Vector2i(rng.randi_range(-18,18),-rng.randi_range(24,70))
		_line(image,root,peak,Color(0.66,0.61,0.51,0.18),3)
		_circle_pixels(image,peak,2,Color(accent,0.26))

func _draw_scars(image: Image, rng: RandomNumberGenerator, base: Color, accent: Color, ruin: float, vegetation: float) -> void:
	var scar_count: int = clampi(4+int(ruin*14.0),4,18)
	for scar: int in range(scar_count):
		var start: Vector2i = Vector2i(rng.randi_range(5,image.get_width()-7),rng.randi_range(5,image.get_height()-7))
		var finish: Vector2i = start + Vector2i(rng.randi_range(6,22),rng.randi_range(-10,10))
		_line(image,start,finish,Color(base.darkened(0.42),0.82),1)
		if vegetation > 0.55 and scar%3 == 0:
			_circle_pixels(image,finish,2,Color(accent.darkened(0.20),0.58))

func _line(image: Image, start: Vector2i, finish: Vector2i, color: Color, width: int = 1) -> void:
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = finish.x
	var y1: int = finish.y
	var dx: int = absi(x1-x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -absi(y1-y0)
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx+dy
	while true:
		var half: int = maxi(0,int(width/2))
		for py: int in range(y0-half,y0+half+1):
			for px: int in range(x0-half,x0+half+1):
				if px>=0 and py>=0 and px<image.get_width() and py<image.get_height(): image.set_pixel(px,py,color)
		if x0==x1 and y0==y1: break
		var e2: int = 2*err
		if e2>=dy: err+=dy; x0+=sx
		if e2<=dx: err+=dx; y0+=sy

func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, width: int) -> void:
	image.fill_rect(Rect2i(rect.position.x,rect.position.y,rect.size.x,width),color)
	image.fill_rect(Rect2i(rect.position.x,rect.end.y-width,rect.size.x,width),color)
	image.fill_rect(Rect2i(rect.position.x,rect.position.y,width,rect.size.y),color)
	image.fill_rect(Rect2i(rect.end.x-width,rect.position.y,width,rect.size.y),color)

func _circle_pixels(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2: int = radius*radius
	for y: int in range(center.y-radius,center.y+radius+1):
		for x: int in range(center.x-radius,center.x+radius+1):
			var dx: int = x-center.x
			var dy: int = y-center.y
			if dx*dx+dy*dy<=r2 and x>=0 and y>=0 and x<image.get_width() and y<image.get_height(): image.set_pixel(x,y,color)

func _circle_outline_pixels(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2: int = radius*radius
	var inner: int = maxi(0,radius-1)
	var inner2: int = inner*inner
	for y: int in range(center.y-radius,center.y+radius+1):
		for x: int in range(center.x-radius,center.x+radius+1):
			var dx: int = x-center.x
			var dy: int = y-center.y
			var d2: int = dx*dx+dy*dy
			if d2<=r2 and d2>=inner2 and x>=0 and y>=0 and x<image.get_width() and y<image.get_height(): image.set_pixel(x,y,color)

func audit_contract() -> Dictionary:
	return {
		"version":VERSION,
		"biomes":BIOME_RULES.size(),
		"condition_driven":true,
		"fastnoise":true,
		"procedural_floor_texture":true,
		"room_unique_decor":true,
		"room_unique_cover":true,
		"authored_surface_grammar":true,
		"uniform_tile_grid":false,
		"fixed_seed_replay":false,
	}
