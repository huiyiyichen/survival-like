extends Resource
class_name ContentDB

const MAX_ITEM_LEVEL := 5

var characters: Dictionary = {
	"apprentice_mage": {
		"display_name": "学徒法师",
		"description": "新手法系入口，依靠群伤快速滚雪球。",
		"starting_weapons": ["fireball"],
		"starting_passives": ["arcane_prism"],
		"trait": "新获得武器直接升到 2 级",
	},
}

var weapons: Dictionary = {
	"fireball": {
		"display_name": "火球术",
		"description": "向最近敌人发射自动追击的火球。",
		"base_damage": 16,
		"cooldown": 1.05,
		"range": 320.0,
	},
	"lightning_rune": {
		"display_name": "雷鸣符文",
		"description": "对最近敌人降下一道闪电。",
		"base_damage": 14,
		"cooldown": 1.2,
		"range": 380.0,
	},
	"thorn_seed": {
		"display_name": "荆棘种子",
		"description": "在敌群附近生成持续伤害区域。",
		"base_damage": 10,
		"cooldown": 1.5,
		"range": 280.0,
	},
}

var passives: Dictionary = {
	"power_talisman": {
		"display_name": "力量护符",
		"description": "提高所有武器伤害。",
	},
	"wind_feather": {
		"display_name": "疾风羽饰",
		"description": "提升移动速度并略微降低冷却。",
	},
	"arcane_prism": {
		"display_name": "奥术棱镜",
		"description": "提高投射数量与区域尺寸。",
	},
}

var icon_specs: Dictionary = {
	"fireball": {
		"path": "res://art/runtime/icons/fireball.png",
	},
	"lightning_rune": {
		"path": "res://art/runtime/icons/lightning_rune.png",
	},
	"thorn_seed": {
		"path": "res://art/runtime/icons/thorn_seed.png",
	},
	"power_talisman": {
		"path": "res://art/runtime/icons/power_talisman.png",
	},
	"wind_feather": {
		"path": "res://art/runtime/icons/wind_feather.png",
	},
	"arcane_prism": {
		"path": "res://art/runtime/icons/arcane_prism.png",
	},
}

var enemies: Dictionary = {
	"acid_slime": {
		"display_name": "酸液史莱姆",
		"max_hp": 28,
		"move_speed": 92.0,
		"damage": 8,
		"xp_reward": 4,
		"attack_range": 20.0,
		"attack_cooldown": 0.85,
		"color": Color(0.490196, 0.843137, 0.345098, 1),
		"radius": 14.0,
	},
	"wolf": {
		"display_name": "魔狼",
		"max_hp": 44,
		"move_speed": 132.0,
		"damage": 10,
		"xp_reward": 6,
		"attack_range": 22.0,
		"attack_cooldown": 0.7,
		"color": Color(0.756863, 0.615686, 0.352941, 1),
		"radius": 16.0,
	},
	"archer": {
		"display_name": "骷髅弓手",
		"max_hp": 36,
		"move_speed": 78.0,
		"damage": 12,
		"xp_reward": 7,
		"attack_range": 120.0,
		"attack_cooldown": 1.0,
		"preferred_distance": 100.0,
		"color": Color(0.847059, 0.847059, 0.909804, 1),
		"radius": 14.0,
	},
	"elite_hornwolf": {
		"display_name": "巨角魔狼",
		"max_hp": 180,
		"move_speed": 126.0,
		"damage": 16,
		"xp_reward": 24,
		"attack_range": 28.0,
		"attack_cooldown": 0.75,
		"is_elite": true,
		"color": Color(0.909804, 0.501961, 0.219608, 1),
		"radius": 24.0,
	},
	"corrupted_sorcerer": {
		"display_name": "腐化术士",
		"max_hp": 420,
		"move_speed": 74.0,
		"damage": 18,
		"xp_reward": 80,
		"attack_range": 160.0,
		"attack_cooldown": 0.9,
		"preferred_distance": 130.0,
		"is_boss": true,
		"color": Color(0.509804, 0.223529, 0.701961, 1),
		"radius": 34.0,
	},
}

var upgrade_order: Array[String] = [
	"fireball",
	"lightning_rune",
	"thorn_seed",
	"power_talisman",
	"wind_feather",
	"arcane_prism",
]


func get_character(character_id: String) -> Dictionary:
	return _read_entry(characters, character_id)


func get_weapon(weapon_id: String) -> Dictionary:
	return _read_entry(weapons, weapon_id)


func get_passive(passive_id: String) -> Dictionary:
	return _read_entry(passives, passive_id)


func get_enemy(enemy_id: String) -> Dictionary:
	return _read_entry(enemies, enemy_id)


func is_weapon(entry_id: String) -> bool:
	return weapons.has(entry_id)


func is_passive(entry_id: String) -> bool:
	return passives.has(entry_id)


func get_display_name(entry_id: String) -> String:
	if is_weapon(entry_id):
		return _read_string(get_weapon(entry_id), "display_name", entry_id)
	if is_passive(entry_id):
		return _read_string(get_passive(entry_id), "display_name", entry_id)
	if enemies.has(entry_id):
		return _read_string(get_enemy(entry_id), "display_name", entry_id)
	return entry_id


