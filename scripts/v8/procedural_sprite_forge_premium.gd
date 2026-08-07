extends "res://scripts/v8/procedural_sprite_forge.gd"

const PREMIUM_FORGE_VERSION := "0.6.2-entropy"

func _draw_humanoid(image: Image, center: Vector2i, direction: Vector2, stride: int, frame_index: int, genome: Dictionary, primary: Color, secondary: Color, accent: Color, skin: Color, outline: Color, scale: int) -> void:
	super._draw_humanoid(image,center,direction,stride,frame_index,genome,primary,secondary,accent,skin,outline,scale)
	var role := String(genome.get("role","melee"))
	var category := String(genome.get("category","preadamic"))
	var lineage := String(genome.get("lineage",""))
	var perp := Vector2(-direction.y,direction.x)
	var chest := center+Vector2i(0,-25*scale)

	match role:
		"charger":
			for side in [-1,1]:
				var shoulder := chest+Vector2i(roundi(perp.x*side*13.0*scale),roundi(perp.y*side*13.0*scale))
				_circle(image,shoulder,5*scale,outline)
				_circle(image,shoulder,3*scale,secondary.darkened(0.06))
				_line(image,shoulder,shoulder+Vector2i(roundi(direction.x*7.0*scale),roundi(direction.y*7.0*scale)),accent.darkened(0.10),2*scale)
			_fill_rect(image,Rect2i(chest.x-7*scale,chest.y-3*scale,14*scale,5*scale),outline)
			_fill_rect(image,Rect2i(chest.x-5*scale,chest.y-2*scale,10*scale,3*scale),accent.darkened(0.22))
		"caster":
			# Robe flare and ritual crown change the body read at gameplay scale.
			for row in range(5):
				var half := (6+row*2)*scale
				var y := center.y-(12-row*2)*scale
				_line(image,Vector2i(center.x-half,y),Vector2i(center.x+half,y),primary.darkened(0.08+row*0.025),2*scale)
			var crown := chest-Vector2i(0,17*scale)
			for side in [-1,0,1]:
				_line(image,crown+Vector2i(side*4*scale,2*scale),crown+Vector2i(side*7*scale,-6*scale),accent,2*scale)
			_circle(image,crown,3*scale,Color(accent,0.70),false)
		"skirmisher":
			# Long diagonal fins/scarf make fast units readable before they move.
			for side in [-1,1]:
				var root := chest+Vector2i(roundi(perp.x*side*6.0*scale),roundi(perp.y*side*6.0*scale))
				var tip := root+Vector2i(roundi((-direction.x*10.0+perp.x*side*7.0)*scale),roundi((-direction.y*10.0+perp.y*side*7.0)*scale))
				_line(image,root,tip,outline,3*scale)
				_line(image,root,tip,accent,scale)
		"ranged":
			# Ammo drum, sight and shoulder brace make gunners visually distinct.
			var drum := chest+Vector2i(roundi(-perp.x*7.0*scale),roundi(-perp.y*7.0*scale))
			_circle(image,drum,4*scale,outline)
			_circle(image,drum,2*scale,accent.darkened(0.10))
			var antenna := chest+Vector2i(roundi(perp.x*8.0*scale),roundi(perp.y*8.0*scale))-Vector2i(0,8*scale)
			_line(image,antenna,antenna-Vector2i(0,8*scale),outline,2*scale)
			_circle(image,antenna-Vector2i(0,8*scale),scale,accent)
		"melee":
			for side in [-1,1]:
				var fist := chest+Vector2i(roundi((direction.x*8.0+perp.x*side*8.0)*scale),roundi((direction.y*8.0+perp.y*side*8.0)*scale))
				_circle(image,fist,4*scale,outline)
				for claw in range(2):
					var tip := fist+Vector2i(roundi(direction.x*(5+claw*3)*scale),roundi(direction.y*(5+claw*3)*scale))+Vector2i(roundi(perp.x*(claw*2-1)*scale),roundi(perp.y*(claw*2-1)*scale))
					_line(image,fist,tip,accent,scale)
		_:
			pass

	match category:
		"fallen": _draw_fallen_ornament(image,chest,direction,perp,frame_index,accent,outline,scale)
		"nephilim": _draw_nephilim_ornament(image,chest,direction,perp,genome,accent,outline,scale)
		"preadamic": _draw_preadamic_ornament(image,chest,perp,genome,secondary,accent,outline,scale)
		"guardian": _draw_guardian_ornament(image,chest,direction,perp,frame_index,accent,outline,scale)

	if not lineage.is_empty():
		_draw_lineage_signature(image,lineage,chest,direction,perp,frame_index,accent,outline,scale)

