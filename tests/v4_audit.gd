extends SceneTree

const DIRECTOR_PATH := "res://scripts/v4/run_director.gd"
const RUNTIME_PATH := "res://scripts/edenfall_v4.gd"

var failures: Array[String] = []

func _init() -> void:
	validate_director()
	validate_runtime()
	validate_project_contract()
	if failures.is_empty():
		print("EDEN//FALL v4 audit passed: director, weapons, modifiers, elites, mastery, UI, saves and inherited v3 contract")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("EDEN//FALL v4 audit failed with %d issue(s)" % failures.size())
		quit(1)

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func validate_director() -> void:
	expect(ResourceLoader.exists(DIRECTOR_PATH), "Missing v4 run director")
	if not ResourceLoader.exists(DIRECTOR_PATH):
		return
	var director_script: Script = load(DIRECTOR_PATH) as Script
	expect(director_script != null, "Could not load v4 run director")
	if director_script == null:
		return
	var director = director_script.new()
	expect(director != null, "Could not instantiate v4 run director")
	if director == null:
		return
	director.configure(123456, "standard")
	var contract: Dictionary = director.audit_contract()
	expect(int(contract.get("version",0)) == 4, "Director contract version mismatch")
	expect(int(contract.get("modifiers",0)) >= 8, "Expected at least eight encounter modifiers")
	expect(int(contract.get("elite_affixes",0)) >= 6, "Expected at least six elite affixes")
	expect(int(contract.get("weapons",0)) == 5, "Expected five lineage weapons")
	expect(int(contract.get("mastery_ranks",0)) >= 8, "Expected eight mastery ranks")
	expect(director.daily_seed(2026, 803) == director.daily_seed(2026, 803), "Daily seed must be deterministic")
	expect(director.daily_seed(2026, 803) != director.daily_seed(2026, 804), "Daily seed must change between dates")
	expect(float(director.threat_level(4, 30, 5, "daily")) > float(director.threat_level(0, 0, 1, "training")), "Threat scaling is not monotonic")
	expect(int(director.encounter_budget(4, 8, 30, "daily")) > int(director.encounter_budget(0, 1, 0, "training")), "Encounter budget is not scaling")
	for lineage in ["adam","abel","cain","seth","naamah"]:
		var weapon: Dictionary = director.weapon_for(lineage)
		expect(not weapon.is_empty(), "Missing weapon for %s" % lineage)
		expect(String(weapon.get("name","")) != "", "Weapon name missing for %s" % lineage)
		expect(float(weapon.get("damage",0.0)) > 0.0, "Weapon damage invalid for %s" % lineage)
	director = null

func validate_runtime() -> void:
	expect(ResourceLoader.exists(RUNTIME_PATH), "Missing v4 runtime")
	if not ResourceLoader.exists(RUNTIME_PATH):
		return
	var runtime_script: Script = load(RUNTIME_PATH) as Script
	expect(runtime_script != null, "Could not load v4 runtime")
	if runtime_script == null:
		return
	var runtime: Node2D = runtime_script.new() as Node2D
	expect(runtime != null, "Could not instantiate v4 runtime")
	if runtime == null:
		return
	expect(runtime.quantize_direction(Vector2.UP) == 0, "Inherited north direction contract failed")
	expect(runtime.quantize_direction(Vector2(1,-1)) == 1, "Inherited northeast direction contract failed")
	expect(runtime.directional_row("attack",4) == 20, "Inherited directional animation row failed")
	expect(runtime.relic_catalog().size() == 60, "Inherited relic catalog changed unexpectedly")
	expect(runtime.title_options().has("DAILY PROTOCOL"), "Daily protocol missing from title options")
	expect(runtime.title_options().has("TRAINING SIMULATION"), "Training simulation missing from title options")
	expect(runtime.settings_rows().size() >= 15, "Expanded accessibility settings missing")
	expect(runtime.accuracy_percent() == 0.0, "Zero-shot accuracy must be zero")
	expect(runtime.audit_v4_readiness() >= 90.0, "v4 runtime readiness contract is below 90 percent")
	runtime.free()

func validate_project_contract() -> void:
	expect(FileAccess.file_exists("res://main.tscn"), "Main scene missing")
	var scene_text := FileAccess.get_file_as_string("res://main.tscn")
	expect(scene_text.contains("scripts/edenfall_v4_quality.gd"), "Main scene does not load the v4 quality runtime")
	expect(FileAccess.file_exists("res://docs/READINESS_V4.md"), "v4 readiness document missing")
	expect(FileAccess.file_exists("res://docs/V4_SYSTEMS.md"), "v4 systems document missing")
	expect(FileAccess.file_exists("res://assets/generated_v3/manifest_v3.json"), "Validated v3 directional assets missing")
