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
	player.global_position = Vector2.ZERO
	await process_frame

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	enemy.global_position = Vector2(220.0, 0.0)
	enemy.configure("boss_hornwolf", ContentDB.new().get_enemy("boss_hornwolf"))
	enemy.set_target(player)
	await process_frame

	var animated_sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if animated_sprite == null:
		_failures.append("Boss hornwolf AnimatedSprite2D node is missing.")
	else:
		if not animated_sprite.visible:
			_failures.append("Boss hornwolf AnimatedSprite2D should be visible.")
		if animated_sprite.sprite_frames == null:
			_failures.append("Boss hornwolf sprite frames were not assigned.")
		elif animated_sprite.sprite_frames.get_frame_count("idle") != 14:
			_failures.append("Boss hornwolf idle animation should contain 14 frames.")

	var start_frame: int = animated_sprite.frame if animated_sprite != null else -1
	if animated_sprite != null:
		for _step in range(5):
			enemy.call("_update_visual_animation", Vector2.RIGHT * enemy.move_speed, 0.11)
	var moving_frame: int = animated_sprite.frame if animated_sprite != null else -1
	var moving_flip_h: bool = animated_sprite.flip_h if animated_sprite != null else false
	if animated_sprite != null:
		enemy.call("_update_visual_animation", Vector2.LEFT * enemy.move_speed, 0.11)
	var flipped_left: bool = animated_sprite.flip_h if animated_sprite != null else false
	if animated_sprite != null:
		enemy.call("_update_visual_animation", Vector2.ZERO, 0.11)
	var rest_frame: int = animated_sprite.frame if animated_sprite != null else -1

	if animated_sprite != null:
		if String(animated_sprite.animation) != "idle":
			_failures.append("Boss hornwolf animation should use idle.")
		if moving_frame == start_frame:
			_failures.append("Boss hornwolf animation frame did not advance.")
		if moving_flip_h:
			_failures.append("Boss hornwolf should face right when moving right.")
		if not flipped_left:
			_failures.append("Boss hornwolf should flip when moving left.")
		if rest_frame != 0:
			_failures.append("Boss hornwolf animation should reset to frame 0 when idle.")

	print("HORNWOLF_ANIMATION_PROBE visible=%s animation=%s start_frame=%d moving_frame=%d rest_frame=%d flip_left=%s enemy_pos=%s" % [
		str(animated_sprite != null and animated_sprite.visible),
		String(animated_sprite.animation) if animated_sprite != null else "missing",
		start_frame,
		moving_frame,
		rest_frame,
		str(flipped_left),
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
