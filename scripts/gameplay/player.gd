extends CharacterBody2D
class_name Player

signal died
signal xp_gained(amount: int)
signal health_changed(current_hp: int, max_hp: int)

const BattleVfx = preload("res://scripts/gameplay/battle_vfx.gd")
const PLAYER_SPRITESHEET := preload("res://art/drafts/spritesheets/characters/char_xuetufashi_v03.png")
const PLAYER_FRAME_SIZE := Vector2i(128, 128)
const PLAYER_ANIMATION_SPEED := 9.0
const PLAYER_ANIMATION_ROWS := {
	"idle_down": 0,
	"idle_side": 1,
	"idle_up": 2,
	"idle_up_diag": 5,
	"idle_down_diag": 6,
}

@export var base_move_speed: float = 220.0
@export var max_hp: int = 100
@export var projectile_scene: PackedScene
@export var area_effect_scene: PackedScene

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var visual: Polygon2D = $Visual

var _current_hp: int = 0
var _enemy_layer: Node2D
var _projectile_layer: Node2D
var _effect_layer: Node2D
var _content_db: ContentDB
var _weapon_levels: Dictionary = {}
var _passive_levels: Dictionary = {}
var _cooldowns: Dictionary = {}
var _last_animation: StringName = &"idle_down"
var _last_flip_h: bool = false


func _ready() -> void:
	add_to_group("player")
	_current_hp = max_hp
	_setup_animated_sprite()
	_update_movement_animation(Vector2.ZERO)
	health_changed.emit(_current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = _get_horizontal_input()
	input_vector.y = _get_vertical_input()
	_update_movement_animation(input_vector)
	velocity = input_vector.normalized() * _get_move_speed() if input_vector != Vector2.ZERO else Vector2.ZERO
	move_and_slide()


func _process(delta: float) -> void:
	if _enemy_layer == null or _content_db == null:
		return
	for raw_weapon_id in _weapon_levels.keys():
		var weapon_id: String = String(raw_weapon_id)
		var current_value: float = float(_cooldowns.get(weapon_id, 0.0))
		_cooldowns[weapon_id] = maxf(0.0, current_value - delta)
		if current_value <= 0.0:
			_try_fire_weapon(weapon_id)


func set_enemy_layer(layer: Node2D) -> void:
	_enemy_layer = layer


func set_projectile_layer(layer: Node2D) -> void:
	_projectile_layer = layer


func set_effect_layer(layer: Node2D) -> void:
	_effect_layer = layer


func set_content_db(content_db: ContentDB) -> void:
	_content_db = content_db


func apply_loadout(weapon_levels: Dictionary, passive_levels: Dictionary) -> void:
	_weapon_levels = weapon_levels.duplicate(true)
	_passive_levels = passive_levels.duplicate(true)
	for raw_weapon_id in _weapon_levels.keys():
		var weapon_id: String = String(raw_weapon_id)
		if not _cooldowns.has(weapon_id):
			_cooldowns[weapon_id] = 0.0


func take_damage(amount: int) -> void:
	_current_hp = maxi(0, _current_hp - amount)
	BattleVfx.flash_red(_get_damage_flash_targets(), 0.12, 0.82)
	health_changed.emit(_current_hp, max_hp)
	if _current_hp <= 0:
		died.emit()


func gain_xp(amount: int) -> void:
	xp_gained.emit(amount)


func heal(amount: int) -> void:
	_current_hp = mini(max_hp, _current_hp + amount)
	health_changed.emit(_current_hp, max_hp)


func get_current_hp() -> int:
	return _current_hp


func get_collision_radius() -> float:
	var shape: Shape2D = $CollisionShape2D.shape if has_node("CollisionShape2D") else null
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius
	return 16.0


func _setup_animated_sprite() -> void:
	if animated_sprite == null:
		return
	if animated_sprite.sprite_frames == null or animated_sprite.sprite_frames.get_animation_names().is_empty():
		animated_sprite.sprite_frames = _build_player_sprite_frames()
	animated_sprite.animation = _last_animation
	animated_sprite.flip_h = _last_flip_h


func _build_player_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	for animation_name in PLAYER_ANIMATION_ROWS.keys():
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, PLAYER_ANIMATION_SPEED)
		var row_index: int = int(PLAYER_ANIMATION_ROWS[animation_name])
		for column in range(8):
			var atlas_texture: AtlasTexture = AtlasTexture.new()
			atlas_texture.atlas = PLAYER_SPRITESHEET
			atlas_texture.region = Rect2(
				float(column * PLAYER_FRAME_SIZE.x),
				float(row_index * PLAYER_FRAME_SIZE.y),
				float(PLAYER_FRAME_SIZE.x),
				float(PLAYER_FRAME_SIZE.y)
			)
			frames.add_frame(animation_name, atlas_texture)
	return frames


