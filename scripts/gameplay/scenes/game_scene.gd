extends Node2D

const ARENA_HALF_SIZE: Vector2 = Vector2(1536.0, 864.0)

@onready var arena: Polygon2D = $Arena
@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var battle_controller: BattleController = $BattleController
@onready var hud: Control = $UI/HUD
@onready var level_up_panel: Control = $UI/LevelUpPanel
@onready var chest_panel: Control = $UI/ChestPanel

var _game_flow
var _config: DemoConfig
var _content_db: ContentDB
var _weapon_levels: Dictionary = {}
var _passive_levels: Dictionary = {}
var _level: int = 1
var _current_xp: int = 0
var _kill_count: int = 0
var _pending_reward: Dictionary = {}
var _boss_spawned: bool = false
var _pending_level_ups: int = 0


func _ready() -> void:
	randomize()
	_game_flow = get_node_or_null("/root/GameFlow")
	if _game_flow == null:
		push_error("GameFlow autoload is missing.")
		return
	_config = _game_flow.get_runtime_config()
	_content_db = _game_flow.get_content_db()
	_setup_panels()
	_setup_camera()
	_setup_character()
	_setup_battle()
	_refresh_hud()


func _process(_delta: float) -> void:
	var elapsed: float = battle_controller.get_elapsed_time()
	var remaining: float = maxf(0.0, float(_config.RUN_DURATION_SEC) - elapsed)
	hud.call("update_timer", _config.format_clock(remaining))
	_update_world_presentation()


func _setup_panels() -> void:
	level_up_panel.visible = false
	chest_panel.visible = false
	hud.call("reset")
	level_up_panel.option_selected.connect(_on_level_option_selected)
	chest_panel.chest_opened.connect(_on_chest_opened)


func _setup_camera() -> void:
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.zoom = Vector2.ONE * 0.8
	arena.z_index = -82
	arena.color = Color(0.027451, 0.039216, 0.05098, 1)
	arena.polygon = PackedVector2Array([
		Vector2(-ARENA_HALF_SIZE.x, -ARENA_HALF_SIZE.y),
		Vector2(ARENA_HALF_SIZE.x, -ARENA_HALF_SIZE.y),
		Vector2(ARENA_HALF_SIZE.x, ARENA_HALF_SIZE.y),
		Vector2(-ARENA_HALF_SIZE.x, ARENA_HALF_SIZE.y),
	])


func _setup_character() -> void:
	var character_data: Dictionary = _game_flow.get_selected_character_data()
	var starting_weapons: Array[String] = _variant_to_string_array(character_data.get("starting_weapons", []))
	var starting_passives: Array[String] = _variant_to_string_array(character_data.get("starting_passives", []))
	for weapon_id in starting_weapons:
		_weapon_levels[weapon_id] = 1
	for passive_id in starting_passives:
		_passive_levels[passive_id] = 1
	player.apply_loadout(_weapon_levels, _passive_levels)
	player.health_changed.connect(_on_player_health_changed)
	player.xp_gained.connect(_on_player_xp_gained)
	_on_player_health_changed(player.get_current_hp(), player.max_hp)


func _setup_battle() -> void:
	battle_controller.configure(_config, _content_db)
	battle_controller.enemy_defeated.connect(_on_enemy_defeated)
	battle_controller.boss_spawned.connect(_on_boss_spawned)
	battle_controller.battle_won.connect(_on_battle_won)
	battle_controller.battle_lost.connect(_on_battle_lost)
	battle_controller.start_battle()


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	hud.call("update_hp", current_hp, max_hp)


func _on_player_xp_gained(amount: int) -> void:
	_current_xp += amount
	while _current_xp >= _config.get_exp_for_level(_level):
		_level += 1
		_pending_level_ups += 1
	_try_open_pending_level_up()
	_refresh_hud()


func _try_open_pending_level_up() -> void:
	if _pending_level_ups <= 0:
		return
	if level_up_panel.visible or chest_panel.visible or get_tree().paused:
		return
	var options: Array[Dictionary] = _game_flow.get_upgrade_options(_weapon_levels, _passive_levels)
	if options.is_empty():
		_pending_level_ups = 0
		return
	get_tree().paused = true
	level_up_panel.call("show_choices", options)


