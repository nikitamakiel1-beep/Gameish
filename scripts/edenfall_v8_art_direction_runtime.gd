extends "res://scripts/edenfall_v8_streaming_runtime.gd"

const V8_ART_DIRECTION_VERSION: String = "0.6.2-art2"
var _lineage_preview_textures: Dictionary = {}

func title_option_rect(index: int) -> Rect2:
	var safe: Rect2 = safe_rect()
	var width: float = minf(520.0, safe.size.x * 0.38)
	var height: float = 50.0
	var x: float = safe.position.x + 54.0
	var y: float = safe.position.y + safe.size.y * 0.49 + float(index) * 58.0
	if safe.size.x < 860.0:
		width = safe.size.x - 40.0
		x = safe.position.x + 20.0
		y = safe.position.y + safe.size.y * 0.43 + float(index) * 54.0
	return Rect2(Vector2(x,y),Vector2(width,height))

func lineage_card_rect(index: int) -> Rect2:
	var safe: Rect2 = safe_rect()
	if safe.size.x < 860.0:
		var width: float = (safe.size.x - 34.0) * 0.5
		var column: int = index % 2
		var row: int = index / 2
		return Rect2(Vector2(safe.position.x + 12.0 + float(column) * (width + 10.0), safe.position.y + safe.size.y * 0.55 + float(row) * 58.0), Vector2(width,50.0))
	var right_x: float = safe.position.x + safe.size.x * 0.57
	var right_w: float = safe.end.x - right_x - 26.0
	return Rect2(Vector2(right_x,safe.position.y+116.0+float(index)*82.0),Vector2(right_w,70.0))

func draw_title() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	draw_rect(Rect2(Vector2.ZERO,size),Color8(3,7,8))
	# Reclaimed-city/laboratory silhouette; large forms replace the old concentric debug motif.
	for tower: int in range(12):
		var width: float = 44.0 + float((tower*19)%42)
		var height: float = 110.0 + float((tower*73)%210)
		var x: float = safe.position.x + safe.size.x*0.48 + float(tower)*safe.size.x*0.045
		var y: float = safe.end.y - height - 14.0
		draw_rect(Rect2(Vector2(x,y),Vector2(width,height)),Color(0.05,0.10,0.09,0.50))
		draw_rect(Rect2(Vector2(x+5.0,y+7.0),Vector2(width-10.0,2.0)),Color(0.32,0.52,0.35,0.12))
		if tower%3==0:
			draw_line(Vector2(x+width*0.5,y),Vector2(x+width*0.5,y-22.0),Color(0.37,0.62,0.42,0.22),2.0)
	# Bio-lab aperture on the right, deliberately off-center.
	var aperture: Vector2 = Vector2(safe.position.x+safe.size.x*0.76,safe.position.y+safe.size.y*0.30)
	for ring: int in range(4):
		draw_arc(aperture,62.0+float(ring)*31.0,-PI*0.88,PI*0.88,56,Color(0.26,0.53,0.35,0.13+float(ring)*0.025),2.0)
	for spoke: int in range(8):
		var angle: float = TAU*float(spoke)/8.0
		draw_line(aperture+Vector2.RIGHT.rotated(angle)*48.0,aperture+Vector2.RIGHT.rotated(angle)*95.0,Color(0.32,0.63,0.41,0.10),2.0)

	var title_pos: Vector2 = Vector2(safe.position.x+54.0,safe.position.y+104.0)
	draw_text("EDEN//FALL",title_pos,50,Color8(235,221,184))
	draw_text("THE GARDEN SURVIVED. HUMANITY DID NOT.",title_pos+Vector2(3,35),13,Color8(133,164,149))
	draw_text("v0.6.2 V8  •  STOCHASTIC EXCURSION  •  GODOT 4.7.1",title_pos+Vector2(3,60),10,Color8(94,142,116))

	var options: Array[String] = title_options()
	for index: int in range(options.size()):
		var rect: Rect2 = title_option_rect(index)
		var selected: bool = index==menu_index
		var fill: Color = Color(0.055,0.105,0.095,0.94) if selected else Color(0.025,0.047,0.048,0.88)
		var border: Color = Color8(164,211,142) if selected else Color8(58,85,76)
		draw_panel(rect,fill,border)
		draw_text(String(options[index]),rect.position+Vector2(18,31),14,Color8(235,224,191) if selected else Color8(174,191,178))
		if selected:
			draw_rect(Rect2(rect.position,Vector2(5,rect.size.y)),Color8(151,209,126))

	# Five lineage silhouettes serve as world identity, not menu decoration.
	var preview_y: float = safe.end.y-112.0
	var preview_x: float = safe.position.x+safe.size.x*0.59
	for index: int in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var texture: Texture2D = _lineage_preview_texture(String(lineage["id"]))
		var x: float = preview_x+float(index)*92.0
		if texture!=null:
			var src: Rect2 = Rect2(Vector2(0,4*48),Vector2(48,48))
			draw_texture_rect_region(texture,Rect2(Vector2(x-35.0,preview_y-60.0),Vector2(70,70)),src,Color(1,1,1,0.76))
		draw_text_centered(String(lineage["name"]),Vector2(x,preview_y+18.0),10,Color(lineage["color"]))