func _update_movement_animation(input_vector: Vector2) -> void:
	if animated_sprite == null:
		return
	if input_vector == Vector2.ZERO:
		_apply_animation_state(_last_animation, _last_flip_h, false)
		return

	var motion: Vector2 = input_vector.normalized()
	var animation_state: Dictionary = _resolve_animation_state(motion)
	_last_animation = StringName(animation_state.get("animation", "idle_down"))
	_last_flip_h = bool(animation_state.get("flip_h", false))
	_apply_animation_state(_last_animation, _last_flip_h, true)


func _resolve_animation_state(motion: Vector2) -> Dictionary:
	var abs_x: float = absf(motion.x)
	var abs_y: float = absf(motion.y)
	var animation_name: StringName = &"idle_down"
	var flip_h: bool = false

	if abs_x <= 0.2 or abs_y > abs_x * 1.35:
		animation_name = &"idle_up" if motion.y < 0.0 else &"idle_down"
	elif abs_y <= 0.2 or abs_x > abs_y * 1.35:
		animation_name = &"idle_side"
		flip_h = motion.x < 0.0
	else:
		if motion.y < 0.0:
			animation_name = &"idle_up_diag"
			flip_h = motion.x < 0.0
		else:
			animation_name = &"idle_down_diag"
			flip_h = motion.x > 0.0

	return {
		"animation": animation_name,
		"flip_h": flip_h,
	}


func _apply_animation_state(animation_name: StringName, flip_h: bool, playing: bool) -> void:
	if animated_sprite == null:
		return
	animated_sprite.flip_h = flip_h
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif playing and not animated_sprite.is_playing():
		animated_sprite.play(animation_name)

	if playing:
		return

	animated_sprite.stop()
	animated_sprite.animation = animation_name
	animated_sprite.frame = 0


func _try_fire_weapon(weapon_id: String) -> void:
	match weapon_id:
		"fireball":
			_cast_fireball()
		"lightning_rune":
			_cast_lightning_rune()
		"thorn_seed":
			_cast_thorn_seed()


func _cast_fireball() -> void:
	if projectile_scene == null or _projectile_layer == null:
		return
	var target: Enemy = _find_closest_enemy(_get_weapon_range("fireball"))
	if target == null:
		return

	var level: int = int(_weapon_levels.get("fireball", 1))
	var projectile_count: int = 1 + mini(2, _get_passive_level("arcane_prism"))
	for index in range(projectile_count):
		var projectile: Node = projectile_scene.instantiate()
		_projectile_layer.add_child(projectile)
		if projectile.has_method("setup"):
			var centered_index: float = float(index) - float(projectile_count - 1) / 2.0
			var aim_point: Vector2 = _get_fireball_aim_point(target, centered_index)
			projectile.call(
				"setup",
				global_position,
				aim_point,
				_get_scaled_damage("fireball", level),
				Color(1.0, 0.509804, 0.211765, 1.0)
			)
	_set_weapon_cooldown("fireball")


func _cast_lightning_rune() -> void:
	var targets: Array[Enemy] = _find_enemies_in_range(_get_weapon_range("lightning_rune"))
	if targets.is_empty():
		var fallback_target: Enemy = _find_closest_enemy(_get_weapon_range("lightning_rune") * 1.6)
		if fallback_target != null:
			targets.append(fallback_target)
	if targets.is_empty():
		return

	var rune_level: int = int(_weapon_levels.get("lightning_rune", 1))
	var bonus_strikes: int = int(floor(float(rune_level) / 2.0))
	var strikes: int = 1 + mini(2, bonus_strikes)
	var damage: int = _get_scaled_damage("lightning_rune", rune_level)
	for index in range(mini(strikes, targets.size())):
		var enemy: Enemy = targets[index]
		enemy.take_damage(damage)
		_spawn_lightning_bolt(enemy.global_position, index)
	_set_weapon_cooldown("lightning_rune")


