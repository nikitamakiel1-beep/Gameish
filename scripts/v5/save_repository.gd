extends RefCounted

const VERSION := 5
const INTEGRITY_FIELD := "_integrity_sha256"

func read_json(path: String, fallback: Dictionary = {}) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var parsed: Dictionary = _read_candidate(candidate)
		if not parsed.is_empty():
			return parsed
	return fallback.duplicate(true)

func write_json_atomic(path: String, payload: Dictionary) -> bool:
	var directory := path.get_base_dir()
	if directory != "" and not DirAccess.dir_exists_absolute(directory):
		var mkdir_result := DirAccess.make_dir_recursive_absolute(directory)
		if mkdir_result != OK:
			return false
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var wrapped := payload.duplicate(true)
	wrapped["schema_version"] = VERSION
	wrapped.erase(INTEGRITY_FIELD)
	var checksum := _checksum_for(wrapped)
	if checksum.is_empty():
		return false
	wrapped[INTEGRITY_FIELD] = checksum

	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(wrapped))
	file.flush()
	file.close()
	if not _candidate_is_valid(temporary):
		DirAccess.remove_absolute(temporary)
		return false

	# Never replace a previous-good backup with a corrupt-but-parseable primary.
	var primary_exists := FileAccess.file_exists(path)
	var primary_valid := primary_exists and _candidate_is_valid(path)
	if primary_valid:
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		if DirAccess.rename_absolute(path, backup) != OK:
			DirAccess.remove_absolute(temporary)
			return false
	elif primary_exists:
		DirAccess.remove_absolute(path)

	var result := DirAccess.rename_absolute(temporary, path)
	if result != OK:
		if FileAccess.file_exists(backup) and not FileAccess.file_exists(path):
			DirAccess.rename_absolute(backup, path)
		return false
	if not _candidate_is_valid(path):
		DirAccess.remove_absolute(path)
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
		"sha256_integrity": true,
		"valid_json_tamper_detection": true,
		"prepromotion_readback": true,
		"preserve_good_backup_on_bad_primary": true,
		"legacy_read_compatibility": true,
	}

func _read_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var document := Dictionary(parsed)
	if document.has(INTEGRITY_FIELD):
		var expected := String(document.get(INTEGRITY_FIELD, ""))
		var actual := _checksum_for(document)
		if expected.is_empty() or actual.is_empty() or expected != actual:
			return {}
	document.erase(INTEGRITY_FIELD)
	return document

func _candidate_is_valid(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return false
	var document := Dictionary(parsed)
	if not document.has(INTEGRITY_FIELD):
		return false
	var expected := String(document.get(INTEGRITY_FIELD, ""))
	return not expected.is_empty() and expected == _checksum_for(document)

func _checksum_for(payload: Dictionary) -> String:
	var canonical := payload.duplicate(true)
	canonical.erase(INTEGRITY_FIELD)
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if context.update(JSON.stringify(canonical).to_utf8_buffer()) != OK:
		return ""
	return context.finish().hex_encode()
