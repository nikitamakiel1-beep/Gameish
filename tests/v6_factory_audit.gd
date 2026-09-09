extends SceneTree

const RegistryScript: Script = preload("res://scripts/v6/asset_registry.gd")
const BootstrapScript: Script = preload("res://scripts/v6/engine_bootstrap.gd")
const BudgetScript: Script = preload("res://scripts/v6/performance_budget.gd")

func _init() -> void:
	var bootstrap: RefCounted = BootstrapScript.new()
	var engine_report: Dictionary = bootstrap.call("configure")
	print("EDEN_FALL_V6_ENGINE_REPORT=" + JSON.stringify(engine_report))
	if not bool(engine_report.get("exact_version", false)):
		push_error("Factory audit requires exact Godot 4.7.1")
		quit(1)
		return

	var budget: RefCounted = BudgetScript.new()
	var budget_report: Dictionary = budget.call("configure")
	print("EDEN_FALL_V6_BUDGET_REPORT=" + JSON.stringify(budget_report))

	var registry: RefCounted = RegistryScript.new()
	var asset_report: Dictionary = registry.call("validate_contract", true)
	print("EDEN_FALL_V6_FACTORY_REPORT=" + JSON.stringify(asset_report))
	if not bool(asset_report.get("passed", false)):
		for error in Array(asset_report.get("errors", [])):
			push_error(String(error))
		quit(2)
		return

	var before_clear: Dictionary = registry.call("cache_report")
	registry.call("clear_caches")
	var after_clear: Dictionary = registry.call("cache_report")
	print("EDEN_FALL_V6_CACHE_BEFORE_CLEAR=" + JSON.stringify(before_clear))
	print("EDEN_FALL_V6_CACHE_AFTER_CLEAR=" + JSON.stringify(after_clear))
	if int(after_clear.get("textures", -1)) != 0 or int(after_clear.get("audio", -1)) != 0:
		push_error("Production asset caches did not clear")
		quit(3)
		return

	print("EDEN_FALL_V6_FACTORY_AUDIT=PASS")
	quit(0)