func _on_level_option_selected(choice_id: String) -> void:
	_apply_reward(choice_id)
	_pending_level_ups = maxi(0, _pending_level_ups - 1)
	level_up_panel.call("hide_panel")
	get_tree().paused = false
	_try_open_pending_level_up()
	_refresh_hud()


func _on_enemy_defeated(_enemy_id: String, _xp_reward: int, _world_position: Vector2, elite: bool, _boss: bool) -> void:
	_kill_count += 1
	hud.call("update_kills", _kill_count)
	if elite:
		_pending_reward = _game_flow.get_chest_reward(_weapon_levels, _passive_levels)
		if not _pending_reward.is_empty():
			get_tree().paused = true
			chest_panel.call("set_reward", _pending_reward)
			chest_panel.visible = true


func _on_chest_opened() -> void:
	if not _pending_reward.is_empty():
		var reward_id: String = String(_pending_reward.get("id", ""))
		_apply_reward(reward_id)
		_pending_reward = {}
	chest_panel.call("hide_panel")
	get_tree().paused = false
	_try_open_pending_level_up()
	_refresh_hud()


func _on_boss_spawned() -> void:
	_boss_spawned = true
	hud.call("show_boss_warning", true, "角狼王降临")


func _on_battle_won() -> void:
	_finish_run(true, "角狼王已击败")


func _on_battle_lost(reason: String) -> void:
	var boss_result: String = "已击败" if reason == "boss_defeated" else "未击败"
	_finish_run(false, boss_result)


func _finish_run(victory: bool, boss_result: String) -> void:
	get_tree().paused = false
	_game_flow.show_result(
		{
			"survival_time": _config.format_clock(battle_controller.get_elapsed_time()),
			"kill_count": _kill_count,
			"outcome": "胜利" if victory else "失败",
			"boss_result": boss_result if _boss_spawned else "未登场",
		}
	)


func _apply_reward(entry_id: String) -> void:
	if entry_id.is_empty():
		return
	if _content_db.is_weapon(entry_id):
		var new_level: int = int(_weapon_levels.get(entry_id, 0))
		if new_level == 0:
			new_level = 2 if _game_flow.get_selected_character_id() == "apprentice_mage" else 1
		else:
			new_level += 1
		_weapon_levels[entry_id] = mini(ContentDB.MAX_ITEM_LEVEL, new_level)
	elif _content_db.is_passive(entry_id):
		_passive_levels[entry_id] = mini(ContentDB.MAX_ITEM_LEVEL, int(_passive_levels.get(entry_id, 0)) + 1)
	player.apply_loadout(_weapon_levels, _passive_levels)


func _refresh_hud() -> void:
	var xp_progress: Dictionary = _config.get_level_progress(_level, _current_xp)
	hud.call(
		"update_xp",
		_level,
		int(xp_progress.get("current", 0)),
		int(xp_progress.get("required", 1))
	)
	hud.call("update_kills", _kill_count)
	var weapon_ids: Array[String] = _dictionary_keys_as_strings(_weapon_levels)
	var passive_ids: Array[String] = _dictionary_keys_as_strings(_passive_levels)
	for index in range(_config.MAX_WEAPON_SLOTS):
		if index < weapon_ids.size():
			var weapon_id: String = weapon_ids[index]
			hud.call(
				"set_weapon_slot",
				index,
				weapon_id,
				"%s Lv%d" % [_content_db.get_display_name(weapon_id), int(_weapon_levels[weapon_id])]
			)
		else:
			hud.call("set_weapon_slot", index, "", "空")
	for index in range(_config.MAX_PASSIVE_SLOTS):
		if index < passive_ids.size():
			var passive_id: String = passive_ids[index]
			hud.call(
				"set_passive_slot",
				index,
				passive_id,
				"%s Lv%d" % [_content_db.get_display_name(passive_id), int(_passive_levels[passive_id])]
			)
		else:
			hud.call("set_passive_slot", index, "", "空")


func _variant_to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(String(entry))
	return result


func _dictionary_keys_as_strings(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry in source.keys():
		result.append(String(entry))
	return result


func _update_world_presentation() -> void:
	if player == null:
		return
	camera.global_position = player.global_position
	arena.global_position = Vector2(
		round(player.global_position.x / 128.0) * 128.0,
		round(player.global_position.y / 128.0) * 128.0
	)