func _cast_thorn_seed() -> void:
	if area_effect_scene == null or _effect_layer == null:
		return
	var target: Enemy = _find_closest_enemy(_get_weapon_range("thorn_seed"))
	if target == null:
		return

	var area_effect: Node = area_effect_scene.instantiate()
	var level: int = int(_weapon_levels.get("thorn_seed", 1))
	var radius: float = 42.0 + level * 8.0
	_effect_layer.add_child(area_effect)
	if area_effect.has_method("setup"):
		area_effect.call(
			"setup",
			target.global_position,
			radius * (1.0 + _get_passive_level("arcane_prism") * 0.12),
			_get_scaled_damage("thorn_seed", level),
			1.1 + level * 0.15,
			Color(0.356863, 0.92549, 0.301961, 0.74)
		)
	_set_weapon_cooldown("thorn_seed")


func _find_closest_enemy(range_limit: float) -> Enemy:
	var best_distance: float = range_limit
	var closest: Enemy
	for child in _enemy_layer.get_children():
		if child is Enemy:
			var enemy: Enemy = child as Enemy
			if not enemy.is_active():
				continue
			var distance: float = global_position.distance_to(enemy.global_position)
			if distance <= best_distance:
				best_distance = distance
				closest = enemy
	return closest


func _find_enemies_in_range(range_limit: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child in _enemy_layer.get_children():
		if child is Enemy:
			var enemy: Enemy = child as Enemy
			if enemy.is_active() and global_position.distance_to(enemy.global_position) <= range_limit:
				var inserted: bool = false
				for index in range(result.size()):
					if global_position.distance_to(enemy.global_position) < global_position.distance_to(result[index].global_position):
						result.insert(index, enemy)
						inserted = true
						break
				if not inserted:
					result.append(enemy)
	return result


func _get_scaled_damage(weapon_id: String, weapon_level: int) -> int:
	var weapon_data: Dictionary = _get_weapon_data(weapon_id)
	var base_damage: int = int(weapon_data.get("base_damage", 10))
	var damage_multiplier: float = 1.0 + _get_passive_level("power_talisman") * 0.18
	return int(round((base_damage + (weapon_level - 1) * 4) * damage_multiplier))


func _get_weapon_range(weapon_id: String) -> float:
	var weapon_data: Dictionary = _get_weapon_data(weapon_id)
	return float(weapon_data.get("range", 260.0))


func _set_weapon_cooldown(weapon_id: String) -> void:
	var weapon_data: Dictionary = _get_weapon_data(weapon_id)
	var base_cooldown: float = float(weapon_data.get("cooldown", 1.0))
	var cooldown_multiplier: float = maxf(0.6, 1.0 - _get_passive_level("wind_feather") * 0.06)
	_cooldowns[weapon_id] = base_cooldown * cooldown_multiplier


func _get_passive_level(passive_id: String) -> int:
	return int(_passive_levels.get(passive_id, 0))


func _get_move_speed() -> float:
	return base_move_speed * (1.0 + _get_passive_level("wind_feather") * 0.08)


func _get_horizontal_input() -> float:
	var right: float = 1.0 if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right") else 0.0
	var left: float = 1.0 if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left") else 0.0
	return right - left


func _get_vertical_input() -> float:
	var down: float = 1.0 if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down") else 0.0
	var up: float = 1.0 if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up") else 0.0
	return down - up


func _get_weapon_data(weapon_id: String) -> Dictionary:
	if _content_db == null:
		return {}
	return _content_db.get_weapon(weapon_id)


func _get_fireball_aim_point(target: Enemy, centered_index: float) -> Vector2:
	var base_direction: Vector2 = (target.global_position - global_position).normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT
	var lateral: Vector2 = base_direction.orthogonal()
	return target.global_position + lateral * centered_index * 28.0


func _spawn_lightning_bolt(target_position: Vector2, strike_index: int) -> void:
	if _effect_layer == null:
		return
	var start_point: Vector2 = global_position + Vector2(0.0, -32.0)
	var control_point: Vector2 = start_point.lerp(target_position, 0.45) + Vector2(randf_range(-26.0, 26.0), randf_range(-20.0, 20.0))
	BattleVfx.spawn_lightning_strike(
		_effect_layer,
		start_point,
		control_point,
		target_position,
		_get_passive_level("arcane_prism"),
		strike_index
	)


func _get_damage_flash_targets() -> Array[CanvasItem]:
	var targets: Array[CanvasItem] = []
	if animated_sprite != null:
		targets.append(animated_sprite)
	if visual != null and visual.visible:
		targets.append(visual)
	return targets
