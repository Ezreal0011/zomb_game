extends Node

## Loads JSON config files for gameplay systems.

static func get_config(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Config file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open config file: %s" % path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Config file must contain a JSON object: %s" % path)
		return {}

	return parsed