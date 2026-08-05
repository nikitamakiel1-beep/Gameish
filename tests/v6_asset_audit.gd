extends SceneTree

const ProductionPackScript: Script = preload("res://scripts/v6/production_pack.gd")
const AnimationContractScript: Script = preload("res://scripts/v6/animation_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var pack: RefCounted = ProductionPackScript.new()
	if not bool(pack.call("mount")):
		failures.append("Production pack failed to mount.")
	var report: Dictionary = pack.call("audit")
	if not bool(report.get("ok", false)):
		for failure in Array(report.get("failures", [])):
			failures.append(String(failure))
	if AnimationContractScript.DIRECTIONS.size() != 8:
		failures.append("Direction contract is not eight-directional.")
	if AnimationContractScript.HERO_ACTIONS.size() != 11:
		failures.append("Hero action contract is incomplete.")
	if int(AnimationContractScript.hero_row("attack", 7)) != 31:
		failures.append("Hero attack row contract is incorrect.")
	if int(AnimationContractScript.enemy_row("death", 7)) != 39:
		failures.append("Enemy death row contract is incorrect.")
	if int(AnimationContractScript.boss_row("phase", 7)) != 47:
		failures.append("Boss phase row contract is incorrect.")
	var registry: Dictionary = pack.get("registry")
	if Dictionary(registry.get("heroes", {})).size() != 5:
		failures.append("Hero registry count mismatch.")
	if Dictionary(registry.get("enemies", {})).size() != 18:
		failures.append("Enemy registry count mismatch.")
	if Dictionary(registry.get("bosses", {})).size() != 5:
		failures.append("Boss registry count mismatch.")
	if Dictionary(registry.get("biomes", {})).size() != 5:
		failures.append("Biome registry count mismatch.")
	var main_scene := load("res://main.tscn")
	if main_scene == null:
		failures.append("Main scene could not be loaded.")
	else:
		var instance := main_scene.instantiate()
		root.add_child(instance)
		await process_frame
		await process_frame
		if not bool(instance.get("v6_asset_ready")):
			failures.append("Main runtime did not mount production assets.")
		if float(instance.get("readiness")) < 90.0:
			failures.append("v0.6 runtime readiness is below 90%.")
		instance.queue_free()
	if failures.is_empty():
		print("EDEN_FALL_V6_ASSET_AUDIT PASS")
		print(JSON.stringify(report))
		quit(0)
	else:
		for failure in failures:
			push_error("[V6 AUDIT] %s" % failure)
		print("EDEN_FALL_V6_ASSET_AUDIT FAIL")
		print(JSON.stringify({"failures": failures, "report": report}))
		quit(1)
