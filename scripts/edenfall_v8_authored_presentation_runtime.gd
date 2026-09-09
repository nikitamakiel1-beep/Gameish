extends "res://scripts/edenfall_v8_art_integrated_runtime.gd"

const AUTHORED_PRESENTATION_VERSION: String = "0.6.3-art3"

func title_option_rect(index: int) -> Rect2:
	var safe: Rect2 = safe_rect()
	var width: float = minf(390.0,safe.size.x*0.34)
	var height: float = 46.0
	var x: float = safe.position.x+48.0
	var y: float = safe.position.y+safe.size.y*0.46+float(index)*51.0
	if safe.size.x < 860.0:
		width = safe.size.x-36.0
		x = safe.position.x+18.0
		y = safe.position.y+safe.size.y*0.45+float(index)*48.0
	return Rect2(Vector2(x,y),Vector2(width,height))

func lineage_card_rect(index: int) -> Rect2:
	var safe: Rect2 = safe_rect()
	if safe.size.x < 900.0:
		var width: float = (safe.size.x-38.0)*0.5
		var column: int = index%2
		var row: int = index/2
		return Rect2(Vector2(safe.position.x+12.0+float(column)*(width+10.0),safe.position.y+safe.size.y*0.58+float(row)*55.0),Vector2(width,48.0))
	var strip_x: float = safe.position.x+safe.size.x*0.60
	var strip_w: float = safe.end.x-strip_x-30.0
	return Rect2(Vector2(strip_x,safe.position.y+132.0+float(index)*74.0),Vector2(strip_w,62.0))

func draw_title() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	draw_rect(Rect2(Vector2.ZERO,size),Color8(3,7,8))
	# Reclaimed city + laboratory silhouette. Large shapes stay quiet and asymmetrical.
	var horizon_y: float = safe.end.y-122.0
	draw_rect(Rect2(Vector2(safe.position.x,horizon_y),Vector2(safe.size.x,2.0)),Color(0.19,0.34,0.28,0.24))
	for tower: int in range(10):
		var width: float = 34.0+float((tower*17)%34)
		var height: float = 64.0+float((tower*53)%156)
		var x: float = safe.position.x+safe.size.x*0.50+float(tower)*safe.size.x*0.048
		var rect: Rect2 = Rect2(Vector2(x,horizon_y-height),Vector2(width,height))
		draw_rect(rect,Color(0.035,0.075,0.066,0.62))
		if tower%3==0:
			draw_line(Vector2(rect.get_center().x,rect.position.y),Vector2(rect.get_center().x,rect.position.y-18.0),Color(0.28,0.53,0.36,0.22),2.0)
	for vine: int in range(7):
		var root: Vector2 = Vector2(safe.position.x+safe.size.x*(0.52+float(vine)*0.055),horizon_y-float((vine*37)%90))
		var tip: Vector2 = root+Vector2(-14.0+float(vine%3)*12.0,-42.0-float((vine*19)%45))
		draw_line(root,tip,Color(0.22,0.46,0.27,0.24),3.0)
		draw_circle(tip,3.0,Color(0.34,0.62,0.35,0.28))

	var title_pos: Vector2 = safe.position+Vector2(48.0,88.0)
	draw_text("EDEN//FALL",title_pos,52,Color8(238,222,181))
	draw_text("THE FIRST GENOME WAS NEVER HUMAN",title_pos+Vector2(2,34),13,Color8(125,157,143))
	draw_text("EXCURSION BUILD  •  AUTHORED HEROES  •  STOCHASTIC WORLD",title_pos+Vector2(2,58),9,Color8(84,126,105))

	var options: Array[String] = title_options()
	for index: int in range(options.size()):
		var rect: Rect2 = title_option_rect(index)
		var selected: bool = index==menu_index
		var fill: Color = Color(0.055,0.105,0.092,0.96) if selected else Color(0.018,0.035,0.036,0.92)
		var border: Color = Color8(163,211,137) if selected else Color8(48,69,64)
		draw_panel(rect,fill,border)
		if selected:
			draw_rect(Rect2(rect.position,Vector2(5.0,rect.size.y)),Color8(156,211,127))
		draw_text(String(options[index]),rect.position+Vector2(17.0,29.0),13,Color8(238,225,191) if selected else Color8(162,181,169))

	# Canonical cast lineup reinforces identity stability before selection.
	var lineup_origin: Vector2 = Vector2(safe.position.x+safe.size.x*0.61,safe.position.y+safe.size.y*0.34)
	for index: int in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var texture: Texture2D = _lineage_preview_texture(String(lineage["id"]))
		var x: float = lineup_origin.x+float(index)*76.0
		if texture!=null:
			var src: Rect2 = Rect2(Vector2(0,4*48),Vector2(48,48))
			draw_circle(Vector2(x,lineup_origin.y+45.0),27.0,Color(0,0,0,0.25))
			draw_texture_rect_region(texture,Rect2(Vector2(x-31.0,lineup_origin.y-18.0),Vector2(62.0,62.0)),src,Color(1,1,1,0.90))
		draw_text_centered(String(lineage["name"]),Vector2(x,lineup_origin.y+67.0),9,Color(lineage["color"]))