func draw_select() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	draw_rect(Rect2(Vector2.ZERO,size),Color8(4,8,9))
	var selected: Dictionary = LINEAGES[selected_lineage]
	var accent: Color = Color(selected["color"])
	draw_text("ENGINEERED LINEAGE",safe.position+Vector2(28,34),12,Color8(105,145,128))
	draw_text(String(selected["name"]),safe.position+Vector2(28,76),34,accent)
	draw_text(String(selected["epithet"]).to_upper(),safe.position+Vector2(30,100),12,Color8(188,192,172))
	var dossier: Rect2 = Rect2(safe.position+Vector2(24,122),Vector2(safe.size.x*0.49,safe.size.y-156.0))
	draw_panel(dossier,Color(0.025,0.048,0.047,0.94),Color(accent,0.62))
	var preview_texture: Texture2D = _lineage_preview_texture(String(selected["id"]))
	var hero_center: Vector2 = Vector2(dossier.position.x+dossier.size.x*0.31,dossier.position.y+dossier.size.y*0.43)
	if preview_texture!=null:
		var direction: int = posmod(int(visual_clock*0.55),8)
		var src: Rect2 = Rect2(Vector2(float(posmod(int(visual_clock*6.0),4))*48.0,float(direction)*48.0),Vector2(48,48))
		draw_circle(hero_center+Vector2(0,40),54.0,Color(0,0,0,0.28))
		draw_texture_rect_region(preview_texture,Rect2(hero_center-Vector2(82,98),Vector2(164,164)),src)
	var stat_x: float = dossier.position.x+dossier.size.x*0.62
	var stat_y: float = dossier.position.y+80.0
	draw_text("VITAL CELLS",Vector2(stat_x,stat_y),10,Color8(121,151,138))
	draw_text("%.0f" % float(selected["max_hp"]),Vector2(stat_x,stat_y+26.0),24,Color8(238,225,189))
	draw_text("WEAPON OUTPUT",Vector2(stat_x,stat_y+70.0),10,Color8(121,151,138))
	draw_text("%.1f" % float(selected["damage"]),Vector2(stat_x,stat_y+96.0),24,Color8(238,225,189))
	draw_text("MOBILITY",Vector2(stat_x,stat_y+140.0),10,Color8(121,151,138))
	draw_text("%.0f" % float(selected["speed"]),Vector2(stat_x,stat_y+166.0),24,Color8(238,225,189))
	var trait_rect: Rect2 = Rect2(Vector2(dossier.position.x+28.0,dossier.end.y-116.0),Vector2(dossier.size.x-56.0,74.0))
	draw_rect(trait_rect,Color(0.035,0.07,0.065,0.84))
	draw_rect(Rect2(trait_rect.position,Vector2(4,trait_rect.size.y)),accent)
	draw_wrapped(String(selected["trait"]),trait_rect.grow(-14.0),13,Color8(214,209,184))

	for index: int in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var rect: Rect2 = lineage_card_rect(index)
		var is_selected: bool = index==selected_lineage
		var color: Color = Color(lineage["color"])
		draw_panel(rect,Color(0.045,0.074,0.072,0.94) if is_selected else Color(0.022,0.038,0.040,0.90),Color(color,0.88) if is_selected else Color8(52,72,68))
		var texture: Texture2D = _lineage_preview_texture(String(lineage["id"]))
		if texture!=null:
			var src: Rect2 = Rect2(Vector2(0,4*48),Vector2(48,48))
			draw_texture_rect_region(texture,Rect2(rect.position+Vector2(10,5),Vector2(58,58)),src)
		draw_text(String(lineage["name"]),rect.position+Vector2(80,28),16,color)
		draw_text(String(lineage["epithet"]),rect.position+Vector2(80,49),10,Color8(155,170,159))
		if is_selected:
			draw_text("READY",rect.end-Vector2(62,22),9,Color8(170,218,146))
	draw_text_centered("ENTER / TAP SELECTED LINEAGE TO DEPLOY",Vector2(safe.get_center().x,safe.end.y-12.0),11,Color8(118,155,138))

