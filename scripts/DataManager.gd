extends Node

# Scalable data management system for SpellCast Survivors
# Loads all game data from JSON files for easy expansion

signal data_loaded

var spells_data: Dictionary = {}
var characters_data: Dictionary = {}
var enemies_data: Dictionary = {}
var progression_data: Dictionary = {}

var is_loaded: bool = false

func _ready():
	load_all_data()

func load_all_data():
	print("DataManager: Loading game data...")
	
	# Load all data files
	spells_data = load_json_file("res://data/spells.json")
	characters_data = load_json_file("res://data/characters.json")
	enemies_data = load_json_file("res://data/enemies.json")
	progression_data = load_json_file("res://data/progression.json")
	
	# Validate data integrity
	if validate_data():
		is_loaded = true
		data_loaded.emit()
		print("DataManager: All data loaded successfully")
		print_data_summary()
	else:
		print("ERROR: DataManager failed to load data")

func load_json_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not load file: ", file_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse JSON in: ", file_path)
		return {}
	
	return json.data

func validate_data() -> bool:
	# Validate that required data structures exist
	var required_spell_fields = ["spells", "spell_categories"]
	var required_character_fields = ["characters", "character_passives"]
	var required_enemy_fields = ["enemies", "enemy_types"]
	var required_progression_fields = ["level_rewards", "persistent_rewards"]
	
	for field in required_spell_fields:
		if not field in spells_data:
			print("ERROR: Missing required field in spells.json: ", field)
			return false
	
	for field in required_character_fields:
		if not field in characters_data:
			print("ERROR: Missing required field in characters.json: ", field)
			return false
	
	for field in required_enemy_fields:
		if not field in enemies_data:
			print("ERROR: Missing required field in enemies.json: ", field)
			return false
	
	for field in required_progression_fields:
		if not field in progression_data:
			print("ERROR: Missing required field in progression.json: ", field)
			return false
	
	return true

func print_data_summary():
	print("=== DATA SUMMARY ===")
	print("Spells loaded: ", spells_data.spells.keys().size())
	print("Characters loaded: ", characters_data.characters.keys().size())
	print("Enemies loaded: ", enemies_data.enemies.keys().size())
	print("Progression rewards: ", progression_data.persistent_rewards.keys().size())
	print("Achievements: ", progression_data.achievements.keys().size())

# ========== SPELL DATA ACCESS ==========

func get_spell_data(spell_id: String) -> Dictionary:
	return spells_data.spells.get(spell_id, {})

func get_all_spells() -> Dictionary:
	return spells_data.spells

func get_spells_by_category(category: String) -> Array:
	return spells_data.spell_categories.get(category, [])

func is_spell_unlocked(spell_id: String, player_data: Dictionary) -> bool:
	var spell = get_spell_data(spell_id)
	if spell.is_empty():
		return false
	
	var unlock_condition = spell.get("unlock_condition", {"type": "default"})
	return check_unlock_condition(unlock_condition, player_data)

func get_spell_upgrade_info(spell_id: String, current_level: int) -> Dictionary:
	var spell = get_spell_data(spell_id)
	if spell.is_empty():
		return {}
	
	var upgrades = spell.get("upgrades", {})
	var info = {"level": current_level + 1}
	
	# Calculate damage increase
	if "damage_per_level" in upgrades:
		info["damage_bonus"] = upgrades.damage_per_level
	
	# Check for special level bonuses
	var level_bonuses = []
	for bonus_type in ["projectile_count_levels", "chain_count_levels", "meteor_count_levels", "radius_levels", "duration_levels"]:
		if bonus_type in upgrades:
			var levels = upgrades[bonus_type]
			if (current_level + 1) in levels:
				level_bonuses.append(bonus_type.replace("_levels", ""))
	
	info["special_bonuses"] = level_bonuses
	info["max_level"] = upgrades.get("max_level", 8)
	
	return info

# ========== CHARACTER DATA ACCESS ==========

func get_character_data(character_id: String) -> Dictionary:
	return characters_data.characters.get(character_id, {})

func get_all_characters() -> Dictionary:
	return characters_data.characters

func get_character_passive_data(passive_id: String) -> Dictionary:
	return characters_data.character_passives.get(passive_id, {})

func is_character_unlocked(character_id: String, player_data: Dictionary) -> bool:
	var character = get_character_data(character_id)
	if character.is_empty():
		return false
	
	var unlock_condition = character.get("unlock_condition", {"type": "default"})
	return check_unlock_condition(unlock_condition, player_data)

func get_character_starting_spells(character_id: String) -> Array:
	var character = get_character_data(character_id)
	return character.get("starting_spells", ["bolt", "life"])

# ========== ENEMY DATA ACCESS ==========

func get_enemy_data(enemy_id: String) -> Dictionary:
	return enemies_data.enemies.get(enemy_id, {})

func get_all_enemies() -> Dictionary:
	return enemies_data.enemies

func get_enemies_by_tier(tier: int) -> Array:
	var enemies = []
	for enemy_id in enemies_data.enemies:
		var enemy = enemies_data.enemies[enemy_id]
		if enemy.get("tier", 1) == tier:
			enemies.append(enemy_id)
	return enemies

func get_enemies_for_time(game_time: float) -> Array:
	var available_enemies = []
	
	for enemy_id in enemies_data.enemies:
		var enemy = enemies_data.enemies[enemy_id]
		var unlock_time = enemy.get("unlock_time", 0)
		if game_time >= unlock_time:
			available_enemies.append(enemy_id)
	
	return available_enemies

