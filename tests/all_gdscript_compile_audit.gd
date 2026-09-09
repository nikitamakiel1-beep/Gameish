extends SceneTree

const ROOTS: Array[String] = ["res://scripts", "res://tests"]
const SELF_PATH: String = "res://tests/all_gdscript_compile_audit.gd"

func _collect_scripts(root: String, out: Array[String], errors: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		errors.append("Cannot open script root: " + root)
		return
	var begin_error: Error = dir.list_dir_begin()
	if begin_error != OK:
		errors.append("Cannot enumerate script root: %s (%s)" % [root, error_string(begin_error)])
		return
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry != "." and entry != ".." and not entry.begins_with("."):
			var full_path: String = root.path_join(entry)
			if dir.current_is_dir():
				_collect_scripts(full_path, out, errors)
			elif entry.ends_with(".gd"):
				out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _init() -> void:
	var errors: Array[String] = []
	var paths: Array[String] = []
	for root: String in ROOTS:
		_collect_scripts(root, paths, errors)
	paths.sort()

	var checked: int = 0
	for path: String in paths:
		if path == SELF_PATH:
			continue
		var resource: Resource = load(path)
		if resource == null:
			errors.append("Failed to load GDScript: " + path)
			continue
		var script: Script = resource as Script
		if script == null:
			errors.append("Resource is not a Script: " + path)
			continue
		if not script.can_instantiate():
			errors.append("GDScript cannot instantiate: " + path)
			continue
		checked += 1
		print("EDEN_GDSCRIPT_PASS=" + path)

	var report: Dictionary = {
		"roots": ROOTS,
		"discovered": paths.size(),
		"checked": checked,
		"errors": errors,
		"passed": errors.is_empty(),
	}
	print("EDEN_ALL_GDSCRIPT_COMPILE_REPORT=" + JSON.stringify(report))
	if errors.is_empty():
		print("EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS")
		quit(0)
	else:
		for message: String in errors:
			push_error(message)
		quit(1)
