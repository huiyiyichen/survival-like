extends Control

signal option_selected(choice_id: String)
signal closed

const UIStyleRef = preload("res://scripts/ui/common/ui_style.gd")
const UIIconLibraryRef = preload("res://scripts/ui/common/ui_icon_library.gd")

@onready var option_buttons: Array[Button] = [
	$CenterPanel/VBox/Choices/ChoiceButton1,
	$CenterPanel/VBox/Choices/ChoiceButton2,
	$CenterPanel/VBox/Choices/ChoiceButton3,
]

var _choices: Array[Dictionary] = []
var _option_views: Array[Dictionary] = []


func _ready() -> void:
	UIStyleRef.apply(self)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	for index in option_buttons.size():
		var button: Button = option_buttons[index]
		button.custom_minimum_size = Vector2(0.0, 84.0)
		_option_views.append(_ensure_option_view(button))
		button.pressed.connect(_on_option_pressed.bind(index))


func show_choices(choices: Array[Dictionary]) -> void:
	_choices = choices.duplicate(true)
	for index in option_buttons.size():
		var button: Button = option_buttons[index]
		var view: Dictionary = _option_views[index]
		if index < _choices.size():
			var choice: Dictionary = _choices[index]
			var label_text: String = String(choice.get("label", "选项 %d" % (index + 1)))
			var label_lines: PackedStringArray = label_text.split("\n", false)
			var title_label: Label = view.get("title") as Label
			var meta_label: Label = view.get("meta") as Label
			var icon_rect: TextureRect = view.get("icon") as TextureRect
			if title_label != null:
				title_label.text = label_lines[0] if not label_lines.is_empty() else label_text
			if meta_label != null:
				meta_label.text = label_lines[1] if label_lines.size() > 1 else String(choice.get("reason", ""))
			if icon_rect != null:
				icon_rect.texture = UIIconLibraryRef.texture_from_spec(Dictionary(choice.get("icon_spec", {})))
			button.visible = true
			button.disabled = false
			button.text = ""
		else:
			button.visible = false
			button.disabled = true
			_clear_option_view(view)
	visible = not _choices.is_empty()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _on_option_pressed(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	var choice: Dictionary = _choices[index]
	option_selected.emit(String(choice.get("id", "")))


func _ensure_option_view(button: Button) -> Dictionary:
	var margin := MarginContainer.new()
	margin.name = "ContentMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(42.0, 42.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var text_column := VBoxContainer.new()
	text_column.name = "TextColumn"
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 3)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_column)

	var title := Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 17)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(title)

	var meta := Label.new()
	meta.name = "Meta"
	meta.add_theme_font_size_override("font_size", 12)
	meta.modulate = Color(0.73, 0.82, 0.91, 0.92)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(meta)

	return {
		"icon": icon,
		"title": title,
		"meta": meta,
	}


func _clear_option_view(view: Dictionary) -> void:
	var title: Label = view.get("title") as Label
	var meta: Label = view.get("meta") as Label
	var icon: TextureRect = view.get("icon") as TextureRect
	if title != null:
		title.text = ""
	if meta != null:
		meta.text = ""
	if icon != null:
		icon.texture = null
