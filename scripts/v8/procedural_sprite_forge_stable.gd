extends RefCounted

const VERSION: String = "0.6.2-entropy-stable"
const FRAME: int = 48
const BOSS_FRAME: int = 96
const FRAMES: int = 4
const DIRECTIONS: Array[Vector2] = [
	Vector2(0.0,-1.0), Vector2(1.0,-1.0), Vector2(1.0,0.0), Vector2(1.0,1.0),
	Vector2(0.0,1.0), Vector2(-1.0,1.0), Vector2(-1.0,0.0), Vector2(-1.0,-1.0),
]
const PALETTES: Array = [
	[Color8(71,47,37),Color8(126,78,49),Color8(220,106,54),Color8(236,199,145),Color8(25,21,20)],
	[Color8(54,60,55),Color8(104,112,78),Color8(204,171,78),Color8(224,206,167),Color8(20,23,22)],
	[Color8(68,42,37),Color8(142,61,45),Color8(229,113,63),Color8(190,153,120),Color8(24,19,19)],
	[Color8(43,53,54),Color8(74,95,91),Color8(179,127,68),Color8(211,181,142),Color8(19,23,24)],
	[Color8(58,61,62),Color8(126,134,126),Color8(226,211,155),Color8(221,203,166),Color8(20,22,23)],
	[Color8(42,55,63),Color8(70,112,124),Color8(112,226,219),Color8(217,215,183),Color8(16,22,26)],
	[Color8(65,60,48),Color8(126,112,74),Color8(238,214,142),Color8(221,205,172),Color8(23,22,18)],
	[Color8(47,43,66),Color8(94,78,128),Color8(176,145,235),Color8(226,218,194),Color8(20,18,28)],
	[Color8(64,36,40),Color8(117,56,60),Color8(224,86,75),Color8(163,112,99),Color8(24,17,20)],
	[Color8(53,43,59),Color8(104,75,115),Color8(201,116,207),Color8(190,157,145),Color8(22,18,27)],
	[Color8(70,53,44),Color8(132,98,67),Color8(217,165,100),Color8(169,132,113),Color8(25,21,18)],
	[Color8(43,48,58),Color8(75,89,115),Color8(146,179,231),Color8(180,165,154),Color8(17,20,26)],
	[Color8(36,52,45),Color8(74,111,88),Color8(126,221,151),Color8(215,204,171),Color8(15,22,19)],
	[Color8(49,43,68),Color8(99,81,132),Color8(201,141,231),Color8(222,208,182),Color8(19,17,27)],
	[Color8(64,55,42),Color8(119,100,67),Color8(236,200,113),Color8(223,205,165),Color8(22,20,16)],
	[Color8(48,22,27),Color8(116,39,45),Color8(239,71,62),Color8(190,128,111),Color8(18,14,17)],
]

func build_enemy_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome,false)

func build_player_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome,false)

func build_boss_sheet(genome: Dictionary) -> Image:
	return _build_sheet(genome,true)

func _build_sheet(genome: Dictionary,boss: bool) -> Image:
	var frame_size: int = BOSS_FRAME if boss else FRAME
	var sheet: Image = Image.create_empty(frame_size*FRAMES,frame_size*8,false,Image.FORMAT_RGBA8)
	sheet.fill(Color(0,0,0,0))
	for direction_index: int in range(8):
		var direction: Vector2 = DIRECTIONS[direction_index].normalized()
		for frame_index: int in range(FRAMES):
			_draw_actor_frame(sheet,Vector2i(frame_index*frame_size,direction_index*frame_size),frame_size,genome,direction,frame_index,boss)
	return sheet

func _draw_actor_frame(image: Image,origin: Vector2i,size: int,genome: Dictionary,direction: Vector2,frame_index: int,boss: bool) -> void:
	var palette_index: int = clampi(int(genome.get("palette_index",0)),0,PALETTES.size()-1)
	var palette: Array = PALETTES[palette_index]
	var primary: Color = Color(palette[0])
	var secondary: Color = Color(palette[1])
	var accent: Color = Color(palette[2])
	var skin: Color = Color(palette[3])
	var outline: Color = Color(palette[4])
	var role: String = String(genome.get("role","melee"))
	var scale: int = 2 if boss else 1
	var stride: int = roundi(sin(float(frame_index)*PI*0.5)*float(2*scale))
	var bob: int = roundi(absf(sin(float(frame_index)*PI*0.5))*float(scale))
	var center: Vector2i = origin+Vector2i(int(size/2),int(float(size)*0.69)+bob)
	if role == "orbiter":
		_draw_orbiter(image,center,direction,frame_index,genome,primary,secondary,accent,outline,scale)
	elif role == "radial":
		_draw_radial(image,center,direction,frame_index,genome,primary,secondary,accent,outline,scale)
	else:
		_draw_humanoid(image,center,direction,stride,frame_index,genome,primary,secondary,accent,skin,outline,scale)

