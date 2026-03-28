extends RefCounted
class_name UIStyle

static var _shared_theme: Theme


static func apply(root: Control) -> void:
	if _shared_theme == null:
		_shared_theme = _build_theme()
	root.theme = _shared_theme


static func make_panel_style(
	background: Color = Color(0.047, 0.062, 0.082, 0.82),
	border: Color = Color(0.258, 0.882, 0.933, 0.22),
	radius: int = 16
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 10
	return style


static func make_button_style(
	background: Color,
	border: Color,
	text_color: Color = Color(0.95, 0.98, 1.0, 1.0)
) -> StyleBoxFlat:
	var style := make_panel_style(background, border, 12)
	style.content_margin_left = 22.0
	style.content_margin_top = 14.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 14.0
	style.shadow_size = 6
	style.expand_margin_left = 0.0
	style.expand_margin_top = 0.0
	style.expand_margin_right = 0.0
	style.expand_margin_bottom = 0.0
	return style


static func make_progress_background() -> StyleBoxFlat:
	return make_panel_style(
		Color(0.08, 0.105, 0.129, 0.92),
		Color(1.0, 1.0, 1.0, 0.05),
		10
	)


static func make_progress_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style


static func _build_theme() -> Theme:
	var theme := Theme.new()
	var label_color := Color(0.95, 0.98, 1.0, 1.0)
	var muted_color := Color(0.71, 0.78, 0.86, 0.9)
	var outline_color := Color(0.01, 0.02, 0.04, 0.9)

	theme.set_color("font_color", "Label", label_color)
	theme.set_color("font_outline_color", "Label", outline_color)
	theme.set_constant("outline_size", "Label", 1)

	theme.set_color("font_color", "Button", label_color)
	theme.set_color("font_hover_color", "Button", Color(1.0, 1.0, 1.0, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.96, 0.99, 1.0, 1.0))
	theme.set_color("font_disabled_color", "Button", Color(0.52, 0.58, 0.66, 0.95))
	theme.set_color("font_outline_color", "Button", outline_color)
	theme.set_constant("outline_size", "Button", 1)

	theme.set_color("font_color", "ProgressBar", label_color)
	theme.set_color("font_outline_color", "ProgressBar", outline_color)
	theme.set_constant("outline_size", "ProgressBar", 1)

	theme.set_color("font_color", "RichTextLabel", label_color)
	theme.set_color("default_color", "RichTextLabel", label_color)
	theme.set_color("font_outline_color", "RichTextLabel", outline_color)
	theme.set_constant("outline_size", "RichTextLabel", 1)

	theme.set_stylebox("panel", "PanelContainer", make_panel_style())
	theme.set_stylebox("panel", "Panel", make_panel_style())

	theme.set_stylebox(
		"normal",
		"Button",
		make_button_style(Color(0.08, 0.11, 0.15, 0.9), Color(0.26, 0.88, 0.94, 0.22))
	)
	theme.set_stylebox(
		"hover",
		"Button",
		make_button_style(Color(0.11, 0.17, 0.21, 0.95), Color(0.37, 0.92, 0.98, 0.38))
	)
	theme.set_stylebox(
		"pressed",
		"Button",
		make_button_style(Color(0.05, 0.22, 0.25, 0.95), Color(0.49, 0.94, 0.96, 0.48))
	)
	theme.set_stylebox(
		"disabled",
		"Button",
		make_button_style(Color(0.07, 0.09, 0.11, 0.65), Color(1.0, 1.0, 1.0, 0.06))
	)
	theme.set_stylebox(
		"focus",
		"Button",
		make_panel_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.47, 0.94, 0.99, 0.62), 14)
	)

	theme.set_stylebox("background", "ProgressBar", make_progress_background())
	theme.set_stylebox("fill", "ProgressBar", make_progress_fill(Color(0.35, 0.78, 0.96, 0.96)))

	theme.set_constant("separation", "VBoxContainer", 10)
	theme.set_constant("separation", "HBoxContainer", 10)

	theme.set_color("font_color", "CheckBox", label_color)
	theme.set_color("font_outline_color", "CheckBox", outline_color)
	theme.set_constant("outline_size", "CheckBox", 1)
	theme.set_color("font_color", "OptionButton", label_color)
	theme.set_color("font_outline_color", "OptionButton", outline_color)
	theme.set_constant("outline_size", "OptionButton", 1)

	theme.set_color("font_color", "LinkButton", muted_color)
	theme.set_color("font_hover_color", "LinkButton", label_color)
	theme.set_color("font_outline_color", "LinkButton", outline_color)
	theme.set_constant("outline_size", "LinkButton", 1)

	return theme
