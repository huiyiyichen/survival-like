extends Node
class_name SpawnManager

signal spawn_enemy(enemy: Enemy)
signal spawn_elite(enemy: Enemy)
signal spawn_boss(enemy: Enemy)

@export var enemy_scene: PackedScene

var _enemy_layer: Node2D
var _player: Player
var _demo_config: DemoConfig
var _content_db: ContentDB
var _elapsed: float = 0.0
var _spawn_accumulator: float = 0.0
var _elite_spawned: bool = false
var _boss_spawned: bool = false


func _process(delta: float) -> void:
	if _enemy_layer == null or _player == null or _demo_config == null or _content_db == null:
		return

	_elapsed += delta
	var wave: Dictionary = _demo_config.get_wave_at(_elapsed)
	_spawn_accumulator += delta

	while _spawn_accumulator >= float(wave["interval"]):
		_spawn_accumulator -= float(wave["interval"])
		var max_active: int = int(wave.get("max_active", 30))
		var active_enemies: int = _count_active_standard_enemies()
		if active_enemies >= max_active:
			continue
		for _count in range(int(wave["count"])):
			if active_enemies >= max_active:
				break
			var enemy_id: String = _pick_wave_enemy_id(wave)
			_spawn_enemy_entry(enemy_id, false, false)
			active_enemies += 1

	if not _elite_spawned and _elapsed >= DemoConfig.ELITE_SPAWN_SEC:
		_elite_spawned = true
		_spawn_enemy_entry("elite_hornwolf", true, false)

	if not _boss_spawned and _elapsed >= DemoConfig.BOSS_SPAWN_SEC:
		_boss_spawned = true
		_spawn_enemy_entry("corrupted_sorcerer", false, true)


func configure(config: DemoConfig, content_db: ContentDB, player: Player) -> void:
	_demo_config = config
	_content_db = content_db
	_player = player


func set_enemy_layer(layer: Node2D) -> void:
	_enemy_layer = layer


func start() -> void:
	_elapsed = 0.0
	_spawn_accumulator = 0.0
	_elite_spawned = false
	_boss_spawned = false


func reset() -> void:
	start()


func get_elapsed_time() -> float:
	return _elapsed


func _pick_wave_enemy_id(wave: Dictionary) -> String:
	var enemy_ids: Array[String] = _variant_to_string_array(wave.get("enemy_ids", []))
	if enemy_ids.is_empty():
		return "acid_slime"
	return String(enemy_ids[randi() % enemy_ids.size()])


func _spawn_enemy_entry(enemy_id: String, elite: bool, boss: bool) -> void:
	if enemy_scene == null or _enemy_layer == null:
		return
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	var enemy_data: Dictionary = _content_db.get_enemy(enemy_id)
	enemy.global_position = _random_spawn_position()
	_enemy_layer.add_child(enemy)
	enemy.configure(enemy_id, enemy_data)
	if boss:
		spawn_boss.emit(enemy)
	elif elite:
		spawn_elite.emit(enemy)
	else:
		spawn_enemy.emit(enemy)


func _random_spawn_position() -> Vector2:
	var origin: Vector2 = _player.global_position if _player != null else Vector2.ZERO
	var angle: float = randf() * TAU
	var distance: float = randf_range(700.0, 860.0)
	return origin + Vector2.RIGHT.rotated(angle) * distance


func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result


func _count_active_standard_enemies() -> int:
	if _enemy_layer == null:
		return 0
	var count: int = 0
	for child in _enemy_layer.get_children():
		if child is Enemy:
			var enemy: Enemy = child as Enemy
			if enemy.is_active() and not enemy.is_elite and not enemy.is_boss:
				count += 1
	return count
