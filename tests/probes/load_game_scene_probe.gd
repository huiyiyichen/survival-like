extends SceneTree


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	print("LOAD_GAME_SCENE_PROBE stage=begin")
	var packed_scene: PackedScene = load("res://scenes/gameplay/game_scene.tscn") as PackedScene
	print("LOAD_GAME_SCENE_PROBE stage=loaded ok=%s" % str(packed_scene != null))
	quit(0 if packed_scene != null else 1)
