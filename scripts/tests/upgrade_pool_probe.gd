extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var content_db: ContentDB = ContentDB.new()

	var early_candidates: Array[Dictionary] = content_db.build_upgrade_candidates(
		{"fireball": 1},
		{"arcane_prism": 1},
		3,
		3
	)
	var mid_candidates: Array[Dictionary] = content_db.build_upgrade_candidates(
		{
			"fireball": 2,
			"lightning_rune": 2,
			"thorn_seed": 2,
		},
		{"arcane_prism": 1},
		3,
		3
	)
	var chest_reward: Dictionary = content_db.build_chest_reward(
		{"fireball": 1},
		{"arcane_prism": 1},
		3,
		3
	)

	if not _contains_family(early_candidates, "passive"):
		_failures.append("Early upgrade pool is missing passive entries.")
	if not _contains_any_id(early_candidates, ["lightning_rune", "thorn_seed"]):
		_failures.append("Early upgrade pool is missing new weapon entries.")
	if not _contains_family(mid_candidates, "passive"):
		_failures.append("Mid upgrade pool is missing passive entries after weapon slots are full.")
	if String(chest_reward.get("family", "")) == "":
		_failures.append("Chest reward was empty.")

	print("UPGRADE_POOL_PROBE early=%s mid=%s chest=%s weapon_count=%d passive_count=%d" % [
		str(_summarize(early_candidates)),
		str(_summarize(mid_candidates)),
		str(chest_reward),
		content_db.weapons.size(),
		content_db.passives.size(),
	])

	if _failures.is_empty():
		quit(0)
	else:
		for message in _failures:
			push_error(message)
		quit(1)


func _contains_family(candidates: Array[Dictionary], family: String) -> bool:
	for candidate in candidates:
		if String(candidate.get("family", "")) == family:
			return true
	return false


func _contains_any_id(candidates: Array[Dictionary], ids: Array[String]) -> bool:
	for candidate in candidates:
		if ids.has(String(candidate.get("id", ""))):
			return true
	return false


func _summarize(candidates: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for candidate in candidates:
		result.append("%s:%s" % [String(candidate.get("family", "")), String(candidate.get("id", ""))])
	return result
