extends RefCounted

const VERSION := "0.6.2-entropy"

const BIOME_RULES := {
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
	var decor_count := clampi(16 + int(viewport_hint.length()/180.0) + rng.randi_range(-4,8), 14, 36)
	var decor: Array = []
	for index in range(decor_count):
		decor.append({
			"u":rng.randf_range(0.025,0.975),
			"v":rng.randf_range(0.035,0.965),
			"kind":rng.randi_range(0,5),
			"size":rng.randf_range(0.55,1.55),
			"rotation":rng.randf_range(-PI,PI),
			"intensity":rng.randf_range(0.25,0.92),
		})
	var cover_base := 2 if room_kind == "boss" else (0 if room_kind in ["start","sanctuary","treasure"] else 3)
	var cover_count := clampi(cover_base + rng.randi_range(0,3) + int(maxf(0.0,threat-1.0)*1.5), 0, 7)
	var families: Array = rules["families"]
	var obstacle_families: Array[String] = []
	for index in range(maxi(1,cover_count)):
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
		"noise_frequency":rng.randf_range(0.025,0.075),
		"cover_count":cover_count,
		"obstacle_families":obstacle_families,
		"hazard":String(hazards[rng.randi_range(0,hazards.size()-1)]),
		"decor":decor,
		"signature":"%s-%08x" % [biome_id,rng.randi()],
	}

func build_noise(recipe: Dictionary) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = int(recipe.get("floor_noise_seed",0))
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = float(recipe.get("noise_frequency",0.045))
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.54
	noise.fractal_lacunarity = 2.0
	return noise

func build_floor_image(recipe: Dictionary, base_color: Color, accent: Color) -> Image:
	var width := 256
	var height := 144
	var image := Image.create_empty(width,height,false,Image.FORMAT_RGBA8)
	var noise := build_noise(recipe)
	var vegetation := float(recipe.get("vegetation",0.3))
	var ruin := float(recipe.get("ruin",0.3))
	var tech := float(recipe.get("tech",0.5))
	var wet := float(recipe.get("wet",0.1))
	var contrast := float(recipe.get("contrast",1.0))
	var block := 4
	for y in range(0,height,block):
		for x in range(0,width,block):
			var value := noise.get_noise_2d(float(x),float(y))
			var light := clampf((value*0.10+0.02)*contrast,-0.12,0.12)
			var color := base_color.lightened(light) if light >= 0.0 else base_color.darkened(-light)
			if wet > 0.2 and value < -0.36:
				color = color.lerp(Color(0.03,0.09,0.08,1.0),wet*0.28)
			if vegetation > 0.25 and value > 0.46:
				color = color.lerp(accent.darkened(0.30),vegetation*0.20)
			image.fill_rect(Rect2i(x,y,block,block),color)
	for x in range(0,width,16):
		image.fill_rect(Rect2i(x,0,1,height),Color(base_color.darkened(0.22),0.78))
		if tech > 0.58 and x%32 == 0:
			image.fill_rect(Rect2i(x+1,0,1,height),Color(accent,0.10+tech*0.08))
	for y in range(0,height,16):
		image.fill_rect(Rect2i(0,y,width,1),Color(base_color.darkened(0.22),0.78))
	var scar_count := clampi(5+int(ruin*18.0),5,22)
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(recipe.get("floor_noise_seed",0)) ^ 0x51f24a
	for scar in range(scar_count):
		var x := local_rng.randi_range(5,width-7)
		var y := local_rng.randi_range(5,height-7)
		var length := local_rng.randi_range(4,14)
		for step in range(length):
			var px := clampi(x+step,0,width-1)
			var py := clampi(y+roundi(sin(float(step)*0.74+scar)*3.0),0,height-1)
			image.set_pixel(px,py,Color(base_color.darkened(0.42),0.90))
			if vegetation > 0.55 and step%3 == 0:
				image.set_pixel(clampi(px+1,0,width-1),py,Color(accent.darkened(0.20),0.72))
	return image

func audit_contract() -> Dictionary:
	return {
		"version":VERSION,
		"biomes":BIOME_RULES.size(),
		"condition_driven":true,
		"fastnoise":true,
		"procedural_floor_texture":true,
		"room_unique_decor":true,
		"room_unique_cover":true,
		"fixed_seed_replay":false,
	}
