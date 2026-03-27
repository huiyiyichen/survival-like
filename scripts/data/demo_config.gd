extends Resource
class_name DemoConfig

const RUN_DURATION_SEC := 300
const BOSS_SPAWN_SEC := 240
const ELITE_SPAWN_SEC := 150
const MAX_WEAPON_SLOTS := 3
const MAX_PASSIVE_SLOTS := 3

var experience_curve: Array[int] = [0, 12, 30, 54, 84, 120, 162, 210, 264, 324]

var wave_schedule: Array[Dictionary] = [
	{"start": 0, "end": 60, "enemy_ids": ["acid_slime"], "interval": 0.72, "count": 2, "max_active": 18},
	{"start": 60, "end": 120, "enemy_ids": ["acid_slime", "wolf"], "interval": 0.58, "count": 3, "max_active": 26},
	{"start": 120, "end": 180, "enemy_ids": ["acid_slime", "wolf", "archer"], "interval": 0.46, "count": 4, "max_active": 34},
	{"start": 180, "end": 240, "enemy_ids": ["wolf", "archer"], "interval": 0.38, "count": 5, "max_active": 42},
	{"start": 240, "end": 300, "enemy_ids": ["archer", "wolf"], "interval": 0.48, "count": 4, "max_active": 38},
]


func get_wave_at(time_sec: float) -> Dictionary:
	for wave in wave_schedule:
		if time_sec >= wave["start"] and time_sec < wave["end"]:
			return wave
	if wave_schedule.is_empty():
		return {}
	var last_wave: Dictionary = wave_schedule[wave_schedule.size() - 1]
	return last_wave


func get_exp_for_level(level: int) -> int:
	var safe_level: int = maxi(level, 0)
	if safe_level < experience_curve.size():
		return experience_curve[safe_level]
	return _calculate_total_exp(safe_level)


func get_level_floor_xp(level: int) -> int:
	var safe_level: int = maxi(level, 1)
	if safe_level <= 1:
		return 0
	return get_exp_for_level(safe_level - 1)


func get_level_progress(level: int, total_xp: int) -> Dictionary:
	var safe_level: int = maxi(level, 1)
	var floor_xp: int = get_level_floor_xp(safe_level)
	var next_level_xp: int = get_exp_for_level(safe_level)
	return {
		"current": maxi(0, total_xp - floor_xp),
		"required": maxi(1, next_level_xp - floor_xp),
		"floor_total": floor_xp,
		"next_total": next_level_xp,
	}


func format_clock(total_seconds: float) -> String:
	var clamped: int = maxi(0, int(round(total_seconds)))
	var minutes: int = floori(float(clamped) / 60.0)
	var seconds: int = clamped % 60
	return "%02d:%02d" % [minutes, seconds]


func _calculate_total_exp(level: int) -> int:
	var safe_level: int = maxi(level, 0)
	return 3 * safe_level * (safe_level + 3)