func _draw_fallen_ornament(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	var halo_center := chest-Vector2i(0,20*scale)
	_circle(image,halo_center,(7+frame_index%2)*scale,outline,false)
	_circle(image,halo_center,6*scale,Color(accent,0.76),false)
	for side in [-1,1]:
		var root := chest+Vector2i(roundi(perp.x*side*7.0*scale),roundi(perp.y*side*7.0*scale))
		for feather in range(2):
			var tip := root+Vector2i(roundi((-direction.x*(8+feather*4)+perp.x*side*(9+feather*4))*scale),roundi((-direction.y*(8+feather*4)+perp.y*side*(9+feather*4))*scale))
			_line(image,root,tip,outline,3*scale)
			_line(image,root,tip,Color(accent,0.72),scale)

func _draw_nephilim_ornament(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, genome: Dictionary, accent: Color, outline: Color, scale: int) -> void:
	var count := 2+int(genome.get("horns",1))
	for graft in range(count):
		var side := -1 if graft%2==0 else 1
		var root := chest+Vector2i(roundi(perp.x*side*(7+graft)*scale),roundi(perp.y*side*(7+graft)*scale))-Vector2i(0,(3+graft)*scale)
		var tip := root+Vector2i(roundi((-direction.x*4.0+perp.x*side*8.0)*scale),roundi((-direction.y*4.0+perp.y*side*8.0)*scale))-Vector2i(0,5*scale)
		_line(image,root,tip,outline,3*scale)
		_line(image,root,tip,accent.darkened(0.15),scale)
		if graft%2==0: _circle(image,root,2*scale,Color(accent,0.72))

func _draw_preadamic_ornament(image: Image, chest: Vector2i, perp: Vector2, genome: Dictionary, secondary: Color, accent: Color, outline: Color, scale: int) -> void:
	var side := -1 if float(genome.get("asymmetry",0.0))<0.0 else 1
	var plate := chest+Vector2i(roundi(perp.x*side*9.0*scale),roundi(perp.y*side*9.0*scale))
	_fill_rect(image,Rect2i(plate.x-4*scale,plate.y-5*scale,8*scale,10*scale),outline)
	_fill_rect(image,Rect2i(plate.x-3*scale,plate.y-4*scale,6*scale,8*scale),secondary.darkened(0.18))
	_line(image,plate-Vector2i(3*scale,2*scale),plate+Vector2i(3*scale,2*scale),Color(accent,0.58),scale)

func _draw_guardian_ornament(image: Image, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	for side in [-1,1]:
		var node := chest+Vector2i(roundi(perp.x*side*11.0*scale),roundi(perp.y*side*11.0*scale))-Vector2i(0,3*scale)
		_circle(image,node,3*scale,outline)
		_circle(image,node,(1+frame_index%2)*scale,accent)

func _draw_lineage_signature(image: Image, lineage: String, chest: Vector2i, direction: Vector2, perp: Vector2, frame_index: int, accent: Color, outline: Color, scale: int) -> void:
	match lineage:
		"adam":
			for side in [-1,1]:
				var root := chest+Vector2i(roundi(perp.x*side*9.0*scale),roundi(perp.y*side*9.0*scale))
				_line(image,root,root-Vector2i(side*3*scale,9*scale),Color(0.34,0.70,0.40,0.80),2*scale)
				_circle(image,root-Vector2i(side*3*scale,9*scale),2*scale,Color(0.47,0.82,0.49,0.78))
		"abel":
			var halo := chest-Vector2i(0,22*scale)
			_circle(image,halo,8*scale,outline,false)
			_circle(image,halo,7*scale,Color(accent,0.80),false)
			_line(image,chest+Vector2i(8*scale,0),chest+Vector2i(12*scale,-16*scale),Color(accent,0.76),2*scale)
		"cain":
			# Red-black cannon lineage: oversized rear power block and muzzle rails.
			var pack := chest-Vector2i(roundi(direction.x*9.0*scale),roundi(direction.y*9.0*scale))
			_fill_rect(image,Rect2i(pack.x-5*scale,pack.y-6*scale,10*scale,12*scale),outline)
			_fill_rect(image,Rect2i(pack.x-3*scale,pack.y-4*scale,6*scale,8*scale),Color(0.44,0.07,0.09,1.0))
			_circle(image,pack,2*scale,Color(0.98,0.22,0.18,0.90))
			for side in [-1,1]:
				var rail := chest+Vector2i(roundi(perp.x*side*5.0*scale),roundi(perp.y*side*5.0*scale))
				_line(image,rail,rail+Vector2i(roundi(direction.x*18.0*scale),roundi(direction.y*18.0*scale)),Color(0.86,0.16,0.14,0.76),scale)
		"seth":
			for side in [-1,1]:
				var node := chest+Vector2i(roundi(perp.x*side*10.0*scale),roundi(perp.y*side*10.0*scale))
				_fill_rect(image,Rect2i(node.x-3*scale,node.y-3*scale,6*scale,6*scale),outline)
				_circle(image,node,2*scale,Color(0.34,0.68,0.96,0.90))
		"naamah":
			for bud in range(4):
				var angle := TAU*float(bud)/4.0+float(frame_index)*0.12
				var p := chest+Vector2i(roundi(cos(angle)*10.0*scale),roundi(sin(angle)*7.0*scale))-Vector2i(0,5*scale)
				_circle(image,p,2*scale,Color(0.78,0.35,0.88,0.82))
		_:
			pass

func audit_contract() -> Dictionary:
	var report: Dictionary = super.audit_contract()
	report["premium_forge_version"] = PREMIUM_FORGE_VERSION
	report["role_morphology"] = true
	report["category_morphology"] = true
	report["lineage_silhouette_signatures"] = true
	report["cain_heavy_cannon_signature"] = true
	return report
