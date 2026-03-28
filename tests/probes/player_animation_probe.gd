extends SceneTree

const PLAYER_SCENE := preload("res://scenes/gameplay/entities/player.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame
	var player: Player = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame

	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		_failures.append("AnimatedSprite2D is missing on Player.")
	else:
		_check_direction(player, sprite, Vector2.DOWN, "idle_down", false)
		_check_direction(player, sprite, Vector2.UP, "idle_up", false)
		_check_direction(player, sprite, Vector2.RIGHT, "idle_side", false)
		_check_direction(player, sprite, Vector2.LEFT, "idle_side", true)
		_check_direction(player, sprite, Vector2(1.0, 1.0), "idle_down_diag", true)
		_check_direction(player, sprite, Vector2(-1.0, 1.0), "idle_down_diag", false)
		_check_direction(player, sprite, Vector2(-1.0, -1.0), "idle_up_diag", true)
		player.call("_update_movement_animation", Vector2.ZERO)
		if sprite.is_playing():
			_failures.append("Player animation should stop when there is no movement.")

	print("PLAYER_ANIMATION_PROBE animation=%s frame=%d playing=%s flip_h=%s" % [
		String(sprite.animation) if sprite != null else "missing",
		sprite.frame if sprite != null else -1,
		str(sprite.is_playing()) if sprite != null else "False",
		str(sprite.flip_h) if sprite != null else "False",
	])

	player.queue_free()

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _check_direction(
	player: Player,
	sprite: AnimatedSprite2D,
	direction: Vector2,
	expected_animation: String,
	expected_flip_h: bool
) -> void:
	player.call("_update_movement_animation", direction)
	if String(sprite.animation) != expected_animation:
		_failures.append(
			"Direction %s expected animation %s but got %s." % [
				str(direction),
				expected_animation,
				String(sprite.animation),
			]
		)
	if sprite.flip_h != expected_flip_h:
		_failures.append(
			"Direction %s expected flip_h=%s but got %s." % [
				str(direction),
				str(expected_flip_h),
				str(sprite.flip_h),
			]
		)
	if not sprite.is_playing():
		_failures.append("Direction %s did not start playing." % str(direction))
