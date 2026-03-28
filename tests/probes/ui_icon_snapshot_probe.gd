extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/components/hud.tscn")
const LEVEL_UP_PANEL_SCENE := preload("res://scenes/ui/components/level_up_panel.tscn")


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var background := ColorRect.new()
	background.color = Color(0.04, 0.08, 0.07, 1.0)
	background.position = Vector2.ZERO
	background.size = Vector2(1280.0, 720.0)
	root.add_child(background)

	var hud: Control = HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame
	hud.call("update_hp", 92, 100)
	hud.call("update_xp", 5, 0, 36)
	hud.call("set_weapon_slot", 0, "fireball", "火球术 Lv1")
	hud.call("set_weapon_slot", 1, "lightning_rune", "雷鸣符文 Lv2")
	hud.call("set_weapon_slot", 2, "thorn_seed", "荆棘种子 Lv2")
	hud.call("set_passive_slot", 0, "arcane_prism", "奥术棱镜 Lv1")
	hud.call("set_passive_slot", 1, "power_talisman", "力量护符 Lv1")

	var panel: Control = LEVEL_UP_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame

	var content_db := ContentDB.new()
	panel.call("show_choices", [
		{
			"id": "wind_feather",
			"label": "疾风羽饰\n获得新被动",
			"icon_spec": content_db.get_icon_spec("wind_feather"),
		},
		{
			"id": "fireball",
			"label": "火球术\n升级到 Lv2",
			"icon_spec": content_db.get_icon_spec("fireball"),
		},
		{
			"id": "power_talisman",
			"label": "力量护符\n升级到 Lv2",
			"icon_spec": content_db.get_icon_spec("power_talisman"),
		},
	])

	await create_timer(0.25).timeout

	var image: Image = root.get_texture().get_image()
	image.save_png("user://ui_icon_snapshot_probe.png")
	print("UI_ICON_SNAPSHOT_PROBE saved=%s" % ProjectSettings.globalize_path("user://ui_icon_snapshot_probe.png"))
	quit()
