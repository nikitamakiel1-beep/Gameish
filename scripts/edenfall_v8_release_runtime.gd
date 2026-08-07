extends "res://scripts/edenfall_v8_streaming_runtime.gd"

const V8_RELEASE_VERSION := "0.6.2-entropy"
const PremiumSpriteForgeScript: Script = preload("res://scripts/v8/procedural_sprite_forge_premium.gd")

func _ready() -> void:
	sprite_forge = PremiumSpriteForgeScript.new()
	super._ready()

func spawn_enemy(id: String, position: Vector2, variant: int = 0) -> void:
	super.spawn_enemy(id,position,variant)
	if enemies.is_empty():
		return
	var index := enemies.size()-1
	var enemy: Dictionary = enemies[index]
	if bool(enemy.get("boss",false)):
		enemies[index] = enemy
		return
	var local_rng: RandomNumberGenerator = entropy.call("fork","trait_timer:"+String(enemy.get("visual_key",id)))
	enemy["v8_trait_timer"] = local_rng.randf_range(2.6,5.5)
	enemy["v8_trait_windup"] = 0.0
	enemy["v8_trait_windup_max"] = 0.0
	enemy["v8_burst_time"] = 0.0
	enemy["v8_burst_dir"] = Vector2.ZERO
	enemies[index] = enemy

func update_enemies(delta: float) -> void:
	super.update_enemies(delta)
	_update_entropy_trait_actions(delta)

