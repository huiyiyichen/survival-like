extends Control

signal back_to_menu_requested

const UIStyleRef = preload("res://scripts/ui/ui_style.gd")

@onready var result_title: Label = $CenterContainer/Card/Content/Root/SummaryColumn/ResultTitle
@onready var summary_label: Label = $CenterContainer/Card/Content/Root/SummaryColumn/SummaryLabel
@onready var stats_label: Label = $CenterContainer/Card/Content/Root/SummaryColumn/StatsLabel
@onready var return_button: Button = $CenterContainer/Card/Content/Root/SummaryColumn/ReturnButton


func _ready() -> void:
	UIStyleRef.apply(self)
	return_button.pressed.connect(_on_return_pressed)
	var game_flow: Node = _get_game_flow()
	display_result(game_flow.call("get_last_result") if game_flow != null else {})


func display_result(summary: Dictionary) -> void:
	var survived_text: String = String(summary.get("survival_time", "00:00"))
	var kill_count: int = int(summary.get("kill_count", 0))
	var outcome: String = String(summary.get("outcome", "失败"))
	var boss_text: String = String(summary.get("boss_result", "未击败"))
	result_title.text = "战斗%s" % ("胜利" if outcome == "胜利" else "失败")
	summary_label.text = "你在诅咒林地坚持了 %s。" % survived_text
	stats_label.text = "击杀 %s | 结果：%s | 首领：%s" % [kill_count, outcome, boss_text]


func _on_return_pressed() -> void:
	back_to_menu_requested.emit()
	var game_flow: Node = _get_game_flow()
	if game_flow != null:
		game_flow.call("return_to_menu")


func _get_game_flow() -> Node:
	return get_node_or_null("/root/GameFlow")
