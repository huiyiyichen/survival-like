extends Area2D

const BattleVfx = preload("res://scripts/gameplay/battle_vfx.gd")

@onready var visual: Polygon2D = $Visual
@onready var glow: Polygon2D = $Glow
@onready var trail: Line2D = $Trail

@export var speed: float = 420.0
@export var lifetime: float = 1.6
@export var explosion_radius: float = 44.0

var _direction: Vector2 = Vector2.RIGHT
var _damage: int = 0
var _elapsed: float = 0.0
var _tint: Color = Color(1.0, 0.509804, 0.211765, 1.0)
var _has_exploded: bool = false
var _spawn_duration: float = 0.08


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func setup(source: Vector2, target: Vector2, damage: int, tint: Color = Color.WHITE) -> void:
	_ensure_visual()
	global_position = source
	_direction = (target - source).normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_damage = damage
	_tint = tint
	if visual != null:
		visual.color = tint
		visual.scale = Vector2.ONE * 0.26
		visual.modulate.a = 0.0
	if glow != null:
		glow.color = Color(tint.r, minf(1.0, tint.g + 0.16), minf(1.0, tint.b + 0.06), 0.65)
		glow.scale = Vector2.ONE * 0.16
		glow.modulate.a = 0.0
	if trail != null:
		trail.default_color = Color(1.0, 0.72, 0.34, 0.65)
		trail.points = PackedVector2Array([
			Vector2(-24.0, 0.0),
			Vector2(-10.0, 0.0),
			Vector2.ZERO,
		])
		trail.scale = Vector2(0.32, 0.32)
		trail.modulate.a = 0.0
	rotation = _direction.angle()


func _process(delta: float) -> void:
	global_position += _direction * speed * delta
	_elapsed += delta
	rotation = _direction.angle()
	_animate_visuals()
	if _elapsed >= lifetime:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		_explode(body)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		_explode(area)


func _ensure_visual() -> void:
	if visual == null:
		visual = get_node_or_null("Visual") as Polygon2D
	if glow == null:
		glow = get_node_or_null("Glow") as Polygon2D
	if trail == null:
		trail = get_node_or_null("Trail") as Line2D


func _animate_visuals() -> void:
	var spawn_ratio: float = _ease_out_cubic(clampf(_elapsed / _spawn_duration, 0.0, 1.0))
	var pulse: float = 1.0 + sin(_elapsed * 18.0) * 0.12
	if visual != null:
		visual.scale = Vector2.ONE * ((0.26 + spawn_ratio * 0.74) * pulse)
		visual.modulate.a = spawn_ratio
	if glow != null:
		glow.scale = Vector2.ONE * ((0.18 + spawn_ratio * 0.9) * (1.08 + sin(_elapsed * 11.0) * 0.14))
		glow.modulate.a = (0.45 + sin(_elapsed * 14.0) * 0.16) * spawn_ratio
	if trail != null:
		trail.width = (6.0 + sin(_elapsed * 10.0) * 1.4) * (0.25 + spawn_ratio * 0.75)
		trail.scale = Vector2(0.32 + spawn_ratio * 0.68, 0.28 + spawn_ratio * 0.72)
		trail.modulate.a = (0.52 + sin(_elapsed * 12.0) * 0.14) * spawn_ratio


func _explode(primary_target: Node = null) -> void:
	if _has_exploded:
		return
	_has_exploded = true

	var explosion_position: Vector2 = global_position
	if primary_target is Node2D:
		explosion_position = (primary_target as Node2D).global_position

	if primary_target != null and primary_target.has_method("take_damage"):
		primary_target.call("take_damage", _damage)

	var splash_damage: int = maxi(1, int(round(float(_damage) * 0.6)))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == primary_target:
			continue
		if enemy is Enemy and enemy.is_active():
			if explosion_position.distance_to((enemy as Enemy).global_position) <= explosion_radius:
				(enemy as Enemy).take_damage(splash_damage)

	var parent: Node = _resolve_vfx_parent()
	BattleVfx.spawn_fireball_burst(parent, explosion_position, _tint, maxf(56.0, explosion_radius * 1.18))
	queue_free()


func _ease_out_cubic(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _resolve_vfx_parent() -> Node:
	var scene: Node = get_tree().current_scene
	if scene != null:
		var effect_layer: Node = scene.get_node_or_null("EffectLayer")
		if effect_layer != null:
			return effect_layer
	return get_parent() if get_parent() != null else scene