func draw_select() -> void:
	var size: Vector2 = get_viewport_rect().size
	var safe: Rect2 = safe_rect()
	var selected: Dictionary = LINEAGES[selected_lineage]
	var accent: Color = Color(selected["color"])
	draw_rect(Rect2(Vector2.ZERO,size),Color8(3,7,8))
	# Left: hero showcase. Right: compact roster. No giant empty framed boxes.
	draw_text("ENGINEERED LINEAGE",safe.position+Vector2(28,34),11,Color8(101,143,125))
	draw_text(String(selected["name"]),safe.position+Vector2(28,73),32,accent)
	draw_text(String(selected["epithet"]).to_upper(),safe.position+Vector2(29,98),11,Color8(187,190,170))
	var showcase: Rect2 = Rect2(safe.position+Vector2(22,120),Vector2(safe.size.x*0.52,safe.size.y-158.0))
	draw_rect(showcase,Color(0.018,0.035,0.035,0.74))
	draw_rect(showcase,Color(accent,0.42),false,1.0)
	var hero_center: Vector2 = Vector2(showcase.position.x+showcase.size.x*0.34,showcase.position.y+showcase.size.y*0.45)
	var preview: Texture2D = _lineage_preview_texture(String(selected["id"]))
	if preview!=null:
		var direction: int = posmod(int(visual_clock*0.42),8)
		var frame: int = posmod(int(visual_clock*5.5),4)
		var src: Rect2 = Rect2(Vector2(float(frame)*48.0,float(direction)*48.0),Vector2(48,48))
		draw_circle(hero_center+Vector2(0,43),48.0,Color(0,0,0,0.30))
		draw_texture_rect_region(preview,Rect2(hero_center-Vector2(76,86),Vector2(152,152)),src)
	var stat_x: float = showcase.position.x+showcase.size.x*0.61
	var stat_y: float = showcase.position.y+84.0
	for stat: Dictionary in [
		{"label":"VITAL CELLS","value":"%.0f"%float(selected["max_hp"])},
		{"label":"WEAPON OUTPUT","value":"%.1f"%float(selected["damage"])},
		{"label":"MOBILITY","value":"%.0f"%float(selected["speed"])}
	]:
		draw_text(String(stat["label"]),Vector2(stat_x,stat_y),9,Color8(113,146,132))
		draw_text(String(stat["value"]),Vector2(stat_x,stat_y+24.0),22,Color8(236,222,185))
		stat_y+=72.0
	var trait_rect: Rect2 = Rect2(Vector2(showcase.position.x+24.0,showcase.end.y-92.0),Vector2(showcase.size.x-48.0,60.0))
	draw_rect(trait_rect,Color(0.03,0.058,0.054,0.86))
	draw_rect(Rect2(trait_rect.position,Vector2(4,trait_rect.size.y)),accent)
	draw_wrapped(String(selected["trait"]),trait_rect.grow(-13.0),12,Color8(214,209,184))

	for index: int in range(LINEAGES.size()):
		var lineage: Dictionary = LINEAGES[index]
		var rect: Rect2 = lineage_card_rect(index)
		var is_selected: bool = index==selected_lineage
		var color: Color = Color(lineage["color"])
		draw_rect(rect,Color(0.045,0.078,0.072,0.94) if is_selected else Color(0.015,0.028,0.030,0.91))
		draw_rect(rect,Color(color,0.80) if is_selected else Color8(45,65,61),false,1.0)
		if is_selected:
			draw_rect(Rect2(rect.position,Vector2(4,rect.size.y)),color)
		var texture: Texture2D = _lineage_preview_texture(String(lineage["id"]))
		if texture!=null:
			var src: Rect2 = Rect2(Vector2(0,4*48),Vector2(48,48))
			draw_texture_rect_region(texture,Rect2(rect.position+Vector2(8,3),Vector2(54,54)),src)
		draw_text(String(lineage["name"]),rect.position+Vector2(70,25),15,color)
		draw_text(String(lineage["epithet"]),rect.position+Vector2(70,44),9,Color8(147,164,153))
		if is_selected:
			draw_text("READY",rect.end-Vector2(54,19),8,Color8(169,217,145))
	draw_text_centered("ENTER / TAP TO DEPLOY",Vector2(showcase.get_center().x,safe.end.y-10.0),10,Color8(113,151,134))

