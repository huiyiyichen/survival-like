extends SceneTree

const BattleVfxRef = preload("res://scripts/gameplay/effects/battle_vfx.gd")
const PLAYER_SCENE := preload("res://scenes/gameplay/entities/player.tscn")
const ENEMY_SCENE := preload("res://scenes/gameplay/entities/enemy.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var root_node := Node2D.new()
	root.add_child(root_node)

	BattleVfxRef.spawn_fireball_burst(root_node, Vector2(120.0, 80.0), Color(1.0, 0.52, 0.24, 1.0), 52.0)
	BattleVfxRef.spawn_dust_cloud(root_node, Vector2(220.0, 80.0), 32.0)
	BattleVfxRef.spawn_lightning_strike(root_node, Vector2(0.0, 0.0), Vector2(70.0, -40.0), Vector2(150.0, 30.0), 1, 0)
	await process_frame
	await process_frame

	var fireball_root: Node2D = _find_effect(root_node, "FireballBurst")
	var dust_root: Node2D = _find_effect(root_node, "DustCloud")
	var lightning_root: Node2D = _find_effect(root_node, "LightningStrike")
	if dust_root == null or lightning_root == null:
		var child_debug: Array[String] = []
		for child in root_node.get_children():
			child_debug.append("%s:%s" % [String(child.name), str(child is Node2D and is_instance_valid(child))])
		print("VFX_CHILDREN %s" % str(child_debug))
	if fireball_root == null or fireball_root.get_child_count() < 4:
		_failures.append("Fireball burst did not create a visible effect root.")
	if dust_root == null or dust_root.get_child_count() < 6:
		_failures.append("Dust cloud did not create enough visible particles.")
	if lightning_root == null or lightning_root.get_child_count() < 4:
		_failures.append("Lightning strike did not create visible segments.")

	var player: Player = PLAYER_SCENE.instantiate()
	root_node.add_child(player)
	await process_frame
	var player_sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var player_base: Color = player_sprite.modulate if player_sprite != null else Color.WHITE
	BattleVfxRef.flash_red([player_sprite], 0.08, 0.86)
	await create_timer(0.14).timeout
	if player_sprite == null or not _color_close(player_sprite.modulate, player_base):
		_failures.append("Player flash red did not restore original modulate.")

	var enemy: Enemy = ENEMY_SCENE.instantiate()
	root_node.add_child(enemy)
	await process_frame
	var content_db := ContentDB.new()
	enemy.configure("acid_slime", content_db.get_enemy("acid_slime"))
	enemy.take_damage(enemy.max_hp)
	await process_frame
	await process_frame
	var death_effect_found: bool = false
	for child in root_node.get_children():
		if child is Node2D and String(child.name).begins_with("DustCloud"):
			death_effect_found = true
			break
	if not death_effect_found:
		_failures.append("Enemy death dust effect did not spawn on lethal hit.")

	print("VFX_VISIBILITY_PROBE fireball=%s dust=%s lightning=%s restored=%s death=%s" % [
		str(fireball_root != null),
		str(dust_root != null),
		str(lightning_root != null),
		str(player_sprite != null and _color_close(player_sprite.modulate, player_base)),
		str(death_effect_found),
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _find_effect(root_node: Node2D, prefix: String) -> Node2D:
	for child in root_node.get_children():
		if child is Node2D and String(child.name).begins_with(prefix):
			return child as Node2D
	return null


func _color_close(a: Color, b: Color) -> bool:
	return (
		is_equal_approx(a.r, b.r)
		and is_equal_approx(a.g, b.g)
		and is_equal_approx(a.b, b.b)
		and is_equal_approx(a.a, b.a)
	)
