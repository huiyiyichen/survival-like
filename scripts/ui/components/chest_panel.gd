extends Control

signal chest_opened
signal closed

const UIStyleRef = preload("res://scripts/ui/common/ui_style.gd")
const UIIconLibraryRef = preload("res://scripts/ui/common/ui_icon_library.gd")

@onready var reward_label: Label = $CenterPanel/VBox/RewardLabel
@onready var open_button: Button = $CenterPanel/VBox/OpenButton

var _reward_icon: TextureRect


func _ready() -> void:
	UIStyleRef.apply(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_setup_reward_icon()
	open_button.pressed.connect(_on_open_pressed)


func set_result(desc: String) -> void:
	reward_label.text = desc


func set_reward(reward: Dictionary) -> void:
	var reward_name: String = String(reward.get("display_name", "未知强化"))
	var reason: String = String(reward.get("reason", "upgrade"))
	var prefix: String = "获得新强化" if reason == "new" else "升级已拥有强化"
	reward_label.text = "%s\n%s" % [reward_name, prefix]
	if _reward_icon != null:
		_reward_icon.texture = UIIconLibraryRef.texture_from_spec(Dictionary(reward.get("icon_spec", {})))
		_reward_icon.visible = _reward_icon.texture != null


func hide_panel() -> void:
	visible = false
	closed.emit()


func _on_open_pressed() -> void:
	chest_opened.emit()


func _setup_reward_icon() -> void:
	if _reward_icon != null:
		return
	var reward_index: int = reward_label.get_index()
	_reward_icon = TextureRect.new()
	_reward_icon.name = "RewardIcon"
	_reward_icon.custom_minimum_size = Vector2(72.0, 72.0)
	_reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reward_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reward_icon.visible = false
	_reward_icon.self_modulate = Color(1.0, 1.0, 1.0, 0.98)
	reward_label.get_parent().add_child(_reward_icon)
	reward_label.get_parent().move_child(_reward_icon, reward_index)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
