extends RefCounted
class_name BattleVfx


static func flash_red(targets: Array[CanvasItem], duration: float = 0.12, strength: float = 0.82) -> void:
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		var base_modulate: Color = _get_flash_base_modulate(target)
		var existing_tween: Variant = target.get_meta("_flash_tween") if target.has_meta("_flash_tween") else null
		if existing_tween is Tween:
			(existing_tween as Tween).kill()
		var flash_color: Color = base_modulate.lerp(Color(1.0, 0.22, 0.22, base_modulate.a), strength)
		target.modulate = flash_color
		var tween = target.create_tween()
		target.set_meta("_flash_tween", tween)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(target, "modulate", base_modulate, duration)
		tween.finished.connect(func() -> void:
			if is_instance_valid(target):
				target.modulate = base_modulate
				target.remove_meta("_flash_tween")
		)


static func spawn_fireball_burst(parent: Node, position: Vector2, tint: Color, radius: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var root := Node2D.new()
	root.name = "FireballBurst"
	root.global_position = position
	root.z_index = 72
	parent.add_child(root)

	var heat_halo: Polygon2D = _make_glow_disc(radius * 2.9, Color(1.0, 0.48, 0.08, 0.44), true, 24)
	heat_halo.scale = Vector2.ONE * 0.16
	heat_halo.modulate.a = 0.0
	root.add_child(heat_halo)

	var outer_bloom: Polygon2D = _make_glow_disc(radius * 1.9, Color(1.0, 0.7, 0.22, 0.84), true, 22)
	outer_bloom.scale = Vector2.ONE * 0.1
	outer_bloom.modulate.a = 0.0
	root.add_child(outer_bloom)

	var inner_core: Polygon2D = _make_glow_disc(radius * 0.82, Color(1.0, 0.95, 0.84, 0.98), false, 16)
	inner_core.scale = Vector2.ONE * 0.08
	inner_core.modulate.a = 0.0
	root.add_child(inner_core)

	var blast_star: Polygon2D = Polygon2D.new()
	blast_star.color = Color(
		clampf(tint.r + 0.12, 0.0, 1.0),
		clampf(tint.g + 0.22, 0.0, 1.0),
		clampf(tint.b + 0.06, 0.0, 1.0),
		0.96
	)
	blast_star.material = _make_additive_material()
	blast_star.polygon = _build_star(radius * 1.06, radius * 0.34, 8)
	blast_star.scale = Vector2.ONE * 0.12
	blast_star.modulate.a = 0.0
	root.add_child(blast_star)

	var shock_ring: Line2D = Line2D.new()
	shock_ring.width = maxf(7.0, radius * 0.28)
	shock_ring.default_color = Color(1.0, 0.86, 0.58, 0.98)
	shock_ring.closed = true
	shock_ring.points = _build_circle(radius * 0.96, 28)
	shock_ring.scale = Vector2.ONE * 0.12
	shock_ring.modulate.a = 0.0
	shock_ring.material = _make_additive_material()
	root.add_child(shock_ring)

	var ember_ring: Line2D = Line2D.new()
	ember_ring.width = maxf(4.0, radius * 0.18)
	ember_ring.default_color = Color(1.0, 0.44, 0.12, 0.92)
	ember_ring.closed = true
	ember_ring.points = _build_circle(radius * 0.62, 20)
	ember_ring.scale = Vector2.ONE * 0.2
	ember_ring.modulate.a = 0.0
	ember_ring.material = _make_additive_material()
	root.add_child(ember_ring)

	var sparks := Node2D.new()
	sparks.name = "Sparks"
	root.add_child(sparks)
	for index in range(14):
		var spark := Line2D.new()
		spark.width = maxf(3.0, radius * 0.13)
		spark.default_color = Color(1.0, 0.82, 0.3, 0.98)
		spark.material = _make_additive_material()
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / 14.0 + randf_range(-0.18, 0.18))
		spark.points = PackedVector2Array([
			Vector2.ZERO,
			direction * radius * randf_range(0.7, 1.08),
			direction * radius * randf_range(1.18, 1.66),
		])
		spark.scale = Vector2.ONE * 0.08
		spark.rotation = randf_range(-0.22, 0.22)
		spark.modulate.a = 0.0
		sparks.add_child(spark)

	root.scale = Vector2.ONE * 0.9
	var root_tween = root.create_tween()
	root_tween.tween_property(root, "scale", Vector2.ONE * 1.04, 0.08)

	var intro = root.create_tween()
	intro.set_parallel(true)
	intro.tween_property(heat_halo, "scale", Vector2.ONE * 1.18, 0.12)
	intro.tween_property(heat_halo, "modulate:a", 1.0, 0.12)
	intro.tween_property(outer_bloom, "scale", Vector2.ONE * 1.14, 0.08)
	intro.tween_property(outer_bloom, "modulate:a", 1.0, 0.08)
	intro.tween_property(inner_core, "scale", Vector2.ONE * 1.06, 0.06)
	intro.tween_property(inner_core, "modulate:a", 1.0, 0.06)
	intro.tween_property(blast_star, "scale", Vector2.ONE * 1.08, 0.07)
	intro.tween_property(blast_star, "modulate:a", 1.0, 0.07)
	intro.tween_property(shock_ring, "scale", Vector2.ONE * 1.06, 0.07)
	intro.tween_property(shock_ring, "modulate:a", 1.0, 0.07)
	intro.tween_property(ember_ring, "scale", Vector2.ONE * 1.12, 0.08)
	intro.tween_property(ember_ring, "modulate:a", 1.0, 0.08)
	for spark in sparks.get_children():
		intro.tween_property(spark, "scale", Vector2.ONE * 1.14, 0.06)
		intro.tween_property(spark, "modulate:a", 1.0, 0.06)

	var outro = root.create_tween()
	outro.tween_interval(0.06)
	outro.set_parallel(true)
	outro.tween_property(heat_halo, "scale", Vector2.ONE * 2.7, 0.34)
	outro.tween_property(heat_halo, "modulate:a", 0.0, 0.34)
	outro.tween_property(outer_bloom, "scale", Vector2.ONE * 2.05, 0.28)
	outro.tween_property(outer_bloom, "modulate:a", 0.0, 0.28)
	outro.tween_property(inner_core, "scale", Vector2.ONE * 0.52, 0.2)
	outro.tween_property(inner_core, "modulate:a", 0.0, 0.2)
	outro.tween_property(blast_star, "scale", Vector2.ONE * 1.92, 0.22)
	outro.tween_property(blast_star, "modulate:a", 0.0, 0.22)
	outro.tween_property(shock_ring, "scale", Vector2.ONE * 2.42, 0.3)
	outro.tween_property(shock_ring, "modulate:a", 0.0, 0.3)
	outro.tween_property(ember_ring, "scale", Vector2.ONE * 1.78, 0.24)
	outro.tween_property(ember_ring, "modulate:a", 0.0, 0.24)
	for spark in sparks.get_children():
		var spark_node: Line2D = spark as Line2D
		var drift: Vector2 = Vector2.RIGHT.rotated(spark_node.rotation) * radius * randf_range(0.18, 0.42)
		outro.tween_property(spark_node, "position", drift, 0.2)
		outro.tween_property(spark_node, "scale", Vector2.ONE * 1.92, 0.2)
		outro.tween_property(spark_node, "modulate:a", 0.0, 0.2)

	var cleanup = root.create_tween()
	cleanup.tween_interval(0.5)
	cleanup.tween_callback(Callable(root, "queue_free"))


