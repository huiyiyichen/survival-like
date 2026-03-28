extends SceneTree

const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var root_node := Node2D.new()
	root.add_child(root_node)

	var player: Player = PLAYER_SCENE.instantiate()
	root_node.add_child(player)
	player.global_position = Vector2.ZERO

	var boss: Enemy = ENEMY_SCENE.instantiate()
	root_node.add_child(boss)
	boss.global_position = Vector2(220.0, 0.0)
	boss.configure("boss_hornwolf", ContentDB.new().get_enemy("boss_hornwolf"))
	boss.set_target(player)
	print("BOSS_RUNTIME_STABILITY_PROBE stage=spawned")

	for step in range(12):
		await physics_frame
		print("BOSS_RUNTIME_STABILITY_PROBE step=%d boss_pos=%s player_hp=%d" % [
			step,
			str(boss.global_position),
			player.get_current_hp(),
		])

	print("BOSS_RUNTIME_STABILITY_PROBE boss_hp=%d boss_pos=%s player_hp=%d" % [
		boss.get_current_hp(),
		str(boss.global_position),
		player.get_current_hp(),
	])
	quit(0)
