extends Node2D
class_name ArenaGround

const FLOOR_TEXTURE := preload("res://art/runtime/environment/tiles/floor/forest_floor_dusk_a.png")
const TILE_STEP := Vector2(161.0, 155.0)
const TILE_OVERLAP := Vector2(2.0, 2.0)
const GRID_EXTENTS := Vector2i(12, 12)

@export var player_path: NodePath

var _player: Node2D
var _camera: Camera2D
var _floor_tiles: Array[Sprite2D] = []
var _last_anchor: Vector2i = Vector2i(1 << 20, 1 << 20)


func _ready() -> void:
	_resolve_refs()
	_build_pool()
	_refresh_tiles(true)


func _process(_delta: float) -> void:
	if (_player == null or not is_instance_valid(_player)) and (_camera == null or not is_instance_valid(_camera)):
		_resolve_refs()
		if _player == null and _camera == null:
			return
	var anchor: Vector2i = _get_anchor_cell()
	if anchor != _last_anchor:
		_refresh_tiles(false)


func _resolve_refs() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_camera = get_parent().get_node_or_null("Camera2D") as Camera2D if get_parent() != null else null


func _build_pool() -> void:
	if not _floor_tiles.is_empty():
		return
	for row in range(GRID_EXTENTS.y * 2 + 1):
		for column in range(GRID_EXTENTS.x * 2 + 1):
			var floor_tile := Sprite2D.new()
			floor_tile.centered = false
			floor_tile.texture = FLOOR_TEXTURE
			floor_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			floor_tile.z_index = -72
			add_child(floor_tile)
			_floor_tiles.append(floor_tile)


func _refresh_tiles(force: bool) -> void:
	if (_player == null or not is_instance_valid(_player)) and (_camera == null or not is_instance_valid(_camera)):
		return
	var anchor: Vector2i = _get_anchor_cell()
	if not force and anchor == _last_anchor:
		return
	_last_anchor = anchor

	var floor_size: Vector2 = FLOOR_TEXTURE.get_size()
	var display_size: Vector2 = floor_size + TILE_OVERLAP
	var scale_value := Vector2(
		display_size.x / maxf(1.0, floor_size.x),
		display_size.y / maxf(1.0, floor_size.y)
	)
	var offset := TILE_OVERLAP * -0.5

	var index := 0
	for row in range(-GRID_EXTENTS.y, GRID_EXTENTS.y + 1):
		for column in range(-GRID_EXTENTS.x, GRID_EXTENTS.x + 1):
			var cell: Vector2i = anchor + Vector2i(column, row)
			var floor_tile: Sprite2D = _floor_tiles[index]
			floor_tile.position = Vector2(cell.x, cell.y) * TILE_STEP + offset
			floor_tile.scale = scale_value
			floor_tile.modulate = Color.WHITE
			floor_tile.flip_h = false
			floor_tile.flip_v = false
			index += 1


func _get_anchor_cell() -> Vector2i:
	var anchor_position: Vector2 = Vector2.ZERO
	if _camera != null and is_instance_valid(_camera):
		anchor_position = _camera.get_screen_center_position()
	elif _player != null and is_instance_valid(_player):
		anchor_position = _player.global_position
	return Vector2i(
		floori(anchor_position.x / TILE_STEP.x),
		floori(anchor_position.y / TILE_STEP.y)
	)
