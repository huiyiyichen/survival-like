extends Node
class_name BattleController

const ENEMY_DESPAWN_DISTANCE: float = 2200.0
const PICKUP_DESPAWN_DISTANCE: float = 2600.0
const TRANSIENT_DESPAWN_DISTANCE: float = 2000.0

signal battle_started
signal battle_won
signal battle_lost(reason: String)
signal enemy_defeated(enemy_id: String, xp_reward: int, world_position: Vector2, elite: bool, boss: bool)
signal boss_spawned

@export var player_path: NodePath
@export var enemy_layer_path: NodePath
@export var projectile_layer_path: NodePath
@export var pickup_layer_path: NodePath
@export var effect_layer_path: NodePath
@export var spawn_manager_path: NodePath

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene
@export var area_effect_scene: PackedScene
@export var xp_pickup_scene: PackedScene

var run_duration: float = 300.0

var _demo_config: DemoConfig
var _content_db: ContentDB
var _player: Player
var _enemy_layer: Node2D
var _projectile_layer: Node2D
var _pickup_layer: Node2D
var _effect_layer: Node2D
var _spawn_manager: SpawnManager
var _boss_alive: bool = false
var _battle_finished: bool = false


func _ready() -> void:
	_resolve_nodes()


func configure(demo_config: DemoConfig, content_db: ContentDB) -> void:
	_demo_config = demo_config
	_content_db = content_db
	run_duration = float(demo_config.RUN_DURATION_SEC)
	_resolve_nodes()


func start_battle() -> void:
	_battle_finished = false
	_boss_alive = false
	_resolve_nodes()
	if _player == null or _spawn_manager == null or _demo_config == null or _content_db == null:
		return

	_player.set_enemy_layer(_enemy_layer)
	_player.set_projectile_layer(_projectile_layer)
	_player.set_effect_layer(_effect_layer)
	_player.set_content_db(_content_db)
	_player.projectile_scene = projectile_scene
	_player.area_effect_scene = area_effect_scene
	if not _player.died.is_connected(_on_player_died):
		_player.died.connect(_on_player_died)

	_spawn_manager.enemy_scene = enemy_scene
	_spawn_manager.set_enemy_layer(_enemy_layer)
	_spawn_manager.configure(_demo_config, _content_db, _player)
	if not _spawn_manager.spawn_enemy.is_connected(_on_enemy_spawned):
		_spawn_manager.spawn_enemy.connect(_on_enemy_spawned)
	if not _spawn_manager.spawn_elite.is_connected(_on_elite_spawned):
		_spawn_manager.spawn_elite.connect(_on_elite_spawned)
	if not _spawn_manager.spawn_boss.is_connected(_on_boss_spawned):
		_spawn_manager.spawn_boss.connect(_on_boss_spawned)
	_spawn_manager.start()
	battle_started.emit()


func get_elapsed_time() -> float:
	if _spawn_manager == null:
		return 0.0
	return _spawn_manager.get_elapsed_time()


func _process(_delta: float) -> void:
	if _battle_finished or _spawn_manager == null:
		return
	_cleanup_distant_nodes()
	if _boss_alive and get_elapsed_time() >= run_duration:
		_finish_battle(false, "timeout")


func _resolve_nodes() -> void:
	_player = get_node_or_null(player_path) as Player
	_enemy_layer = get_node_or_null(enemy_layer_path) as Node2D
	_projectile_layer = get_node_or_null(projectile_layer_path) as Node2D
	_pickup_layer = get_node_or_null(pickup_layer_path) as Node2D
	_effect_layer = get_node_or_null(effect_layer_path) as Node2D
	_spawn_manager = get_node_or_null(spawn_manager_path) as SpawnManager
	if _spawn_manager == null:
		_spawn_manager = SpawnManager.new()
		_spawn_manager.name = "SpawnManager"
		add_child(_spawn_manager)


func _on_enemy_spawned(enemy: Enemy) -> void:
	_connect_enemy(enemy)


func _on_elite_spawned(enemy: Enemy) -> void:
	_connect_enemy(enemy)


func _on_boss_spawned(enemy: Enemy) -> void:
	_boss_alive = true
	_connect_enemy(enemy)
	boss_spawned.emit()


func _connect_enemy(enemy: Enemy) -> void:
	enemy.set_target(_player)
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy_id: String, xp_reward: int, world_position: Vector2, elite: bool, boss: bool) -> void:
	_spawn_xp_pickup(world_position, xp_reward)
	enemy_defeated.emit(enemy_id, xp_reward, world_position, elite, boss)
	if boss:
		_boss_alive = false
		_finish_battle(true, "boss_defeated")


func _spawn_xp_pickup(world_position: Vector2, xp_reward: int) -> void:
	if xp_pickup_scene == null or _pickup_layer == null:
		return
	call_deferred("_deferred_spawn_xp_pickup", world_position, xp_reward)


func _deferred_spawn_xp_pickup(world_position: Vector2, xp_reward: int) -> void:
	if xp_pickup_scene == null or _pickup_layer == null:
		return
	var pickup: Node2D = xp_pickup_scene.instantiate() as Node2D
	if pickup == null:
		return
	_pickup_layer.add_child(pickup)
	if pickup.has_method("setup"):
		pickup.call("setup", xp_reward)
	if pickup.has_method("set_player_target"):
		pickup.call("set_player_target", _player)
	pickup.global_position = world_position


func _on_player_died() -> void:
	_finish_battle(false, "player_dead")


func _finish_battle(victory: bool, reason: String) -> void:
	if _battle_finished:
		return
	_battle_finished = true
	if victory:
		battle_won.emit()
	else:
		battle_lost.emit(reason)


func _cleanup_distant_nodes() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var origin: Vector2 = _player.global_position
	_cleanup_enemies(origin)
	_cleanup_layer(_pickup_layer, origin, PICKUP_DESPAWN_DISTANCE)
	_cleanup_layer(_projectile_layer, origin, TRANSIENT_DESPAWN_DISTANCE)
	_cleanup_layer(_effect_layer, origin, TRANSIENT_DESPAWN_DISTANCE)


func _cleanup_enemies(origin: Vector2) -> void:
	if _enemy_layer == null:
		return
	for child in _enemy_layer.get_children():
		if child is Enemy:
			var enemy: Enemy = child as Enemy
			if enemy.is_boss or enemy.is_elite:
				continue
			if origin.distance_to(enemy.global_position) > ENEMY_DESPAWN_DISTANCE:
				enemy.queue_free()


func _cleanup_layer(layer: Node2D, origin: Vector2, max_distance: float) -> void:
	if layer == null:
		return
	for child in layer.get_children():
		if child is Node2D and origin.distance_to((child as Node2D).global_position) > max_distance:
			child.queue_free()
