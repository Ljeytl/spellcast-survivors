extends Control

signal upgrade_selected(upgrade_data: Dictionary)

var available_upgrades: Array = []
var upgrade_buttons: Array = []

# Generic upgrades - balanced values per design document
var generic_upgrades = {
	"spell_damage": {
		"name": "Spell Power",
		"description": "+10% Spell Damage",
		"icon": "⚡",
		"effect": {"type": "spell_damage", "value": 0.10}
	},
	"cast_speed": {
		"name": "Quick Cast",
		"description": "+10% Cast Speed",
		"icon": "⏱️",
		"effect": {"type": "cast_speed", "value": 0.10}
	},
	"movement_speed": {
		"name": "Swift Step", 
		"description": "+8% Movement Speed",
		"icon": "💨",
		"effect": {"type": "movement_speed", "value": 0.08}
	},
	"max_health": {
		"name": "Vitality",
		"description": "+15 Max Health",
		"icon": "❤️",
		"effect": {"type": "max_health", "value": 15}
	},
	"xp_range": {
		"name": "Experience Magnet",
		"description": "+20% XP Collection Range",
		"icon": "🧲",
		"effect": {"type": "xp_range", "value": 0.20}
	}
}

# Spell-specific upgrades with detailed descriptions
var spell_upgrades = {
	"mana_bolt": {
		"name": "Mana Bolt+",
		"description": "+15% damage, faster firing",
		"icon": "🔵",
		"effect": {"type": "spell_upgrade", "spell": "mana_bolt"}
	},
	"bolt": {
		"name": "Bolt+", 
		"description": "+15% damage, +1 projectile every 3 levels",
		"icon": "⚡",
		"effect": {"type": "spell_upgrade", "spell": "bolt"}
	},
	"life": {
		"name": "Life+",
		"description": "+15% healing, longer duration",
		"icon": "💚",
		"effect": {"type": "spell_upgrade", "spell": "life"}
	},
	"ice blast": {
		"name": "Ice Blast+",
		"description": "+15% damage, +20% area every 2 levels",
		"icon": "❄️", 
		"effect": {"type": "spell_upgrade", "spell": "ice blast"}
	},
	"earth shield": {
		"name": "Earth Shield+",
		"description": "+15% overheal amount, longer duration",
		"icon": "🛡️",
		"effect": {"type": "spell_upgrade", "spell": "earth shield"}
	},
	"lightning arc": {
		"name": "Lightning Arc+",
		"description": "+15% damage, +1 target every 2 levels",
		"icon": "⚡",
		"effect": {"type": "spell_upgrade", "spell": "lightning arc"}
	},
	"meteor shower": {
		"name": "Meteor Shower+",
		"description": "+15% damage, +1 meteor every 2 levels",
		"icon": "☄️",
		"effect": {"type": "spell_upgrade", "spell": "meteor shower"}
	}
}

@onready var title_label: Label = $Panel/VBoxContainer/TitleContainer/TitleLabel
@onready var level_label: Label = $Panel/VBoxContainer/TitleContainer/LevelLabel
@onready var upgrade_container: VBoxContainer = $Panel/VBoxContainer/UpgradeContainer
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var panel: Panel = $Panel

# Upgrade card components
var upgrade_cards: Array = []
var progress_bars: Array = []

# Tooltip system
@onready var tooltip_panel: Panel = null
@onready var tooltip_label: RichTextLabel = null
var tooltip_tween: Tween

