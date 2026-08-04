extends RefCounted

const VERSION := 5

func read_json(path: String, fallback: Dictionary = {}) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var file := FileAccess.open(candidate, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			return Dictionary(parsed)
	return fallback.duplicate(true)

func write_json_atomic(path: String, payload: Dictionary) -> bool:
	var directory := path.get_base_dir()
	if directory != "" and not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	var wrapped := payload.duplicate(true)
	wrapped["schema_version"] = VERSION
	file.store_string(JSON.stringify(wrapped))
	file.flush()
	file = null
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, backup)
	var result := DirAccess.rename_absolute(temporary, path)
	if result != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, path)
		return false
	return true

func remove_with_backup(path: String) -> void:
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)

func audit_contract() -> Dictionary:
	return {
		"version": VERSION,
		"atomic_write": true,
		"backup_recovery": true,
		"temporary_file": true,
		"schema_tag": true,
	}
