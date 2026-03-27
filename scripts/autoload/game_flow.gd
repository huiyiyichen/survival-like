extends Node

signal request_scene_change(scene_path: String)
signal battle_requested(character_id: String)
signal result_ready(result_data: Dictionary)

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/character_select.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const RESULT_SCENE := "res://scenes/ui/result_screen.tscn"

var demo_config: DemoConfig
var content_db: ContentDB
var selected_character: String = ""
var cached_result: Dictionary = {}


func _ready() -> void:
	demo_config = DemoConfig.new()
	content_db = ContentDB.new()


func _change_scene(scene_path: String) -> void:
	request_scene_change.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func go_to_character_select() -> void:
	_change_scene(CHARACTER_SELECT_SCENE)


func select_character(character_id: String) -> bool:
	if content_db.characters.has(character_id):
		selected_character = character_id
		return true
	return false


func ensure_selected_character() -> String:
	if selected_character.is_empty():
		for character_id in content_db.characters.keys():
			selected_character = String(character_id)
			break
	return selected_character


func start_game() -> void:
	var character_id: String = ensure_selected_character()
	battle_requested.emit(character_id)
	_change_scene(GAME_SCENE)


func restart_last_character() -> void:
	start_game()


func cache_result(data: Dictionary) -> void:
	cached_result = data.duplicate(true)


func show_result(data: Dictionary = {}) -> void:
	if not data.is_empty():
		cache_result(data)
	result_ready.emit(cached_result)
	_change_scene(RESULT_SCENE)


func return_to_menu() -> void:
	cached_result = {}
	_change_scene(MAIN_MENU_SCENE)


func get_last_result() -> Dictionary:
	return cached_result.duplicate(true)


func get_selected_character_id() -> String:
	return ensure_selected_character()


func get_selected_character_data() -> Dictionary:
	return content_db.get_character(get_selected_character_id())


func get_character_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for character_id in content_db.characters.keys():
		var character_key: String = String(character_id)
		var data: Dictionary = content_db.get_character(character_key)
		var starting_weapons: Array[String] = _variant_to_string_array(data.get("starting_weapons", []))
		var starting_weapon_id: String = ""
		if not starting_weapons.is_empty():
			starting_weapon_id = starting_weapons[0]
		entries.append(
			{
				"id": character_key,
				"name": String(data.get("display_name", character_key)),
				"description": String(data.get("description", "")),
				"weapon": starting_weapon_id,
				"weapon_name": content_db.get_display_name(starting_weapon_id),
				"trait": String(data.get("trait", "")),
				"locked": false,
			}
		)
	return entries


func get_upgrade_options(weapon_levels: Dictionary, passive_levels: Dictionary) -> Array[Dictionary]:
	return content_db.build_upgrade_candidates(
		weapon_levels,
		passive_levels,
		demo_config.MAX_WEAPON_SLOTS,
		demo_config.MAX_PASSIVE_SLOTS
	)


func get_chest_reward(weapon_levels: Dictionary, passive_levels: Dictionary) -> Dictionary:
	return content_db.build_chest_reward(
		weapon_levels,
		passive_levels,
		demo_config.MAX_WEAPON_SLOTS,
		demo_config.MAX_PASSIVE_SLOTS
	)


func get_runtime_config() -> DemoConfig:
	return demo_config


func get_content_db() -> ContentDB:
	return content_db


func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result