func _ready():
	visible = false
	modulate = Color.TRANSPARENT
	
	# Allow this screen to process even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Get references to upgrade cards and progress bars
	upgrade_buttons = []
	upgrade_cards = []
	progress_bars = []
	
	if upgrade_container:
		for i in range(3):
			if i < upgrade_container.get_child_count():
				var panel_container = upgrade_container.get_child(i)
				if panel_container:
					# Get the actual button (UpgradeCard)
					var button = panel_container.get_child(0)  # UpgradeCard1/2/3
					if button:
						upgrade_buttons.append(button)
						upgrade_cards.append(panel_container)
						button.pressed.connect(_on_upgrade_button_pressed.bind(i))
						button.mouse_entered.connect(_on_upgrade_button_mouse_entered.bind(button, panel_container, i))
						button.mouse_exited.connect(_on_upgrade_button_mouse_exited.bind(button, panel_container))
						
						# Get progress bar for this upgrade
						var progress_bg = panel_container.get_node_or_null("ProgressBarBG")
						if progress_bg:
							var progress_bar = progress_bg.get_node_or_null("ProgressBar")
							if progress_bar:
								progress_bars.append(progress_bar)
							else:
								print("Warning: ProgressBar not found in panel ", i)
								progress_bars.append(null)
						else:
							print("Warning: ProgressBarBG not found in panel ", i)
							progress_bars.append(null)
					else:
						print("ERROR: Upgrade card ", i, " is null")
				else:
					print("ERROR: Upgrade panel ", i, " is null")
			else:
				print("ERROR: Not enough children in upgrade_container for panel ", i)
	else:
		print("ERROR: upgrade_container is null in _ready()")
	
	# Setup tooltip components
	tooltip_panel = panel.get_node_or_null("TooltipPanel")
	tooltip_label = tooltip_panel.get_node_or_null("TooltipLabel") if tooltip_panel else null

func show_level_up(player_level: int, player_stats: Dictionary = {}):
	available_upgrades = generate_upgrade_options(player_stats, player_level)
	update_ui(player_level, player_stats)
	
	# Play level up sound effect
	if is_instance_valid(AudioManager):
		AudioManager.play_sound(AudioManager.SoundType.LEVEL_UP)
	
	show_screen()