func get_icon_spec(entry_id: String) -> Dictionary:
	return _read_entry(icon_specs, entry_id).duplicate(true)


func build_upgrade_candidates(
	weapon_levels: Dictionary,
	passive_levels: Dictionary,
	max_weapon_slots: int,
	max_passive_slots: int
) -> Array[Dictionary]:
	var new_weapon_candidates: Array[Dictionary] = _collect_new_candidates(
		weapon_levels,
		passive_levels,
		max_weapon_slots,
		max_passive_slots,
		"weapon"
	)
	var new_passive_candidates: Array[Dictionary] = _collect_new_candidates(
		weapon_levels,
		passive_levels,
		max_weapon_slots,
		max_passive_slots,
		"passive"
	)
	var upgrade_weapon_candidates: Array[Dictionary] = _collect_upgrade_candidates(
		weapon_levels,
		passive_levels,
		"weapon"
	)
	var upgrade_passive_candidates: Array[Dictionary] = _collect_upgrade_candidates(
		weapon_levels,
		passive_levels,
		"passive"
	)
	return _merge_candidate_pools(
		[
			new_weapon_candidates,
			new_passive_candidates,
			upgrade_weapon_candidates,
			upgrade_passive_candidates,
		],
		3
	)


func build_chest_reward(
	weapon_levels: Dictionary,
	passive_levels: Dictionary,
	max_weapon_slots: int,
	max_passive_slots: int
) -> Dictionary:
	var owned_upgrade_candidates: Array[Dictionary] = _merge_candidate_pools(
		[
			_collect_upgrade_candidates(weapon_levels, passive_levels, "weapon"),
			_collect_upgrade_candidates(weapon_levels, passive_levels, "passive"),
		],
		1
	)
	if not owned_upgrade_candidates.is_empty():
		return Dictionary(owned_upgrade_candidates[0])

	var upgrades: Array[Dictionary] = build_upgrade_candidates(weapon_levels, passive_levels, max_weapon_slots, max_passive_slots)
	if upgrades.is_empty():
		return {}
	return Dictionary(upgrades[0])


func _build_new_payload(entry_id: String, family: String) -> Dictionary:
	var family_text: String = "新武器" if family == "weapon" else "新被动"
	return {
		"id": entry_id,
		"family": family,
		"display_name": get_display_name(entry_id),
		"icon_spec": get_icon_spec(entry_id),
		"label": "%s\n获得 %s" % [get_display_name(entry_id), family_text],
		"reason": "new",
	}


func _build_existing_payload(entry_id: String, family: String, level: int) -> Dictionary:
	return {
		"id": entry_id,
		"family": family,
		"display_name": get_display_name(entry_id),
		"icon_spec": get_icon_spec(entry_id),
		"label": "%s\n升级到 Lv%d" % [get_display_name(entry_id), level + 1],
		"reason": "upgrade",
	}


func _read_entry(source: Dictionary, entry_id: String) -> Dictionary:
	var result: Dictionary = {}
	var raw_value: Variant = source.get(entry_id, {})
	if raw_value is Dictionary:
		result = raw_value
	return result


func _read_string(source: Dictionary, key: String, fallback: String) -> String:
	return String(source.get(key, fallback))


func _collect_new_candidates(
	weapon_levels: Dictionary,
	passive_levels: Dictionary,
	max_weapon_slots: int,
	max_passive_slots: int,
	family: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var has_available_slot: bool = weapon_levels.size() < max_weapon_slots if family == "weapon" else passive_levels.size() < max_passive_slots
	if not has_available_slot:
		return result

	for entry_id in upgrade_order:
		if family == "weapon" and is_weapon(entry_id) and not weapon_levels.has(entry_id):
			result.append(_build_new_payload(entry_id, family))
		elif family == "passive" and is_passive(entry_id) and not passive_levels.has(entry_id):
			result.append(_build_new_payload(entry_id, family))
	return result


func _collect_upgrade_candidates(
	weapon_levels: Dictionary,
	passive_levels: Dictionary,
	family: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry_id in upgrade_order:
		if family == "weapon" and weapon_levels.has(entry_id):
			var weapon_level: int = int(weapon_levels[entry_id])
			if weapon_level < MAX_ITEM_LEVEL:
				result.append(_build_existing_payload(entry_id, family, weapon_level))
		elif family == "passive" and passive_levels.has(entry_id):
			var passive_level: int = int(passive_levels[entry_id])
			if passive_level < MAX_ITEM_LEVEL:
				result.append(_build_existing_payload(entry_id, family, passive_level))
	return result


func _merge_candidate_pools(pools: Array, limit: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	while result.size() < limit and _has_available_pool_items(pools):
		for pool in pools:
			if result.size() >= limit:
				break
			if pool is Array and not pool.is_empty():
				result.append(pool[0])
				pool.remove_at(0)
	return result


func _has_available_pool_items(pools: Array) -> bool:
	for pool in pools:
		if pool is Array and not pool.is_empty():
			return true
	return false
