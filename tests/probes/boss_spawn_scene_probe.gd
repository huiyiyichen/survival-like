extends SceneTree

const GAME_SCENE := preload("res://scenes/gameplay/game_scene.tscn")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var game: Node = GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	var battle_controller: BattleController = game.get_node_or_null("BattleController") as BattleController
	var enemy_layer: Node2D = game.get_node_or_null("EnemyLayer") as Node2D
	var enemy_scene: PackedScene = battle_controller.enemy_scene if battle_controller != null else null
	if battle_controller == null or enemy_layer == null or enemy_scene == null:
		push_error("Boss scene probe failed to resolve scene nodes.")
		quit(1)
		return

	var boss: Enemy = enemy_scene.instantiate() as Enemy
	enemy_layer.add_child(boss)
	boss.global_position = Vector2(260.0, 0.0)
	boss.configure("boss_hornwolf", ContentDB.new().get_enemy("boss_hornwolf"))
	battle_controller.call("_on_boss_spawned", boss)
	var player: Player = game.get_node_or_null("Player") as Player
	if player != null:
		player.apply_loadout({}, {})

	for _step in range(6):
		await process_frame

	print("BOSS_SPAWN_SCENE_PROBE boss_hp=%d boss_pos=%s" % [
		boss.get_current_hp(),
		str(boss.global_position),
	])
	quit(0)