func update_enemy_style(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	var movement := super.update_enemy_style(enemy,direction,distance,delta)
	var burst := maxf(0.0,float(enemy.get("v8_burst_time",0.0))-delta)
	if float(enemy.get("v8_burst_time",0.0)) > 0.0:
		enemy["v8_burst_time"] = burst
		var burst_dir := Vector2(enemy.get("v8_burst_dir",direction)).normalized()
		if burst_dir.length_squared() > 0.01:
			return burst_dir*float(enemy.get("speed",80.0))*2.35
	return movement

func update_boss(enemy: Dictionary, direction: Vector2, distance: float, delta: float) -> Vector2:
	if not bool(enemy.get("visual_pending",false)) and float(enemy.get("boss_windup",0.0)) <= 0.0 and float(enemy.get("cooldown",0.0)) <= 0.0:
		var cycle := int(enemy.get("v8_boss_roll_cycle",0))
		var local_rng: RandomNumberGenerator = entropy.call("fork","boss_pattern:%s:%d" % [String(enemy.get("visual_key",enemy.get("id","boss"))),cycle])
		enemy["boss_pattern_index"] = local_rng.randi_range(0,2)
		enemy["v8_boss_roll_cycle"] = cycle+1
	return super.update_boss(enemy,direction,distance,delta)

func _update_entropy_trait_actions(delta: float) -> void:
	for index in range(enemies.size()):
		if index >= enemies.size():
			break
		var enemy: Dictionary = enemies[index]
		if bool(enemy.get("boss",false)) or bool(enemy.get("visual_pending",false)) or float(enemy.get("activation_delay",0.0)) > 0.0:
			continue
		var genome: Dictionary = enemy.get("v8_visual_genome",{})
		if genome.is_empty():
			continue
		var windup := float(enemy.get("v8_trait_windup",0.0))
		if windup > 0.0:
			windup = maxf(0.0,windup-delta)
			enemy["v8_trait_windup"] = windup
			enemy["attack"] = maxf(float(enemy.get("attack",0.0)),windup)
			enemies[index] = enemy
			if windup <= 0.0:
				_release_entropy_trait_action(index)
			continue
		var timer := float(enemy.get("v8_trait_timer",3.6))-delta
		enemy["v8_trait_timer"] = timer
		if timer <= 0.0:
			var role := String(genome.get("role",enemy.get("style","melee")))
			var windup_duration := _trait_windup_for_role(role)
			enemy["v8_trait_windup"] = windup_duration
			enemy["v8_trait_windup_max"] = windup_duration
			enemy["attack"] = windup_duration
			_play_trait_warning(role)
		enemies[index] = enemy

func _trait_windup_for_role(role: String) -> float:
	match role:
		"charger": return 0.64
		"caster", "radial": return 0.70
		"ranged": return 0.52
		"skirmisher", "orbiter": return 0.46
		_: return 0.42

func _play_trait_warning(role: String) -> void:
	var warning := "warning_melee"
	if role == "ranged": warning = "warning_aimed"
	elif role in ["caster","radial","orbiter"]: warning = "warning_radial"
	play_sfx(warning,-9.0,95)

func _release_entropy_trait_action(index: int) -> void:
	if index < 0 or index >= enemies.size() or player.is_empty():
		return
	var enemy: Dictionary = enemies[index]
	var genome: Dictionary = enemy.get("v8_visual_genome",{})
	var trait := String(genome.get("trait",""))
	var role := String(genome.get("role",enemy.get("style","melee")))
	var origin := Vector2(enemy["pos"])
	var target := (Vector2(player["pos"])-origin).normalized()
	if target.length_squared() < 0.001:
		target = Vector2.DOWN
	match trait:
		"burst":
			for angle in [-0.12,0.0,0.12]: enemy_shoot(origin,target.rotated(angle),380.0*float(genome.get("projectile_speed_mult",1.0)),1.0)
		"marksman":
			enemy_shoot(origin,target,520.0*float(genome.get("projectile_speed_mult",1.0)),1.2)
		"suppression":
			for angle in [-0.42,-0.21,0.0,0.21,0.42]: enemy_shoot(origin,target.rotated(angle),305.0,0.85)
		"scatter":
			for angle in [-0.54,-0.36,-0.18,0.0,0.18,0.36,0.54]: enemy_shoot(origin,target.rotated(angle),280.0,0.75)
		"ritual", "nova", "ring":
			var count := 8 if trait != "nova" else 12
			var phase := float(genome.get("phase_offset",0.0))+visual_clock*0.11
			for shot in range(count): enemy_shoot(origin,Vector2.RIGHT.rotated(TAU*float(shot)/float(count)+phase),275.0,0.9)
		"seeker":
			for angle in [-0.22,0.0,0.22]: enemy_shoot(origin,target.rotated(angle),340.0,0.9)
		"zone", "minefield":
			for shot in range(6): enemy_shoot(origin,Vector2.RIGHT.rotated(TAU*float(shot)/6.0),205.0,0.8)
		"summoner":
			if enemies.size() < 9:
				var pool: Array = enemy_pool_for_biome()
				var summon_id := String(entropy.call("pick",pool,"feral_scavenger"))
				var side_rng: RandomNumberGenerator = entropy.call("fork","summon:"+String(enemy.get("visual_key","")))
				var angle := side_rng.randf_range(0.0,TAU)
				spawn_enemy(summon_id,_resolve_position_against_obstacles(origin+Vector2.RIGHT.rotated(angle)*82.0,20.0),_enemy_uid_counter)
		"flanker", "feint", "blink", "dashshot":
			var side := -1.0 if bool(entropy.call("chance",0.5)) else 1.0
			enemy["v8_burst_dir"] = target.rotated(side*0.82)
			enemy["v8_burst_time"] = 0.24
			if trait == "dashshot": enemy_shoot(origin,target,390.0,0.9)
		"ram", "juggernaut", "shockwave", "breach":
			enemy["v8_burst_dir"] = target
			enemy["v8_burst_time"] = 0.30 if trait != "juggernaut" else 0.38
			if trait == "shockwave":
				for shot in range(6): enemy_shoot(origin,Vector2.RIGHT.rotated(TAU*float(shot)/6.0),190.0,0.75)
		"orbit", "satellite", "spiral", "harrier":
			var count := 6 if trait != "spiral" else 9
			for shot in range(count): enemy_shoot(origin,Vector2.RIGHT.rotated(TAU*float(shot)/float(count)+visual_clock*0.24),250.0,0.8)
		"ripper", "stalker", "leaper", "bloodrush":
			enemy["v8_burst_dir"] = target
			enemy["v8_burst_time"] = 0.20 if trait != "bloodrush" else 0.32
		_:
			if role in ["ranged","caster","radial","orbiter"]: enemy_shoot(origin,target,320.0,0.85)
	var reset_rng: RandomNumberGenerator = entropy.call("fork","trait_reset:"+String(enemy.get("visual_key",enemy.get("id","enemy"))))
	enemy["v8_trait_timer"] = reset_rng.randf_range(3.0,6.2)
	enemy["v8_trait_windup"] = 0.0
	enemy["attack"] = 0.22
	if index < enemies.size():
		enemies[index] = enemy

func draw_enemies() -> void:
	super.draw_enemies()
	var strong := bool(settings.get("strong_telegraphs",true))
	for enemy_variant in enemies:
		var enemy: Dictionary = enemy_variant
		if bool(enemy.get("boss",false)):
			continue
		var windup := float(enemy.get("v8_trait_windup",0.0))
		if windup <= 0.0:
			continue
		var maximum := maxf(windup,float(enemy.get("v8_trait_windup_max",windup)))
		var progress := clampf(1.0-windup/maxf(0.001,maximum),0.0,1.0)
		var pos := Vector2(enemy["pos"])
		var radius := float(enemy.get("radius",18.0))+20.0
		var color := Color(1.0,0.49,0.22,0.90 if strong else 0.58)
		draw_arc(pos,radius,-PI*0.5,-PI*0.5+TAU*progress,28,color,4.0 if strong else 2.0)

func get_v6_diagnostics() -> Dictionary:
	var report: Dictionary = super.get_v6_diagnostics()
	report["v8_release_version"] = V8_RELEASE_VERSION
	report["generation_mode"] = "stochastic_condition_driven"
	report["fixed_seed_replay"] = false
	report["premium_sprite_forge"] = true
	report["stochastic_guardian_pattern_order"] = true
	report["generated_trait_combat_actions"] = true
	return report

func audit_godmode_contract() -> Dictionary:
	var report: Dictionary = super.audit_godmode_contract()
	report["version"] = V8_RELEASE_VERSION
	report["deterministic_floor_graph"] = false
	report["deterministic_special_rooms"] = false
	report["fixed_seed_replay"] = false
	report["entropy_floor_graph"] = true
	report["entropy_special_rooms"] = true
	report["active_run_recipe_persistence"] = true
	report["stochastic_guardian_pattern_order"] = true
	return report

func audit_entropy_contract() -> Dictionary:
	var report: Dictionary = super.audit_entropy_contract()
	report["version"] = V8_RELEASE_VERSION
	report["release_root"] = true
	report["premium_sprite_forge"] = true
	report["stochastic_guardian_pattern_order"] = true
	report["generated_trait_combat_actions"] = true
	report["trait_windups"] = true
	return report

func audit_masterpiece_contract() -> Dictionary:
	var report: Dictionary = super.audit_masterpiece_contract()
	report["version"] = V8_RELEASE_VERSION
	report["release_root"] = true
	report["premium_sprite_forge"] = true
	report["generated_trait_combat_actions"] = true
	return report
