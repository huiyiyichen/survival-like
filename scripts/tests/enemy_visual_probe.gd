extends SceneTree

const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var content_db := ContentDB.new()
	_check_enemy_visual(content_db, "acid_slime", true, false)
	_check_enemy_visual(content_db, "wolf", false, true)
	_check_enemy_visual(content_db, "archer", false, true)
	_check_enemy_visual(content_db, "elite_hornwolf", true, false)
	_check_enemy_visual(content_db, "boss_hornwolf", true, false)

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _check_enemy_visual(content_db: ContentDB, enemy_id: String, expect_animation: bool, expect_polygon: bool) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root.add_child(enemy)
	enemy.configure(enemy_id, content_db.get_enemy(enemy_id))

	var animated_sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var sprite: Sprite2D = enemy.get_node_or_null("Sprite2D") as Sprite2D
	var visual: Polygon2D = enemy.get_node_or_null("Visual") as Polygon2D

	if animated_sprite == null or animated_sprite.visible != expect_animation:
		_failures.append("%s animated visibility mismatch." % enemy_id)
	if sprite != null and sprite.visible:
		_failures.append("%s should not use the static slime cutout sprite." % enemy_id)
	if visual == null or visual.visible != expect_polygon:
		_failures.append("%s polygon placeholder visibility mismatch." % enemy_id)

	print("ENEMY_VISUAL_PROBE enemy=%s animated=%s sprite=%s polygon=%s" % [
		enemy_id,
		str(animated_sprite != null and animated_sprite.visible),
		str(sprite != null and sprite.visible),
		str(visual != null and visual.visible),
	])

	enemy.queue_free()
