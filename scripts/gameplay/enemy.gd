extends CharacterBody2D
class_name Enemy

signal died(enemy_id: String, xp_reward: int, world_position: Vector2, elite: bool, boss: bool)

const BattleVfx = preload("res://scripts/gameplay/battle_vfx.gd")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual
@onready var sprite: Sprite2D = $Sprite2D

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
	var use_sprite: bool = sprite != null and sprite.texture != null
	if sprite != null:
		sprite.visible = use_sprite
		sprite.scale = Vector2.ONE * (radius / 180.0)
		sprite.modulate = _get_sprite_tint(enemy_id, tint)
	if visual != null:
		visual.visible = not use_sprite
		visual.color = tint
		visual.polygon = PackedVector2Array([
			Vector2(0, -radius),
			Vector2(radius, 0),
			Vector2(0, radius),
			Vector2(-radius, 0),
		])


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	var to_target: Vector2 = _target.global_position - global_position
	var distance: float = to_target.length()
	var surface_distance: float = _get_surface_distance(distance)
	var direction: Vector2 = to_target.normalized() if distance > 0.0 else Vector2.ZERO

	if preferred_distance > 0.0:
		if surface_distance > preferred_distance:
			velocity = direction * move_speed
		elif surface_distance < preferred_distance * 0.6:
			velocity = -direction * move_speed * 0.7
		else:
			velocity = Vector2.ZERO
	else:
		velocity = direction * move_speed if surface_distance > attack_range * 0.35 else Vector2.ZERO

	move_and_slide()

	if surface_distance <= attack_range and _attack_timer <= 0.0:
		_target.take_damage(damage)
		_attack_timer = attack_cooldown


func set_target(target_node: Player) -> void:
	_target = target_node


func take_damage(amount: int) -> void:
	_current_hp = maxi(0, _current_hp - amount)
	BattleVfx.flash_red(_get_damage_flash_targets(), 0.1, 0.88)
	if _current_hp <= 0:
		BattleVfx.spawn_enemy_death_effect(
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


func get_current_hp() -> int:
	return _current_hp


func _get_damage_flash_targets() -> Array[CanvasItem]:
	var targets: Array[CanvasItem] = []
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
			return Color(1.0, 0.9, 0.68, 1.0)
		"corrupted_sorcerer":
			return Color(0.68, 0.86, 0.7, 1.0)
		_:
			return fallback


func _get_surface_distance(center_distance: float) -> float:
	var target_radius: float = _target.get_collision_radius() if _target != null else 0.0
	return maxf(0.0, center_distance - (_collision_radius + target_radius))


func _get_primary_visual_source() -> CanvasItem:
	if sprite != null and sprite.visible:
		return sprite
	if visual != null and visual.visible:
		return visual
	return null


func _resolve_vfx_parent() -> Node:
	var scene: Node = get_tree().current_scene
	if scene != null:
		var effect_layer: Node = scene.get_node_or_null("EffectLayer")
		if effect_layer != null:
			return effect_layer
	return get_parent() if get_parent() != null else scene


func _get_death_tint() -> Color:
	if sprite != null and sprite.visible:
		return sprite.modulate
	if visual != null and visual.visible:
		return visual.color
	return Color(0.62, 0.58, 0.52, 1.0)
