extends SceneTree

const ARENA_GROUND_SCRIPT := preload("res://scripts/gameplay/world/arena_ground.gd")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(1600, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var background := ColorRect.new()
	background.color = Color(0.03, 0.04, 0.05, 1.0)
	background.position = Vector2.ZERO
	background.size = Vector2(1600.0, 900.0)
	viewport.add_child(background)

	var canvas := Node2D.new()
	viewport.add_child(canvas)

	var player := Marker2D.new()
	player.name = "Player"
	player.position = Vector2(320.0, 192.0)
	canvas.add_child(player)

	var ground := ARENA_GROUND_SCRIPT.new()
	ground.player_path = NodePath("../Player")
	canvas.add_child(ground)

	await process_frame
	await process_frame
	player.position = Vector2(512.0, 320.0)
	await process_frame
	await create_timer(0.1).timeout

	var image: Image = viewport.get_texture().get_image()
	var output_path := "user://arena_ground_visual_snapshot_probe.png"
	image.save_png(output_path)
	print("ARENA_GROUND_VISUAL_SNAPSHOT_PROBE saved=%s" % ProjectSettings.globalize_path(output_path))
	quit()