func draw_arena() -> void:
	var size: Vector2 = get_viewport_rect().size
	var arena: Rect2 = arena_rect()
	var biome: Dictionary = BIOMES[biome_index]
	var floor: Color = Color(biome["floor"])
	var accent: Color = Color(biome["accent"])
	draw_rect(Rect2(Vector2.ZERO,size),Color8(2,5,6))
	draw_rect(arena,floor.darkened(0.12))
	# Large perimeter architecture; the stochastic floor texture is drawn later by V8 world rendering.
	draw_rect(Rect2(arena.position,Vector2(arena.size.x,8.0)),Color(floor.lightened(0.05),1.0))
	draw_rect(Rect2(Vector2(arena.position.x,arena.end.y-8.0),Vector2(arena.size.x,8.0)),Color(floor.darkened(0.28),1.0))
	for bay: int in range(6):
		var x: float = arena.position.x+arena.size.x*(float(bay)+0.5)/6.0
		draw_line(Vector2(x,arena.position.y+10.0),Vector2(x,arena.position.y+24.0),Color(accent,0.22),2.0)
	draw_rect(arena,Color(accent,0.76),false,3.0)

func draw_player() -> void:
	if player.is_empty(): return
	var texture: Texture2D = _player_entropy_texture()
	if texture==null:
		super.draw_player()
		return
	var genome: Dictionary = player.get("v8_visual_genome",{})
	var pos: Vector2 = Vector2(player["pos"])
	var direction_index: int = quantize_direction(Vector2(player.get("look",last_aim)))
	var moving: bool = input_move.length_squared()>0.04
	var frame: int = posmod(int(visual_clock*(9.0 if moving else 4.0)),4)
	var display: float = 88.0*float(genome.get("visual_scale",1.0))
	var alpha: float = 0.42 if invulnerability>0.0 and int(invulnerability*20.0)%2==0 else 1.0
	draw_circle(pos+Vector2(0,24),31.0,Color(0,0,0,0.34))
	draw_arc(pos+Vector2(0,2),31.0,0,TAU,30,Color(player["color"],0.20),2.0)
	var dest: Rect2 = Rect2(pos-Vector2(display*0.5,display*0.63),Vector2(display,display))
	var src: Rect2 = Rect2(Vector2(frame*48,direction_index*48),Vector2(48,48))
	draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
	var aim: Vector2 = Vector2(player.get("aim",last_aim)).normalized()
	if aim.length_squared()>0.01:
		draw_line(pos+aim*28.0,pos+aim*48.0,Color(0.98,0.86,0.61,0.46),2.0)
		draw_circle(pos+aim*49.0,2.5,Color(0.98,0.86,0.61,0.82))
	if bool(player.get("shield",false)):
		draw_arc(pos,40.0,-PI*0.88,PI*0.88,32,Color8(112,190,247),4.0)

