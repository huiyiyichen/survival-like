extends Area2D

const THORN_ANGLES := [-1.34, -0.74, -0.08, 0.62, 1.18, 2.62]
const THORN_LENGTHS := [0.4, 0.34, 0.28, 0.32, 0.38, 0.24]
const THORN_WIDTHS := [0.1, 0.085, 0.075, 0.082, 0.095, 0.07]
const THORN_DISTANCES := [0.3, 0.34, 0.24, 0.27, 0.33, 0.22]
const SPORE_ANGLES := [-1.2, -0.46, 0.24, 0.98, 1.74, 2.58, 3.44]
const SPORE_DISTANCES := [0.56, 0.62, 0.48, 0.66, 0.58, 0.52, 0.6]
const SPORE_PHASES := [0.0, 0.8, 1.5, 2.2, 3.1, 3.9, 4.6]
const SPORE_SPEEDS := [0.74, 0.92, 0.86, 1.04, 0.82, 0.96, 0.88]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var fill: Polygon2D = $Fill
@onready var glow: Polygon2D = $Glow
@onready var outer_ring: Line2D = $OuterRing
@onready var inner_ring: Line2D = $InnerRing
@onready var pulse_ring: Line2D = $PulseRing
@onready var vine_layer: Node2D = $VineLayer
@onready var bloom_layer: Node2D = $BloomLayer
@onready var spore_layer: Node2D = $SporeLayer
@onready var seed_halo: Polygon2D = $SeedHalo
@onready var seed_core: Polygon2D = $SeedCore
@onready var seed_inner_core: Polygon2D = $SeedInnerCore
@onready var sprout_left: Polygon2D = $SproutLeft
@onready var sprout_right: Polygon2D = $SproutRight

var damage_per_tick: int = 12
var tick_interval: float = 0.35
var duration: float = 1.5
var _elapsed: float = 0.0
var _tick_accumulator: float = 0.0
var _radius: float = 24.0
var _main_tint: Color = Color(0.34, 0.86, 0.28, 0.8)
var _highlight_tint: Color = Color(0.84, 1.0, 0.76, 1.0)
var _vine_nodes: Array[Line2D] = []
var _vine_controls: Array[Vector2] = []
var _vine_ends: Array[Vector2] = []
var _vine_phases: Array[float] = []
var _thorn_nodes: Array[Polygon2D] = []
var _thorn_positions: Array[Vector2] = []
var _thorn_rotations: Array[float] = []
var _thorn_scales: Array[float] = []
var _thorn_phases: Array[float] = []
var _spores: Array[Polygon2D] = []


func setup(center: Vector2, radius: float, tick_damage: int, total_duration: float, tint: Color) -> void:
	_ensure_node_refs()
	global_position = center
	damage_per_tick = tick_damage
	duration = total_duration
	_radius = maxf(16.0, radius)
	_elapsed = 0.0
	_tick_accumulator = 0.0

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = _radius
	if collision_shape != null:
		collision_shape.shape = circle

	_main_tint = Color(
		clampf(tint.r * 0.78, 0.0, 1.0),
		clampf(tint.g + 0.12, 0.0, 1.0),
		clampf(tint.b * 0.7, 0.0, 1.0),
		0.82
	)
	_highlight_tint = _main_tint.lerp(Color(0.92, 1.0, 0.8, 1.0), 0.42)

	_rebuild_dynamic_layers()
	_configure_static_shapes()
	_set_initial_visual_state()


func _process(delta: float) -> void:
	_elapsed += delta
	_tick_accumulator += delta
	_animate_visuals(delta)
	if _tick_accumulator >= tick_interval:
		_tick_accumulator = 0.0
		_apply_damage()
	if _elapsed >= duration:
		queue_free()


func _apply_damage() -> void:
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.call("take_damage", damage_per_tick)


