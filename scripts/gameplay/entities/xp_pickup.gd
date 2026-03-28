extends Area2D

signal picked_up(amount: int)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var value: int = 4
var magnet_radius: float = 160.0
var magnet_speed: float = 280.0
var _target_player: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_value: int, tint: Color = Color(0.4, 0.7, 1.0, 1.0)) -> void:
	_ensure_node_refs()
	value = new_value
	if visual != null:
		visual.color = tint
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	if collision_shape != null:
		collision_shape.shape = circle
	if visual != null:
		visual.polygon = PackedVector2Array([
			Vector2(0, -8),
			Vector2(7, 0),
			Vector2(0, 8),
			Vector2(-7, 0),
		])


func _process(delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		return
	var distance: float = global_position.distance_to(_target_player.global_position)
	if distance <= magnet_radius:
		global_position = global_position.move_toward(_target_player.global_position, magnet_speed * delta)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).gain_xp(value)
		picked_up.emit(value)
		queue_free()


func _ensure_node_refs() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if visual == null:
		visual = get_node_or_null("Visual") as Polygon2D


func set_player_target(target: Player) -> void:
	_target_player = target