static func spawn_dust_cloud(parent: Node, position: Vector2, radius: float, tint: Color = Color(0.62, 0.58, 0.52, 1.0)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Node2D.new()
	root.name = "DustCloud"
	root.global_position = position
	root.z_index = 42
	parent.add_child(root)
	_populate_dust_cloud(root, radius, tint, 1.0, false)
	var cleanup = root.create_tween()
	cleanup.tween_interval(0.58)
	cleanup.tween_callback(Callable(root, "queue_free"))


static func spawn_enemy_death_effect(
	parent: Node,
	position: Vector2,
	source_visual: CanvasItem,
	radius: float,
	tint: Color = Color(0.62, 0.58, 0.52, 1.0)
) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var root := Node2D.new()
	root.name = "DustCloudDeath"
	root.global_position = position
	root.z_index = 48
	parent.add_child(root)

	var silhouette: Node2D = _clone_visual_snapshot(source_visual)
	if silhouette != null:
		var source_color: Color = source_visual.modulate if source_visual != null and is_instance_valid(source_visual) else tint
		var ash_color: Color = source_color.lerp(Color(0.76, 0.73, 0.7, 0.96), 0.72)
		if silhouette is Sprite2D:
			var sprite_clone: Sprite2D = silhouette as Sprite2D
			sprite_clone.modulate = ash_color
			sprite_clone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		elif silhouette is Polygon2D:
			var poly_clone: Polygon2D = silhouette as Polygon2D
			poly_clone.color = ash_color
			poly_clone.modulate = ash_color
		else:
			silhouette.modulate = ash_color
		root.add_child(silhouette)

		var base_position: Vector2 = silhouette.position
		var base_scale: Vector2 = silhouette.scale
		silhouette.scale = base_scale * 1.18
		var silhouette_intro = root.create_tween()
		silhouette_intro.set_parallel(true)
		silhouette_intro.tween_property(silhouette, "scale", base_scale * 1.32, 0.08)
		silhouette_intro.tween_property(silhouette, "modulate:a", 0.96, 0.08)

		var silhouette_fade = root.create_tween()
		silhouette_fade.tween_interval(0.06)
		silhouette_fade.set_parallel(true)
		silhouette_fade.tween_property(
			silhouette,
			"position",
			base_position + Vector2(randf_range(-4.0, 4.0), -radius * 0.38),
			0.42
		)
		silhouette_fade.tween_property(silhouette, "scale", base_scale * 1.54, 0.42)
		silhouette_fade.tween_property(silhouette, "rotation", silhouette.rotation + randf_range(-0.16, 0.16), 0.42)
		silhouette_fade.tween_property(silhouette, "modulate:a", 0.0, 0.42)

	_populate_dust_cloud(root, radius * 1.22, tint.lerp(Color(0.78, 0.74, 0.68, 1.0), 0.45), 1.42, true)

	var cleanup = root.create_tween()
	cleanup.tween_interval(0.74)
	cleanup.tween_callback(Callable(root, "queue_free"))


static func spawn_lightning_strike(
	parent: Node,
	start_position: Vector2,
	control_position: Vector2,
	target_position: Vector2,
	prism_bonus: int,
	strike_index: int
) -> void:
	if parent == null or not is_instance_valid(parent):
		return

	var root := Node2D.new()
	root.name = "LightningStrike"
	root.global_position = start_position
	root.z_index = 80 + strike_index
	parent.add_child(root)

	var relative_control: Vector2 = control_position - start_position
	var relative_target: Vector2 = target_position - start_position
	var main_points: PackedVector2Array = _build_lightning_points(relative_control, relative_target, 9, 18.0 + float(prism_bonus) * 2.4)
	var glow_points: PackedVector2Array = _build_lightning_points(relative_control + Vector2(6.0, -6.0), relative_target, 9, 24.0 + float(prism_bonus) * 3.2)

	var back_glow: Line2D = _make_lightning_line(
		glow_points,
		32.0 + float(prism_bonus) * 3.6,
		Color(0.08, 0.78, 1.0, 0.42),
		true
	)
	root.add_child(back_glow)

	var mid_glow: Line2D = _make_lightning_line(
		main_points,
		22.0 + float(prism_bonus) * 2.8,
		Color(0.28, 0.94, 1.0, 0.68),
		true
	)
	root.add_child(mid_glow)

	var main_line: Line2D = _make_lightning_line(
		main_points,
		11.0 + float(prism_bonus) * 1.8,
		Color(0.96, 0.99, 1.0, 1.0),
		false
	)
	root.add_child(main_line)

	var branches: Array[Line2D] = []
	for branch_index in range(2 + mini(1, prism_bonus)):
		var branch_start: Vector2 = main_points[2 + branch_index]
		var branch_end: Vector2 = relative_target.lerp(branch_start, randf_range(0.28, 0.42))
		branch_end += Vector2(randf_range(-34.0, 34.0), randf_range(-22.0, 22.0))
		var branch_control: Vector2 = branch_start.lerp(branch_end, 0.5) + Vector2(randf_range(-18.0, 18.0), randf_range(-14.0, 14.0))
		var branch_points: PackedVector2Array = _build_lightning_branch(branch_start, branch_control, branch_end, 5, 10.0 + float(prism_bonus) * 1.8)
		var branch_line: Line2D = _make_lightning_line(
			branch_points,
			6.0 + float(prism_bonus) * 0.8,
			Color(0.74, 0.96, 1.0, 0.94),
			true
		)
		root.add_child(branch_line)
		branches.append(branch_line)

	var source_flash: Polygon2D = _make_glow_disc(30.0 + float(prism_bonus) * 2.0, Color(0.78, 0.96, 1.0, 0.78), true, 18)
	source_flash.scale = Vector2.ONE * 0.14
	source_flash.modulate.a = 0.0
	root.add_child(source_flash)

	var impact_halo: Polygon2D = _make_glow_disc(42.0 + float(prism_bonus) * 4.0, Color(0.32, 0.92, 1.0, 0.78), true, 22)
	impact_halo.position = relative_target
	impact_halo.scale = Vector2.ONE * 0.16
	impact_halo.modulate.a = 0.0
	root.add_child(impact_halo)

	var impact_star: Polygon2D = Polygon2D.new()
	impact_star.color = Color(0.94, 0.99, 1.0, 0.98)
	impact_star.material = _make_additive_material()
	impact_star.polygon = _build_star(36.0 + float(prism_bonus) * 3.0, 12.0, 6)
	impact_star.position = relative_target
	impact_star.scale = Vector2.ONE * 0.12
	impact_star.modulate.a = 0.0
	root.add_child(impact_star)

	var impact_sparks := Node2D.new()
	impact_sparks.position = relative_target
	root.add_child(impact_sparks)
	for index in range(6):
		var spark := Line2D.new()
		spark.width = 3.0 + float(prism_bonus) * 0.4
		spark.default_color = Color(0.82, 0.98, 1.0, 0.96)
		spark.material = _make_additive_material()
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / 6.0 + randf_range(-0.2, 0.2))
		spark.points = PackedVector2Array([Vector2.ZERO, direction * randf_range(16.0, 28.0)])
		spark.scale = Vector2.ONE * 0.12
		spark.modulate.a = 0.0
		impact_sparks.add_child(spark)

	for line in [back_glow, mid_glow, main_line]:
		(line as Line2D).scale = Vector2(1.0, 0.04)
		(line as Line2D).modulate.a = 0.0
	for branch in branches:
		branch.scale = Vector2(1.0, 0.06)
		branch.modulate.a = 0.0

	var intro = root.create_tween()
	intro.set_parallel(true)
	intro.tween_property(back_glow, "modulate:a", 1.0, 0.05)
	intro.tween_property(back_glow, "scale", Vector2.ONE, 0.05)
	intro.tween_property(mid_glow, "modulate:a", 1.0, 0.045)
	intro.tween_property(mid_glow, "scale", Vector2.ONE, 0.045)
	intro.tween_property(main_line, "modulate:a", 1.0, 0.04)
	intro.tween_property(main_line, "scale", Vector2.ONE, 0.04)
	intro.tween_property(source_flash, "modulate:a", 1.0, 0.045)
	intro.tween_property(source_flash, "scale", Vector2.ONE * 1.06, 0.045)
	intro.tween_property(impact_halo, "modulate:a", 1.0, 0.05)
	intro.tween_property(impact_halo, "scale", Vector2.ONE * 1.18, 0.05)
	intro.tween_property(impact_star, "modulate:a", 1.0, 0.04)
	intro.tween_property(impact_star, "scale", Vector2.ONE * 1.08, 0.04)
	for branch in branches:
		intro.tween_property(branch, "modulate:a", 0.98, 0.045)
		intro.tween_property(branch, "scale", Vector2.ONE, 0.045)
	for spark in impact_sparks.get_children():
		intro.tween_property(spark, "modulate:a", 1.0, 0.04)
		intro.tween_property(spark, "scale", Vector2.ONE * 1.16, 0.04)

	var flicker = root.create_tween()
	flicker.tween_interval(0.045)
	flicker.set_parallel(true)
	flicker.tween_property(main_line, "modulate:a", 0.86, 0.035)
	flicker.tween_property(mid_glow, "modulate:a", 0.78, 0.035)
	for branch in branches:
		flicker.tween_property(branch, "modulate:a", 0.7, 0.035)

	var outro = root.create_tween()
	outro.tween_interval(0.08)
	outro.set_parallel(true)
	outro.tween_property(back_glow, "modulate:a", 0.0, 0.22)
	outro.tween_property(back_glow, "scale", Vector2(1.0, 1.62), 0.22)
	outro.tween_property(mid_glow, "modulate:a", 0.0, 0.18)
	outro.tween_property(mid_glow, "scale", Vector2(1.0, 1.34), 0.18)
	outro.tween_property(main_line, "modulate:a", 0.0, 0.16)
	outro.tween_property(main_line, "scale", Vector2(1.0, 1.22), 0.16)
	outro.tween_property(source_flash, "modulate:a", 0.0, 0.18)
	outro.tween_property(source_flash, "scale", Vector2.ONE * 1.58, 0.18)
	outro.tween_property(impact_halo, "modulate:a", 0.0, 0.22)
	outro.tween_property(impact_halo, "scale", Vector2.ONE * 1.92, 0.22)
	outro.tween_property(impact_star, "modulate:a", 0.0, 0.18)
	outro.tween_property(impact_star, "scale", Vector2.ONE * 1.68, 0.18)
	for branch in branches:
		outro.tween_property(branch, "modulate:a", 0.0, 0.14)
		outro.tween_property(branch, "scale", Vector2(1.0, 1.18), 0.14)
	for spark in impact_sparks.get_children():
		var spark_line: Line2D = spark as Line2D
		var push: Vector2 = spark_line.points[spark_line.points.size() - 1] * 0.4
		outro.tween_property(spark_line, "position", push, 0.14)
		outro.tween_property(spark_line, "modulate:a", 0.0, 0.14)
		outro.tween_property(spark_line, "scale", Vector2.ONE * 1.42, 0.14)

	var cleanup = root.create_tween()
	cleanup.tween_interval(0.36)
	cleanup.tween_callback(Callable(root, "queue_free"))


