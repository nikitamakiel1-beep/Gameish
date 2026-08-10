extends SceneTree

const RegistryScript: Script = preload("res://scripts/v7/asset_registry_masterpiece.gd")
const EvaluatorScript: Script = preload("res://scripts/v7/sprite_quality_evaluator.gd")
const BOSS_IDS: Array[String] = ["watcher_engine","first_nephilim","gate_cherub","tower_enoch","serpent_interface"]

func _init() -> void:
	var registry: RefCounted = RegistryScript.new()
	var evaluator: RefCounted = EvaluatorScript.new()
	var failed: Array[String] = []
	for id: String in BOSS_IDS:
		var result: Dictionary = evaluator.call("evaluate_actor",registry.call("boss_sheet",id),Vector2i(96,96),Vector2i(28,34),3)
		print("EDEN_GUARDIAN_READABILITY=%s:%s" % [id,JSON.stringify(result)])
		if not bool(result.get("passed",false)):
			failed.append(id)
	if failed.is_empty():
		print("EDEN_GUARDIAN_READABILITY=PASS")
		quit(0)
	else:
		push_error("EDEN_GUARDIAN_READABILITY=FAIL:" + ",".join(failed))
		quit(1)
