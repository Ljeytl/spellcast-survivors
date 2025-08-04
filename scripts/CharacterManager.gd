extends Node

# Character progression and unlock system
# Handles character selection, starting spells, and long-term progression

signal character_unlocked(character_id: String)
signal spell_unlocked(spell_name: String)

# Character definitions with their starting spells and unlock conditions
var characters = {
	"wizard": {
		"name": "Wizard",
		"description": "A balanced spellcaster with diverse magic",
		"starting_spells": ["bolt", "life"],
		"unlock_condition": "default",  # Always unlocked
		"icon": "🧙",
		"color": Color.BLUE
	},
	"battlemage": {
		"name": "Battle Mage", 
		"description": "Combat-focused caster with powerful attacks",
		"starting_spells": ["bolt", "ice blast"],
		"unlock_condition": "reach_level_10",
		"icon": "⚔️",
		"color": Color.RED
	},
	"healer": {
		"name": "Healer",
		"description": "Support specialist with enhanced healing",
		"starting_spells": ["life", "earth shield"], 
		"unlock_condition": "survive_15_minutes",
		"icon": "💚",
		"color": Color.GREEN
	},
	"archmage": {
		"name": "Archmage",
		"description": "Master of advanced spells",
		"starting_spells": ["lightning arc", "meteor shower"],
		"unlock_condition": "unlock_all_basic_spells",
		"icon": "🌟",
		"color": Color.GOLD
	}
}

# Spell unlock system - spells can be unlocked through various means
var spell_unlock_conditions = {
	"bolt": {"type": "default"},  # Always unlocked
	"life": {"type": "default"},  # Always unlocked  
	"ice blast": {"type": "level", "value": 5},
	"earth shield": {"type": "level", "value": 7},
	"lightning arc": {"type": "level", "value": 10},
	"meteor shower": {"type": "level", "value": 15},
	
	# Future spells can be unlocked by various conditions:
	# "fire storm": {"type": "achievement", "value": "cast_100_spells"},
	# "time stop": {"type": "survive_time", "value": 1800},  # 30 minutes
	# "chain heal": {"type": "heal_amount", "value": 10000},
}

# Save slot system
var current_save_slot: int = 1
var max_save_slots: int = 3

# Current character selection and unlocked spells (per save slot)
var current_character: String = "wizard"
var unlocked_characters: Array = ["wizard"]
var unlocked_spells: Array = ["mana_bolt", "bolt", "life"]  # Always start with these

# Persistent progression data (per save slot)
var persistent_xp: int = 0
var total_games_played: int = 0
var best_survival_time: float = 0.0
var total_enemies_killed: int = 0
var total_spells_cast: int = 0
var achievements: Array = []

# Progression rewards
var progression_rewards = {
	100: {"type": "reroll", "amount": 1, "description": "+1 Reroll per level up"},
	250: {"type": "ban", "amount": 1, "description": "+1 Ban per level up"},
	500: {"type": "character", "value": "battlemage", "description": "Unlock Battle Mage"},
	750: {"type": "lock", "amount": 1, "description": "+1 Lock per level up"},
	1000: {"type": "character", "value": "healer", "description": "Unlock Healer"},
	1500: {"type": "revive", "amount": 1, "description": "Gain 1 Revive token"},
	2000: {"type": "character", "value": "archmage", "description": "Unlock Archmage"},
}

func _ready():
	load_progression_data()
	
	# Ensure basic spells are always unlocked
	for spell in ["mana_bolt", "bolt", "life"]:
		if spell not in unlocked_spells:
			unlocked_spells.append(spell)

