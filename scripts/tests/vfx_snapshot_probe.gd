extends SceneTree

const BattleVfx = preload("res://scripts/gameplay/battle_vfx.gd")
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame
	var canvas := Node2D.new()
	root.add_child(canvas)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.08, 0.06, 1.0)
	background.position = Vector2.ZERO
	background.size = Vector2(1280.0, 720.0)
	canvas.add_child(background)

	BattleVfx.spawn_fireball_burst(canvas, Vector2(180.0, 200.0), Color(1.0, 0.52, 0.24, 1.0), 58.0)
	BattleVfx.spawn_dust_cloud(canvas, Vector2(340.0, 200.0), 40.0)
	BattleVfx.spawn_lightning_strike(canvas, Vector2(430.0, 90.0), Vector2(470.0, 170.0), Vector2(520.0, 250.0), 1, 0)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	canvas.add_child(enemy)
	enemy.global_position = Vector2(700.0, 220.0)
	await process_frame
	var content_db := ContentDB.new()
	enemy.configure("acid_slime", content_db.get_enemy("acid_slime"))
	enemy.take_damage(enemy.max_hp)

	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw

	var image: Image = root.get_texture().get_image()
	image.save_png("user://vfx_snapshot_probe.png")
	print("VFX_SNAPSHOT_PROBE saved=%s" % ProjectSettings.globalize_path("user://vfx_snapshot_probe.png"))
	quit()
