extends "res://scripts/edenfall_v8_authored_presentation_runtime.gd"

const AUTHORED_ANIMATION_VERSION: String = "0.6.3-art3"

func _player_authored_frame() -> int:
	if dash_time > 0.0:
		return 3
	if invulnerability > 0.0:
		return 3
	if not player.is_empty():
		var fire_delay: float = maxf(0.04,float(player.get("fire_delay",0.25)))
		if fire_timer > fire_delay*0.46:
			return 2
	if input_move.length_squared() > 0.04:
		return 1 if posmod(int(visual_clock*8.0),2)==0 else 3
	return 0

func _enemy_authored_frame(enemy: Dictionary) -> int:
	if float(enemy.get("flash",0.0)) > 0.0:
		return 3
	var windup: float = maxf(
		float(enemy.get("windup",0.0)),
		maxf(float(enemy.get("special_windup",0.0)),maxf(float(enemy.get("boss_windup",0.0)),float(enemy.get("v8_trait_windup",0.0))))
	)
	if windup > 0.0:
		return 2
	if float(enemy.get("attack",0.0)) > 0.05:
		return 2
	var velocity: Vector2 = Vector2(enemy.get("velocity",Vector2.ZERO))
	if velocity.length_squared() > 20.0:
		return 1 if posmod(int((visual_clock+float(enemy.get("variant",0))*0.13)*7.0),2)==0 else 3
	return 0

func draw_player() -> void:
	if player.is_empty():
		return
	var texture: Texture2D = _player_entropy_texture()
	if texture == null:
		super.draw_player()
		return
	var genome: Dictionary = player.get("v8_visual_genome",{})
	var pos: Vector2 = Vector2(player["pos"])
	var direction_index: int = quantize_direction(Vector2(player.get("look",last_aim)))
	var frame: int = _player_authored_frame()
	var display: float = 78.0*float(genome.get("visual_scale",1.0))
	var alpha: float = 0.42 if invulnerability > 0.0 and int(invulnerability*20.0)%2==0 else 1.0
	if dash_time > 0.0:
		var dash_dir: Vector2 = Vector2(player.get("dash_direction",Vector2.ZERO))
		for echo: int in range(1,4):
			var echo_pos: Vector2 = pos-dash_dir*float(echo)*15.0
			var echo_dest: Rect2 = Rect2(echo_pos-Vector2(display*0.5,display*0.68),Vector2(display,display))
			var echo_src: Rect2 = Rect2(Vector2(3*48,direction_index*48),Vector2(48,48))
			draw_texture_rect_region(texture,echo_dest,echo_src,Color(1,1,1,0.12/float(echo)))
	draw_circle(pos+Vector2(0,18),24.0,Color(0,0,0,0.30))
	var dest: Rect2 = Rect2(pos-Vector2(display*0.5,display*0.68),Vector2(display,display))
	var src: Rect2 = Rect2(Vector2(frame*48,direction_index*48),Vector2(48,48))
	draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
	var aim: Vector2 = Vector2(player.get("aim",last_aim)).normalized()
	if aim.length_squared() > 0.01:
		draw_line(pos+aim*21.0,pos+aim*42.0,Color(0.96,0.86,0.67,0.42),2.0)
		draw_circle(pos+aim*43.0,2.0,Color(0.96,0.86,0.67,0.70))
	if frame == 2 and aim.length_squared() > 0.01:
		var muzzle: Vector2 = pos+aim*46.0
		draw_line(muzzle,muzzle+aim*8.0,Color(1.0,0.77,0.32,0.72),3.0)
	if bool(player.get("shield",false)):
		draw_arc(pos,36.0,-PI*0.88,PI*0.88,30,Color8(112,190,247),4.0)