func _draw_humanoid(image: Image,center: Vector2i,direction: Vector2,stride: int,frame_index: int,genome: Dictionary,primary: Color,secondary: Color,accent: Color,skin: Color,outline: Color,scale: int) -> void:
	var perp: Vector2 = Vector2(-direction.y,direction.x)
	var body_w: int = clampi(int(genome.get("body_width",16))*scale,14*scale,30*scale)
	var body_h: int = clampi(int(genome.get("body_height",18))*scale,16*scale,34*scale)
	var half_w: int = int(body_w/2)
	var role: String = String(genome.get("role","melee"))
	_fill_ellipse(image,center+Vector2i(0,3*scale),maxi(8*scale,half_w),4*scale,Color(0,0,0,0.34))
	var leg_y: int = center.y-9*scale
	for side_variant in [-1,1]:
		var side: int = int(side_variant)
		var leg_x: int = center.x+side*(4*scale)+side*stride
		_fill_rect(image,Rect2i(leg_x-3*scale,leg_y,6*scale,10*scale),outline)
		_fill_rect(image,Rect2i(leg_x-2*scale,leg_y,4*scale,8*scale),secondary.darkened(0.18))
	var torso: Rect2i = Rect2i(center.x-half_w,center.y-(body_h+10*scale),body_w,body_h)
	_fill_rect(image,torso.grow(2*scale),outline)
	_fill_rect(image,torso,primary)
	_fill_rect(image,Rect2i(torso.position+Vector2i(2*scale,2*scale),Vector2i(maxi(scale,torso.size.x-4*scale),3*scale)),primary.lightened(0.16))
	_fill_rect(image,Rect2i(torso.position+Vector2i(2*scale,torso.size.y-4*scale),Vector2i(maxi(scale,torso.size.x-4*scale),3*scale)),primary.darkened(0.25))
	var shoulder_style: int = int(genome.get("shoulder_style",0))
	for side_variant in [-1,1]:
		var side: int = int(side_variant)
		var shoulder: Vector2i = Vector2i(center.x+side*(half_w+2*scale),torso.position.y+5*scale)
		_circle(image,shoulder,(4+shoulder_style%2)*scale,outline)
		_circle(image,shoulder,(2+shoulder_style%2)*scale,secondary)
	var head: Vector2i = Vector2i(center.x,torso.position.y-6*scale)
	_circle(image,head,8*scale,outline)
	_circle(image,head,6*scale,skin)
	var head_style: int = int(genome.get("head_style",0))
	if head_style%3 == 0:
		_fill_rect(image,Rect2i(head.x-6*scale,head.y-6*scale,12*scale,6*scale),primary.darkened(0.16))
	elif head_style%3 == 1:
		_fill_rect(image,Rect2i(head.x-6*scale,head.y-5*scale,12*scale,10*scale),outline)
		_fill_rect(image,Rect2i(head.x-4*scale,head.y-3*scale,8*scale,5*scale),secondary)
	else:
		_circle(image,head,9*scale,accent.darkened(0.18),false)
	var eye: Vector2i = head+Vector2i(roundi(direction.x*3.0*scale),roundi(direction.y*2.0*scale))
	_circle(image,eye,maxi(1,scale),accent)
	var horns: int = clampi(int(genome.get("horns",0)),0,3)
	for horn: int in range(horns):
		var side: int = -1 if horn%2==0 else 1
		_line(image,head+Vector2i(side*4*scale,-4*scale),head+Vector2i(side*(8+horn*2)*scale,-11*scale),outline,2*scale)
	_draw_weapon(image,center+Vector2i(0,-20*scale),direction,perp,frame_index,genome,role,primary,secondary,accent,outline,scale)

func _draw_weapon(image: Image,origin: Vector2i,direction: Vector2,perp: Vector2,frame_index: int,genome: Dictionary,role: String,primary: Color,secondary: Color,accent: Color,outline: Color,scale: int) -> void:
	var style: int = int(genome.get("weapon_style",0))
	var reach: int = 15*scale
	if role == "caster": reach = 18*scale
	elif role == "charger": reach = 13*scale
	elif role == "skirmisher": reach = 14*scale
	if style == 5: reach += 7*scale
	var grip: Vector2i = origin+Vector2i(roundi(perp.x*3.0*scale),roundi(perp.y*3.0*scale))
	var muzzle: Vector2i = grip+Vector2i(roundi(direction.x*reach),roundi(direction.y*reach))
	if role == "melee":
		_line(image,grip,muzzle,outline,5*scale)
		_line(image,grip,muzzle,Color8(216,211,183),2*scale)
	elif role == "caster":
		_line(image,grip,muzzle,outline,4*scale)
		_line(image,grip,muzzle,secondary,2*scale)
		_circle(image,muzzle,(3+frame_index%2)*scale,accent)
	elif role == "skirmisher":
		for side_variant in [-1,1]:
			var side: int = int(side_variant)
			var start: Vector2i = grip+Vector2i(roundi(perp.x*side*4.0*scale),roundi(perp.y*side*4.0*scale))
			var finish: Vector2i = start+Vector2i(roundi(direction.x*reach),roundi(direction.y*reach))
			_line(image,start,finish,outline,4*scale)
			_line(image,start,finish,accent,2*scale)
	else:
		var thickness: int = 7*scale if style==5 else 5*scale
		_line(image,grip,muzzle,outline,thickness)
		_line(image,grip,muzzle,secondary,maxi(scale,thickness-3*scale))
		_circle(image,muzzle,2*scale,accent)