func _ensure_node_refs() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if fill == null:
		fill = get_node_or_null("Fill") as Polygon2D
	if glow == null:
		glow = get_node_or_null("Glow") as Polygon2D
	if outer_ring == null:
		outer_ring = get_node_or_null("OuterRing") as Line2D
	if inner_ring == null:
		inner_ring = get_node_or_null("InnerRing") as Line2D
	if pulse_ring == null:
		pulse_ring = get_node_or_null("PulseRing") as Line2D
	if vine_layer == null:
		vine_layer = get_node_or_null("VineLayer") as Node2D
	if bloom_layer == null:
		bloom_layer = get_node_or_null("BloomLayer") as Node2D
	if spore_layer == null:
		spore_layer = get_node_or_null("SporeLayer") as Node2D
	if seed_halo == null:
		seed_halo = get_node_or_null("SeedHalo") as Polygon2D
	if seed_core == null:
		seed_core = get_node_or_null("SeedCore") as Polygon2D
	if seed_inner_core == null:
		seed_inner_core = get_node_or_null("SeedInnerCore") as Polygon2D
	if sprout_left == null:
		sprout_left = get_node_or_null("SproutLeft") as Polygon2D
	if sprout_right == null:
		sprout_right = get_node_or_null("SproutRight") as Polygon2D


func _configure_static_shapes() -> void:
	if fill != null:
		fill.color = Color(_main_tint.r * 0.44, _main_tint.g * 0.58, _main_tint.b * 0.42, 0.36)
		fill.polygon = _build_blob_points(_radius * 0.54, 18, 0.18, -0.2)
	if glow != null:
		glow.color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.1)
		glow.polygon = _build_blob_points(_radius * 0.68, 18, 0.12, 0.3)
	if outer_ring != null:
		outer_ring.closed = false
		outer_ring.width = maxf(1.2, _radius * 0.026)
		outer_ring.default_color = Color(_main_tint.r, _main_tint.g, _main_tint.b, 0.18)
		outer_ring.points = _build_tendril_path(_radius * 0.52, 14, -1.72, 2.68, 0.12)
	if inner_ring != null:
		inner_ring.closed = false
		inner_ring.width = maxf(1.0, _radius * 0.02)
		inner_ring.default_color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.12)
		inner_ring.points = _build_tendril_path(_radius * 0.34, 12, -0.92, 2.24, 0.1)
	if pulse_ring != null:
		pulse_ring.closed = false
		pulse_ring.width = maxf(1.0, _radius * 0.018)
		pulse_ring.default_color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.0)
		pulse_ring.points = _build_tendril_path(_radius * 0.76, 14, -1.24, 2.92, 0.18)
	if seed_halo != null:
		seed_halo.color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.16)
		seed_halo.polygon = _build_seed_halo_points(_radius * 0.18)
	if seed_core != null:
		seed_core.color = Color(_main_tint.r * 0.88, _main_tint.g, _main_tint.b * 0.58, 0.95)
		seed_core.polygon = _build_seed_core_points(_radius * 0.16)
	if seed_inner_core != null:
		seed_inner_core.color = Color(0.92, 1.0, 0.76, 0.84)
		seed_inner_core.polygon = _build_seed_core_points(_radius * 0.08)
	if sprout_left != null:
		sprout_left.color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.72)
		sprout_left.polygon = _build_sprout_points(_radius * 0.12, _radius * 0.05)
		sprout_left.position = Vector2(-_radius * 0.05, -_radius * 0.09)
		sprout_left.rotation = -1.18
	if sprout_right != null:
		sprout_right.color = Color(_highlight_tint.r, _highlight_tint.g, _highlight_tint.b, 0.68)
		sprout_right.polygon = _build_sprout_points(_radius * 0.1, _radius * 0.045)
		sprout_right.position = Vector2(_radius * 0.05, -_radius * 0.08)
		sprout_right.rotation = -0.18


func _set_initial_visual_state() -> void:
	if fill != null:
		fill.scale = Vector2.ONE * 0.1
		fill.modulate.a = 0.0
	if glow != null:
		glow.scale = Vector2.ONE * 0.08
		glow.modulate.a = 0.0
	if outer_ring != null:
		outer_ring.modulate.a = 0.0
	if inner_ring != null:
		inner_ring.modulate.a = 0.0
	if seed_halo != null:
		seed_halo.scale = Vector2.ONE * 0.18
		seed_halo.modulate.a = 0.0
	if seed_core != null:
		seed_core.scale = Vector2.ONE * 0.28
		seed_core.modulate.a = 0.0
	if seed_inner_core != null:
		seed_inner_core.scale = Vector2.ONE * 0.22
		seed_inner_core.modulate.a = 0.0
	if sprout_left != null:
		sprout_left.scale = Vector2.ONE * 0.1
		sprout_left.modulate.a = 0.0
	if sprout_right != null:
		sprout_right.scale = Vector2.ONE * 0.1
		sprout_right.modulate.a = 0.0
	for vine in _vine_nodes:
		vine.modulate.a = 0.0
		vine.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	for thorn in _thorn_nodes:
		thorn.scale = Vector2.ONE * 0.08
		thorn.modulate.a = 0.0
	for spore in _spores:
		spore.scale = Vector2.ONE * 0.2
		spore.modulate.a = 0.0


