extends SceneTree

const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	enemy.global_position = Vector2(56.0, 0.0)
	enemy.configure("acid_slime", ContentDB.new().get_enemy("acid_slime"))
	enemy.set_target(player)
	await process_frame

	var hp_before: int = player.get_current_hp()
	for _step in range(180):
		await physics_frame
	var hp_after: int = player.get_current_hp()

	if hp_after >= hp_before:
		_failures.append("Enemy did not damage player during probe.")
	if player.collision_mask != 0:
		_failures.append("Player collision mask is not softened.")
	if enemy.collision_mask != 0:
		_failures.append("Enemy collision mask is not softened.")

	print("COMBAT_PROBE hp_before=%d hp_after=%d player_mask=%d enemy_mask=%d enemy_pos=%s" % [
		hp_before,
		hp_after,
		player.collision_mask,
		enemy.collision_mask,
		str(enemy.global_position),
	])

	player.queue_free()
	enemy.queue_free()

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
