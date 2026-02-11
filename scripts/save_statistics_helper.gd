extends RefCounted
class_name SaveStatisticsHelper

## SaveStatisticsHelper - Statistics tracking extracted from save_manager.gd.

func increment_stat(save_data: Dictionary, save_to_disk: Callable, stat_name: String, amount: float = 1.0) -> void:
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return
	save_data["statistics"][stat_name] += amount
	save_to_disk.call()

func get_stat(save_data: Dictionary, stat_name: String) -> float:
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return 0.0
	return save_data["statistics"][stat_name]

func update_stat_if_higher(save_data: Dictionary, save_to_disk: Callable, stat_name: String, new_value: float) -> void:
	if not save_data["statistics"].has(stat_name):
		push_warning("Statistic not found: " + stat_name)
		return
	if new_value > save_data["statistics"][stat_name]:
		save_data["statistics"][stat_name] = new_value
		save_to_disk.call()

func get_all_statistics(save_data: Dictionary) -> Dictionary:
	return save_data["statistics"].duplicate()

func migrate_statistics(save_data: Dictionary, save_to_disk: Callable) -> void:
	"""Migrate old saves that don't have newer statistics keys."""
	var updated = false
	if not save_data["statistics"].has("total_individual_levels_completed"):
		save_data["statistics"]["total_individual_levels_completed"] = save_data["statistics"].get("total_levels_completed", 0)
		updated = true
	if not save_data["statistics"].has("total_set_runs_completed"):
		save_data["statistics"]["total_set_runs_completed"] = 0
		updated = true
	if updated:
		save_to_disk.call()
