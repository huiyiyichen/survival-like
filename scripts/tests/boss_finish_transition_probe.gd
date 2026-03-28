extends SceneTree

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const RESULT_SCENE_PATH := "res://scenes/ui/result_screen.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var tree: SceneTree = self
	if tree == null:
		push_error("BOSS_FINISH_TRANSITION_PROBE missing SceneTree.")
		quit(1)
		return

	tree.change_scene_to_packed(GAME_SCENE)
	for _step in range(3):
		await process_frame

	var game: Node = tree.current_scene
	var battle_controller: BattleController = game.get_node_or_null("BattleController") as BattleController if game != null else null
	var enemy_layer: Node2D = game.get_node_or_null("EnemyLayer") as Node2D if game != null else null
	var projectile_layer: Node2D = game.get_node_or_null("ProjectileLayer") as Node2D if game != null else null
	var player: Player = game.get_node_or_null("Player") as Player if game != null else null

	if battle_controller == null:
		_failures.append("BattleController is missing.")
	if enemy_layer == null:
		_failures.append("EnemyLayer is missing.")
	if projectile_layer == null:
		_failures.append("ProjectileLayer is missing.")
	if player == null:
		_failures.append("Player is missing.")
	if battle_controller != null and battle_controller.enemy_scene == null:
		_failures.append("Enemy scene is missing on BattleController.")
	if battle_controller != null and battle_controller.projectile_scene == null:
		_failures.append("Projectile scene is missing on BattleController.")
	if not _failures.is_empty():
		_finish()
		return

	var boss: Enemy = battle_controller.enemy_scene.instantiate() as Enemy
	enemy_layer.add_child(boss)
	boss.global_position = player.global_position + Vector2(120.0, 0.0)
	boss.configure("boss_hornwolf", ContentDB.new().get_enemy("boss_hornwolf"))
	await process_frame
	battle_controller.call("_on_boss_spawned", boss)
	await process_frame

	var projectile: Area2D = battle_controller.projectile_scene.instantiate() as Area2D
	projectile_layer.add_child(projectile)
	projectile.call("setup", player.global_position, boss.global_position, 9999, Color(1.0, 0.52, 0.18, 1.0))
	projectile.call("_explode", boss)

	for _step in range(6):
		await process_frame

	var current_scene: Node = tree.current_scene
	var current_scene_path: String = ""
	if current_scene != null:
		current_scene_path = String(current_scene.scene_file_path)

	print("BOSS_FINISH_TRANSITION_PROBE current_scene=%s" % current_scene_path)
	if current_scene_path != RESULT_SCENE_PATH:
		_failures.append("Expected result scene after boss death, got %s." % current_scene_path)
	_finish()


func _finish() -> void:
	if _failures.is_empty():
		quit(0)
		return
	for message in _failures:
		push_error(message)
	quit(1)
