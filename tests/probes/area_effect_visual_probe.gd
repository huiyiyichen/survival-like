extends SceneTree

const AREA_EFFECT_SCENE := preload("res://scenes/gameplay/entities/area_effect.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame
	var effect: Area2D = AREA_EFFECT_SCENE.instantiate()
	root.add_child(effect)
	await process_frame

	effect.call("setup", Vector2.ZERO, 72.0, 14, 1.4, Color(0.36, 0.92, 0.28, 0.72))
	await process_frame

	var bloom_layer: Node2D = effect.get_node_or_null("BloomLayer") as Node2D
	var spore_layer: Node2D = effect.get_node_or_null("SporeLayer") as Node2D
	var seed_core: Polygon2D = effect.get_node_or_null("SeedCore") as Polygon2D
	var seed_halo: Polygon2D = effect.get_node_or_null("SeedHalo") as Polygon2D
	var sprout_left: Polygon2D = effect.get_node_or_null("SproutLeft") as Polygon2D
	var sprout_right: Polygon2D = effect.get_node_or_null("SproutRight") as Polygon2D
	var pulse_ring: Line2D = effect.get_node_or_null("PulseRing") as Line2D
	var fill: Polygon2D = effect.get_node_or_null("Fill") as Polygon2D

	if bloom_layer == null or bloom_layer.get_child_count() < 6:
		_failures.append("BloomLayer did not create enough thorn petals.")
	if spore_layer == null or spore_layer.get_child_count() < 6:
		_failures.append("SporeLayer did not create enough toxic spores.")
	if seed_core == null or seed_core.polygon.size() < 6:
		_failures.append("SeedCore polygon was not built.")
	if seed_halo == null or seed_halo.polygon.size() < 8:
		_failures.append("SeedHalo polygon was not built.")
	if sprout_left == null or sprout_left.polygon.size() < 4:
		_failures.append("SproutLeft polygon was not built.")
	if sprout_right == null or sprout_right.polygon.size() < 4:
		_failures.append("SproutRight polygon was not built.")
	if pulse_ring == null or pulse_ring.points.size() < 12:
		_failures.append("PulseRing points were not built.")
	if fill == null or fill.polygon.size() < 16:
		_failures.append("Fill polygon is too simple.")

	for _step in range(12):
		await process_frame

	print("AREA_EFFECT_VISUAL_PROBE petals=%d spores=%d seed_points=%d pulse_points=%d fill_points=%d" % [
		bloom_layer.get_child_count() if bloom_layer != null else -1,
		spore_layer.get_child_count() if spore_layer != null else -1,
		seed_core.polygon.size() if seed_core != null else -1,
		pulse_ring.points.size() if pulse_ring != null else -1,
		fill.polygon.size() if fill != null else -1,
	])

	effect.queue_free()

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