func _animate_visuals(delta: float) -> void:
	var life_ratio: float = clampf(1.0 - (_elapsed / maxf(duration, 0.001)), 0.0, 1.0)
	var seed_ratio: float = _ease_out_cubic(clampf(_elapsed / 0.12, 0.0, 1.0))
	var grow_ratio: float = _ease_out_cubic(clampf((_elapsed - 0.04) / 0.2, 0.0, 1.0))
	var sprout_ratio: float = _ease_out_cubic(clampf((_elapsed - 0.08) / 0.18, 0.0, 1.0))
	var spore_ratio: float = _ease_out_cubic(clampf((_elapsed - 0.14) / 0.2, 0.0, 1.0))
	var puddle_pulse: float = 1.0 + sin(_elapsed * 4.8) * 0.035

	if fill != null:
		fill.scale = Vector2.ONE * ((0.12 + grow_ratio * 0.88) * puddle_pulse)
		fill.modulate.a = 0.36 * life_ratio * grow_ratio
	if glow != null:
		glow.scale = Vector2.ONE * ((0.08 + grow_ratio * 0.92) * (1.0 + sin(_elapsed * 4.2) * 0.04))
		glow.modulate.a = 0.12 * life_ratio * grow_ratio
	if outer_ring != null:
		outer_ring.points = _build_tendril_path(
			_radius * (0.5 + sin(_elapsed * 2.0) * 0.015),
			14,
			-1.72 + sin(_elapsed * 1.6) * 0.08,
			2.68 + sin(_elapsed * 1.4) * 0.12,
			0.12 + sin(_elapsed * 2.0) * 0.03
		)
		outer_ring.modulate.a = 0.14 * life_ratio * grow_ratio
	if inner_ring != null:
		inner_ring.points = _build_tendril_path(
			_radius * (0.34 + sin(_elapsed * 2.2) * 0.012),
			12,
			-0.92 + sin(_elapsed * 2.1) * 0.1,
			2.24 + sin(_elapsed * 1.7) * 0.08,
			0.1 + sin(_elapsed * 2.8) * 0.02
		)
		inner_ring.modulate.a = 0.08 * life_ratio * grow_ratio
	if pulse_ring != null:
		pulse_ring.points = _build_tendril_path(
			_radius * (0.5 + grow_ratio * 0.34 + sin(_elapsed * 3.8) * 0.02),
			14,
			-1.2 + sin(_elapsed * 4.2) * 0.08,
			2.9 + sin(_elapsed * 3.4) * 0.16,
			0.16 + sin(_elapsed * 5.0) * 0.03
		)
		pulse_ring.modulate.a = 0.32 * life_ratio * spore_ratio
	if seed_halo != null:
		seed_halo.scale = Vector2.ONE * (0.18 + seed_ratio * 0.82)
		seed_halo.rotation += 0.38 * delta
		seed_halo.modulate.a = 0.16 * life_ratio * seed_ratio
	if seed_core != null:
		seed_core.scale = Vector2.ONE * (0.28 + seed_ratio * 0.72 + sin(_elapsed * 10.0) * 0.04)
		seed_core.modulate.a = 0.95 * life_ratio * seed_ratio
	if seed_inner_core != null:
		seed_inner_core.scale = Vector2.ONE * (0.22 + seed_ratio * 0.78 + sin(_elapsed * 12.0) * 0.06)
		seed_inner_core.modulate.a = 0.76 * life_ratio * seed_ratio
	if sprout_left != null:
		sprout_left.scale = Vector2.ONE * (0.1 + sprout_ratio * 0.95 + sin(_elapsed * 8.0) * 0.03)
		sprout_left.modulate.a = 0.7 * life_ratio * sprout_ratio
	if sprout_right != null:
		sprout_right.scale = Vector2.ONE * (0.1 + sprout_ratio * 0.9 + sin(_elapsed * 7.4 + 0.4) * 0.03)
		sprout_right.modulate.a = 0.66 * life_ratio * sprout_ratio

	_animate_vines(life_ratio, grow_ratio)
	_animate_thorns(life_ratio, grow_ratio)
	_animate_spores(delta, life_ratio, spore_ratio)


