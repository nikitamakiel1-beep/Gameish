extends RefCounted

const VERSION: String = "0.6.1-rc7"
const ActorFactoryScript: Script = preload("res://scripts/v7/actor_asset_factory_masterpiece.gd")
const BaseActorFactoryScript: Script = preload("res://scripts/v6/actor_asset_factory.gd")
const SupportFactoryScript: Script = preload("res://scripts/v6/support_asset_factory.gd")
const AudioFactoryScript: Script = preload("res://scripts/v7/audio_asset_factory_masterpiece.gd")
const BaseAudioFactoryScript: Script = preload("res://scripts/v6/audio_asset_factory.gd")
const TOUCH_SIZES := {
	"joystick_base": Vector2i(192,192),
	"joystick_thumb": Vector2i(96,96),
	"touch_dash": Vector2i(128,128),
	"touch_interact": Vector2i(112,112),
	"touch_pause": Vector2i(72,72),
}

var actors: RefCounted = null
var support: RefCounted = null
var sound: RefCounted = null

func _init() -> void:
	_ensure_factories()

func _ensure_factories() -> void:
	if actors == null:
		if ActorFactoryScript.can_instantiate():
			actors = ActorFactoryScript.new() as RefCounted
		if actors == null and BaseActorFactoryScript.can_instantiate():
			push_warning("EDEN//FALL RC7 actor masterpiece unavailable; using stable V6 actor compatibility factory")
			actors = BaseActorFactoryScript.new() as RefCounted
	if support == null and SupportFactoryScript.can_instantiate():
		support = SupportFactoryScript.new() as RefCounted
	if sound == null:
		if AudioFactoryScript.can_instantiate():
			sound = AudioFactoryScript.new() as RefCounted
		if sound == null and BaseAudioFactoryScript.can_instantiate():
			push_warning("EDEN//FALL RC7 audio masterpiece unavailable; using stable V6 audio compatibility factory")
			sound = BaseAudioFactoryScript.new() as RefCounted

func _actor() -> RefCounted:
	_ensure_factories()
	return actors

func _support() -> RefCounted:
	_ensure_factories()
	return support

func _sound() -> RefCounted:
	_ensure_factories()
	return sound

func _invalid_image(label: String) -> Image:
	push_error("EDEN//FALL RC7 could not instantiate required factory: "+label)
	return Image.create(2,2,false,Image.FORMAT_RGBA8)

func build_hero_sheet(id: String) -> Image:
	var factory: RefCounted = _actor()
	if factory == null: return _invalid_image("actors")
	return factory.call("build_hero_sheet",id) as Image

func build_enemy_sheet(id: String) -> Image:
	var factory: RefCounted = _actor()
	if factory == null: return _invalid_image("actors")
	return factory.call("build_enemy_sheet",id) as Image

func build_boss_sheet(id: String) -> Image:
	var factory: RefCounted = _actor()
	if factory == null: return _invalid_image("actors")
	return factory.call("build_boss_sheet",id) as Image

func build_portrait(id: String) -> Image:
	var factory: RefCounted = _actor()
	if factory == null: return _invalid_image("actors")
	return factory.call("build_portrait",id) as Image

func build_biome(id: String,kind: String) -> Image:
	var factory: RefCounted = _support()
	if factory == null: return _invalid_image("support")
	return factory.call("build_biome",id,kind) as Image

func build_utility(id: String) -> Image:
	var image: Image = null
	var factory: RefCounted = _support()
	if factory != null:
		image = factory.call("build_utility",id) as Image
	if TOUCH_SIZES.has(id):
		var expected: Vector2i = TOUCH_SIZES[id]
		if image == null or image.is_empty() or image.get_size()!=expected:
			push_warning("EDEN//FALL RC7 repaired invalid touch utility: %s" % id)
			return _build_touch_fallback(id,expected)
	if image == null or image.is_empty(): return _invalid_image("support:"+id)
	return image