static func _populate_dust_cloud(root: Node2D, radius: float, tint: Color, intensity: float, with_silhouette: bool) -> void:
	var haze: Polygon2D = _make_glow_disc(radius * 1.2, Color(0.54, 0.5, 0.46, 0.32), false, 18)
	haze.scale = Vector2.ONE * 0.12
	haze.modulate.a = 0.0
	root.add_child(haze)

	if with_silhouette:
		var ash_flash: Polygon2D = _make_glow_disc(radius * 0.86, Color(0.94, 0.88, 0.8, 0.42), false, 16)
		ash_flash.scale = Vector2.ONE * 0.1
		ash_flash.modulate.a = 0.0
		root.add_child(ash_flash)
		var ash_flash_intro = root.create_tween()
		ash_flash_intro.set_parallel(true)
		ash_flash_intro.tween_property(ash_flash, "scale", Vector2.ONE * 1.32, 0.08)
		ash_flash_intro.tween_property(ash_flash, "modulate:a", 0.86, 0.08)
		var ash_flash_fade = root.create_tween()
		ash_flash_fade.tween_interval(0.05)
		ash_flash_fade.set_parallel(true)
		ash_flash_fade.tween_property(ash_flash, "scale", Vector2.ONE * 1.86, 0.24)
		ash_flash_fade.tween_property(ash_flash, "modulate:a", 0.0, 0.24)

	var ash_ring: Polygon2D = Polygon2D.new()
	ash_ring.color = Color(0.86, 0.82, 0.76, 0.52)
	ash_ring.polygon = _build_star(radius * 0.92, radius * 0.42, 8)
	ash_ring.scale = Vector2.ONE * 0.12
	ash_ring.modulate.a = 0.0
	root.add_child(ash_ring)

	var shock_ring: Line2D = Line2D.new()
	shock_ring.width = maxf(3.0, radius * 0.12)
	shock_ring.default_color = Color(0.92, 0.88, 0.82, 0.76)
	shock_ring.closed = true
	shock_ring.points = _build_circle(radius * 0.7, 20)
	shock_ring.scale = Vector2.ONE * 0.18
	shock_ring.modulate.a = 0.0
	root.add_child(shock_ring)

	var mote_count: int = 14 if not with_silhouette else 18
	for index in range(mote_count):
		var mote := Polygon2D.new()
		var mote_radius: float = randf_range(radius * 0.12, radius * 0.28) * intensity
		mote.color = Color(
			clampf(tint.r + randf_range(0.08, 0.16), 0.0, 1.0),
			clampf(tint.g + randf_range(0.07, 0.14), 0.0, 1.0),
			clampf(tint.b + randf_range(0.05, 0.12), 0.0, 1.0),
			0.96
		)
		mote.polygon = _build_circle(mote_radius, 8)
		mote.position = Vector2.RIGHT.rotated(TAU * float(index) / float(mote_count) + randf_range(-0.22, 0.22)) * randf_range(2.0, radius * 0.18)
		mote.scale = Vector2.ONE * 0.08
		mote.modulate.a = 0.0
		root.add_child(mote)

		var drift: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / float(mote_count) + randf_range(-0.3, 0.3)) * randf_range(radius * 0.7, radius * 1.5)
		var rise: Vector2 = Vector2(randf_range(-6.0, 6.0), -radius * randf_range(0.28, 0.54))
		var mote_intro = root.create_tween()
		mote_intro.set_parallel(true)
		mote_intro.tween_property(mote, "scale", Vector2.ONE * randf_range(1.0, 1.24), 0.08)
		mote_intro.tween_property(mote, "modulate:a", 1.0, 0.08)

		var mote_fade = root.create_tween()
		mote_fade.tween_interval(0.05)
		mote_fade.set_parallel(true)
		mote_fade.tween_property(mote, "position", mote.position + drift + rise, 0.48)
		mote_fade.tween_property(mote, "scale", Vector2.ONE * randf_range(1.9, 2.8), 0.48)
		mote_fade.tween_property(mote, "modulate:a", 0.0, 0.48)

	var streak_count: int = 4 if not with_silhouette else 7
	for index in range(streak_count):
		var streak := Line2D.new()
		streak.width = maxf(2.0, radius * 0.08)
		streak.default_color = Color(0.84, 0.8, 0.76, 0.88)
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / float(streak_count) + randf_range(-0.2, 0.2))
		streak.points = PackedVector2Array([Vector2.ZERO, direction * randf_range(radius * 0.34, radius * 0.58)])
		streak.scale = Vector2.ONE * 0.12
		streak.modulate.a = 0.0
		root.add_child(streak)

		var streak_tween = root.create_tween()
		streak_tween.set_parallel(true)
		streak_tween.tween_property(streak, "scale", Vector2.ONE * 1.22, 0.07)
		streak_tween.tween_property(streak, "modulate:a", 0.9, 0.07)
		var streak_fade = root.create_tween()
		streak_fade.tween_interval(0.05)
		streak_fade.set_parallel(true)
		streak_fade.tween_property(streak, "position", direction * randf_range(radius * 0.16, radius * 0.34), 0.24)
		streak_fade.tween_property(streak, "scale", Vector2.ONE * 1.68, 0.24)
		streak_fade.tween_property(streak, "modulate:a", 0.0, 0.24)

	var intro = root.create_tween()
	intro.set_parallel(true)
	intro.tween_property(haze, "scale", Vector2.ONE * 1.06, 0.08)
	intro.tween_property(haze, "modulate:a", 0.84, 0.08)
	intro.tween_property(ash_ring, "scale", Vector2.ONE * 1.08, 0.07)
	intro.tween_property(ash_ring, "modulate:a", 1.0, 0.07)
	intro.tween_property(shock_ring, "scale", Vector2.ONE * 1.0, 0.06)
	intro.tween_property(shock_ring, "modulate:a", 1.0, 0.06)

	var fade = root.create_tween()
	fade.tween_interval(0.06)
	fade.set_parallel(true)
	fade.tween_property(haze, "scale", Vector2.ONE * 1.58, 0.4)
	fade.tween_property(haze, "modulate:a", 0.0, 0.4)
	fade.tween_property(ash_ring, "scale", Vector2.ONE * 1.84, 0.34)
	fade.tween_property(ash_ring, "modulate:a", 0.0, 0.34)
	fade.tween_property(shock_ring, "scale", Vector2.ONE * 2.06, 0.3)
	fade.tween_property(shock_ring, "modulate:a", 0.0, 0.3)


