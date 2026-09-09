extends SceneTree

const EXPECTED_RELEASE_ROOT: String = "res://scripts/edenfall_v8_release_runtime.gd"
const EXPECTED_FORGE: String = "res://scripts/v8/procedural_sprite_forge_art4.gd"
const EXPECTED_GENOME: String = "res://scripts/v8/enemy_genome_director_art4.gd"
const EXPECTED_WORLD: String = "res://scripts/v8/procedural_world_director_art4.gd"
const EXPECTED_REVISION: String = "0.6.4-authored-art4"

func _script_path(value: Variant) -> String:
	if value == null or not (value is Object):
		return ""
	var object: Object = value
	var script: Script = object.get_script() as Script
	return script.resource_path if script != null else ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var scene: PackedScene = load("res://main.tscn") as PackedScene
	if scene == null:
		errors.append("main.tscn failed to load")
		_finish(errors, {})
		return

	var instance: Node = scene.instantiate()
	root.add_child(instance)
	await process_frame

	var runtime_script: Script = instance.get_script() as Script
	var release_root_path: String = runtime_script.resource_path if runtime_script != null else ""
	if release_root_path != EXPECTED_RELEASE_ROOT:
		errors.append("Live root script mismatch: " + release_root_path)

	var forge: Variant = instance.get("sprite_forge")
	var genomes: Variant = instance.get("genome_director")
	var world: Variant = instance.get("world_director")
	var forge_path: String = _script_path(forge)
	var genome_path: String = _script_path(genomes)
	var world_path: String = _script_path(world)

	if forge_path != EXPECTED_FORGE:
		errors.append("Live sprite forge is not Art4: " + forge_path)
	if genome_path != EXPECTED_GENOME:
		errors.append("Live genome director is not Art4: " + genome_path)
	if world_path != EXPECTED_WORLD:
		errors.append("Live world director is not Art4: " + world_path)

	var forge_contract: Dictionary = {}
	if forge != null and forge.has_method("audit_contract"):
		forge_contract = forge.call("audit_contract")
		if String(forge_contract.get("art4_forge_version", "")) != EXPECTED_REVISION:
			errors.append("Live forge contract revision mismatch")
	else:
		errors.append("Live sprite forge audit contract unavailable")

	var genome_contract: Dictionary = {}
	if genomes != null and genomes.has_method("audit_contract"):
		genome_contract = genomes.call("audit_contract")
		if String(genome_contract.get("art4_genome_version", "")) != EXPECTED_REVISION:
			errors.append("Live genome contract revision mismatch")
	else:
		errors.append("Live genome audit contract unavailable")

	var world_contract: Dictionary = {}
	if world != null and world.has_method("audit_contract"):
		world_contract = world.call("audit_contract")
		if String(world_contract.get("art4_world_version", "")) != EXPECTED_REVISION:
			errors.append("Live world contract revision mismatch")
	else:
		errors.append("Live world audit contract unavailable")

	var runtime_contract: Dictionary = {}
	if instance.has_method("audit_release_binding_contract"):
		runtime_contract = instance.call("audit_release_binding_contract")
		if String(runtime_contract.get("product_revision", "")) != EXPECTED_REVISION:
			errors.append("Live release binding revision mismatch")
		if not bool(runtime_contract.get("parent_installs_art4", false)):
			errors.append("Release binding does not require parent Art4 installation")
	else:
		errors.append("Release binding contract unavailable on live instance")

	# Counter-check the contracts with actual generated output from the installed
	# objects. This prevents a set of true flags from passing while the live
	# component graph is wrong or non-functional.
	if forge != null and genomes != null and forge.has_method("build_player_sheet") and genomes.has_method("player_genome"):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 440044
		var adam: Dictionary = genomes.call("player_genome", rng, "adam", 0)
		var sheet: Image = forge.call("build_player_sheet", adam)
		if sheet == null or sheet.is_empty():
			errors.append("Live Art4 forge could not generate canonical Adam sheet")
		elif sheet.get_width() < 48 or sheet.get_height() < 48:
			errors.append("Live Art4 player sheet is below the 48px actor ABI")
	else:
		errors.append("Live Art4 components cannot generate a player sheet")

	var report: Dictionary = {
		"revision": EXPECTED_REVISION,
		"inside_tree": instance.is_inside_tree(),
		"release_root": release_root_path,
		"sprite_forge": forge_path,
		"genome_director": genome_path,
		"world_director": world_path,
		"forge_contract": forge_contract,
		"genome_contract": genome_contract,
		"world_contract": world_contract,
		"release_binding": runtime_contract,
		"errors": errors,
		"passed": errors.is_empty(),
	}
	instance.queue_free()
	_finish(errors, report)

func _finish(errors: Array[String], report: Dictionary) -> void:
	if report.is_empty():
		report = {"revision": EXPECTED_REVISION, "errors": errors, "passed": false}
	print("EDEN_FALL_V8_LIVE_BINDING_COUNTERAUDIT_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_FALL_V8_LIVE_BINDING_COUNTERAUDIT=PASS")
		quit(0)
	else:
		for message: String in errors:
			push_error(message)
		quit(1)