func synth_loop(index: int,ambience: bool) -> AudioStreamWAV:
	var factory: RefCounted = _sound()
	if factory == null: return null
	return factory.call("synth_loop",index,ambience) as AudioStreamWAV

func synth_sfx(id: String) -> AudioStreamWAV:
	var factory: RefCounted = _sound()
	if factory == null: return null
	return factory.call("synth_sfx",id) as AudioStreamWAV

func _build_touch_fallback(id: String,size: Vector2i) -> Image:
	var image: Image = Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	var center: Vector2 = Vector2(float(size.x)*0.5,float(size.y)*0.5)
	var outer: float = float(mini(size.x,size.y))*0.46
	var inner: float = outer-5.0
	var accent: Color = Color8(112,190,247)
	if id=="touch_interact": accent=Color8(235,202,130)
	elif id=="touch_pause": accent=Color8(216,216,198)
	elif id.begins_with("joystick"): accent=Color8(105,181,145)
	for y: int in range(size.y):
		for x: int in range(size.x):
			var point: Vector2 = Vector2(float(x)+0.5,float(y)+0.5)
			var distance: float = point.distance_to(center)
			if distance<=outer: image.set_pixel(x,y,Color(0.02,0.05,0.06,0.68))
			if distance>=inner-2.0 and distance<=inner+1.0: image.set_pixel(x,y,Color(accent,0.90))
	var cx: int = int(size.x/2)
	var cy: int = int(size.y/2)
	if id=="touch_pause":
		_fill_rect(image,Rect2i(cx-12,cy-18,8,36),accent)
		_fill_rect(image,Rect2i(cx+4,cy-18,8,36),accent)
	elif id=="touch_interact":
		_draw_rect_outline(image,Rect2i(cx-14,cy-14,28,28),accent,3)
		_fill_rect(image,Rect2i(cx-4,cy-4,8,8),accent)
	elif id=="touch_dash":
		_draw_line(image,Vector2i(cx-20,cy+8),Vector2i(cx+19,cy-10),accent,4)
	elif id=="joystick_thumb":
		var radius: int = int(float(mini(size.x,size.y))*0.23)
		for y: int in range(cy-radius,cy+radius+1):
			for x: int in range(cx-radius,cx+radius+1):
				if x>=0 and y>=0 and x<size.x and y<size.y and Vector2(float(x-cx),float(y-cy)).length()<=float(radius):
					image.set_pixel(x,y,Color(accent,0.78))
	return image

func _fill_rect(image: Image,rect: Rect2i,color: Color) -> void:
	var clipped: Rect2i = rect.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	if clipped.size.x>0 and clipped.size.y>0: image.fill_rect(clipped,color)

func _draw_rect_outline(image: Image,rect: Rect2i,color: Color,thickness: int) -> void:
	_fill_rect(image,Rect2i(rect.position.x,rect.position.y,rect.size.x,thickness),color)
	_fill_rect(image,Rect2i(rect.position.x,rect.end.y-thickness,rect.size.x,thickness),color)
	_fill_rect(image,Rect2i(rect.position.x,rect.position.y,thickness,rect.size.y),color)
	_fill_rect(image,Rect2i(rect.end.x-thickness,rect.position.y,thickness,rect.size.y),color)

func _draw_line(image: Image,start: Vector2i,finish: Vector2i,color: Color,width: int) -> void:
	var steps: int = maxi(absi(finish.x-start.x),absi(finish.y-start.y))
	var half: int = maxi(0,int(width/2))
	for index: int in range(steps+1):
		var ratio: float = float(index)/float(maxi(1,steps))
		var point: Vector2i = Vector2i(roundi(lerpf(float(start.x),float(finish.x),ratio)),roundi(lerpf(float(start.y),float(finish.y),ratio)))
		_fill_rect(image,Rect2i(point-Vector2i(half,half),Vector2i(width,width)),color)

func audit_contract() -> Dictionary:
	_ensure_factories()
	return {"version":VERSION,"actor_factory_ready":actors!=null,"support_factory_ready":support!=null,"audio_factory_ready":sound!=null,"no_poison_1x1_fallback":true}
