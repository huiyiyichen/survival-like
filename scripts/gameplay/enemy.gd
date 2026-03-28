extends CharacterBody2D
class_name Enemy

signal died(enemy_id: String, xp_reward: int, world_position: Vector2, elite: bool, boss: bool)

const BattleVfxRef = preload("res://scripts/gameplay/battle_vfx.gd")
const ACID_SLIME_SPRITESHEET := preload("res://art/drafts/spritesheets/enemies/acid_slime_walk_sheet.png")
const ACID_SLIME_FRAME_SIZE := Vector2i(480, 720)
const ACID_SLIME_ANIMATION_NAME := &"idle"
const ACID_SLIME_ANIMATION_SPEED := 10.0
const ACID_SLIME_ANIMATION_CELLS := [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(3, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(3, 1),
	Vector2i(0, 2),
	Vector2i(1, 2),
]
const HORNWOLF_ANIMATION_NAME := &"idle"
const HORNWOLF_ANIMATION_SPEED := 12.0
const HORNWOLF_FRAME_TEXTURES := [
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_00.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_01.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_02.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_03.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_04.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_05.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_06.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_07.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_08.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_09.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_10.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_11.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_12.png"),
	preload("res://art/runtime/enemies/hornwolf/idle/hornwolf_idle_13.png"),
]
const PUSH_DAMPING: float = 940.0
const MAX_PUSH_VELOCITY: float = 180.0
const SOFT_SEPARATION_PADDING: float = 8.0
const SOFT_SEPARATION_SPEED_RATIO: float = 0.58

static var _acid_slime_sprite_frames: SpriteFrames
static var _hornwolf_sprite_frames: SpriteFrames

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var enemy_id: String = "acid_slime"
var display_name: String = "敌人"
var max_hp: int = 30
var move_speed: float = 90.0
var damage: int = 8
var xp_reward: int = 4
var attack_range: float = 22.0
var preferred_distance: float = 0.0
var attack_cooldown: float = 0.8
var is_elite: bool = false
var is_boss: bool = false

var _current_hp: int = 0
var _target: Player
var _attack_timer: float = 0.0
var _collision_radius: float = 14.0
var _push_velocity: Vector2 = Vector2.ZERO
var _animation_timer: float = 0.0
var _animation_frame: int = 0
func _ready() -> void:
	add_to_group("enemies")
	_current_hp = max_hp


func configure(new_enemy_id: String, data: Dictionary) -> void:
	_ensure_node_refs()
	enemy_id = new_enemy_id
	display_name = String(data.get("display_name", enemy_id))
	max_hp = int(data.get("max_hp", 30))
	move_speed = float(data.get("move_speed", 90.0))
	damage = int(data.get("damage", 8))
	xp_reward = int(data.get("xp_reward", 4))
	attack_range = float(data.get("attack_range", 22.0))
	preferred_distance = float(data.get("preferred_distance", 0.0))
	attack_cooldown = float(data.get("attack_cooldown", 0.8))
	is_elite = bool(data.get("is_elite", false))
	is_boss = bool(data.get("is_boss", false))
	_current_hp = max_hp

	var radius: float = float(data.get("radius", 14.0))
	_collision_radius = radius
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	if collision_shape != null:
		collision_shape.shape = circle
	var color_value: Variant = data.get("color", Color.WHITE)
	var tint: Color = Color.WHITE
	if color_value is Color:
		tint = color_value
	var use_animated_sprite: bool = _uses_animated_enemy_sprite()
	var use_sprite: bool = _uses_static_enemy_sprite()
	if animated_sprite != null:
		animated_sprite.visible = use_animated_sprite
		if use_animated_sprite:
			animated_sprite.sprite_frames = _get_enemy_sprite_frames(enemy_id)
			animated_sprite.position = _get_animated_sprite_offset(enemy_id)
			animated_sprite.scale = Vector2.ONE * _get_animated_sprite_scale(enemy_id, radius)
			animated_sprite.modulate = _get_sprite_tint(enemy_id, tint)
			animated_sprite.animation = _get_enemy_animation_name(enemy_id)
			animated_sprite.flip_h = false
			animated_sprite.frame = 0
			animated_sprite.frame_progress = 0.0
			_animation_timer = 0.0
			_animation_frame = 0
	if sprite != null:
		sprite.visible = use_sprite
		sprite.scale = Vector2.ONE * (radius / 180.0)
		sprite.modulate = _get_sprite_tint(enemy_id, tint)
	if visual != null:
		visual.visible = not use_sprite and not use_animated_sprite
		visual.color = tint
		visual.polygon = _build_visual_polygon(enemy_id, radius)


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		_update_visual_animation(Vector2.ZERO, delta)
		move_and_slide()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	var surface_distance: float = _get_surface_distance(distance)
	var direction: Vector2 = to_target.normalized() if distance > 0.0 else Vector2.ZERO
	var desired_velocity: Vector2 = Vector2.ZERO

	if preferred_distance > 0.0:
		if surface_distance > preferred_distance:
			desired_velocity = direction * move_speed
		elif surface_distance < preferred_distance * 0.6:
			desired_velocity = -direction * move_speed * 0.7
		else:
			desired_velocity = Vector2.ZERO
	else:
		desired_velocity = direction * move_speed if surface_distance > attack_range * 0.35 else Vector2.ZERO

	_push_velocity = _push_velocity.move_toward(Vector2.ZERO, PUSH_DAMPING * delta)
	velocity = desired_velocity + _compute_soft_separation() + _push_velocity
	_update_visual_animation(velocity, delta)
	move_and_slide()

	var current_surface_distance: float = _get_surface_distance(global_position.distance_to(_target.global_position))
	if current_surface_distance <= attack_range and _attack_timer <= 0.0:
		_target.take_damage(damage)
		_attack_timer = attack_cooldown


func set_target(target_node: Player) -> void:
	_target = target_node


func take_damage(amount: int) -> void:
	_current_hp = maxi(0, _current_hp - amount)
	BattleVfxRef.flash_red(_get_damage_flash_targets(), 0.1, 0.88)
	if _current_hp <= 0:
		BattleVfxRef.spawn_enemy_death_effect(
			_resolve_vfx_parent(),
			global_position,
			_get_primary_visual_source(),
			maxf(34.0, _collision_radius * 2.8),
			_get_death_tint()
		)
		died.emit(enemy_id, xp_reward, global_position, is_elite, is_boss)
		queue_free()


func is_active() -> bool:
	return _current_hp > 0


func get_collision_radius() -> float:
	return _collision_radius


func _ensure_node_refs() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual == null:
		visual = get_node_or_null("Visual") as Polygon2D
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if animated_sprite == null:
		animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


func get_current_hp() -> int:
	return _current_hp


func apply_player_push(push_direction: Vector2, push_distance: float) -> void:
	if push_direction == Vector2.ZERO or push_distance <= 0.0:
		return
	var weight: float = 0.72
	if is_elite:
		weight = 0.52
	if is_boss:
		weight = 0.36
	var size_resistance: float = clampf(18.0 / maxf(10.0, _collision_radius), 0.72, 1.0)
	_push_velocity += push_direction.normalized() * minf(MAX_PUSH_VELOCITY, push_distance * 32.0) * weight * size_resistance
	if _push_velocity.length() > MAX_PUSH_VELOCITY:
		_push_velocity = _push_velocity.normalized() * MAX_PUSH_VELOCITY


func _get_damage_flash_targets() -> Array[CanvasItem]:
	var targets: Array[CanvasItem] = []
	if animated_sprite != null and animated_sprite.visible:
		targets.append(animated_sprite)
	if sprite != null and sprite.visible:
		targets.append(sprite)
	if visual != null and visual.visible:
		targets.append(visual)
	return targets


func _get_sprite_tint(new_enemy_id: String, fallback: Color) -> Color:
	match new_enemy_id:
		"acid_slime":
			return Color.WHITE
		"wolf":
			return Color(0.76, 0.69, 0.56, 1.0)
		"archer":
			return Color(0.9, 0.93, 0.98, 1.0)
		"elite_hornwolf":
			return Color(0.98, 0.88, 0.74, 1.0)
		"boss_hornwolf":
			return Color(1.0, 0.96, 0.88, 1.0)
		_:
			return fallback


func _get_surface_distance(center_distance: float) -> float:
	var target_radius: float = _target.get_collision_radius() if _target != null else 0.0
	return maxf(0.0, center_distance - (_collision_radius + target_radius))


func _get_primary_visual_source() -> CanvasItem:
	if animated_sprite != null and animated_sprite.visible:
		return animated_sprite
	if sprite != null and sprite.visible:
		return sprite
	if visual != null and visual.visible:
		return visual
	return null


func _resolve_vfx_parent() -> Node:
	var tree: SceneTree = get_tree()
	var scene: Node = tree.current_scene if tree != null else null
	if scene != null:
		var effect_layer: Node = scene.get_node_or_null("EffectLayer")
		if effect_layer != null:
			return effect_layer
	var parent: Node = get_parent()
	if parent != null and is_instance_valid(parent):
		return parent
	return scene


func _get_death_tint() -> Color:
	if animated_sprite != null and animated_sprite.visible:
		return animated_sprite.modulate
	if sprite != null and sprite.visible:
		return sprite.modulate
	if visual != null and visual.visible:
		return visual.color
	return Color(0.62, 0.58, 0.52, 1.0)


func _compute_soft_separation() -> Vector2:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return Vector2.ZERO

	var separation: Vector2 = Vector2.ZERO
	for child in parent_node.get_children():
		if child == self or not child is Enemy:
			continue
		var other: Enemy = child as Enemy
		if other == null or not other.is_active():
			continue

		var offset: Vector2 = global_position - other.global_position
		var distance: float = offset.length()
		var desired_spacing: float = _collision_radius + other.get_collision_radius() + SOFT_SEPARATION_PADDING
		if distance <= 0.001:
			var fallback_angle: float = float(get_instance_id() % 360) / 360.0 * TAU
			separation += Vector2.RIGHT.rotated(fallback_angle)
			continue
		if distance >= desired_spacing:
			continue

		var strength: float = (desired_spacing - distance) / desired_spacing
		separation += offset / distance * strength

	if separation == Vector2.ZERO:
		return Vector2.ZERO
	return separation.normalized() * move_speed * SOFT_SEPARATION_SPEED_RATIO * minf(1.0, separation.length())


func _uses_animated_enemy_sprite() -> bool:
	if animated_sprite == null:
		return false
	match enemy_id:
		"acid_slime", "elite_hornwolf", "boss_hornwolf":
			return true
		_:
			return false


func _uses_static_enemy_sprite() -> bool:
	return false


func _update_visual_animation(motion: Vector2, delta: float) -> void:
	if animated_sprite == null or not animated_sprite.visible:
		return
	var animation_name: StringName = _get_enemy_animation_name(enemy_id)
	animated_sprite.animation = animation_name
	if absf(motion.x) > 3.0:
		animated_sprite.flip_h = motion.x < 0.0
	if motion.length_squared() > 4.0:
		if animated_sprite.sprite_frames == null:
			return
		var frame_count: int = animated_sprite.sprite_frames.get_frame_count(String(animation_name))
		if frame_count <= 0:
			return
		_animation_timer += delta
		var frame_duration: float = 1.0 / _get_enemy_animation_speed(enemy_id)
		while _animation_timer >= frame_duration:
			_animation_timer -= frame_duration
			_animation_frame = (_animation_frame + 1) % frame_count
		animated_sprite.frame = _animation_frame
		animated_sprite.frame_progress = 0.0
		return
	_animation_timer = 0.0
	_animation_frame = 0
	animated_sprite.frame = 0
	animated_sprite.frame_progress = 0.0


func _get_enemy_sprite_frames(new_enemy_id: String) -> SpriteFrames:
	match new_enemy_id:
		"acid_slime":
			return _get_acid_slime_sprite_frames()
		"elite_hornwolf", "boss_hornwolf":
			return _get_hornwolf_sprite_frames()
		_:
			return null


func _get_acid_slime_sprite_frames() -> SpriteFrames:
	if _acid_slime_sprite_frames == null:
		_acid_slime_sprite_frames = _build_sprite_frames(
			ACID_SLIME_ANIMATION_NAME,
			ACID_SLIME_ANIMATION_SPEED,
			ACID_SLIME_SPRITESHEET,
			ACID_SLIME_FRAME_SIZE,
			ACID_SLIME_ANIMATION_CELLS
		)
	return _acid_slime_sprite_frames


func _get_hornwolf_sprite_frames() -> SpriteFrames:
	if _hornwolf_sprite_frames == null:
		_hornwolf_sprite_frames = _build_sprite_frames_from_textures(
			HORNWOLF_ANIMATION_NAME,
			HORNWOLF_ANIMATION_SPEED,
			HORNWOLF_FRAME_TEXTURES
		)
	return _hornwolf_sprite_frames


func _build_sprite_frames(
	animation_name: StringName,
	animation_speed: float,
	spritesheet: Texture2D,
	frame_size: Vector2i,
	cells: Array
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, animation_speed)
	for raw_cell in cells:
		var cell: Vector2i = raw_cell
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = spritesheet
		atlas_texture.region = Rect2(
			float(cell.x * frame_size.x),
			float(cell.y * frame_size.y),
			float(frame_size.x),
			float(frame_size.y)
		)
		frames.add_frame(animation_name, atlas_texture)
	return frames


func _build_sprite_frames_from_textures(
	animation_name: StringName,
	animation_speed: float,
	textures: Array
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, animation_speed)
	for texture in textures:
		if texture is Texture2D:
			frames.add_frame(animation_name, texture)
	return frames


func _get_enemy_animation_name(new_enemy_id: String) -> StringName:
	match new_enemy_id:
		"elite_hornwolf", "boss_hornwolf":
			return HORNWOLF_ANIMATION_NAME
		_:
			return ACID_SLIME_ANIMATION_NAME


func _get_enemy_animation_speed(new_enemy_id: String) -> float:
	match new_enemy_id:
		"elite_hornwolf", "boss_hornwolf":
			return HORNWOLF_ANIMATION_SPEED
		_:
			return ACID_SLIME_ANIMATION_SPEED


func _get_animated_sprite_scale(new_enemy_id: String, radius: float) -> float:
	match new_enemy_id:
		"elite_hornwolf":
			return radius / 240.0
		"boss_hornwolf":
			return radius / 250.0
		_:
			return radius / 160.0


func _get_animated_sprite_offset(new_enemy_id: String) -> Vector2:
	match new_enemy_id:
		"elite_hornwolf", "boss_hornwolf":
			return Vector2(0.0, -18.0)
		_:
			return Vector2(0.0, -6.0)


func _build_visual_polygon(new_enemy_id: String, radius: float) -> PackedVector2Array:
	match new_enemy_id:
		"wolf":
			return PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.82, -radius * 0.18),
				Vector2(radius * 0.55, radius * 0.88),
				Vector2(-radius * 0.55, radius * 0.88),
				Vector2(-radius * 0.82, -radius * 0.18),
			])
		"archer":
			return PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.74, -radius * 0.46),
				Vector2(radius * 0.86, radius * 0.18),
				Vector2(0.0, radius),
				Vector2(-radius * 0.86, radius * 0.18),
				Vector2(-radius * 0.74, -radius * 0.46),
			])
		"elite_hornwolf":
			return PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.42, -radius * 0.92),
				Vector2(radius, -radius * 0.08),
				Vector2(radius * 0.62, radius),
				Vector2(-radius * 0.62, radius),
				Vector2(-radius, -radius * 0.08),
				Vector2(-radius * 0.42, -radius * 0.92),
			])
		"boss_hornwolf":
			return PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius * 0.34, -radius * 0.96),
				Vector2(radius, -radius * 0.14),
				Vector2(radius * 0.66, radius),
				Vector2(0.0, radius),
				Vector2(-radius * 0.66, radius),
				Vector2(-radius, -radius * 0.14),
				Vector2(-radius * 0.34, -radius * 0.96),
			])
		_:
			return PackedVector2Array([
				Vector2(0.0, -radius),
				Vector2(radius, 0.0),
				Vector2(0.0, radius),
				Vector2(-radius, 0.0),
			])