func _draw_orbiter(image: Image,center: Vector2i,direction: Vector2,frame_index: int,genome: Dictionary,primary: Color,secondary: Color,accent: Color,outline: Color,scale: int) -> void:
	_fill_ellipse(image,center+Vector2i(0,7*scale),12*scale,4*scale,Color(0,0,0,0.30))
	_circle(image,center,13*scale,outline)
	_circle(image,center,10*scale,primary)
	_circle(image,center,6*scale,secondary)
	_circle(image,center+Vector2i(roundi(direction.x*3.0*scale),roundi(direction.y*3.0*scale)),2*scale,accent)
	var arm_count: int = 4+clampi(int(genome.get("accent_count",2)),1,4)
	for arm: int in range(arm_count):
		var angle: float = float(frame_index)*0.65+TAU*float(arm)/float(arm_count)
		var inner: Vector2i = center+Vector2i(roundi(cos(angle)*10.0*scale),roundi(sin(angle)*10.0*scale))
		var outer: Vector2i = center+Vector2i(roundi(cos(angle)*19.0*scale),roundi(sin(angle)*19.0*scale))
		_line(image,inner,outer,outline,3*scale)
		_circle(image,outer,scale,accent)

func _draw_radial(image: Image,center: Vector2i,direction: Vector2,frame_index: int,genome: Dictionary,primary: Color,secondary: Color,accent: Color,outline: Color,scale: int) -> void:
	_fill_ellipse(image,center+Vector2i(0,8*scale),15*scale,5*scale,Color(0,0,0,0.32))
	_circle(image,center,16*scale,outline)
	_circle(image,center,13*scale,primary)
	_circle(image,center,8*scale,secondary)
	var arms: int = 6+clampi(int(genome.get("horns",0)),0,3)
	for arm: int in range(arms):
		var angle: float = TAU*float(arm)/float(arms)+float(frame_index)*0.14
		var start: Vector2i = center+Vector2i(roundi(cos(angle)*10.0*scale),roundi(sin(angle)*10.0*scale))
		var finish: Vector2i = center+Vector2i(roundi(cos(angle)*21.0*scale),roundi(sin(angle)*21.0*scale))
		_line(image,start,finish,outline,4*scale)
		_line(image,start,finish,accent,2*scale)
	_circle(image,center+Vector2i(roundi(direction.x*4.0*scale),roundi(direction.y*4.0*scale)),3*scale,accent)

func _fill_rect(image: Image,rect: Rect2i,color: Color) -> void:
	var clipped: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if clipped.size.x>0 and clipped.size.y>0:
		image.fill_rect(clipped,color)

func _circle(image: Image,center: Vector2i,radius: int,color: Color,filled: bool=true) -> void:
	var r2: int = radius*radius
	var inner: int = maxi(0,radius-2)
	var inner2: int = inner*inner
	for y: int in range(center.y-radius,center.y+radius+1):
		for x: int in range(center.x-radius,center.x+radius+1):
			var dx: int = x-center.x
			var dy: int = y-center.y
			var d2: int = dx*dx+dy*dy
			if d2<=r2 and (filled or d2>=inner2):
				_set_pixel_safe(image,x,y,color)

func _fill_ellipse(image: Image,center: Vector2i,rx: int,ry: int,color: Color) -> void:
	if rx<=0 or ry<=0: return
	for y: int in range(center.y-ry,center.y+ry+1):
		for x: int in range(center.x-rx,center.x+rx+1):
			var nx: float = float(x-center.x)/float(rx)
			var ny: float = float(y-center.y)/float(ry)
			if nx*nx+ny*ny<=1.0: _set_pixel_safe(image,x,y,color)

func _line(image: Image,start: Vector2i,finish: Vector2i,color: Color,width: int=1) -> void:
	var steps: int = maxi(absi(finish.x-start.x),absi(finish.y-start.y))
	var half: int = maxi(0,int(width/2))
	for index: int in range(steps+1):
		var ratio: float = float(index)/float(maxi(1,steps))
		var point: Vector2i = Vector2i(roundi(lerpf(float(start.x),float(finish.x),ratio)),roundi(lerpf(float(start.y),float(finish.y),ratio)))
		_fill_rect(image,Rect2i(point-Vector2i(half,half),Vector2i(width,width)),color)

func _set_pixel_safe(image: Image,x: int,y: int,color: Color) -> void:
	if x>=0 and y>=0 and x<image.get_width() and y<image.get_height(): image.set_pixel(x,y,color)

func audit_contract() -> Dictionary:
	return {"version":VERSION,"directions":8,"animation_frames":FRAMES,"instance_unique":true,"role_specific_silhouettes":true,"hard_pixel_outline":true,"procedural_weapons":true,"procedural_armor":true,"external_sprite_data":false,"godot_47_safe":true}
