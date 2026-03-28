extends SceneTree

const MAIN_MENU_SCENE := preload("res://scenes/ui/screens/main_menu.tscn")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw

	var image: Image = root.get_texture().get_image()
	image.save_png("user://main_menu_snapshot_probe.png")
	print("MAIN_MENU_SNAPSHOT_PROBE saved=%s size=%sx%s" % [
		ProjectSettings.globalize_path("user://main_menu_snapshot_probe.png"),
		image.get_width(),
		image.get_height(),
	])
	quit()
