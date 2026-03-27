extends Node2D
class_name ArenaGround

const TILE_SHEET := preload("res://art/runtime/environment/forest_tile_sheet.png")
const TILE_WORLD_SIZE := Vector2(192.0, 192.0)
const GRID_EXTENTS := Vector2i(5, 4)
const FLOOR_REGIONS := [
	Rect2(2.0, 2.0, 163.0, 157.0),
	Rect2(2.0, 163.0, 163.0, 219.0),
	Rect2(2.0, 386.0, 163.0, 219.0),
	Rect2(2.0, 609.0, 163.0, 157.0),
]
const DECOR_REGIONS := [
	Rect2(1246.0, 167.0, 75.0, 71.0),
	Rect2(251.0, 689.0, 82.0, 77.0),
	Rect2(1076.0, 536.0, 81.0, 68.0),
	Rect2(991.0, 689.0, 80.0, 77.0),
]
const DECOR_TARGET_SIZES := [
	Vector2(78.0, 72.0),
	Vector2(88.0, 82.0),
	Vector2(86.0, 74.0),
	Vector2(82.0, 76.0),
]

@export var player_path: NodePath

var _player: Node2D
var _floor_tiles: Array[Sprite2D] = []
var _decor_tiles: Array[Sprite2D] = []
var _last_anchor: Vector2i = Vector2i(1 << 20, 1 << 20)


func _ready() -> void:
	_resolve_player()
	_build_pool()
	_refresh_tiles(true)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		if _player == null:
			return
	var anchor: Vector2i = _get_anchor_cell()
	if anchor != _last_anchor:
		_refresh_tiles(false)


func _resolve_player() -> void:
	_player = get_node_or_null(player_path) as Node2D


func _build_pool() -> void:
	if not _floor_tiles.is_empty():
		return
	for row in range(GRID_EXTENTS.y * 2 + 1):
		for column in range(GRID_EXTENTS.x * 2 + 1):
			var floor_tile := Sprite2D.new()
			floor_tile.centered = false
			floor_tile.texture = TILE_SHEET
			floor_tile.region_enabled = true
			floor_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			floor_tile.z_index = -40
			add_child(floor_tile)
			_floor_tiles.append(floor_tile)

			var decor_tile := Sprite2D.new()
			decor_tile.centered = true
			decor_tile.texture = TILE_SHEET
			decor_tile.region_enabled = true
			decor_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			decor_tile.z_index = -32
			decor_tile.visible = false
			add_child(decor_tile)
			_decor_tiles.append(decor_tile)


func _refresh_tiles(force: bool) -> void:
	if _player == null:
		return
	var anchor: Vector2i = _get_anchor_cell()
	if not force and anchor == _last_anchor:
		return
	_last_anchor = anchor

	var index: int = 0
	for row in range(-GRID_EXTENTS.y, GRID_EXTENTS.y + 1):
		for column in range(-GRID_EXTENTS.x, GRID_EXTENTS.x + 1):
			var cell: Vector2i = anchor + Vector2i(column, row)
			var floor_hash: int = _cell_hash(cell)
			var floor_region: Rect2 = FLOOR_REGIONS[posmod(floor_hash, FLOOR_REGIONS.size())]
			var floor_tile: Sprite2D = _floor_tiles[index]
			_configure_region_sprite(floor_tile, floor_region, TILE_WORLD_SIZE, false)
			floor_tile.position = Vector2(cell.x, cell.y) * TILE_WORLD_SIZE
			floor_tile.modulate = _get_floor_tint(floor_hash)

			var decor_tile: Sprite2D = _decor_tiles[index]
			_configure_decor_tile(decor_tile, cell, floor_hash)
			index += 1


func _configure_decor_tile(sprite: Sprite2D, cell: Vector2i, floor_hash: int) -> void:
	var decor_hash: int = _cell_hash(cell + Vector2i(17, -29))
	if posmod(decor_hash, 7) > 1:
		sprite.visible = false
		return

	var variant_index: int = posmod(decor_hash / 7, DECOR_REGIONS.size())
	var target_size: Vector2 = DECOR_TARGET_SIZES[variant_index] * randf_range(0.94, 1.08)
	_configure_region_sprite(sprite, DECOR_REGIONS[variant_index], target_size, true)
	sprite.visible = true
	sprite.position = Vector2(
		(cell.x + 0.5) * TILE_WORLD_SIZE.x + _hash_float(floor_hash, -34.0, 34.0),
		(cell.y + 0.58) * TILE_WORLD_SIZE.y + _hash_float(decor_hash, -12.0, 16.0)
	)
	sprite.modulate = Color(0.92, 0.96, 0.9, 0.88 + _hash_float(decor_hash + 9, 0.0, 0.12))


func _configure_region_sprite(sprite: Sprite2D, region: Rect2, target_size: Vector2, centered: bool) -> void:
	sprite.centered = centered
	sprite.region_rect = region
	sprite.scale = Vector2(
		target_size.x / maxf(1.0, region.size.x),
		target_size.y / maxf(1.0, region.size.y)
	)


func _get_anchor_cell() -> Vector2i:
	return Vector2i(
		floori(_player.global_position.x / TILE_WORLD_SIZE.x),
		floori(_player.global_position.y / TILE_WORLD_SIZE.y)
	)


func _get_floor_tint(hash_value: int) -> Color:
	var hue_shift: float = _hash_float(hash_value * 3 + 11, -0.025, 0.025)
	var darken: float = _hash_float(hash_value * 5 + 7, -0.08, 0.04)
	return Color.from_hsv(
		0.27 + hue_shift,
		0.24 + _hash_float(hash_value + 17, -0.05, 0.06),
		0.28 + darken,
		1.0
	)


func _cell_hash(cell: Vector2i) -> int:
	var value: int = cell.x * 92837111
	value ^= cell.y * 689287499
	value ^= (cell.x + cell.y * 31) * 283923481
	return abs(value)


func _hash_float(hash_value: int, min_value: float, max_value: float) -> float:
	var normalized: float = float(posmod(hash_value, 1000)) / 999.0
	return lerpf(min_value, max_value, normalized)