func _rebuild_dynamic_layers() -> void:
	_clear_dynamic_nodes()
	_vine_nodes.clear()
	_vine_controls.clear()
	_vine_ends.clear()
	_vine_phases.clear()
	_thorn_nodes.clear()
	_thorn_positions.clear()
	_thorn_rotations.clear()
	_thorn_scales.clear()
	_thorn_phases.clear()
	_spores.clear()

	if vine_layer != null and bloom_layer != null:
		for index in range(THORN_ANGLES.size()):
			var angle: float = THORN_ANGLES[index]
			var end_point: Vector2 = Vector2.RIGHT.rotated(angle) * _radius * THORN_DISTANCES[index]
			var control_point: Vector2 = Vector2.RIGHT.rotated(angle + 0.32) * _radius * 0.16

			var vine: Line2D = Line2D.new()
			vine.width = maxf(1.6, _radius * 0.026)
			vine.default_color = Color(_main_tint.r * 0.68, _main_tint.g * 0.92, _main_tint.b * 0.58, 0.54)
			vine.texture_mode = Line2D.LINE_TEXTURE_NONE
			vine.points = PackedVector2Array([Vector2.ZERO, control_point * 0.05, end_point * 0.08])
			vine_layer.add_child(vine)
			_vine_nodes.append(vine)
			_vine_controls.append(control_point)
			_vine_ends.append(end_point)
			_vine_phases.append(float(index) * 0.54)

			var thorn: Polygon2D = Polygon2D.new()
			thorn.color = Color(_main_tint.r * 0.82, _main_tint.g * 0.98, _main_tint.b * 0.62, 0.92)
			thorn.polygon = _build_thorn_spike_points(_radius * THORN_LENGTHS[index], _radius * THORN_WIDTHS[index])
			thorn.position = end_point
			thorn.rotation = angle
			var base_scale: float = 0.88 + float(index % 3) * 0.06
			thorn.scale = Vector2.ONE * base_scale
			bloom_layer.add_child(thorn)
			_thorn_nodes.append(thorn)
			_thorn_positions.append(end_point)
			_thorn_rotations.append(angle)
			_thorn_scales.append(base_scale)
			_thorn_phases.append(float(index) * 0.76)

	if spore_layer != null:
		for index in range(SPORE_ANGLES.size()):
			var spore: Polygon2D = Polygon2D.new()
			var radius_scale: float = _radius * (0.028 + float(index % 3) * 0.007)
			spore.color = Color(0.84, 1.0, 0.76, 0.44)
			spore.polygon = _build_circle_points(radius_scale, 6)
			spore_layer.add_child(spore)
			_spores.append(spore)


func _clear_dynamic_nodes() -> void:
	if vine_layer != null:
		for child in vine_layer.get_children():
			child.free()
	if bloom_layer != null:
		for child in bloom_layer.get_children():
			child.free()
	if spore_layer != null:
		for child in spore_layer.get_children():
			child.free()


func _animate_vines(life_ratio: float, grow_ratio: float) -> void:
	for index in range(_vine_nodes.size()):
		var vine: Line2D = _vine_nodes[index]
		var phase: float = _vine_phases[index]
		var wobble: Vector2 = Vector2.RIGHT.rotated(_vine_controls[index].angle() + PI * 0.5) * sin(_elapsed * 4.0 + phase) * _radius * 0.015
		var control_point: Vector2 = (_vine_controls[index] + wobble) * grow_ratio
		var end_point: Vector2 = _vine_ends[index] * grow_ratio
		vine.points = PackedVector2Array([Vector2.ZERO, control_point, end_point])
		vine.modulate.a = 0.5 * life_ratio * grow_ratio


