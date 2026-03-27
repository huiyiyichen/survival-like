extends Control

signal character_chosen(character_id: String)
signal cancel_requested

const UIStyle = preload("res://scripts/ui/ui_style.gd")

@onready var confirm_button: Button = $CenterContainer/Card/Content/VBox/ButtonRow/ConfirmButton
@onready var back_button: Button = $CenterContainer/Card/Content/VBox/ButtonRow/BackButton
@onready var character_name: Label = $CenterContainer/Card/Content/VBox/MainRow/InfoPanel/InfoMargin/InfoContent/CharacterName
@onready var description: Label = $CenterContainer/Card/Content/VBox/MainRow/InfoPanel/InfoMargin/InfoContent/Description
@onready var starting_weapon: Label = $CenterContainer/Card/Content/VBox/MainRow/InfoPanel/InfoMargin/InfoContent/StartingWeapon
@onready var trait_label: Label = $CenterContainer/Card/Content/VBox/MainRow/InfoPanel/InfoMargin/InfoContent/TraitLabel
@onready var hint_label: Label = $CenterContainer/Card/Content/VBox/MainRow/InfoPanel/InfoMargin/InfoContent/HintLabel

var _characters: Array[Dictionary] = []
var _selected_character_id: String = ""


func _ready() -> void:
	UIStyle.apply(self)
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	var game_flow: Node = _get_game_flow()
	display_characters(game_flow.call("get_character_entries") if game_flow != null else [])


func display_characters(data: Array[Dictionary]) -> void:
	_characters = data.duplicate(true)
	if _characters.is_empty():
		_selected_character_id = ""
		confirm_button.disabled = true
		return

	var entry: Dictionary = _characters[0]
	_selected_character_id = String(entry.get("id", ""))
	var display_name: String = String(entry.get("name", "未命名角色"))
	character_name.text = display_name
	description.text = String(entry.get("description", ""))
	var weapon_id: String = String(entry.get("weapon", ""))
	var weapon_name: String = String(entry.get("weapon_name", weapon_id))
	starting_weapon.text = "初始武器：%s" % (weapon_id if weapon_id.is_empty() else weapon_name)
	trait_label.text = "特性：%s" % String(entry.get("trait", ""))
	hint_label.text = "首版 Demo 固定开放 %s" % display_name
	confirm_button.disabled = bool(entry.get("locked", false))


func lock_character(character_id: String, locked: bool) -> void:
	if character_id == _selected_character_id:
		confirm_button.disabled = locked


func _on_confirm_pressed() -> void:
	if not _selected_character_id.is_empty():
		character_chosen.emit(_selected_character_id)
		var game_flow: Node = _get_game_flow()
		if game_flow != null:
			game_flow.call("select_character", _selected_character_id)
			game_flow.call("start_game")


func _on_back_pressed() -> void:
	cancel_requested.emit()
	var game_flow: Node = _get_game_flow()
	if game_flow != null:
		game_flow.call("go_to_main_menu")


func _get_game_flow() -> Node:
	return get_node_or_null("/root/GameFlow")