func get_spawn_pattern_for_time(game_time: float) -> Dictionary:
	var spawn_patterns = enemies_data.get("spawn_patterns", {})
	
	for pattern_name in spawn_patterns:
		var pattern = spawn_patterns[pattern_name]
		var time_range = pattern.get("time_range", [0, 999999])
		if game_time >= time_range[0] and game_time < time_range[1]:
			return pattern
	
	# Fallback to early game pattern
	return spawn_patterns.get("early_game", {})

func get_enemy_special_ability(ability_id: String) -> Dictionary:
	return enemies_data.special_abilities.get(ability_id, {})

# ========== PROGRESSION DATA ACCESS ==========

func get_generic_upgrades() -> Dictionary:
	return progression_data.level_rewards.generic_upgrades

func get_guaranteed_unlock_for_level(level: int) -> Array:
	var guaranteed = progression_data.level_rewards.get("guaranteed_unlocks", {})
	return guaranteed.get(str(level), [])

func get_persistent_reward(xp_threshold: int) -> Dictionary:
	return progression_data.persistent_rewards.get(str(xp_threshold), {})

func get_all_persistent_rewards() -> Dictionary:
	return progression_data.persistent_rewards

func get_achievement_data(achievement_id: String) -> Dictionary:
	return progression_data.achievements.get(achievement_id, {})

func get_all_achievements() -> Dictionary:
	return progression_data.achievements

func get_upgrade_resource_info(resource_id: String) -> Dictionary:
	return progression_data.upgrade_resources.get(resource_id, {})

func calculate_xp_needed(level: int) -> int:
	# Use formula from progression data: "100 + (level * 25) + (level^2 * 2)"
	return 100 + (level * 25) + (level * level * 2)

# ========== UNLOCK CONDITION CHECKING ==========

func check_unlock_condition(condition: Dictionary, player_data: Dictionary) -> bool:
	var type = condition.get("type", "default")
	var value = condition.get("value", 0)
	
	match type:
		"default":
			return true
		"level":
			return player_data.get("level", 1) >= value
		"persistent_xp":
			return player_data.get("persistent_xp", 0) >= value
		"survive_time":
			return player_data.get("best_survival_time", 0.0) >= value
		"spells_unlocked":
			return player_data.get("unlocked_spells", []).size() >= value
		"characters_unlocked":
			return player_data.get("unlocked_characters", []).size() >= value
		"achievement":
			return value in player_data.get("achievements", [])
		"character":
			return value in player_data.get("unlocked_characters", [])
		"enemies_killed":
			return player_data.get("total_enemies_killed", 0) >= value
		"spells_cast":
			return player_data.get("total_spells_cast", 0) >= value
		"games_completed":
			return player_data.get("total_games_played", 0) >= value
		"spell_maxed":
			# Check if player has maxed any spells
			var maxed_spells = player_data.get("maxed_spells", [])
			return maxed_spells.size() >= value
		"elements_mastered":
			var mastered_elements = player_data.get("mastered_elements", [])
			return mastered_elements.size() >= value
		"minions_summoned":
			return player_data.get("total_minions_summoned", 0) >= value
		_:
			print("WARNING: Unknown unlock condition type: ", type)
			return false

# ========== SCALING CALCULATIONS ==========

func calculate_enemy_stats(enemy_id: String, game_time: float) -> Dictionary:
	var enemy = get_enemy_data(enemy_id)
	if enemy.is_empty():
		return {}
	
	var enemy_type = enemy.get("type", "basic")
	var type_data = enemies_data.enemy_types.get(enemy_type, {})
	var scaling = type_data.get("scaling", {"health": 0.1, "damage": 0.08, "speed": 0.02})
	
	# Calculate time-based multipliers (every 30 seconds = 1 interval)
	var time_intervals = floor(game_time / 30.0)
	
	var scaled_stats = enemy.duplicate()
	scaled_stats["health"] = int(enemy.health * (1.0 + scaling.health * time_intervals))
	scaled_stats["damage"] = int(enemy.damage * (1.0 + scaling.damage * time_intervals)) 
	scaled_stats["speed"] = int(enemy.speed * (1.0 + scaling.speed * time_intervals))
	
	return scaled_stats

func calculate_xp_reward(base_xp: int, enemy_health_multiplier: float) -> int:
	# XP scales with enemy health: base_xp * sqrt(health_multiplier)
	return int(base_xp * sqrt(enemy_health_multiplier))

# ========== UTILITY FUNCTIONS ==========

func get_weighted_random_upgrade(available_upgrades: Array, weights: Dictionary) -> Dictionary:
	if available_upgrades.is_empty():
		return {}
	
	var total_weight = 0
	var weighted_upgrades = []
	
	for upgrade_key in available_upgrades:
		var weight = weights.get(upgrade_key, 50)  # Default weight
		total_weight += weight
		weighted_upgrades.append({"key": upgrade_key, "weight": weight, "cumulative": total_weight})
	
	var random_value = randi() % total_weight
	
	for weighted_upgrade in weighted_upgrades:
		if random_value < weighted_upgrade.cumulative:
			return {"key": weighted_upgrade.key}
	
	# Fallback
	return {"key": available_upgrades[0]}

func validate_save_compatibility(save_version: String) -> bool:
	# Add version checking for save compatibility when data structure changes
	# For now, always return true
	return true

# ========== DEBUG FUNCTIONS ==========

func reload_data():
	print("DataManager: Reloading all data...")
	load_all_data()

func get_data_stats() -> Dictionary:
	return {
		"spells": spells_data.spells.keys().size(),
		"characters": characters_data.characters.keys().size(), 
		"enemies": enemies_data.enemies.keys().size(),
		"achievements": progression_data.achievements.keys().size(),
		"persistent_rewards": progression_data.persistent_rewards.keys().size()
	}