func draw_hud() -> void:
	if player.is_empty():
		return
	var safe: Rect2 = safe_rect()
	var accent: Color = Color(BIOMES[biome_index]["accent"])
	var hp_ratio: float = clampf(float(player["hp"])/maxf(0.001,float(player["max_hp"])),0.0,1.0)
	var identity: Rect2 = Rect2(safe.position+Vector2(8,7),Vector2(minf(286.0,safe.size.x*0.28),44.0))
	draw_rect(identity,Color(0.01,0.024,0.026,0.90))
	draw_rect(identity,Color(0.25,0.39,0.34,0.76),false,1.0)
	var icon: Texture2D = _player_entropy_texture()
	if icon!=null:
		var src: Rect2 = Rect2(Vector2(0,4*48),Vector2(48,48))
		draw_texture_rect_region(icon,Rect2(identity.position+Vector2(5,4),Vector2(36,36)),src)
	draw_text(String(player["name"]),identity.position+Vector2(47,18),12,Color8(237,224,188))
	var hp: Rect2 = Rect2(identity.position+Vector2(47,25),Vector2(identity.size.x-57.0,9.0))
	draw_rect(hp,Color8(48,19,23))
	draw_rect(Rect2(hp.position,Vector2(hp.size.x*hp_ratio,hp.size.y)),Color8(211,66,64))

	var objective_pos: Vector2 = Vector2(safe.get_center().x,safe.position.y+22.0)
	draw_text_centered(String(BIOMES[biome_index]["name"]),objective_pos,11,Color8(232,219,184))
	draw_text_centered(objective,objective_pos+Vector2(0,18),8,Color8(127,157,144))

	var resource: Rect2 = Rect2(Vector2(safe.end.x-218.0,safe.position.y+7.0),Vector2(210.0,44.0))
	draw_rect(resource,Color(0.01,0.024,0.026,0.90))
	draw_rect(resource,Color(0.25,0.39,0.34,0.76),false,1.0)
	draw_text("SCRAP %03d"%scraps,resource.position+Vector2(11,18),10,Color8(223,177,96))
	draw_text("GENOME %04d"%int(profile.get("genome",0)),resource.position+Vector2(11,34),9,Color8(148,204,173))
	var pause_rect: Rect2 = pause_button_rect()
	draw_rect(pause_rect,Color(0.015,0.03,0.03,0.90))
	draw_rect(pause_rect,Color8(80,111,99),false,1.0)
	draw_text_centered("II",pause_rect.get_center()+Vector2(0,4),12,Color8(225,216,185))

	var weapon_name: String = String(player.get("weapon",{}).get("name",String(player.get("weapon_name","GENOME WEAPON")))) if player.get("weapon",{}) is Dictionary else String(player.get("weapon_name","GENOME WEAPON"))
	var weapon_box: Rect2 = Rect2(Vector2(safe.get_center().x-120.0,safe.end.y-27.0),Vector2(240.0,20.0))
	draw_rect(weapon_box,Color(0.012,0.026,0.027,0.84))
	draw_rect(weapon_box,Color(accent,0.48),false,1.0)
	draw_text_centered(weapon_name.to_upper(),weapon_box.get_center()+Vector2(0,3),8,Color8(226,214,181))

	if boss_max_health>0.0 and boss_health>0.0:
		var boss_bar: Rect2 = Rect2(Vector2(safe.get_center().x-220.0,safe.position.y+56.0),Vector2(440.0,12.0))
		draw_rect(boss_bar,Color8(38,17,20))
		draw_rect(Rect2(boss_bar.position,Vector2(boss_bar.size.x*boss_health/maxf(1.0,boss_max_health),boss_bar.size.y)),Color8(177,43,53))
		draw_rect(boss_bar,Color8(226,182,108),false,1.0)
		draw_text_centered(BOSS_NAMES[biome_index],boss_bar.get_center()+Vector2(0,3),8,Color.WHITE)

func audit_art_direction_contract() -> Dictionary:
	var report: Dictionary = super.audit_art_direction_contract()
	report["authored_presentation_version"] = AUTHORED_PRESENTATION_VERSION
	report["hero_first_selection"] = true
	report["vertical_title_menu"] = true
	report["reduced_ui_chrome"] = true
	report["compact_icon_hud"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["authored_presentation"] = true
	report["reduced_ui_chrome"] = true
	return report