func draw_enemies() -> void:
	var strong: bool = bool(settings.get("strong_telegraphs",true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		var pos: Vector2 = Vector2(enemy["pos"])
		var radius: float = float(enemy.get("radius",18.0))
		var boss: bool = bool(enemy.get("boss",false))
		var genome: Dictionary = enemy.get("v8_visual_genome",{})
		var delay: float = float(enemy.get("activation_delay",0.0))
		var windup: float = maxf(float(enemy.get("windup",0.0)),maxf(float(enemy.get("special_windup",0.0)),maxf(float(enemy.get("boss_windup",0.0)),float(enemy.get("v8_trait_windup",0.0)))))
		if windup > 0.0:
			var maximum: float = maxf(windup,maxf(float(enemy.get("windup_max",0.0)),maxf(float(enemy.get("special_windup_max",0.0)),maxf(float(enemy.get("boss_windup_max",0.0)),float(enemy.get("v8_trait_windup_max",0.0))))))
			var progress: float = clampf(1.0-windup/maxf(0.001,maximum),0.0,1.0)
			var danger: Color = Color(1.0,0.34,0.22,0.92 if strong else 0.62)
			draw_arc(pos,radius+16.0,-PI*0.5,-PI*0.5+TAU*progress,30,danger,4.0 if strong else 2.0)
			var tdir: Vector2 = Vector2(enemy.get("telegraph_dir",enemy.get("look",Vector2.DOWN))).normalized()
			if tdir.length_squared()>0.1 and String(enemy.get("style","")) in ["charger","ranged","skirmisher"]:
				draw_line(pos+tdir*(radius+5.0),pos+tdir*(190.0 if String(enemy.get("style",""))=="charger" else 128.0),Color(danger,0.23),4.0 if strong else 2.0)
		if delay > 0.0:
			var max_delay: float = maxf(0.001,float(enemy.get("activation_delay_max",delay)))
			var materialize: float = clampf(1.0-delay/max_delay,0.0,1.0)
			var biome_accent: Color = Color(BIOMES[biome_index]["accent"])
			draw_circle(pos,radius*(0.42+materialize*0.38),Color(biome_accent,0.08+materialize*0.10))
			draw_arc(pos,radius+12.0,-PI*0.5,-PI*0.5+TAU*materialize,26,Color(biome_accent,0.78),3.0)
		var texture: Texture2D = _enemy_entropy_texture(enemy)
		var source_size: int = 96 if boss else 48
		var direction_index: int = quantize_direction(Vector2(enemy.get("look",Vector2.DOWN)))
		var frame: int = _enemy_authored_frame(enemy)
		var scale: float = float(genome.get("visual_scale",1.0))
		var display: float = (122.0+radius*0.68)*scale if boss else (60.0+radius*0.76)*scale
		draw_circle(pos+Vector2(0,radius*0.72),radius*0.74,Color(0,0,0,0.28))
		if texture != null:
			var alpha: float = 0.55+0.45*clampf(1.0-delay/maxf(0.001,float(enemy.get("activation_delay_max",1.0))),0.0,1.0) if delay>0.0 else 1.0
			var dest: Rect2 = Rect2(pos-Vector2(display*0.5,display*0.66),Vector2(display,display))
			var src: Rect2 = Rect2(Vector2(frame*source_size,direction_index*source_size),Vector2(source_size,source_size))
			draw_texture_rect_region(texture,dest,src,Color(1,1,1,alpha))
			if frame == 2 and not boss:
				var facing: Vector2 = Vector2(enemy.get("look",Vector2.DOWN)).normalized()
				if facing.length_squared()>0.01:
					draw_circle(pos+facing*(radius+22.0),2.5,Color(1.0,0.48,0.23,0.74))
		if bool(enemy.get("elite",false)):
			var definition: Dictionary = director.elite_definition(String(enemy.get("affix","armored")))
			var elite_color: Color = Color(definition.get("color",Color8(226,188,102)))
			draw_arc(pos,radius+10.0,visual_clock,visual_clock+PI*1.6,28,elite_color,3.0)
		if float(enemy.get("shield_hp",0.0))>0.0:
			draw_arc(pos,radius+6.0,-PI*0.86,PI*0.86,24,Color8(121,171,244),3.0)
		var hp_ratio: float = clampf(float(enemy.get("hp",1.0))/maxf(0.001,float(enemy.get("max_hp",enemy.get("hp",1.0)))),0.0,1.0)
		if hp_ratio<0.999 or boss or bool(enemy.get("elite",false)):
			var width: float = clampf(radius*2.25,38.0,110.0)
			var health: Rect2 = Rect2(pos+Vector2(-width*0.5,radius+14.0),Vector2(width,6.0 if boss else 5.0))
			draw_rect(health,Color8(31,16,18,225))
			draw_rect(Rect2(health.position,Vector2(health.size.x*hp_ratio,health.size.y)),Color8(217,68,59))
			draw_rect(health,Color8(236,196,142,165),false,1.0)
		var status_index: int = 0
		for status_variant in ["burn","marked","spore","stagger"]:
			var status: String = String(status_variant)
			if float(enemy.get(status,0.0))>0.0:
				var status_color: Color = Color8(226,110,80) if status=="burn" else (Color8(224,86,70) if status=="marked" else (Color8(177,104,207) if status=="spore" else Color8(226,196,105)))
				draw_circle(pos+Vector2(-15.0+status_index*10.0,-radius-10.0),3.2,status_color)
				status_index += 1

func audit_art_direction_contract() -> Dictionary:
	var report: Dictionary = super.audit_art_direction_contract()
	report["authored_animation_version"] = AUTHORED_ANIMATION_VERSION
	report["state_addressed_frames"] = true
	report["idle_pose"] = true
	report["locomotion_pose"] = true
	report["attack_recoil_pose"] = true
	report["dash_hurt_pose"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["state_addressed_animation"] = true
	return report
