extends RefCounted

const VERSION := "0.6.1-rc7"
const ActorFactoryScript = preload("res://scripts/v7/actor_asset_factory_masterpiece.gd")
const SupportFactoryScript = preload("res://scripts/v6/support_asset_factory.gd")
const AudioFactoryScript = preload("res://scripts/v7/audio_asset_factory_masterpiece.gd")
const TOUCH_SIZES := {
	"joystick_base": Vector2i(192,192),
	"joystick_thumb": Vector2i(96,96),
	"touch_dash": Vector2i(128,128),
	"touch_interact": Vector2i(112,112),
	"touch_pause": Vector2i(72,72),
}

var actors = null
var support = null
var sound = null

func _init() -> void:
	actors = ActorFactoryScript.new()
	support = SupportFactoryScript.new()
	sound = AudioFactoryScript.new()

func _require_factory(factory: Variant, label: String) -> bool:
	if factory == null:
		push_error("EDEN//FALL RC7 factory failed to instantiate: " + label)
		return false
	return true

func build_hero_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_hero_sheet", id) as Image

func build_enemy_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_enemy_sheet", id) as Image

func build_boss_sheet(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_boss_sheet", id) as Image

func build_portrait(id: String) -> Image:
	if not _require_factory(actors, "actors"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return actors.call("build_portrait", id) as Image

func build_biome(id: String, kind: String) -> Image:
	if not _require_factory(support, "support"):
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return support.call("build_biome", id, kind) as Image

func build_utility(id: String) -> Image:
	var image: Image = null
	if _require_factory(support, "support"):
		image = support.call("build_utility", id) as Image
	if TOUCH_SIZES.has(id):
		var expected: Vector2i = TOUCH_SIZES[id]
		if image == null or image.is_empty() or image.get_size() != expected:
			push_warning("EDEN//FALL RC7 repaired invalid touch utility: %s" % id)
			return _build_touch_fallback(id, expected)
	if image == null or image.is_empty():
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	return image

func _build_touch_fallback(id: String, size: Vector2i) -> Image:
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	image.fill(Color(0.0,0.0,0.0,0.0))
	var center := Vector2(float(size.x)*0.5,float(size.y)*0.5)
	var outer := float(mini(size.x,size.y))*0.46
	var inner := outer-5.0
	var accent := Color8(112,190,247)
	if id == "touch_interact": accent = Color8(235,202,130)
	elif id == "touch_pause": accent = Color8(216,216,198)
	elif id.begins_with("joystick"): accent = Color8(105,181,145)
	for y in range(size.y):
		for x in range(size.x):
			var point := Vector2(float(x)+0.5,float(y)+0.5)
			var distance := point.distance_to(center)
			if distance <= outer:
				image.set_pixel(x,y,Color(0.02,0.05,0.06,0.68))
			if distance >= inner-2.0 and distance <= inner+1.0:
				image.set_pixel(x,y,Color(accent,0.90))
	var cx := int(size.x/2)
	var cy := int(size.y/2)
	if id == "touch_pause":
		_fill_rect(image,Rect2i(cx-12,cy-18,8,36),accent)
		_fill_rect(image,Rect2i(cx+4,cy-18,8,36),accent)
	elif id == "touch_interact":
		_draw_rect_outline(image,Rect2i(cx-14,cy-14,28,28),accent,3)
		_fill_rect(image,Rect2i(cx-4,cy-4,8,8),accent)
	elif id == "touch_dash":
		_draw_line(image,Vector2i(cx-20,cy+8),Vector2i(cx+19,cy-10),accent,4)
		_draw_line(image,Vector2i(cx+7,cy-15),Vector2i(cx+20,cy-10),accent,4)
		_draw_line(image,Vector2i(cx+19,cy-10),Vector2i(cx+12,cy+2),accent,4)
	elif id == "joystick_thumb":
		var thumb_radius := int(float(mini(size.x,size.y))*0.23)
		for y in range(cy-thumb_radius,cy+thumb_radius+1):
			for x in range(cx-thumb_radius,cx+thumb_radius+1):
				if x >= 0 and y >= 0 and x < size.x and y < size.y and Vector2(float(x-cx),float(y-cy)).length() <= float(thumb_radius):
					image.set_pixel(x,y,Color(accent,0.78))
	return image

func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0,rect.position.y),mini(image.get_height(),rect.end.y)):
		for x in range(maxi(0,rect.position.x),mini(image.get_width(),rect.end.x)):
			image.set_pixel(x,y,color)

func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, thickness: int) -> void:
	_fill_rect(image,Rect2i(rect.position.x,rect.position.y,rect.size.x,thickness),color)
	_fill_rect(image,Rect2i(rect.position.x,rect.end.y-thickness,rect.size.x,thickness),color)
	_fill_rect(image,Rect2i(rect.position.x,rect.position.y,thickness,rect.size.y),color)
	_fill_rect(image,Rect2i(rect.end.x-thickness,rect.position.y,thickness,rect.size.y),color)

func _draw_line(image: Image, start: Vector2i, finish: Vector2i, color: Color, width: int) -> void:
	var steps := maxi(absi(finish.x-start.x),absi(finish.y-start.y))
	var half := maxi(0,int(width/2))
	for index in range(steps+1):
		var ratio := float(index)/float(maxi(1,steps))
		var point := Vector2i(roundi(lerpf(float(start.x),float(finish.x),ratio)),roundi(lerpf(float(start.y),float(finish.y),ratio)))
		_fill_rect(image,Rect2i(point-Vector2i(half,half),Vector2i(width,width)),color)

func synth_loop(index: int, ambience: bool) -> AudioStreamWAV:
	if not _require_factory(sound, "audio"):
		return AudioStreamWAV.new()
	return sound.call("synth_loop", index, ambience) as AudioStreamWAV

func synth_sfx(id: String) -> AudioStreamWAV:
	if not _require_factory(sound, "audio"):
		return AudioStreamWAV.new()
	return sound.call("synth_sfx", id) as AudioStreamWAV
