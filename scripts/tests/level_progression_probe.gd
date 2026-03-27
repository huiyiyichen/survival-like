extends SceneTree

const GAME_SCENE := preload("res://scenes/game/game.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var game: Node2D = GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var config: DemoConfig = game._config
	var threshold_level_9: int = config.get_exp_for_level(9)
	var threshold_level_10: int = config.get_exp_for_level(10)
	game._level = 9
	game._current_xp = threshold_level_9 - 1
	game._pending_level_ups = 0
	game._refresh_hud()

	game._on_player_xp_gained((threshold_level_10 - threshold_level_9) + 2)
	await process_frame

	if game._level != 11:
		_failures.append("Level did not continue beyond 9 when XP exceeded later thresholds.")
	if game._pending_level_ups != 2:
		_failures.append("Queued level-up count is incorrect after multi-threshold XP gain.")
	if not game.level_up_panel.visible:
		_failures.append("Level up panel did not open after queued level gain.")

	game._on_level_option_selected("power_talisman")
	await process_frame
	if game._pending_level_ups != 1:
		_failures.append("Queued level-up count did not decrement after selecting an upgrade.")
	if not game.level_up_panel.visible:
		_failures.append("Queued follow-up level up did not reopen the panel.")

	game._on_level_option_selected("wind_feather")
	await process_frame
	if game._pending_level_ups != 0:
		_failures.append("Queued level-ups were not fully consumed.")
	if game.level_up_panel.visible:
		_failures.append("Level up panel stayed open after queued upgrades were resolved.")

	var xp_label: Label = game.hud.get_node("TopLeftCard/Margin/StatsColumn/XPLabel") as Label
	if xp_label == null or xp_label.text.find("/ 72") == -1:
		_failures.append("HUD XP label did not switch to per-level progress after level 10.")

	paused = false
	game.queue_free()

	print("LEVEL_PROGRESSION_PROBE level=%d pending=%d label=%s threshold10=%d threshold11=%d" % [
		game._level,
		game._pending_level_ups,
		xp_label.text if xp_label != null else "missing",
		threshold_level_10,
		config.get_exp_for_level(11),
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
