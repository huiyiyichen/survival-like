extends SceneTree

const PLAYER_SCENE := preload("res://scenes/gameplay/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/gameplay/entities/enemy.tscn")

var _failures: Array[String] = []
var _boss_spawn_count: int = 0
var _boss_enemy_id: String = ""


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var enemy_layer := Node2D.new()
	root.add_child(enemy_layer)

	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)

	var spawn_manager := SpawnManager.new()
	root.add_child(spawn_manager)
	spawn_manager.enemy_scene = ENEMY_SCENE
	spawn_manager.set_enemy_layer(enemy_layer)
	spawn_manager.configure(DemoConfig.new(), ContentDB.new(), player)
	spawn_manager.spawn_boss.connect(_on_spawn_boss)
	spawn_manager.start()

	spawn_manager._process(59.0)
	if _boss_spawn_count != 0:
		_failures.append("Boss spawned before 60 seconds.")

	spawn_manager._process(1.1)
	if DemoConfig.BOSS_SPAWN_SEC != 60:
		_failures.append("Boss spawn time constant is not 60.")
	if _boss_spawn_count != 1:
		_failures.append("Boss did not spawn exactly once at 60 seconds.")
	if _boss_enemy_id != "boss_hornwolf":
		_failures.append("Spawned boss enemy id mismatch.")

	print("BOSS_SPAWN_TIMING_PROBE boss_spawn_sec=%d spawn_count=%d boss_id=%s" % [
		DemoConfig.BOSS_SPAWN_SEC,
		_boss_spawn_count,
		_boss_enemy_id,
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _on_spawn_boss(enemy: Enemy) -> void:
	_boss_spawn_count += 1
	_boss_enemy_id = enemy.enemy_id
