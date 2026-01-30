extends Node

## SetLoader - Autoload singleton for loading level sets from JSON
## Provides set data and manages set configurations

const SETS_DATA_PATH = "res://data/level_sets.json"

# Cached sets data
var sets_data: Dictionary = {}
var sets_array: Array = []

func _ready():
	"""Initialize set loader and load sets from JSON"""
	print("SetLoader ready")
	load_sets()

func load_sets() -> void:
	"""Load all sets from the JSON configuration file"""
	if not FileAccess.file_exists(SETS_DATA_PATH):
		push_error("Sets data file not found: " + SETS_DATA_PATH)
		return

	var file = FileAccess.open(SETS_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open sets data file: " + SETS_DATA_PATH)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse sets data JSON")
		return

	var data = json.data
	sets_array = data.get("sets", [])

	# Build a dictionary for quick lookup by set_id
	for set_data in sets_array:
		var set_id = int(set_data.get("set_id", -1))  # Convert to int to avoid float issues
		if set_id != -1:
			sets_data[set_id] = set_data

	print("Loaded ", sets_array.size(), " level sets")

func get_set_data(set_id: int) -> Dictionary:
	"""Get set data by ID. Returns empty dict if not found."""
	return sets_data.get(set_id, {})

func get_all_sets() -> Array:
	"""Get array of all sets"""
	return sets_array.duplicate()

func get_total_set_count() -> int:
	"""Get the total number of sets available"""
	return sets_array.size()

func set_exists(set_id: int) -> bool:
	"""Check if a set with the given ID exists"""
	return sets_data.has(set_id)

func get_set_level_ids(set_id: int) -> Array:
	"""Get the array of level IDs for a set"""
	var set_data = get_set_data(set_id)
	return set_data.get("level_ids", [])

func get_set_name(set_id: int) -> String:
	"""Get the name of a set"""
	var set_data = get_set_data(set_id)
	return set_data.get("name", "Unknown Set")

func get_set_description(set_id: int) -> String:
	"""Get the description of a set"""
	var set_data = get_set_data(set_id)
	return set_data.get("description", "")
