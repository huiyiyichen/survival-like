extends SceneTree

const PROJECTILE_SCENE := preload("res://scenes/gameplay/entities/projectile.tscn")
const ENEMY_SCENE := preload("res://scenes/gameplay/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var root_node: Node2D = Node2D.new()
	root.add_child(root_node)

	var primary_enemy: Enemy = ENEMY_SCENE.instantiate()
	var splash_enemy: Enemy = ENEMY_SCENE.instantiate()
	var far_enemy: Enemy = ENEMY_SCENE.instantiate()
	root_node.add_child(primary_enemy)
	root_node.add_child(splash_enemy)
	root_node.add_child(far_enemy)
	await process_frame

	var content_db: ContentDB = ContentDB.new()
	primary_enemy.configure("wolf", content_db.get_enemy("wolf"))
	splash_enemy.configure("wolf", content_db.get_enemy("wolf"))
	far_enemy.configure("wolf", content_db.get_enemy("wolf"))
	primary_enemy.global_position = Vector2(96.0, 0.0)
	splash_enemy.global_position = Vector2(138.0, 0.0)
	far_enemy.global_position = Vector2(250.0, 0.0)

	var projectile: Area2D = PROJECTILE_SCENE.instantiate()
	root_node.add_child(projectile)
	projectile.call("setup", Vector2.ZERO, primary_enemy.global_position, 18, Color(1.0, 0.52, 0.24, 1.0))
	await process_frame
	projectile.call("_explode", primary_enemy)
	await process_frame

	if primary_enemy.get_current_hp() > primary_enemy.max_hp - 18:
		_failures.append("Primary enemy did not receive explosion damage in addition to direct hit.")
	if splash_enemy.get_current_hp() >= splash_enemy.max_hp:
		_failures.append("Nearby enemy did not take splash damage from projectile explosion.")
	if far_enemy.get_current_hp() != far_enemy.max_hp:
		_failures.append("Far enemy should stay outside the fireball explosion damage radius.")
	if not primary_enemy.is_in_group("enemies"):
		_failures.append("Enemy is not registered in enemies group.")

	print("WEAPON_FEEDBACK_PROBE primary_hp=%d splash_hp=%d far_hp=%d group=%s" % [
		primary_enemy.get_current_hp(),
		splash_enemy.get_current_hp(),
		far_enemy.get_current_hp(),
		str(primary_enemy.is_in_group("enemies")),
	])

	root_node.queue_free()

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