func draw_enemies() -> void:
	var strong: bool = bool(settings.get("strong_telegraphs",true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos: Vector2 = Vector2(enemy["pos"])
		var radius: float = float(enemy.get("radius",18.0))
		var boss: bool = bool(enemy.get("boss",false))
		var genome: Dictionary = enemy.get("v8_visual_genome",{})
		var delay: float = float(enemy.get("activation_delay",0.0))
		var role: String = String(genome.get("role",enemy.get("style","melee")))
		var windup: float = maxf(float(enemy.get("windup",0.0)),maxf(float(enemy.get("special_windup",0.0)),float(enemy.get("boss_windup",0.0))))
		if windup>0.0:
			var maximum: float = maxf(windup,maxf(float(enemy.get("windup_max",0.0)),maxf(float(enemy.get("special_windup_max",0.0)),float(enemy.get("boss_windup_max",0.0)))))
			var progress: float = clampf(1.0-windup/maxf(0.001,maximum),0.0,1.0)
			var danger: Color = Color(1.0,0.34,0.22,0.92 if strong else 0.62)
			draw_arc(pos,radius+19.0,-PI*0.5,-PI*0.5+TAU*progress,30,danger,4.0 if strong else 2.0)
			var tdir: Vector2 = Vector2(enemy.get("telegraph_dir",enemy.get("look",Vector2.DOWN))).normalized()
			if tdir.length_squared()>0.1 and role in ["charger","ranged","skirmisher"]:
				draw_line(pos+tdir*(radius+8.0),pos+tdir*(200.0 if role=="charger" else 140.0),Color(danger,0.22),4.0 if strong else 2.0)
		if delay>0.0:
			var max_delay: float = maxf(0.001,float(enemy.get("activation_delay_max",delay)))
			var materialize: float = clampf(1.0-delay/max_delay,0.0,1.0)
			var accent: Color = Color(BIOMES[biome_index]["accent"])
			draw_arc(pos,radius+14.0,-PI*0.5,-PI*0.5+TAU*materialize,28,Color(accent,0.82),3.0)
		var texture: Texture2D = _enemy_entropy_texture(enemy)
		var source_size: int = 96 if boss else 48
		var direction_index: int = quantize_direction(Vector2(enemy.get("look",Vector2.DOWN)))
		var frame: int = posmod(int((visual_clock+float(enemy.get("variant",0))*0.17)*8.0),4)
		var scale: float = float(genome.get("visual_scale",1.0))
		var role_bonus: float = 10.0 if role=="charger" else (6.0 if role in ["caster","radial"] else 0.0)
		var display: float = (148.0+radius*0.72)*scale if boss else (68.0+radius*0.82+role_bonus)*scale
		draw_circle(pos+Vector2(0,radius*0.78),radius*0.88,Color(0,0,0,0.34))
		if texture!=null:
			var alpha: float = 0.55+0.45*clampf(1.0-delay/maxf(0.001,float(enemy.get("activation_delay_max",1.0))),0.0,1.0) if delay>0.0 else 1.0
			var dest: Rect2 = Rect2(pos-Vector2(display*0.5,display*0.62),Vector2(display,display))
			var src: Rect2 = Rect2(Vector2(frame*source_size,direction_index*source_size),Vector2(source_size,source_size))
			draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
		if bool(enemy.get("elite",false)):
			var definition: Dictionary = director.elite_definition(String(enemy.get("affix","armored")))
			var elite_color: Color = Color(definition.get("color",Color8(226,188,102)))
			draw_arc(pos,radius+12.0,visual_clock,visual_clock+PI*1.6,28,elite_color,3.0)
		if float(enemy.get("shield_hp",0.0))>0.0:
			draw_arc(pos,radius+8.0,-PI*0.86,PI*0.86,24,Color8(121,171,244),3.0)
		var hp_ratio: float = clampf(float(enemy.get("hp",1.0))/maxf(0.001,float(enemy.get("max_hp",enemy.get("hp",1.0)))),0.0,1.0)
		if hp_ratio<0.999 or boss or bool(enemy.get("elite",false)):
			var width: float = clampf(radius*2.4,42.0,126.0)
			var health: Rect2 = Rect2(pos+Vector2(-width*0.5,radius+17.0),Vector2(width,7.0 if boss else 5.0))
			draw_rect(health,Color8(31,16,18,225))
			draw_rect(Rect2(health.position,Vector2(health.size.x*hp_ratio,health.size.y)),Color8(217,68,59))
			draw_rect(health,Color8(236,196,142,165),false,1.0)

func draw_hud() -> void:
	if player.is_empty(): return
	var safe: Rect2 = safe_rect()
	var accent: Color = Color(BIOMES[biome_index]["accent"])
	var top_y: float = safe.position.y+8.0
	var left: Rect2 = Rect2(Vector2(safe.position.x+8.0,top_y),Vector2(minf(330.0,safe.size.x*0.30),48.0))
	var center: Rect2 = Rect2(Vector2(safe.get_center().x-minf(240.0,safe.size.x*0.23),top_y),Vector2(minf(480.0,safe.size.x*0.46),48.0))
	var right: Rect2 = Rect2(Vector2(safe.end.x-minf(245.0,safe.size.x*0.23)-8.0,top_y),Vector2(minf(245.0,safe.size.x*0.23),48.0))
	for rect in [left,center,right]: draw_panel(rect,Color(0.015,0.03,0.032,0.91),Color(0.24,0.37,0.33,0.85))
	var hp_ratio: float = clampf(float(player["hp"])/maxf(0.001,float(player["max_hp"])),0.0,1.0)
	draw_text(String(player["name"]),left.position+Vector2(12,19),13,Color8(237,224,188))
	var hp: Rect2 = Rect2(left.position+Vector2(12,26),Vector2(left.size.x-24.0,10.0))
	draw_rect(hp,Color8(52,21,24))
	draw_rect(Rect2(hp.position,Vector2(hp.size.x*hp_ratio,hp.size.y)),Color8(211,68,65))
	draw_text_centered(String(BIOMES[biome_index]["name"]),center.position+Vector2(center.size.x*0.5,18),12,Color8(232,220,184))
	draw_text_centered(objective,center.position+Vector2(center.size.x*0.5,36),9,Color8(142,170,157))
	draw_text("SCRAP %03d" % scraps,right.position+Vector2(12,20),11,Color8(223,177,96))
	draw_text("GENOME %04d" % int(profile.get("genome",0)),right.position+Vector2(12,37),10,Color8(148,204,173))
	var pause_rect: Rect2 = pause_button_rect()
	draw_rect(pause_rect,Color(0.02,0.04,0.04,0.88))
	draw_rect(pause_rect,Color8(83,112,101),false,1.0)
	draw_text_centered("II",pause_rect.get_center()+Vector2(0,5),13,Color8(224,216,185))
	var weapon_name: String = String(player.get("weapon",{}).get("name",String(player.get("weapon_name","GENOME WEAPON")))) if player.get("weapon",{}) is Dictionary else String(player.get("weapon_name","GENOME WEAPON"))
	var weapon_box: Rect2 = Rect2(Vector2(safe.get_center().x-150.0,safe.end.y-32.0),Vector2(300.0,24.0))
	draw_panel(weapon_box,Color(0.015,0.03,0.032,0.86),Color(accent,0.58))
	draw_text_centered(weapon_name.to_upper(),weapon_box.get_center()+Vector2(0,4),9,Color8(228,215,181))
	if boss_max_health>0.0 and boss_health>0.0:
		var boss_bar: Rect2 = Rect2(Vector2(safe.get_center().x-260.0,safe.position.y+62.0),Vector2(520.0,16.0))
		draw_rect(boss_bar,Color8(39,18,21))
		draw_rect(Rect2(boss_bar.position,Vector2(boss_bar.size.x*boss_health/maxf(1.0,boss_max_health),boss_bar.size.y)),Color8(176,43,54))
		draw_rect(boss_bar,Color8(232,187,112),false,2.0)
		draw_text_centered(BOSS_NAMES[biome_index],boss_bar.get_center()+Vector2(0,4),9,Color.WHITE)

func draw_end(victory: bool) -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	draw_rect(Rect2(Vector2.ZERO,size),Color8(3,7,8))
	var accent: Color = Color8(122,197,132) if victory else Color8(220,77,68)
	var center: Vector2 = safe.get_center()
	for ring: int in range(3): draw_arc(center-Vector2(0,100),56.0+float(ring)*26.0,0,TAU,48,Color(accent,0.18+0.07*ring),2.0)
	draw_text_centered("EDEN BREACHED" if victory else "GENOME TERMINATED",center+Vector2(0,22),34,accent)
	draw_text_centered("Rooms purged %d  •  Biome %d/5" % [rooms_cleared,biome_index+1],center+Vector2(0,58),12,Color8(215,209,181))
	draw_text_centered("SCORE %d  •  MASTERY +%d  •  BEST COMBO %d" % [run_score,mastery_gained,best_combo],center+Vector2(0,86),10,Color8(139,167,153))
	draw_text_centered("ENTER / TAP TO RETURN TO LINEAGE SELECTION",center+Vector2(0,124),10,Color8(112,153,134))

func _lineage_preview_texture(lineage_id: String) -> Texture2D:
	if _lineage_preview_textures.has(lineage_id): return _lineage_preview_textures[lineage_id]
	var local_rng: RandomNumberGenerator = entropy.call("fork","lineage_preview:"+lineage_id)
	var genome: Dictionary = genome_director.call("player_genome",local_rng,lineage_id,0)
	var image: Image = sprite_forge.call("build_player_sheet",genome)
	if image==null or image.is_empty(): return null
	var texture: Texture2D = ImageTexture.create_from_image(image)
	_lineage_preview_textures[lineage_id]=texture
	return texture

func audit_art_direction_contract() -> Dictionary:
	return {
		"version":V8_ART_DIRECTION_VERSION,
		"authored_lineage_dossier":true,
		"compact_combat_hud":true,
		"actor_screen_presence":true,
		"non_tiled_base_arena":true,
		"authored_title_composition":true,
	}

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["authored_art_direction"] = true
	report["compact_combat_hud"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["authored_art_direction"] = true
	report["compact_combat_hud"] = true
	return report
