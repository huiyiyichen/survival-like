extends SceneTree

const PLAYER_SCENE := preload("res://scenes/gameplay/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/gameplay/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var enemy_layer := Node2D.new()
	root.add_child(enemy_layer)
	await process_frame

	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	player.set_enemy_layer(enemy_layer)
	await process_frame

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy_layer.add_child(enemy)
	enemy.global_position = Vector2(56.0, 0.0)
	enemy.configure("acid_slime", ContentDB.new().get_enemy("acid_slime"))
	enemy.set_target(player)
	await process_frame

	var hp_before: int = player.get_current_hp()
	for _step in range(180):
		await physics_frame
	var hp_after: int = player.get_current_hp()
	var enemy_position_before_push: Vector2 = enemy.global_position
	player.call("_push_blocking_enemies", 0.16, Vector2.RIGHT)
	for _step in range(8):
		await physics_frame
	var enemy_position_after_push: Vector2 = enemy.global_position

	if hp_after >= hp_before:
		_failures.append("Enemy did not damage player during probe.")
	if player.collision_mask != 2:
		_failures.append("Player collision mask should target enemies.")
	if enemy.collision_mask != 1:
		_failures.append("Enemy collision mask should target player.")
	if enemy_position_after_push.x <= enemy_position_before_push.x:
		_failures.append("Player push did not move enemy away.")

	print("COMBAT_PROBE hp_before=%d hp_after=%d player_mask=%d enemy_mask=%d enemy_pos_before=%s enemy_pos_after=%s" % [
		hp_before,
		hp_after,
		player.collision_mask,
		enemy.collision_mask,
		str(enemy_position_before_push),
		str(enemy_position_after_push),
	])

	player.queue_free()
	enemy.queue_free()

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