func generate_upgrade_options(player_stats: Dictionary, player_level: int) -> Array:
	var options = []
	var all_upgrades = []
	
	# Spell unlock levels (matching SpellManager exactly)
	var spell_unlock_levels = {
		"bolt": 1,
		"life": 3,
		"ice blast": 5,
		"earth shield": 7,
		"lightning arc": 10,
		"meteor shower": 15
	}
	
	# Add generic upgrades with current stat values
	for key in generic_upgrades:
		var upgrade = generic_upgrades[key].duplicate(true)
		# Update descriptions with current values
		match key:
			"spell_damage":
				var current_bonus = (player_stats.get("spell_damage_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = "+10% Spell Damage (Currently: +" + str(int(current_bonus)) + "%)"
			"cast_speed":
				var current_bonus = (player_stats.get("cast_speed_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = "+10% Cast Speed (Currently: +" + str(int(current_bonus)) + "%)"
			"movement_speed":
				var current_bonus = (player_stats.get("movement_speed_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = "+8% Movement Speed (Currently: +" + str(int(current_bonus)) + "%)"
			"max_health":
				var current_health = player_stats.get("max_health", 100)
				upgrade["description"] = "+15 Max Health (Currently: " + str(int(current_health)) + ")"
			"xp_range":
				var current_bonus = (player_stats.get("xp_range_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = "+20% XP Range (Currently: +" + str(int(current_bonus)) + "%)"
		all_upgrades.append(upgrade)
	
	# Add spell upgrades only for unlocked spells with dynamic descriptions
	for key in spell_upgrades:
		var spell_name = spell_upgrades[key].get("effect", {}).get("spell", key)
		var required_level = spell_unlock_levels.get(spell_name, 1)
		
		# Always allow mana_bolt (auto-attack) regardless of level
		if spell_name == "mana_bolt" or player_level >= required_level:
			var upgrade = spell_upgrades[key].duplicate(true)
			# Get current spell level from SpellManager to show specific upgrade benefits
			var current_spell_level = get_current_spell_level(spell_name)
			upgrade["description"] = get_detailed_spell_upgrade_description(spell_name, current_spell_level)
			all_upgrades.append(upgrade)
	
	# Randomly select 3 unique upgrades
	all_upgrades.shuffle()
	for i in range(min(3, all_upgrades.size())):
		options.append(all_upgrades[i])
	
	return options

func update_ui(player_level: int, player_stats: Dictionary = {}):
	# Update UI labels with null checks
	if title_label:
		title_label.text = "LEVEL UP!"
	else:
		print("ERROR: title_label is null in update_ui()")
		
	if level_label:
		level_label.text = "Level " + str(player_level)
	else:
		print("ERROR: level_label is null in update_ui()")
	
	# Update upgrade buttons with available options
	for i in range(upgrade_buttons.size()):
		var button = upgrade_buttons[i]
		if i < available_upgrades.size():
			var upgrade = available_upgrades[i]
			update_upgrade_button(button, upgrade)
			button.visible = true
			# Show the parent panel too
			if i < upgrade_cards.size() and upgrade_cards[i]:
				upgrade_cards[i].visible = true
		else:
			button.visible = false
			# Hide the parent panel too
			if i < upgrade_cards.size() and upgrade_cards[i]:
				upgrade_cards[i].visible = false
	
	# Update progress bars
	update_progress_bars(player_stats)

func update_upgrade_button(button: Button, upgrade: Dictionary):
	# Create rich text for the button with null check
	if not button:
		print("ERROR: Button is null in update_upgrade_button()")
		return
		
	var icon = upgrade.get("icon", "")
	var name = upgrade.get("name", "Unknown")
	var description = upgrade.get("description", "")
	
	# Format the button text with better spacing
	var title_line = icon + " " + name
	button.text = title_line + "\n" + description
	
	# Add subtle color coding based on upgrade type
	var effect_type = upgrade.get("effect", {}).get("type", "")
	match effect_type:
		"spell_damage":
			button.modulate = Color(1.0, 0.9, 0.9)  # Slight red tint
		"cast_speed":
			button.modulate = Color(0.9, 0.9, 1.0)  # Slight blue tint
		"movement_speed":
			button.modulate = Color(0.9, 1.0, 0.9)  # Slight green tint
		"max_health":
			button.modulate = Color(1.0, 0.95, 0.9) # Slight orange tint
		"xp_range":
			button.modulate = Color(1.0, 1.0, 0.9)  # Slight yellow tint
		"spell_upgrade":
			button.modulate = Color(0.95, 0.9, 1.0) # Slight purple tint
		_:
			button.modulate = Color.WHITE

func show_screen():
	visible = true
	modulate = Color.WHITE
	
	if fade_overlay:
		fade_overlay.modulate = Color(0, 0, 0, 0.7)
	
	if panel:
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE

func hide_screen():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out with null checks
	if fade_overlay:
		tween.tween_property(fade_overlay, "modulate", Color.TRANSPARENT, 0.2)
		
	if panel:
		tween.tween_property(panel, "modulate", Color.TRANSPARENT, 0.2)
		tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	await tween.finished
	visible = false

func _on_upgrade_button_pressed(button_index: int):
	if button_index < available_upgrades.size():
		var selected_upgrade = available_upgrades[button_index]
		
		# Play selection sound effect
		if is_instance_valid(AudioManager):
			AudioManager.play_sound(AudioManager.SoundType.UI_LEVEL_SELECT)
		
		upgrade_selected.emit(selected_upgrade)
		hide_screen()

# Enhanced hover effects with glow and scale
# Enhanced hover effects with glow, scale, and tooltip
func _on_upgrade_button_mouse_entered(button: Button, panel_container: Panel, upgrade_index: int):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel_container, "scale", Vector2(1.03, 1.03), 0.15)
	tween.tween_property(button, "modulate", button.modulate * 1.2, 0.15)
	
	# Add subtle glow effect by brightening the panel
	if panel_container.has_method("set_self_modulate"):
		tween.tween_property(panel_container, "self_modulate", Color(1.1, 1.1, 1.1), 0.15)
	
	# Play hover sound effect
	if is_instance_valid(AudioManager):
		AudioManager.play_sound(AudioManager.SoundType.UI_BUTTON_HOVER)
	
	# Show detailed tooltip
	show_tooltip(upgrade_index)

func _on_upgrade_button_mouse_exited(button: Button, panel_container: Panel):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.15)
	tween.tween_property(button, "modulate", button.modulate / 1.2, 0.15)
	
	# Remove glow effect
	if panel_container.has_method("set_self_modulate"):
		tween.tween_property(panel_container, "self_modulate", Color.WHITE, 0.15)
	
	# Hide tooltip
	hide_tooltip()

# Helper function to get current spell level from SpellManager
func get_current_spell_level(spell_name: String) -> int:
	var scene_tree = get_tree()
	if not scene_tree:
		return 1
	
	var spell_manager = scene_tree.get_first_node_in_group("game")
	if spell_manager:
		spell_manager = spell_manager.get_node_or_null("SpellManager")
	
	if not spell_manager:
		return 1
	
	# Handle mana bolt separately
	if spell_name == "mana_bolt":
		if "mana_bolt_level" in spell_manager:
			return spell_manager.mana_bolt_level
		else:
			return 1
	
	# Check spell dictionary
	if "spells" in spell_manager:
		var spells = spell_manager.spells
		for slot in spells:
			var spell_info = spells[slot]
			if spell_info.get("name") == spell_name:
				if "level" in spell_info:
					return spell_info.level
				else:
					return 1
	
	return 1

# Generate detailed upgrade descriptions showing current level and next improvements
func get_detailed_spell_upgrade_description(spell_name: String, current_level: int) -> String:
	var next_level = current_level + 1
	var base_description = ""
	
	match spell_name:
		"mana_bolt":
			base_description = "Level %d→%d: +15%% damage" % [current_level, next_level]
			if next_level % 3 == 1 and next_level > 1:
				base_description += ", +1 missile"
		"bolt":
			base_description = "Level %d→%d: +15%% damage" % [current_level, next_level]
			if next_level % 3 == 1 and next_level > 1:
				base_description += ", +1 projectile"
		"life":
			base_description = "Level %d→%d: +15%% healing/sec" % [current_level, next_level]
			if current_level < 3:
				base_description += ", longer duration"
		"ice blast":
			base_description = "Level %d→%d: +15%% damage" % [current_level, next_level]
			if next_level % 2 == 1 and next_level > 1:
				base_description += ", +20% area"
		"earth shield":
			base_description = "Level %d→%d: +15%% overheal amount" % [current_level, next_level]
			if current_level < 4:
				base_description += ", longer duration"
		"lightning arc":
			base_description = "Level %d→%d: +15%% damage" % [current_level, next_level]
			if next_level % 2 == 1 and next_level > 1:
				base_description += ", +1 chain target"
		"meteor shower":
			base_description = "Level %d→%d: +15%% damage" % [current_level, next_level]
			if next_level % 2 == 1 and next_level > 1:
				base_description += ", +1 meteor"
		_:
			base_description = "Level %d→%d: +15%% effectiveness" % [current_level, next_level]
	
	return base_description

# Update progress bars to show spell/stat progression
func update_progress_bars(player_stats: Dictionary):
	for i in range(min(progress_bars.size(), available_upgrades.size())):
		var progress_bar = progress_bars[i]
		if not progress_bar or not is_instance_valid(progress_bar):
			continue
			
		var upgrade = available_upgrades[i]
		var effect = upgrade.get("effect", {})
		var progress_value = 0.0
		
		# Calculate progress based on upgrade type
		match effect.get("type", ""):
			"spell_damage":
				var current_bonus = (player_stats.get("spell_damage_multiplier", 1.0) - 1.0)
				progress_value = min(current_bonus * 2.0, 1.0)  # Cap at 50% bonus = full bar
			"cast_speed":
				var current_bonus = (player_stats.get("cast_speed_multiplier", 1.0) - 1.0)
				progress_value = min(current_bonus * 2.0, 1.0)  # Cap at 50% bonus = full bar
			"movement_speed":
				var current_bonus = (player_stats.get("movement_speed_multiplier", 1.0) - 1.0)
				progress_value = min(current_bonus * 3.0, 1.0)  # Cap at 33% bonus = full bar
			"max_health":
				var current_health = player_stats.get("max_health", 100)
				progress_value = min((current_health - 100) / 200.0, 1.0)  # Cap at 300 HP = full bar
			"xp_range":
				var current_bonus = (player_stats.get("xp_range_multiplier", 1.0) - 1.0)
				progress_value = min(current_bonus * 2.5, 1.0)  # Cap at 40% bonus = full bar
			"spell_upgrade":
				var spell_name = effect.get("spell", "")
				var current_level = get_current_spell_level(spell_name)
				progress_value = min((current_level - 1) / 7.0, 1.0)  # Level 8 = full bar
			_:
				progress_value = 0.3  # Default low value
		
		# Update progress bar width directly
		progress_bar.anchor_right = clamp(progress_value, 0.0, 1.0)

# Helper function to smoothly animate progress bar width
func set_progress_bar_width(progress_bar: ColorRect, width: float):
	if progress_bar and is_instance_valid(progress_bar):
		progress_bar.anchor_right = clamp(width, 0.0, 1.0)

# Show detailed tooltip with rich information
func show_tooltip(upgrade_index: int):
	if not tooltip_panel or not tooltip_label or upgrade_index >= available_upgrades.size():
		return
	
	var upgrade = available_upgrades[upgrade_index]
	var effect = upgrade.get("effect", {})
	var tooltip_text = generate_tooltip_text(upgrade, effect)
	
	tooltip_label.text = tooltip_text
	tooltip_panel.visible = true
	
	# Animate tooltip appearance
	if tooltip_tween:
		tooltip_tween.kill()
	tooltip_tween = create_tween()
	tooltip_panel.modulate = Color.TRANSPARENT
	tooltip_tween.tween_property(tooltip_panel, "modulate", Color.WHITE, 0.2)

# Hide tooltip with animation
func hide_tooltip():
	if not tooltip_panel:
		return
	
	if tooltip_tween:
		tooltip_tween.kill()
	tooltip_tween = create_tween()
	tooltip_tween.tween_property(tooltip_panel, "modulate", Color.TRANSPARENT, 0.15)
	tooltip_tween.tween_callback(func(): tooltip_panel.visible = false)

# Generate rich text tooltip content
func generate_tooltip_text(upgrade: Dictionary, effect: Dictionary) -> String:
	var text = "[center][b]" + upgrade.get("name", "Unknown") + "[/b][/center]\n\n"
	
	match effect.get("type", ""):
		"spell_damage":
			text += "[color=red]Spell Damage Boost[/color]\n"
			text += "• Increases all spell damage by 10%\n"
			text += "• Stacks multiplicatively with other bonuses\n"
			text += "• Affects: Mana Bolt, all castable spells\n\n"
			text += "[color=gray]Formula: damage × (1 + bonus)[/color]"
			
		"cast_speed":
			text += "[color=blue]Casting Speed Boost[/color]\n"
			text += "• Reduces spell casting time by 10%\n"
			text += "• Faster typing = more DPS\n"
			text += "• Affects: All spell casting\n\n"
			text += "[color=gray]Makes time dilation feel smoother[/color]"
			
		"movement_speed":
			text += "[color=green]Movement Speed Boost[/color]\n"
			text += "• Increases movement speed by 8%\n"
			text += "• Better positioning and kiting\n"
			text += "• Essential for survival\n\n"
			text += "[color=gray]Faster movement = safer gameplay[/color]"
			
		"max_health":
			text += "[color=orange]Health Increase[/color]\n"
			text += "• Permanently adds 15 max health\n"
			text += "• Instantly heals to new maximum\n"
			text += "• More survivability vs tough enemies\n\n"
			text += "[color=gray]Health scaling is crucial late game[/color]"
			
		"xp_range":
			text += "[color=yellow]XP Collection Range[/color]\n"
			text += "• Increases XP pickup range by 20%\n"
			text += "• Auto-collect XP from further away\n"
			text += "• Faster leveling = more upgrades\n\n"
			text += "[color=gray]Quality of life improvement[/color]"
			
		"spell_upgrade":
			var spell_name = effect.get("spell", "")
			var current_level = get_current_spell_level(spell_name)
			var next_level = current_level + 1
			
			text += "[color=purple]Spell Enhancement[/color]\n"
			text += "• Upgrade " + spell_name + " to level " + str(next_level) + "\n"
			text += "• +15% base damage\n"
			
			# Add spell-specific bonus info
			match spell_name:
				"mana_bolt":
					if next_level % 3 == 1 and next_level > 1:
						text += "• [b]+1 additional missile![/b]\n"
				"bolt":
					if next_level % 3 == 1 and next_level > 1:
						text += "• [b]+1 projectile spread![/b]\n"
				"ice blast":
					if next_level % 2 == 1 and next_level > 1:
						text += "• [b]+20% area of effect![/b]\n"
				"lightning arc":
					if next_level % 2 == 1 and next_level > 1:
						text += "• [b]+1 chain target![/b]\n"
				"meteor shower":
					if next_level % 2 == 1 and next_level > 1:
						text += "• [b]+1 meteor strike![/b]\n"
			
			text += "\n[color=gray]Max level: 8[/color]"
			
		_:
			text += "[color=white]Generic Enhancement[/color]\n"
			text += "• Improves overall effectiveness\n"
			text += "• Stacks with other upgrades"
	
	return text
