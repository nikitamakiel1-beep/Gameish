extends "res://scripts/v8/procedural_sprite_forge_premium.gd"

const ROGUELIKE_FORGE_VERSION: String = "0.6.3-authored"

func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	var role: String = String(genome.get("role","melee"))
	var silhouette: String = String(genome.get("silhouette_key",role))
	var lineage: String = String(genome.get("lineage",""))
	var category: String = String(genome.get("category","preadamic"))
	var perp: Vector2 = Vector2(-direction.y,direction.x)
	var foot_y: int = center.y + 8 * scale
	var body_center_y: int = foot_y - 11 * scale
	var torso_w: int = 12 * scale
	var torso_h: int = 11 * scale
	if role == "charger":
		torso_w = 17 * scale
		torso_h = 12 * scale
	elif role == "caster":
		torso_w = 12 * scale
		torso_h = 13 * scale
	elif role == "skirmisher":
		torso_w = 10 * scale
	elif silhouette.find("giant") >= 0 or silhouette.find("colossus") >= 0:
		torso_w = 18 * scale
		torso_h = 13 * scale
	if not lineage.is_empty():
		match lineage:
			"cain": torso_w = 15 * scale
			"seth": torso_w = 14 * scale
			"abel", "naamah": torso_h = 13 * scale
			_:
				pass

	# Compact cast shadow and short legs keep the character readable as a game sprite.
	_fill_ellipse(image,Vector2i(center.x,foot_y+2*scale),maxi(7*scale,int(torso_w*0.62)),3*scale,Color(0,0,0,0.34))
	var walk_phase: int = -1 if frame_index == 1 else (1 if frame_index == 3 else 0)
	for side_variant in [-1,1]:
		var side: int = int(side_variant)
		var leg_x: int = center.x + side * 3 * scale + side * walk_phase * scale
		var leg_y: int = foot_y - 6 * scale
		_fill_rect(image,Rect2i(leg_x-2*scale,leg_y,4*scale,7*scale),outline)
		_fill_rect(image,Rect2i(leg_x-scale,leg_y,2*scale,5*scale),secondary.darkened(0.18))
		_fill_rect(image,Rect2i(leg_x-2*scale,foot_y-2*scale,5*scale,3*scale),outline)

	var torso: Rect2i = Rect2i(center.x-int(torso_w/2),body_center_y-int(torso_h/2),torso_w,torso_h)
	_fill_rect(image,torso.grow(scale),outline)
	_fill_rect(image,torso,primary)
	_fill_rect(image,Rect2i(torso.position+Vector2i(scale,scale),Vector2i(maxi(scale,torso.size.x-2*scale),2*scale)),primary.lightened(0.16))
	_fill_rect(image,Rect2i(torso.position+Vector2i(scale,torso.size.y-3*scale),Vector2i(maxi(scale,torso.size.x-2*scale),2*scale)),primary.darkened(0.24))
	_draw_compact_chest(image,torso,role,silhouette,lineage,secondary,accent,outline,scale)

	# Large head: readable expression/facing at gameplay scale without pseudo-real anatomy.
	var head: Vector2i = Vector2i(center.x,torso.position.y-6*scale)
	var head_rx: int = 7 * scale
	var head_ry: int = 6 * scale
	if role == "charger":
		head_rx = 6 * scale
	if silhouette.find("giant") >= 0:
		head_rx = 8 * scale
	_fill_ellipse(image,head,head_rx+2*scale,head_ry+2*scale,outline)
	_fill_ellipse(image,head,head_rx,head_ry,skin)
	_draw_chunky_head(image,head,direction,silhouette,lineage,genome,primary,secondary,accent,outline,scale)

	# Shoulder/role mass is deliberately sparse: a few large pixels beat random micro-detail.
	if role == "charger" or silhouette.find("sentinel") >= 0:
		for side_variant in [-1,1]:
			var side: int = int(side_variant)
			var shoulder: Vector2i = Vector2i(torso.get_center().x+side*(int(torso_w/2)+3*scale),torso.position.y+3*scale)
			_fill_rect(image,Rect2i(shoulder.x-4*scale,shoulder.y-3*scale,8*scale,6*scale),outline)
			_fill_rect(image,Rect2i(shoulder.x-3*scale,shoulder.y-2*scale,6*scale,4*scale),secondary)

	_draw_chunky_weapon(image,torso.get_center(),direction,perp,frame_index,role,silhouette,lineage,genome,secondary,accent,outline,scale)
	_draw_family_mark(image,torso,head,direction,perp,category,silhouette,lineage,genome,secondary,accent,outline,scale)