static func _build_circle(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


static func _build_star(outer_radius: float, inner_radius: float, spikes: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(spikes * 2):
		var angle: float = TAU * float(index) / float(spikes * 2)
		var radius: float = outer_radius if index % 2 == 0 else inner_radius
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points


static func _make_glow_disc(radius: float, color: Color, additive: bool, segments: int) -> Polygon2D:
	var disc := Polygon2D.new()
	disc.color = color
	disc.polygon = _build_circle(radius, segments)
	if additive:
		disc.material = _make_additive_material()
	return disc


static func _make_lightning_line(points: PackedVector2Array, width: float, color: Color, additive: bool) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.texture_mode = Line2D.LINE_TEXTURE_NONE
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = points
	if additive:
		line.material = _make_additive_material()
	return line


static func _build_lightning_points(control: Vector2, target: Vector2, segments: int, jitter: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var t: float = float(index) / float(segments)
		var curve_point: Vector2 = _quadratic_bezier(Vector2.ZERO, control, target, t)
		if index != 0 and index != segments:
			var tangent: Vector2 = _quadratic_bezier_tangent(Vector2.ZERO, control, target, t)
			var normal: Vector2 = tangent.orthogonal().normalized()
			curve_point += normal * randf_range(-jitter, jitter) * sin(t * PI)
		points.append(curve_point)
	return points


static func _build_lightning_branch(
	start: Vector2,
	control: Vector2,
	target: Vector2,
	segments: int,
	jitter: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments + 1):
		var t: float = float(index) / float(segments)
		var curve_point: Vector2 = _quadratic_bezier(start, control, target, t)
		if index != 0 and index != segments:
			var tangent: Vector2 = _quadratic_bezier_tangent(start, control, target, t)
			var normal: Vector2 = tangent.orthogonal().normalized()
			curve_point += normal * randf_range(-jitter, jitter) * sin(t * PI)
		points.append(curve_point)
	return points


static func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var inv_t: float = 1.0 - t
	return inv_t * inv_t * a + 2.0 * inv_t * t * b + t * t * c


static func _quadratic_bezier_tangent(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return 2.0 * (1.0 - t) * (b - a) + 2.0 * t * (c - b)


static func _clone_visual_snapshot(source_visual: CanvasItem) -> Node2D:
	if source_visual == null or not is_instance_valid(source_visual):
		return null
	if source_visual is AnimatedSprite2D:
		var animated_source: AnimatedSprite2D = source_visual as AnimatedSprite2D
		var frame_texture: Texture2D = null
		if animated_source.sprite_frames != null:
			frame_texture = animated_source.sprite_frames.get_frame_texture(
				String(animated_source.animation),
				animated_source.frame
			)
		if frame_texture == null:
			return null
		var animated_clone := Sprite2D.new()
		animated_clone.texture = frame_texture
		animated_clone.position = animated_source.position
		animated_clone.scale = animated_source.scale
		animated_clone.rotation = animated_source.rotation
		animated_clone.skew = animated_source.skew
		animated_clone.offset = animated_source.offset
		animated_clone.centered = animated_source.centered
		animated_clone.flip_h = animated_source.flip_h
		animated_clone.flip_v = animated_source.flip_v
		animated_clone.texture_filter = animated_source.texture_filter
		return animated_clone
	if source_visual is Sprite2D:
		var sprite_source: Sprite2D = source_visual as Sprite2D
		var sprite_clone := Sprite2D.new()
		sprite_clone.texture = sprite_source.texture
		sprite_clone.position = sprite_source.position
		sprite_clone.scale = sprite_source.scale
		sprite_clone.rotation = sprite_source.rotation
		sprite_clone.skew = sprite_source.skew
		sprite_clone.offset = sprite_source.offset
		sprite_clone.centered = sprite_source.centered
		sprite_clone.flip_h = sprite_source.flip_h
		sprite_clone.flip_v = sprite_source.flip_v
		sprite_clone.hframes = sprite_source.hframes
		sprite_clone.vframes = sprite_source.vframes
		sprite_clone.frame = sprite_source.frame
		sprite_clone.frame_coords = sprite_source.frame_coords
		sprite_clone.region_enabled = sprite_source.region_enabled
		sprite_clone.region_rect = sprite_source.region_rect
		sprite_clone.texture_filter = sprite_source.texture_filter
		return sprite_clone
	if source_visual is Polygon2D:
		var polygon_source: Polygon2D = source_visual as Polygon2D
		var polygon_clone := Polygon2D.new()
		polygon_clone.position = polygon_source.position
		polygon_clone.scale = polygon_source.scale
		polygon_clone.rotation = polygon_source.rotation
		polygon_clone.skew = polygon_source.skew
		polygon_clone.polygon = polygon_source.polygon
		polygon_clone.color = polygon_source.color
		return polygon_clone
	return null


static func _make_additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


static func _get_flash_base_modulate(target: CanvasItem) -> Color:
	if target.has_meta("_flash_base_modulate"):
		var stored: Variant = target.get_meta("_flash_base_modulate")
		if stored is Color:
			return stored
	target.set_meta("_flash_base_modulate", target.modulate)
	return target.modulate