func _animate_thorns(life_ratio: float, grow_ratio: float) -> void:
	for index in range(_thorn_nodes.size()):
		var thorn: Polygon2D = _thorn_nodes[index]
		var phase: float = _thorn_phases[index]
		thorn.position = _thorn_positions[index] * grow_ratio
		thorn.rotation = _thorn_rotations[index] + sin(_elapsed * 3.6 + phase) * 0.08
		thorn.scale = Vector2.ONE * (_thorn_scales[index] * (0.08 + grow_ratio * 0.92 + sin(_elapsed * 7.0 + phase) * 0.04))
		thorn.modulate.a = 0.82 * life_ratio * grow_ratio


func _animate_spores(delta: float, life_ratio: float, spore_ratio: float) -> void:
	for index in range(_spores.size()):
		var spore: Polygon2D = _spores[index]
		var orbit_angle: float = SPORE_ANGLES[index] + _elapsed * SPORE_SPEEDS[index] * 0.42
		var orbit_radius: float = _radius * SPORE_DISTANCES[index] * spore_ratio
		var bob: float = sin(_elapsed * 5.4 + SPORE_PHASES[index]) * _radius * 0.02
		spore.position = Vector2.RIGHT.rotated(orbit_angle) * orbit_radius + Vector2(0.0, bob)
		spore.scale = Vector2.ONE * (0.2 + spore_ratio * 0.9 + sin(_elapsed * 7.8 + SPORE_PHASES[index]) * 0.08)
		spore.modulate.a = 0.38 * life_ratio * spore_ratio


func _build_circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


func _build_blob_points(radius: float, segments: int, variance: float, angle_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle: float = angle_offset + TAU * float(index) / float(segments)
		var wobble: float = 1.0
		wobble += sin(angle * 2.0 + 0.7) * variance * 0.45
		wobble += cos(angle * 4.0 - 0.2) * variance * 0.32
		wobble += sin(angle * 3.0 + 1.1) * variance * 0.23
		points.append(Vector2.RIGHT.rotated(angle) * radius * wobble)
	return points


func _build_tendril_path(radius: float, segments: int, start_angle: float, sweep: float, variance: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var ratio: float = float(index) / float(maxi(segments - 1, 1))
		var angle: float = start_angle + sweep * ratio
		var local_radius: float = radius * (0.4 + ratio * 0.72)
		local_radius *= 1.0 + sin(ratio * PI * 2.4 + 0.7) * variance * 0.42
		local_radius *= 1.0 + cos(ratio * PI * 4.0 - 0.3) * variance * 0.18
		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * local_radius
		offset += Vector2.RIGHT.rotated(angle + PI * 0.5) * sin(ratio * PI * 3.2 + 0.4) * radius * variance * 0.18
		points.append(offset)
	return points


func _build_thorn_spike_points(length: float, width: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-width * 0.65, -width * 0.28),
		Vector2(length * 0.24, -width * 0.46),
		Vector2(length * 0.76, -width * 0.14),
		Vector2(length, 0.0),
		Vector2(length * 0.66, width * 0.16),
		Vector2(length * 0.28, width * 0.44),
		Vector2(-width * 0.32, width * 0.24),
		Vector2(length * 0.12, 0.0),
	])


func _build_seed_halo_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius * 1.8),
		Vector2(radius * 0.88, -radius * 0.56),
		Vector2(radius * 1.08, 0.0),
		Vector2(radius * 0.56, radius * 1.02),
		Vector2(0.0, radius * 1.48),
		Vector2(-radius * 0.58, radius * 1.04),
		Vector2(-radius * 1.04, 0.0),
		Vector2(-radius * 0.86, -radius * 0.58),
	])


func _build_seed_core_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -radius * 1.7),
		Vector2(radius * 0.86, -radius * 0.74),
		Vector2(radius * 0.98, 0.0),
		Vector2(radius * 0.52, radius * 1.08),
		Vector2(0.0, radius * 1.48),
		Vector2(-radius * 0.56, radius * 1.02),
		Vector2(-radius * 0.96, 0.0),
		Vector2(-radius * 0.84, -radius * 0.76),
	])


func _build_sprout_points(length: float, width: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(length * 0.26, -width),
		Vector2(length, 0.0),
		Vector2(length * 0.3, width * 1.02),
	])


func _ease_out_cubic(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)
