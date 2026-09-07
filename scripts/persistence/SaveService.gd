extends Node

const SCHEMA_VERSION := 1

var profile_path := "user://profile_v1.json"
var temporary_path := "user://profile_v1.tmp"
var backup_path := "user://profile_v1.bak"


func configure_paths(profile: String, temporary: String, backup: String) -> void:
	profile_path = profile
	temporary_path = temporary
	backup_path = backup


func load_profile() -> Dictionary:
	var primary := _read_valid_profile(profile_path)
	if not primary.is_empty():
		return primary
	var backup := _read_valid_profile(backup_path)
	if not backup.is_empty():
		return backup
	return default_profile()


func mark_level_complete(level_id: String, white_actions: int) -> Dictionary:
	var profile := load_profile()
	var completed: Array = profile["completed_level_ids"]
	if not completed.has(level_id):
		completed.append(level_id)
		completed.sort()
	var best: Dictionary = profile["best_white_actions"]
	var old_best := int(best.get(level_id, 0))
	if old_best == 0 or white_actions < old_best:
		best[level_id] = white_actions
	profile["completed_level_ids"] = completed
	profile["best_white_actions"] = best
	var error := save_profile(profile)
	return {"ok": error.is_empty(), "error": error, "profile": profile}


func save_profile(profile: Dictionary) -> String:
	if not _is_valid_profile(profile):
		return "Profile data does not match schema v1."
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return "Unable to create the temporary profile."
	file.store_string(JSON.stringify(profile, "\t", true))
	file.flush()
	file.close()
	if _read_valid_profile(temporary_path).is_empty():
		return "Temporary profile validation failed."
	if FileAccess.file_exists(profile_path):
		DirAccess.copy_absolute(profile_path, backup_path)
	var rename_error := DirAccess.rename_absolute(temporary_path, profile_path)
	if rename_error != OK:
		return "Unable to replace the profile with the validated temporary file."
	return ""


func default_profile() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"completed_level_ids": [],
		"best_white_actions": {},
		"settings": {
			"reduced_motion": false,
			"high_contrast": false,
		},
	}


func _read_valid_profile(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not _is_valid_profile(parsed):
		return {}
	return parsed


func _is_valid_profile(profile: Dictionary) -> bool:
	if int(profile.get("schema_version", 0)) != SCHEMA_VERSION:
		return false
	if not profile.get("completed_level_ids", null) is Array:
		return false
	if not profile.get("best_white_actions", null) is Dictionary:
		return false
	var settings = profile.get("settings", null)
	if not settings is Dictionary:
		return false
	return settings.has("reduced_motion") and settings.has("high_contrast")