func _draw_compact_chest(image: Image, torso: Rect2i, role: String, silhouette: String, lineage: String, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	if role == "caster":
		_fill_rect(image,Rect2i(torso.position.x+2*scale,torso.position.y+4*scale,maxi(2*scale,torso.size.x-4*scale),torso.size.y-3*scale),secondary.darkened(0.12))
		_fill_rect(image,Rect2i(torso.position.x-scale,torso.end.y-3*scale,torso.size.x+2*scale,3*scale),outline)
	elif role == "charger":
		_fill_rect(image,Rect2i(torso.position.x+2*scale,torso.position.y+3*scale,maxi(2*scale,torso.size.x-4*scale),4*scale),secondary.darkened(0.18))
		_fill_rect(image,Rect2i(torso.position.x-scale,torso.get_center().y-scale,torso.size.x+2*scale,2*scale),outline)
	else:
		_fill_rect(image,Rect2i(torso.position.x+2*scale,torso.position.y+3*scale,maxi(2*scale,torso.size.x-4*scale),3*scale),secondary.darkened(0.08))
	if lineage == "cain" or silhouette.find("gunner") >= 0:
		_fill_rect(image,Rect2i(torso.position.x+2*scale,torso.end.y-4*scale,maxi(2*scale,torso.size.x-4*scale),2*scale),accent)
	elif lineage == "seth":
		_fill_rect(image,Rect2i(torso.get_center().x-scale,torso.position.y+2*scale,2*scale,torso.size.y-4*scale),accent)
	elif lineage == "naamah":
		_circle(image,torso.get_center(),2*scale,accent)

func _draw_chunky_head(image: Image, head: Vector2i, direction: Vector2, silhouette: String, lineage: String, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	if lineage == "abel":
		_fill_rect(image,Rect2i(head.x-6*scale,head.y-6*scale,12*scale,3*scale),Color8(224,205,146))
	elif lineage == "cain":
		_fill_rect(image,Rect2i(head.x-7*scale,head.y-6*scale,14*scale,5*scale),outline)
		_fill_rect(image,Rect2i(head.x-5*scale,head.y-4*scale,10*scale,3*scale),primary.darkened(0.12))
	elif lineage == "seth":
		_fill_rect(image,Rect2i(head.x-7*scale,head.y-5*scale,14*scale,5*scale),outline)
		_fill_rect(image,Rect2i(head.x-5*scale,head.y-3*scale,10*scale,2*scale),secondary)
	elif lineage == "naamah":
		_fill_rect(image,Rect2i(head.x-6*scale,head.y-6*scale,12*scale,3*scale),primary.darkened(0.12))
		_circle(image,head-Vector2i(4*scale,6*scale),2*scale,accent)
		_circle(image,head+Vector2i(4*scale,-6*scale),2*scale,accent)
	elif silhouette.find("cultist") >= 0 or silhouette.find("caster") >= 0:
		_fill_rect(image,Rect2i(head.x-7*scale,head.y-6*scale,14*scale,7*scale),outline)
		_fill_rect(image,Rect2i(head.x-5*scale,head.y-4*scale,10*scale,4*scale),primary.darkened(0.18))
	elif silhouette.find("hunter") >= 0:
		_fill_rect(image,Rect2i(head.x-8*scale,head.y-6*scale,16*scale,3*scale),outline)
		_fill_rect(image,Rect2i(head.x-7*scale,head.y-5*scale,14*scale,2*scale),primary)
	elif silhouette.find("brute") >= 0 or silhouette.find("giant") >= 0:
		_fill_rect(image,Rect2i(head.x-7*scale,head.y-5*scale,14*scale,5*scale),outline)
		_fill_rect(image,Rect2i(head.x-5*scale,head.y-3*scale,10*scale,2*scale),secondary)
	else:
		var style: int = int(genome.get("head_style",0))
		if style % 2 == 0:
			_fill_rect(image,Rect2i(head.x-6*scale,head.y-6*scale,12*scale,3*scale),primary.darkened(0.16))
		else:
			_fill_rect(image,Rect2i(head.x-6*scale,head.y-4*scale,12*scale,4*scale),outline)
			_fill_rect(image,Rect2i(head.x-4*scale,head.y-2*scale,8*scale,2*scale),secondary)
	var eye_center: Vector2i = head + Vector2i(roundi(direction.x*4.0*scale),roundi(direction.y*2.0*scale))
	_fill_rect(image,Rect2i(eye_center.x-scale,eye_center.y-scale,2*scale,2*scale),accent)

func _draw_chunky_weapon(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, role: String, silhouette: String, lineage: String, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var recoil: float = 2.0*float(scale) if frame_index == 2 else 0.0
	var grip_v: Vector2 = Vector2(chest) + perp*4.0*float(scale) - direction*recoil
	var grip: Vector2i = Vector2i(roundi(grip_v.x),roundi(grip_v.y))
	if role == "caster":
		var tip_v: Vector2 = Vector2(grip)+direction*17.0*float(scale)
		var tip: Vector2i = Vector2i(roundi(tip_v.x),roundi(tip_v.y))
		_line(image,grip,tip,outline,4*scale)
		_line(image,grip,tip,secondary,2*scale)
		_circle(image,tip,3*scale,outline)
		_circle(image,tip,2*scale,accent)
		return
	if role == "melee":
		var tip_v: Vector2 = Vector2(grip)+direction*16.0*float(scale)
		var tip: Vector2i = Vector2i(roundi(tip_v.x),roundi(tip_v.y))
		_line(image,grip,tip,outline,5*scale)
		_line(image,grip,tip,Color8(222,211,174),2*scale)
		return
	if role == "charger":
		var shield_v: Vector2 = Vector2(chest)+direction*8.0*float(scale)
		var shield: Vector2i = Vector2i(roundi(shield_v.x),roundi(shield_v.y))
		_fill_rect(image,Rect2i(shield.x-6*scale,shield.y-7*scale,12*scale,14*scale),outline)
		_fill_rect(image,Rect2i(shield.x-4*scale,shield.y-5*scale,8*scale,10*scale),secondary.darkened(0.12))
		_fill_rect(image,Rect2i(shield.x-scale,shield.y-4*scale,2*scale,8*scale),accent)
		return
	if role == "skirmisher":
		for side_variant in [-1,1]:
			var side: int = int(side_variant)
			var gun_grip_v: Vector2 = Vector2(chest)+perp*float(side)*5.0*float(scale)
			var gun_tip_v: Vector2 = gun_grip_v+direction*12.0*float(scale)
			var gun_grip: Vector2i = Vector2i(roundi(gun_grip_v.x),roundi(gun_grip_v.y))
			var gun_tip: Vector2i = Vector2i(roundi(gun_tip_v.x),roundi(gun_tip_v.y))
			_line(image,gun_grip,gun_tip,outline,4*scale)
			_line(image,gun_grip,gun_tip,accent,2*scale)
		return
	var heavy: bool = lineage == "cain" or silhouette.find("gunner") >= 0 or int(genome.get("weapon_style",0)) == 5
	var length: float = 23.0 if heavy else 17.0
	var tip_v: Vector2 = Vector2(grip)+direction*length*float(scale)
	var tip: Vector2i = Vector2i(roundi(tip_v.x),roundi(tip_v.y))
	_line(image,grip,tip,outline,(7 if heavy else 5)*scale)
	_line(image,grip,tip,secondary,(4 if heavy else 3)*scale)
	var muzzle_a_v: Vector2 = Vector2(tip)+perp*(4.0 if heavy else 3.0)*float(scale)
	var muzzle_b_v: Vector2 = Vector2(tip)-perp*(4.0 if heavy else 3.0)*float(scale)
	_line(image,Vector2i(roundi(muzzle_a_v.x),roundi(muzzle_a_v.y)),Vector2i(roundi(muzzle_b_v.x),roundi(muzzle_b_v.y)),accent,2*scale)
	if heavy:
		var stock_v: Vector2 = Vector2(grip)-direction*7.0*float(scale)
		var stock: Vector2i = Vector2i(roundi(stock_v.x),roundi(stock_v.y))
		_fill_rect(image,Rect2i(stock.x-4*scale,stock.y-3*scale,8*scale,6*scale),outline)
		_fill_rect(image,Rect2i(stock.x-2*scale,stock.y-2*scale,4*scale,4*scale),accent.darkened(0.18))

func _draw_family_mark(image: Image, torso: Rect2i, head: Vector2i, direction: Vector2, perp: Vector2, category: String, silhouette: String, lineage: String, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	if not lineage.is_empty():
		match lineage:
			"adam":
				var leaf_root: Vector2i = torso.position+Vector2i(2*scale,2*scale)
				_line(image,leaf_root,leaf_root-Vector2i(3*scale,6*scale),Color8(85,150,83),2*scale)
				_circle(image,leaf_root-Vector2i(4*scale,7*scale),2*scale,Color8(123,188,105))
			"abel":
				_circle(image,head-Vector2i(0,7*scale),8*scale,outline,false)
				_circle(image,head-Vector2i(0,7*scale),7*scale,Color8(232,197,93),false)
			"cain":
				var pack_v: Vector2 = Vector2(torso.get_center())-direction*8.0*float(scale)
				var pack: Vector2i = Vector2i(roundi(pack_v.x),roundi(pack_v.y))
				_fill_rect(image,Rect2i(pack.x-4*scale,pack.y-4*scale,8*scale,8*scale),outline)
				_circle(image,pack,2*scale,Color8(238,50,44))
			"seth":
				for side_variant in [-1,1]:
					var side: int = int(side_variant)
					var node_v: Vector2 = Vector2(torso.get_center())+perp*float(side)*9.0*float(scale)
					var node: Vector2i = Vector2i(roundi(node_v.x),roundi(node_v.y))
					_fill_rect(image,Rect2i(node.x-2*scale,node.y-2*scale,4*scale,4*scale),outline)
					_circle(image,node,scale,Color8(91,170,238))
			"naamah":
				for bud: int in range(3):
					var p: Vector2i = head+Vector2i((bud-1)*4*scale,-6*scale-abs(bud-1)*2*scale)
					_circle(image,p,2*scale,Color8(200,86,219))
		return
	if category == "fallen":
		_circle(image,head-Vector2i(0,7*scale),7*scale,Color(accent,0.82),false)
		for side_variant in [-1,1]:
			var side: int = int(side_variant)
			var root_v: Vector2 = Vector2(torso.get_center())+perp*float(side)*7.0*float(scale)
			var tip_v: Vector2 = root_v-direction*5.0*float(scale)+perp*float(side)*6.0*float(scale)
			_line(image,Vector2i(roundi(root_v.x),roundi(root_v.y)),Vector2i(roundi(tip_v.x),roundi(tip_v.y)),outline,3*scale)
	elif category == "nephilim":
		for side_variant in [-1,1]:
			var side: int = int(side_variant)
			_line(image,head+Vector2i(side*4*scale,-3*scale),head+Vector2i(side*8*scale,-10*scale),outline,3*scale)
			_line(image,head+Vector2i(side*4*scale,-3*scale),head+Vector2i(side*8*scale,-10*scale),accent.darkened(0.16),scale)
	elif silhouette.find("feral") >= 0:
		_line(image,torso.position,torso.position-Vector2i(5*scale,4*scale),accent.darkened(0.20),2*scale)

func _draw_orbiter(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var silhouette: String = String(genome.get("silhouette_key","role_orbiter"))
	if silhouette.find("ophanim") >= 0:
		_fill_ellipse(image,center+Vector2i(0,7*scale),11*scale,3*scale,Color(0,0,0,0.30))
		_circle(image,center,12*scale,outline,false)
		_circle(image,center,8*scale,secondary,false)
		var eye: Vector2i = center+Vector2i(roundi(direction.x*5.0*scale),roundi(direction.y*5.0*scale))
		_circle(image,eye,3*scale,accent)
		for spoke: int in range(4):
			var angle: float = TAU*float(spoke)/4.0+float(frame_index)*0.08
			var a: Vector2i = center+Vector2i(roundi(cos(angle)*8.0*scale),roundi(sin(angle)*8.0*scale))
			var b: Vector2i = center+Vector2i(roundi(cos(angle)*15.0*scale),roundi(sin(angle)*15.0*scale))
			_line(image,a,b,outline,3*scale)
		return
	if silhouette.find("serpent") >= 0:
		var perp: Vector2 = Vector2(-direction.y,direction.x)
		var previous: Vector2i = center+Vector2i(roundi(direction.x*7.0*scale),roundi(direction.y*7.0*scale))
		for segment: int in range(5):
			var point_v: Vector2 = Vector2(center)-direction*float(segment*5*scale)+perp*sin(float(segment+frame_index))*3.0*float(scale)
			var point: Vector2i = Vector2i(roundi(point_v.x),roundi(point_v.y))
			if segment > 0:
				_line(image,previous,point,outline,5*scale)
				_line(image,previous,point,primary,3*scale)
			previous = point
		_circle(image,center+Vector2i(roundi(direction.x*6.0*scale),roundi(direction.y*6.0*scale)),4*scale,accent)
		return
	# Cherub/drone: compact floating body, strong wing blades.
	_fill_ellipse(image,center+Vector2i(0,7*scale),10*scale,3*scale,Color(0,0,0,0.30))
	_fill_rect(image,Rect2i(center.x-6*scale,center.y-5*scale,12*scale,10*scale),outline)
	_fill_rect(image,Rect2i(center.x-4*scale,center.y-3*scale,8*scale,6*scale),primary)
	var eye: Vector2i = center+Vector2i(roundi(direction.x*4.0*scale),roundi(direction.y*3.0*scale))
	_circle(image,eye,2*scale,accent)
	var perp: Vector2 = Vector2(-direction.y,direction.x)
	for side_variant in [-1,1]:
		var side: int = int(side_variant)
		var root_v: Vector2 = Vector2(center)+perp*float(side)*6.0*float(scale)
		var tip_v: Vector2 = root_v-direction*4.0*float(scale)+perp*float(side)*9.0*float(scale)
		_line(image,Vector2i(roundi(root_v.x),roundi(root_v.y)),Vector2i(roundi(tip_v.x),roundi(tip_v.y)),outline,4*scale)
		_line(image,Vector2i(roundi(root_v.x),roundi(root_v.y)),Vector2i(roundi(tip_v.x),roundi(tip_v.y)),secondary,2*scale)

func _draw_radial(image: Image, center: Vector2i, direction: Vector2, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	_fill_ellipse(image,center+Vector2i(0,8*scale),13*scale,4*scale,Color(0,0,0,0.32))
	_circle(image,center,12*scale,outline)
	_circle(image,center,9*scale,primary)
	_fill_rect(image,Rect2i(center.x-5*scale,center.y-3*scale,10*scale,6*scale),secondary)
	for arm: int in range(6):
		var angle: float = TAU*float(arm)/6.0+float(frame_index)*0.05
		var start: Vector2i = center+Vector2i(roundi(cos(angle)*9.0*scale),roundi(sin(angle)*9.0*scale))
		var finish: Vector2i = center+Vector2i(roundi(cos(angle)*15.0*scale),roundi(sin(angle)*15.0*scale))
		_line(image,start,finish,outline,3*scale)
	var facing: Vector2i = center+Vector2i(roundi(direction.x*11.0*scale),roundi(direction.y*11.0*scale))
	_circle(image,facing,3*scale,accent)

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["roguelike_forge_version"] = ROGUELIKE_FORGE_VERSION
	report["chunky_proportions"] = true
	report["large_head_compact_body"] = true
	report["oversized_weapon_read"] = true
	report["five_color_ramp_discipline"] = true
	report["random_microdetail"] = false
	return report