# Save/Load system with multiple save slots
func save_progression_data(slot: int = current_save_slot):
	var save_data = {
		"current_character": current_character,
		"unlocked_characters": unlocked_characters,
		"unlocked_spells": unlocked_spells,
		"persistent_xp": persistent_xp,
		"total_games_played": total_games_played,
		"best_survival_time": best_survival_time,
		"total_enemies_killed": total_enemies_killed,
		"total_spells_cast": total_spells_cast,
		"achievements": achievements
	}
	
	var save_file_name = "user://spellcast_save_slot_" + str(slot) + ".save"
	var save_file = FileAccess.open(save_file_name, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Save slot ", slot, " progression data saved")
	else:
		print("Error: Could not save progression data to slot ", slot)

func load_progression_data(slot: int = current_save_slot):
	var save_file_name = "user://spellcast_save_slot_" + str(slot) + ".save"
	var save_file = FileAccess.open(save_file_name, FileAccess.READ)
	if save_file:
		var json_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var save_data = json.data
			current_character = save_data.get("current_character", "wizard")
			unlocked_characters = save_data.get("unlocked_characters", ["wizard"])
			unlocked_spells = save_data.get("unlocked_spells", ["mana_bolt", "bolt", "life"])
			persistent_xp = save_data.get("persistent_xp", 0)
			total_games_played = save_data.get("total_games_played", 0)
			best_survival_time = save_data.get("best_survival_time", 0.0)
			total_enemies_killed = save_data.get("total_enemies_killed", 0)
			total_spells_cast = save_data.get("total_spells_cast", 0)
			achievements = save_data.get("achievements", [])
			print("Save slot ", slot, " progression data loaded")
		else:
			print("Error parsing progression data from slot ", slot)
	else:
		print("No progression data found for slot ", slot, ", using defaults")

# Save slot management
func switch_save_slot(slot: int):
	if slot < 1 or slot > max_save_slots:
		print("Invalid save slot: ", slot)
		return false
	
	# Save current slot before switching
	save_progression_data(current_save_slot)
	
	# Switch to new slot
	current_save_slot = slot
	
	# Load the new slot's data
	load_progression_data(slot)
	
	print("Switched to save slot ", slot)
	return true

func get_save_slot_info(slot: int) -> Dictionary:
	var save_file_name = "user://spellcast_save_slot_" + str(slot) + ".save"
	var save_file = FileAccess.open(save_file_name, FileAccess.READ)
	if save_file:
		var json_text = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var save_data = json.data
			return {
				"exists": true,
				"character": save_data.get("current_character", "wizard"),
				"persistent_xp": save_data.get("persistent_xp", 0),
				"total_games_played": save_data.get("total_games_played", 0),
				"best_survival_time": save_data.get("best_survival_time", 0.0),
				"last_modified": FileAccess.get_modified_time(save_file_name)
			}
	
	return {
		"exists": false,
		"character": "wizard",
		"persistent_xp": 0,
		"total_games_played": 0,
		"best_survival_time": 0.0,
		"last_modified": 0
	}

func delete_save_slot(slot: int) -> bool:
	if slot < 1 or slot > max_save_slots:
		print("Invalid save slot: ", slot)
		return false
	
	var save_file_name = "user://spellcast_save_slot_" + str(slot) + ".save"
	if FileAccess.file_exists(save_file_name):
		DirAccess.remove_absolute(save_file_name)
		print("Save slot ", slot, " deleted")
		return true
	else:
		print("Save slot ", slot, " does not exist")
		return false

# Character system
func get_current_character() -> Dictionary:
	return characters.get(current_character, characters["wizard"])

func get_starting_spells() -> Array:
	var character_data = get_current_character()
	return character_data.get("starting_spells", ["bolt", "life"])

func select_character(character_id: String):
	if character_id in unlocked_characters:
		current_character = character_id
		print("Selected character: ", characters[character_id]["name"])
		save_progression_data()
	else:
		print("Character not unlocked: ", character_id)

# Spell unlock system
func get_unlocked_spells() -> Array:
	return unlocked_spells.duplicate()

func is_spell_unlocked(spell_name: String) -> bool:
	return spell_name in unlocked_spells

func unlock_spell(spell_name: String, reason: String = ""):
	if spell_name not in unlocked_spells:
		unlocked_spells.append(spell_name)
		spell_unlocked.emit(spell_name)
		print("Spell unlocked: ", spell_name, " (", reason, ")")
		save_progression_data()

func check_spell_unlocks(player_level: int, game_time: float, stats: Dictionary):
	# Check level-based unlocks
	for spell_name in spell_unlock_conditions:
		if spell_name in unlocked_spells:
			continue
			
		var condition = spell_unlock_conditions[spell_name]
		var should_unlock = false
		
		match condition.type:
			"default":
				should_unlock = true
			"level":
				should_unlock = player_level >= condition.value
			"survive_time":
				should_unlock = game_time >= condition.value
			"achievement":
				should_unlock = condition.value in achievements
		
		if should_unlock:
			unlock_spell(spell_name, "met condition: " + str(condition))

# Progression system
func add_persistent_xp(amount: int):
	persistent_xp += amount
	check_progression_rewards()
	save_progression_data()

func check_progression_rewards():
	for xp_threshold in progression_rewards:
		if persistent_xp >= xp_threshold:
			var reward = progression_rewards[xp_threshold]
			if not has_claimed_reward(xp_threshold):
				claim_progression_reward(reward)
				mark_reward_claimed(xp_threshold)

func claim_progression_reward(reward: Dictionary):
	match reward.type:
		"character":
			unlock_character(reward.value)
		"spell":
			unlock_spell(reward.value, "progression reward")
		"reroll", "ban", "lock":
			# These are handled by the level up system
			print("Progression reward: ", reward.description)

func unlock_character(character_id: String):
	if character_id not in unlocked_characters:
		unlocked_characters.append(character_id)
		character_unlocked.emit(character_id)
		print("Character unlocked: ", characters[character_id]["name"])
		save_progression_data()

func has_claimed_reward(xp_threshold: int) -> bool:
	return str(xp_threshold) in achievements

func mark_reward_claimed(xp_threshold: int):
	var reward_key = str(xp_threshold)
	if reward_key not in achievements:
		achievements.append(reward_key)

# Game end processing
func process_game_end(survival_time: float, level: int, enemies_killed: int, spells_cast: int):
	total_games_played += 1
	total_enemies_killed += enemies_killed
	total_spells_cast += spells_cast
	
	if survival_time > best_survival_time:
		best_survival_time = survival_time
	
	# Award persistent XP based on performance
	var base_xp = level * 10  # 10 XP per level reached
	var survival_xp = int(survival_time / 60.0) * 5  # 5 XP per minute survived
	var combat_xp = enemies_killed * 2  # 2 XP per enemy killed
	var spell_xp = spells_cast  # 1 XP per spell cast
	
	var total_xp = base_xp + survival_xp + combat_xp + spell_xp
	add_persistent_xp(total_xp)
	
	print("Game completed! Earned ", total_xp, " persistent XP")
	print("Total persistent XP: ", persistent_xp)
	
	# Check for spell unlocks based on this game's performance
	check_spell_unlocks(level, survival_time, {
		"enemies_killed": enemies_killed,
		"spells_cast": spells_cast
	})

# Console commands for debugging
func set_persistent_xp(amount: int):
	persistent_xp = amount
	check_progression_rewards()
	save_progression_data()
	print("Persistent XP set to: ", persistent_xp)

func unlock_all_characters():
	for character_id in characters.keys():
		unlock_character(character_id)

func unlock_all_spells():
	for spell_name in spell_unlock_conditions.keys():
		unlock_spell(spell_name, "debug unlock")

func reset_progression():
	unlocked_characters = ["wizard"]
	unlocked_spells = ["mana_bolt", "bolt", "life"]
	persistent_xp = 0
	total_games_played = 0
	best_survival_time = 0.0
	total_enemies_killed = 0
	total_spells_cast = 0
	achievements = []
	current_character = "wizard"
	save_progression_data()
	print("Progression reset to defaults")