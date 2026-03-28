extends SceneTree

const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")
const TRACE_PATH := "res://boss_crash_trace.log"


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	_write_trace("stage=initialize")
	await process_frame
	_write_trace("stage=process_frame_1")

	var root_node := Node2D.new()
	root.add_child(root_node)
	_write_trace("stage=root_added")

	var player: Player = PLAYER_SCENE.instantiate()
	root_node.add_child(player)
	player.global_position = Vector2.ZERO
	_write_trace("stage=player_added")

	var boss: Enemy = ENEMY_SCENE.instantiate()
	root_node.add_child(boss)
	_write_trace("stage=boss_instanced")
	boss.global_position = Vector2(220.0, 0.0)
	_write_trace("stage=boss_positioned")
	boss.configure("boss_hornwolf", ContentDB.new().get_enemy("boss_hornwolf"))
	_write_trace("stage=boss_configured")
	boss.set_target(player)
	_write_trace("stage=target_set")

	for step in range(6):
		await physics_frame
		_write_trace("stage=physics_step step=%d boss_pos=%s player_hp=%d boss_hp=%d" % [
			step,
			str(boss.global_position),
			player.get_current_hp(),
			boss.get_current_hp(),
		])

	_write_trace("stage=completed")
	quit(0)


func _write_trace(message: String) -> void:
	var file := FileAccess.open(TRACE_PATH, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(message)
	file.flush()
	file.close()
