extends SceneTree

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const TRACE_PATH := "res://boss_spawn_signal_probe.log"

var _battle_controller: BattleController
var _boss_spawn_count: int = 0


func _initialize() -> void:
	var absolute_trace_path: String = ProjectSettings.globalize_path(TRACE_PATH)
	if FileAccess.file_exists(absolute_trace_path):
		DirAccess.remove_absolute(absolute_trace_path)
	call_deferred("_run_probe")


func _run_probe() -> void:
	Engine.time_scale = 120.0
	await process_frame

	var game: Node = GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	_battle_controller = game.get_node_or_null("BattleController") as BattleController
	if _battle_controller == null:
		_append_trace("battle_controller_missing")
		quit(1)
		return

	_battle_controller.boss_spawned.connect(_on_boss_spawned)
	_append_trace("probe_started")

	for _step in range(48):
		await process_frame
		if _boss_spawn_count > 0:
			break

	var elapsed: float = _battle_controller.get_elapsed_time()
	_append_trace("probe_finished boss_spawn_count=%d elapsed=%.2f" % [_boss_spawn_count, elapsed])
	quit(0 if _boss_spawn_count == 1 else 1)


func _on_boss_spawned() -> void:
	_boss_spawn_count += 1
	var elapsed: float = _battle_controller.get_elapsed_time() if _battle_controller != null else -1.0
	_append_trace("boss_spawned count=%d elapsed=%.2f" % [_boss_spawn_count, elapsed])


func _append_trace(message: String) -> void:
	var absolute_trace_path: String = ProjectSettings.globalize_path(TRACE_PATH)
	var file: FileAccess = FileAccess.open(absolute_trace_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(absolute_trace_path, FileAccess.WRITE_READ)
	if file == null:
		return
	file.seek_end()
	file.store_line(message)
	file.flush()
	file.close()
