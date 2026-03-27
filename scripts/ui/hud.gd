extends Control

const UIStyle = preload("res://scripts/ui/ui_style.gd")
const UIIconLibrary = preload("res://scripts/ui/ui_icon_library.gd")

@onready var hp_label: Label = $TopLeftCard/Margin/StatsColumn/HPLabel
@onready var hp_bar: ProgressBar = $TopLeftCard/Margin/StatsColumn/HPBar
@onready var xp_label: Label = $TopLeftCard/Margin/StatsColumn/XPLabel
@onready var xp_bar: ProgressBar = $TopLeftCard/Margin/StatsColumn/XPBar
@onready var timer_label: Label = $TopRightCard/Margin/RunContent/TimerLabel
@onready var kill_label: Label = $TopRightCard/Margin/RunContent/KillLabel
@onready var boss_banner: PanelContainer = $BossBanner
@onready var boss_label: Label = $BossBanner/BossLabel
@onready var build_content: VBoxContainer = $BuildCard/Margin/BuildContent
@onready var weapons_text: Label = $BuildCard/Margin/BuildContent/WeaponsText
@onready var passives_text: Label = $BuildCard/Margin/BuildContent/PassivesText

var _weapon_slots: Array[Dictionary] = []
var _passive_slots: Array[Dictionary] = []


func _ready() -> void:
	UIStyle.apply(self)
	hp_bar.add_theme_stylebox_override("background", UIStyle.make_progress_background())
	hp_bar.add_theme_stylebox_override("fill", UIStyle.make_progress_fill(Color(0.905882, 0.356863, 0.333333, 0.96)))
	xp_bar.add_theme_stylebox_override("background", UIStyle.make_progress_background())
	xp_bar.add_theme_stylebox_override("fill", UIStyle.make_progress_fill(Color(0.333333, 0.72549, 0.972549, 0.96)))
	boss_banner.add_theme_stylebox_override(
		"panel",
		UIStyle.make_panel_style(Color(0.18, 0.07, 0.08, 0.92), Color(1.0, 0.47, 0.35, 0.4), 14)
	)
	$TopLeftCard.add_theme_stylebox_override(
		"panel",
		UIStyle.make_panel_style(Color(0.047, 0.062, 0.082, 0.78), Color(0.258, 0.882, 0.933, 0.12), 14)
	)
	$TopRightCard.add_theme_stylebox_override(
		"panel",
		UIStyle.make_panel_style(Color(0.047, 0.062, 0.082, 0.78), Color(0.258, 0.882, 0.933, 0.12), 14)
	)
	$BuildCard.add_theme_stylebox_override(
		"panel",
		UIStyle.make_panel_style(Color(0.047, 0.062, 0.082, 0.72), Color(0.258, 0.882, 0.933, 0.1), 14)
	)
	_setup_build_sections()
	reset()


func update_hp(current: float, maximum: float) -> void:
	var max_value: float = maxf(1.0, maximum)
	hp_label.text = "HP %d / %d" % [int(round(current)), int(round(maximum))]
	hp_bar.max_value = max_value
	hp_bar.value = clampf(current, 0.0, max_value)


func update_xp(level: int, current_xp: int, required_xp: int) -> void:
	var capped_goal: int = maxi(1, required_xp)
	xp_label.text = "Lv %d  XP %d / %d" % [level, current_xp, required_xp]
	xp_bar.max_value = float(capped_goal)
	xp_bar.value = clampf(float(current_xp), 0.0, float(capped_goal))


func update_timer(time_text: String) -> void:
	timer_label.text = time_text


func update_kills(count: int) -> void:
	kill_label.text = "击杀 %d" % count


func set_weapon_slot(index: int, entry_id: String, description: String) -> void:
	_set_slot_data(_weapon_slots, index, entry_id, description)


func set_passive_slot(index: int, entry_id: String, description: String) -> void:
	_set_slot_data(_passive_slots, index, entry_id, description)


func show_boss_warning(active: bool, text: String = "首领逼近：腐化术士") -> void:
	boss_banner.visible = active
	boss_label.text = text


func reset() -> void:
	hp_label.text = "HP 100 / 100"
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	xp_label.text = "Lv 1  XP 0 / 12"
	xp_bar.max_value = 12.0
	xp_bar.value = 0.0
	timer_label.text = "05:00"
	kill_label.text = "击杀 0"
	show_boss_warning(false)
	for index in range(_weapon_slots.size()):
		_set_slot_data(_weapon_slots, index, "", "空")
	for index in range(_passive_slots.size()):
		_set_slot_data(_passive_slots, index, "", "空")


func _setup_build_sections() -> void:
	weapons_text.text = "武器"
	passives_text.text = "被动"
	weapons_text.add_theme_font_size_override("font_size", 13)
	passives_text.add_theme_font_size_override("font_size", 13)
	weapons_text.modulate = Color(0.98, 0.92, 0.72, 0.95)
	passives_text.modulate = Color(0.84, 0.9, 1.0, 0.95)

	var weapon_list: VBoxContainer = _create_slot_list("WeaponList")
	var passive_list: VBoxContainer = _create_slot_list("PassiveList")
	build_content.add_child(weapon_list)
	build_content.move_child(weapon_list, build_content.get_children().find(weapons_text) + 1)
	build_content.move_child(passives_text, build_content.get_children().find(weapon_list) + 1)
	build_content.add_child(passive_list)
	build_content.move_child(passive_list, build_content.get_children().find(passives_text) + 1)

	for index in range(3):
		var weapon_view: Dictionary = _create_slot_view("WeaponSlot%d" % (index + 1))
		weapon_list.add_child(weapon_view.get("row"))
		_weapon_slots.append(weapon_view)
		var passive_view: Dictionary = _create_slot_view("PassiveSlot%d" % (index + 1))
		passive_list.add_child(passive_view.get("row"))
		_passive_slots.append(passive_view)


func _create_slot_list(name: String) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.name = name
	list.add_theme_constant_override("separation", 4)
	return list


func _create_slot_view(name: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = name
	row.custom_minimum_size = Vector2(0.0, 22.0)
	row.add_theme_constant_override("separation", 6)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(18.0, 18.0)
	icon.expand_mode = 1
	icon.stretch_mode = 5
	icon.texture_filter = 1
	row.add_child(icon)

	var label := Label.new()
	label.name = "Label"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.text = "空"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	return {
		"row": row,
		"icon": icon,
		"label": label,
	}


func _set_slot_data(slot_views: Array[Dictionary], index: int, entry_id: String, description: String) -> void:
	if index < 0 or index >= slot_views.size():
		return

	var view: Dictionary = slot_views[index]
	var icon: TextureRect = view.get("icon") as TextureRect
	var label: Label = view.get("label") as Label
	var texture: Texture2D = UIIconLibrary.get_icon_texture(entry_id)
	if icon != null:
		icon.texture = texture
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0) if texture != null else Color(0.52, 0.6, 0.68, 0.24)
	if label != null:
		label.text = description
		label.modulate = Color(0.95, 0.98, 1.0, 1.0) if not entry_id.is_empty() else Color(0.63, 0.71, 0.8, 0.72)
