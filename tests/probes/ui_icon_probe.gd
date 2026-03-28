extends SceneTree

const HUD_SCENE := preload("res://scenes/ui/components/hud.tscn")
const LEVEL_UP_PANEL_SCENE := preload("res://scenes/ui/components/level_up_panel.tscn")
const CHEST_PANEL_SCENE := preload("res://scenes/ui/components/chest_panel.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	await process_frame

	var hud: Control = HUD_SCENE.instantiate()
	root.add_child(hud)
	await process_frame
	hud.call("set_weapon_slot", 0, "fireball", "火球术 Lv3")
	hud.call("set_passive_slot", 0, "arcane_prism", "奥术棱镜 Lv2")
	await process_frame

	var weapon_icon: TextureRect = hud.get_node_or_null("BuildCard/Margin/BuildContent/WeaponList/WeaponSlot1/Icon") as TextureRect
	var passive_icon: TextureRect = hud.get_node_or_null("BuildCard/Margin/BuildContent/PassiveList/PassiveSlot1/Icon") as TextureRect
	if weapon_icon == null or weapon_icon.texture == null:
		_failures.append("HUD weapon icon was not populated.")
	if passive_icon == null or passive_icon.texture == null:
		_failures.append("HUD passive icon was not populated.")

	var content_db := ContentDB.new()
	var level_up_panel: Control = LEVEL_UP_PANEL_SCENE.instantiate()
	root.add_child(level_up_panel)
	await process_frame
	level_up_panel.call(
		"show_choices",
		content_db.build_upgrade_candidates({"fireball": 1}, {"arcane_prism": 1}, 3, 3)
	)
	await process_frame

	var choice_icon: TextureRect = level_up_panel.get_node_or_null("CenterPanel/VBox/Choices/ChoiceButton1/ContentMargin/Row/Icon") as TextureRect
	if choice_icon == null or choice_icon.texture == null:
		_failures.append("Level up panel icon was not populated.")

	var chest_panel: Control = CHEST_PANEL_SCENE.instantiate()
	root.add_child(chest_panel)
	await process_frame
	chest_panel.call(
		"set_reward",
		content_db.build_chest_reward({"fireball": 1}, {"arcane_prism": 1}, 3, 3)
	)
	await process_frame

	var reward_icon: TextureRect = chest_panel.get_node_or_null("CenterPanel/VBox/RewardIcon") as TextureRect
	if reward_icon == null or reward_icon.texture == null:
		_failures.append("Chest reward icon was not populated.")

	print("UI_ICON_PROBE hud_weapon=%s hud_passive=%s choice_icon=%s reward_icon=%s" % [
		str(weapon_icon != null and weapon_icon.texture != null),
		str(passive_icon != null and passive_icon.texture != null),
		str(choice_icon != null and choice_icon.texture != null),
		str(reward_icon != null and reward_icon.texture != null),
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)
