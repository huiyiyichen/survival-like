extends SceneTree

const GAME_FLOW_SCRIPT := preload("res://scripts/autoload/game_flow.gd")
const GAME_SCENE_PATH := "res://scenes/game/game.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	print("ARENA_GROUND_SNAPSHOT_PROBE stage=init")
	await process_frame

	var game_flow: Node = GAME_FLOW_SCRIPT.new()
	game_flow.name = "GameFlow"
	root.add_child(game_flow)
	print("ARENA_GROUND_SNAPSHOT_PROBE stage=game_flow_added")
	await process_frame
	game_flow.call("select_character", "apprentice_mage")

	print("ARENA_GROUND_SNAPSHOT_PROBE stage=before_scene_load")
	var packed_scene: PackedScene = load(GAME_SCENE_PATH) as PackedScene
	if packed_scene == null:
		_failures.append("Game scene failed to load.")
		for message in _failures:
			push_error(message)
		quit(1)
		return
	print("ARENA_GROUND_SNAPSHOT_PROBE stage=scene_loaded")

	var game: Node2D = packed_scene.instantiate()
	root.add_child(game)
	print("ARENA_GROUND_SNAPSHOT_PROBE stage=game_added")
	await process_frame
	await process_frame
	await process_frame
	print("ARENA_GROUND_SNAPSHOT_PROBE stage=frames_ready")

	var ground_layer: Node2D = game.get_node_or_null("GroundLayer") as Node2D
	if ground_layer == null:
		_failures.append("GroundLayer is missing from the game scene.")
	else:
		if ground_layer.get_child_count() < 200:
			_failures.append("GroundLayer did not build the expected tile pool.")

		var textured_sprites: int = 0
		for child in ground_layer.get_children():
			if child is Sprite2D and (child as Sprite2D).texture != null:
				textured_sprites += 1
		if textured_sprites < 200:
			_failures.append("GroundLayer did not populate enough textured sprites.")

	var player: Node2D = game.get_node_or_null("Player") as Node2D
	if player != null:
		player.global_position = Vector2(384.0, 224.0)
		await process_frame
		await process_frame
		print("ARENA_GROUND_SNAPSHOT_PROBE stage=player_moved")

	print("ARENA_GROUND_SNAPSHOT_PROBE result children=%d" % [
		ground_layer.get_child_count() if ground_layer != null else -1,
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
