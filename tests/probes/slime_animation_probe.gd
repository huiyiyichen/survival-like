extends SceneTree

const PLAYER_SCENE := preload("res://scenes/gameplay/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/gameplay/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	player.global_position = Vector2.ZERO
	await process_frame

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	enemy.global_position = Vector2(180.0, 0.0)
	enemy.configure("acid_slime", ContentDB.new().get_enemy("acid_slime"))
	enemy.set_target(player)
	await process_frame

	var animated_sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		_failures.append("Enemy AnimatedSprite2D node is missing.")
	else:
		if not animated_sprite.visible:
			_failures.append("Acid slime AnimatedSprite2D should be visible.")
		if animated_sprite.sprite_frames == null:
			_failures.append("Acid slime sprite frames were not assigned.")
		elif animated_sprite.sprite_frames.get_frame_count("idle") != 10:
			_failures.append("Acid slime idle animation should contain 10 frames.")

	var start_frame: int = animated_sprite.frame if animated_sprite != null else -1
	if animated_sprite != null:
		for _step in range(4):
			enemy.call("_update_visual_animation", Vector2.LEFT * enemy.move_speed, 0.12)
	var moving_frame: int = animated_sprite.frame if animated_sprite != null else -1
	if animated_sprite != null:
		enemy.call("_update_visual_animation", Vector2.ZERO, 0.12)
	var rest_frame: int = animated_sprite.frame if animated_sprite != null else -1

	if animated_sprite != null:
		if String(animated_sprite.animation) != "idle":
			_failures.append("Acid slime animation should use idle.")
		if moving_frame == start_frame:
			_failures.append("Acid slime animation frame did not advance.")
		if rest_frame != 0:
			_failures.append("Acid slime animation should reset to frame 0 when idle.")

	print("SLIME_ANIMATION_PROBE visible=%s animation=%s start_frame=%d moving_frame=%d rest_frame=%d enemy_pos=%s" % [
		str(animated_sprite != null and animated_sprite.visible),
		String(animated_sprite.animation) if animated_sprite != null else "missing",
		start_frame,
		moving_frame,
		rest_frame,
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
