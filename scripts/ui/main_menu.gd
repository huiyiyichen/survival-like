extends Control

signal start_requested

const UIStyle = preload("res://scripts/ui/ui_style.gd")

@onready var start_button: Button = $CenterContainer/Card/Content/Root/LeftColumn/ActionRow/StartButton


func _ready() -> void:
	UIStyle.apply(self)
	start_button.pressed.connect(_on_start_pressed)
	set_start_label("开始游戏")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()


func _on_start_pressed() -> void:
	start_requested.emit()
	var game_flow: Node = get_node_or_null("/root/GameFlow")
	if game_flow != null:
		game_flow.call("go_to_character_select")


func set_start_label(text: String) -> void:
	start_button.text = text
