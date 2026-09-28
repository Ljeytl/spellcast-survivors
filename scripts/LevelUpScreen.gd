extends Control

var selecting_upgrade: bool = false
var choice_mode: String = "select"
var offered_stats: Dictionary = {}
var offered_level: int = 1

signal upgrade_selected(upgrade_data: Dictionary)

var available_upgrades: Array = []
var upgrade_buttons: Array = []

# Reroll system resources
var rerolls_remaining: int = 5
var banishes_remaining: int = 5  
var locks_remaining: int = 5

# Upgrade state management
var locked_upgrades: Array = []  # Indices of locked upgrades
var banished_upgrades: Array = []  # Upgrade keys that are banished
var current_upgrade_pool: Array = []  # Current available upgrades before filtering

# Data-driven upgrades loaded from DataManager
var generic_upgrades = {}

# Spell upgrades loaded from DataManager
var spell_upgrades = {}

@onready var title_label: Label = $Panel/VBoxContainer/TitleContainer/TitleLabel
@onready var level_label: Label = $Panel/VBoxContainer/TitleContainer/LevelLabel
@onready var upgrade_container: VBoxContainer = $Panel/VBoxContainer/UpgradeScroll/UpgradeContainer
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var panel: Panel = $Panel

# Reroll system UI elements
@onready var reroll_button: Button = $Panel/VBoxContainer/RerollActionsContainer/RerollButton
@onready var banish_button: Button = $Panel/VBoxContainer/RerollActionsContainer/BanishButton  
@onready var lock_button: Button = $Panel/VBoxContainer/RerollActionsContainer/LockButton

# Upgrade card components
var upgrade_cards: Array = []
var progress_bars: Array = []

func _ready():
	visible = false
	modulate = Color.TRANSPARENT
	
	# Allow this screen to process even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load upgrades from DataManager
	load_upgrades_from_data()
	
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
						button.mouse_entered.connect(_on_upgrade_button_mouse_entered.bind(button, panel_container))
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
	
	# Connect reroll system buttons
	setup_reroll_system()
	

# Load upgrades from DataManager
func load_upgrades_from_data():
	if not DataManager:
		print("Warning: DataManager not available, using fallback upgrades")
		return
		
	# Load generic upgrades
	generic_upgrades = DataManager.get_generic_upgrades()
	
	# Generate spell upgrades from spell data
	var spell_data = DataManager.get_all_spells()
	for spell_id in spell_data:
		var spell = spell_data[spell_id]
		spell_upgrades[spell_id] = {
			"name": spell.name + "+",
			"description": "+15% damage, scaling bonuses per level",
			"icon": "⭐",
			"effect": {"type": "spell_upgrade", "spell": spell_id}
		}

func _input(event):
	if visible and event is InputEventKey and event.pressed and event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()

func show_level_up(player_level: int, player_stats: Dictionary = {}):
	selecting_upgrade = false
	locks_remaining += locked_upgrades.size()
	locked_upgrades.clear()
	choice_mode = "select"
	banish_button.modulate = Color.WHITE
	lock_button.modulate = Color.WHITE
	offered_stats = player_stats
	offered_level = player_level
	available_upgrades = generate_upgrade_options(player_stats, player_level)
	update_ui(player_level, player_stats)
	
	update_reroll_button_texts()
	for i in range(upgrade_cards.size()):
		update_upgrade_visual_state(i)
	show_screen()

func generate_upgrade_options(player_stats: Dictionary, player_level: int) -> Array:
	var options = []
	var all_upgrades = []
	
	# Get list of currently unlocked spells from SpellManager
	var unlocked_spells = get_unlocked_spells()
	
	# Add generic upgrades with current stat values
	for key in generic_upgrades:
		var upgrade = generic_upgrades[key].duplicate(true)
		# Update descriptions with current values
		var effect = upgrade.get("effect", {})
		if not get_tree().get_first_node_in_group("game").player.can_acquire_passive(effect.get("type", "")):
			continue
		match effect.get("type", ""):
			"spell_damage":
				var current_bonus = (player_stats.get("spell_damage_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = upgrade["description"] + " (Currently: +" + str(int(current_bonus)) + "%)"
			"cast_speed":
				var current_bonus = (player_stats.get("cast_speed_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = upgrade["description"] + " (Currently: +" + str(int(current_bonus)) + "%)"
			"movement_speed":
				var current_bonus = (player_stats.get("movement_speed_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = upgrade["description"] + " (Currently: +" + str(int(current_bonus)) + "%)"
			"max_health":
				var current_health = player_stats.get("max_health", 100)
				upgrade["description"] = upgrade["description"] + " (Currently: " + str(int(current_health)) + ")"
			"xp_range":
				var current_bonus = (player_stats.get("xp_range_multiplier", 1.0) - 1.0) * 100
				upgrade["description"] = upgrade["description"] + " (Currently: +" + str(int(current_bonus)) + "%)"
		upgrade["key"] = "passive:" + key
		all_upgrades.append(upgrade)
	
	var manager = get_tree().get_first_node_in_group("game").get_node("SpellManager")
	for spell_name in unlocked_spells:
		if spell_name == "mana_bolt":
			continue
		var slot = manager.find_spell_slot(spell_name)
		if not preload("res://scripts/SpellProgression.gd").can_upgrade(manager.get_spell_info(slot)):
			continue
		var title = "Mana Bolt" if spell_name == "mana_bolt" else manager.get_spell_info(slot).name
		all_upgrades.append({"key": "rank:" + spell_name, "name": title + "+", "icon": "⭐",
			"description": manager.get_rank_upgrade_description(spell_name),
			"effect": {"type": "spell_upgrade", "spell": spell_name}})
	all_upgrades.append_array(manager.get_learnable_spell_cards())
	all_upgrades = all_upgrades.filter(func(card): return get_upgrade_key(card) not in banished_upgrades)
	if all_upgrades.is_empty():
		all_upgrades.append({"key": "recovery", "name": "Recovery", "description": "Restore 25 health.", "icon": "✚", "effect": {"type": "recovery", "value": 25.0}})
	current_upgrade_pool = all_upgrades

	# Randomly select 3 unique upgrades
	all_upgrades.shuffle()
	var learning = all_upgrades.filter(func(card): return card.effect.type == "learn_spell")
	if not learning.is_empty():
		options.append(learning[0])
	for card in all_upgrades:
		if options.size() == 3:
			break
		if card not in options:
			options.append(card)
	
	ensure_optional_evolutions(options)
	return options

func is_evolution_card(card: Dictionary) -> bool:
	var effect = card.get("effect", {})
	return effect.get("type") == "learn_spell" and effect.get("spell") in preload("res://scripts/SynergyCatalog.gd").RECIPES

func ensure_optional_evolutions(options: Array, locked: Array = []):
	if options.is_empty() or not options.all(is_evolution_card):
		return
	var used = options.map(get_upgrade_key)
	var alternatives = current_upgrade_pool.filter(func(card): return not is_evolution_card(card) and get_upgrade_key(card) not in banished_upgrades and get_upgrade_key(card) not in used)
	if alternatives.is_empty():
		return
	var preferred: Array = []
	for card in options:
		preferred.append("rank:" + preload("res://scripts/SynergyCatalog.gd").RECIPES[card.effect.spell].ingredients[0])
	alternatives.sort_custom(func(a, b): return get_upgrade_key(a) in preferred and get_upgrade_key(b) not in preferred)
	for i in range(options.size() - 1, -1, -1):
		if i not in locked:
			options[i] = alternatives[0]
			return

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
		
	var name = upgrade.get("name", "Unknown")
	var description = upgrade.get("description", "")
	
	var effect = upgrade.get("effect", {})
	var category = "PASSIVE UPGRADE"
	if effect.get("type", "") == "learn_spell":
		category = "EVOLUTION" if effect.get("spell", "") in preload("res://scripts/SynergyCatalog.gd").RECIPES else "NEW SPELL"
	elif effect.get("type", "") == "spell_upgrade":
		category = "SPELL UPGRADE"
	var game = get_tree().get_first_node_in_group("game")
	var debug = game != null and game.interface_debug
	var title_line = category if debug else ""
	if not debug:
		description = preload("res://scripts/UpgradeCopy.gd").description(upgrade, game.spell_manager)
	button.text = ""
	var copy = button.get_node_or_null("CardText") as Label
	if copy == null:
		copy = Label.new()
		copy.name = "CardText"
		copy.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		copy.add_theme_font_size_override("font_size", 18)
		copy.add_theme_color_override("font_color", Color("eee8d8"))
		button.add_child(copy)
		copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		copy.offset_left = 12
		copy.offset_right = -12
		copy.offset_top = 10
		copy.offset_bottom = -16
		copy.minimum_size_changed.connect(_resize_card.bind(button, copy))
	var heading = button.get_node_or_null("KeyTitle") as Label
	if heading == null:
		heading = Label.new()
		heading.name = "KeyTitle"
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preload("res://scripts/AuthoredInterface.gd").apply_heading(heading, 24)
		button.add_child(heading)
		heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		heading.offset_left = 12
		heading.offset_right = -12
		heading.offset_top = 10
		heading.minimum_size_changed.connect(_resize_card.bind(button, copy))
	heading.text = name
	copy.text = (title_line + "\n" if debug else "") + description
	button.set_meta("debug_description", upgrade.get("description", ""))
	copy.set_meta("base_copy", copy.text)
	_resize_card.call_deferred(button, copy)
	
	
	button.modulate = Color.WHITE
	var accent = Color("dfbd76") if category in ["NEW SPELL", "EVOLUTION"] else Color("58728b")
	var style = preload("res://scripts/GameplayReadability.gd").panel_style(accent)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", preload("res://scripts/GameplayReadability.gd").panel_style(Color("dfbd76")))
	button.add_theme_stylebox_override("pressed", preload("res://scripts/GameplayReadability.gd").panel_style(Color("79d9e8")))
	button.set_meta("unlocked_style", style.duplicate())

func _resize_card(button: Button, copy: Label):
	var heading = button.get_node_or_null("KeyTitle") as Label
	var heading_height = heading.get_minimum_size().y + 8 if heading else 0.0
	copy.offset_top = 10 + heading_height
	button.get_parent().custom_minimum_size.y = maxf(80.0, copy.get_minimum_size().y + heading_height + 26.0)

func show_screen():
	visible = true
	modulate = Color.WHITE
	
	if fade_overlay:
		fade_overlay.modulate = Color(0, 0, 0, 0.7)
	
	if panel:
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
	configure_choice_navigation()
	focus_first_choice.call_deferred()

func configure_choice_navigation():
	var controls: Array = []
	for button in upgrade_buttons + [reroll_button, banish_button, lock_button]:
		if button and button.visible and not button.disabled:
			controls.append(button)
	for i in range(controls.size()):
		var previous = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
		var next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = previous
		controls[i].focus_next = next
		controls[i].focus_neighbor_top = previous
		controls[i].focus_neighbor_left = previous
		controls[i].focus_neighbor_bottom = next
		controls[i].focus_neighbor_right = next

func focus_first_choice():
	if not visible or selecting_upgrade or available_upgrades.is_empty():
		return
	var scroll = $Panel/VBoxContainer/UpgradeScroll
	scroll.follow_focus = false
	upgrade_buttons[0].grab_focus()
	scroll.follow_focus = true
	scroll.scroll_vertical = 0
	await get_tree().process_frame
	if visible and not selecting_upgrade and get_viewport().gui_get_focus_owner() == upgrade_buttons[0]:
		scroll.scroll_vertical = 0

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
	if selecting_upgrade:
		return
	if button_index >= 0 and button_index < available_upgrades.size():
		if choice_mode == "banish":
			banish_upgrade(button_index)
			return
		if choice_mode == "lock":
			lock_upgrade(button_index)
			return
		selecting_upgrade = true
		var selected_upgrade = available_upgrades[button_index]
		
		# Play selection sound effect
		if is_instance_valid(AudioManager):
			AudioManager.play_sound(AudioManager.SoundType.UI_LEVEL_SELECT)
		
		await hide_screen()
		upgrade_selected.emit(selected_upgrade)

# Enhanced hover effects with glow and scale
# Enhanced hover effects with glow, scale, and tooltip
func _on_upgrade_button_mouse_entered(button: Button, panel_container: Panel):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "modulate", button.modulate * 1.2, 0.15)
	
	# Add subtle glow effect by brightening the panel
	if panel_container.has_method("set_self_modulate"):
		tween.tween_property(panel_container, "self_modulate", Color(1.1, 1.1, 1.1), 0.15)
	
	# Play hover sound effect
	if is_instance_valid(AudioManager):
		AudioManager.play_sound(AudioManager.SoundType.UI_BUTTON_HOVER)
	

func _on_upgrade_button_mouse_exited(button: Button, panel_container: Panel):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "modulate", button.modulate / 1.2, 0.15)
	
	# Remove glow effect
	if panel_container.has_method("set_self_modulate"):
		tween.tween_property(panel_container, "self_modulate", Color.WHITE, 0.15)
	

# Get list of currently unlocked spells from SpellManager
func get_unlocked_spells() -> Array:
	var scene_tree = get_tree()
	if not scene_tree:
		return ["mana_bolt"]  # Fallback to just mana bolt
	
	var spell_manager = scene_tree.get_first_node_in_group("game")
	if spell_manager:
		spell_manager = spell_manager.get_node_or_null("SpellManager")
	
	if not spell_manager:
		return ["mana_bolt"]  # Fallback to just mana bolt
	
	# Get available spells from SpellManager
	if spell_manager.has_method("get_unlocked_spell_names"):
		return spell_manager.get_unlocked_spell_names()
	
	# Fallback: check each spell individually using existing method
	var unlocked = ["mana_bolt"]  # mana_bolt is always available
	var spell_names = ["bolt", "life", "ice blast", "earth shield", "lightning arc", "meteor shower"]
	
	for i in range(spell_names.size()):
		if spell_manager.has_method("is_spell_unlocked") and spell_manager.is_spell_unlocked(i + 1):
			unlocked.append(spell_names[i])
	
	return unlocked

# Helper function to get current spell level from SpellManager
func get_current_spell_level(spell_name: String) -> int:
	var game = get_tree().get_first_node_in_group("game")
	return game.get_node("SpellManager").get_spell_rank(spell_name) if game else 0

func get_detailed_spell_upgrade_description(spell_name: String, _current_level: int) -> String:
	return get_tree().get_first_node_in_group("game").get_node("SpellManager").get_rank_upgrade_description(spell_name)

func update_progress_bars(player_stats: Dictionary):
	for i in range(min(progress_bars.size(), available_upgrades.size())):
		var progress_bar = progress_bars[i]
		if progress_bar:
			progress_bar.get_parent().visible = get_tree().get_first_node_in_group("game").interface_debug
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
				progress_value = 0.0  # Default low value
		
		# Update progress bar width directly
		progress_bar.anchor_right = clamp(progress_value, 0.0, 1.0)

# Helper function to smoothly animate progress bar width
func set_progress_bar_width(progress_bar: ColorRect, width: float):
	if progress_bar and is_instance_valid(progress_bar):
		progress_bar.anchor_right = clamp(width, 0.0, 1.0)

func setup_reroll_system():
	# Connect button signals
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll_pressed)
		reroll_button.disabled = (rerolls_remaining <= 0)
	if banish_button:
		banish_button.pressed.connect(_on_banish_mode_toggled)
		banish_button.disabled = (banishes_remaining <= 0)
		banish_button.tooltip_text = "Choose Banish, then choose a card to remove from this run"
	if lock_button:
		lock_button.pressed.connect(_on_lock_mode_toggled)
		lock_button.disabled = (locks_remaining <= 0 and locked_upgrades.is_empty())
		lock_button.tooltip_text = "Choose Lock, then a card; right-click also locks or unlocks"
	
	# Setup right-click detection on upgrade cards
	setup_upgrade_right_click()
	
	# Update button texts
	update_reroll_button_texts()

func setup_upgrade_right_click():
	# Add right-click detection to each upgrade card
	for i in range(upgrade_buttons.size()):
		var button = upgrade_buttons[i]
		if button:
			# Connect gui_input for right-click detection
			button.gui_input.connect(_on_upgrade_right_click.bind(i))

func _on_upgrade_right_click(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		handle_upgrade_right_click(index)

func handle_upgrade_right_click(index: int):
	lock_upgrade(index)

func show_upgrade_context_menu(index: int):
	lock_upgrade(index)

func _on_reroll_pressed():
	if selecting_upgrade or rerolls_remaining <= 0:
		return
		
	rerolls_remaining -= 1
	
	# Regenerate upgrades, keeping locked ones
	reroll_upgrades()
	
	# Update UI
	update_reroll_button_texts()
	update_upgrade_displays()

func _on_banish_mode_toggled():
	if selecting_upgrade:
		return
	choice_mode = "select" if choice_mode == "banish" else "banish"
	banish_button.modulate = Color.WHITE
	lock_button.modulate = Color.WHITE
	update_choice_prompt()

func _on_lock_mode_toggled():
	if selecting_upgrade:
		return
	choice_mode = "select" if choice_mode == "lock" else "lock"
	lock_button.modulate = Color.WHITE
	banish_button.modulate = Color.WHITE
	update_choice_prompt()

func reroll_upgrades():
	generate_upgrade_options(offered_stats, offered_level)
	var used: Array = []
	for i in locked_upgrades:
		used.append(get_upgrade_key(available_upgrades[i]))
	var candidates = current_upgrade_pool.filter(func(card): return get_upgrade_key(card) not in used)
	candidates.shuffle()
	var has_learning = available_upgrades.any(func(card): return get_upgrade_key(card) in used and card.effect.type == "learn_spell")
	if not has_learning:
		candidates.sort_custom(func(a, b): return a.effect.type == "learn_spell" and b.effect.type != "learn_spell")
	for i in range(available_upgrades.size()):
		if i not in locked_upgrades and not candidates.is_empty():
			available_upgrades[i] = candidates.pop_front()
	ensure_optional_evolutions(available_upgrades, locked_upgrades)

func banish_upgrade(index: int):
	if selecting_upgrade or banishes_remaining <= 0 or index < 0 or index >= available_upgrades.size():
		return
	var used = available_upgrades.map(func(card): return get_upgrade_key(card))
	var candidates = current_upgrade_pool.filter(func(card): return get_upgrade_key(card) not in used and get_upgrade_key(card) not in banished_upgrades)
	if candidates.is_empty():
		return
	banishes_remaining -= 1
	banished_upgrades.append(get_upgrade_key(available_upgrades[index]))
	if index in locked_upgrades:
		locked_upgrades.erase(index)
		locks_remaining += 1
	var has_learning = false
	for i in range(available_upgrades.size()):
		if i != index and available_upgrades[i].effect.type == "learn_spell":
			has_learning = true
	var learning = candidates.filter(func(card): return card.effect.type == "learn_spell")
	available_upgrades[index] = learning.pick_random() if not has_learning and not learning.is_empty() else candidates.pick_random()
	ensure_optional_evolutions(available_upgrades, locked_upgrades)
	choice_mode = "select"
	banish_button.modulate = Color.WHITE
	update_reroll_button_texts()
	update_upgrade_displays()

func lock_upgrade(index: int):
	if selecting_upgrade or index < 0 or index >= available_upgrades.size() or (locks_remaining <= 0 and index not in locked_upgrades):
		return
		
	if index in locked_upgrades:
		# Unlock the upgrade
		locked_upgrades.erase(index)
		locks_remaining += 1  # Refund lock
	else:
		# Lock the upgrade
		locks_remaining -= 1
		locked_upgrades.append(index)
	
	# Update UI
	update_reroll_button_texts()
	update_upgrade_visual_state(index)
	
	print("Toggled lock on upgrade ", index, ". Locked upgrades: ", locked_upgrades)

func generate_single_upgrade() -> Dictionary:
	# Generate a single upgrade that isn't banished
	var attempts = 0
	var max_attempts = 50
	
	while attempts < max_attempts:
		var upgrade = generate_random_upgrade()
		var upgrade_key = get_upgrade_key(upgrade)
		
		if upgrade_key not in banished_upgrades:
			return upgrade
			
		attempts += 1
	
	# Fallback - return any upgrade if we can't find a non-banished one
	return generate_random_upgrade()

func generate_random_upgrade() -> Dictionary:
	var candidates = current_upgrade_pool.filter(func(card): return get_upgrade_key(card) not in banished_upgrades)
	return candidates.pick_random() if not candidates.is_empty() else {}

func get_upgrade_key(upgrade: Dictionary) -> String:
	# Extract a unique key for the upgrade
	if upgrade.has("key"):
		return upgrade.key
	elif upgrade.has("data") and upgrade.data.has("name"):
		return upgrade.data.name
	else:
		return ""

func update_reroll_button_texts():
	update_choice_prompt()
	for action in [reroll_button, banish_button, lock_button]:
		if action:
			action.add_theme_font_size_override("font_size", 20)
	# Update button texts with remaining counts
	if reroll_button:
		reroll_button.text = "Reroll " + str(rerolls_remaining)
		reroll_button.disabled = (rerolls_remaining <= 0)
		
	if banish_button:
		banish_button.text = "Banish " + str(banishes_remaining)
		banish_button.disabled = (banishes_remaining <= 0)
		banish_button.tooltip_text = "Choose Banish, then choose a card to remove from this run"
		
	if lock_button:
		lock_button.text = "Lock " + str(locks_remaining)
		lock_button.disabled = (locks_remaining <= 0 and locked_upgrades.is_empty())
		lock_button.tooltip_text = "Choose Lock, then a card; right-click also locks or unlocks"

func update_choice_prompt():
	var prompt = $Panel/VBoxContainer/UpgradeLabel
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match choice_mode:
		"lock":
			prompt.text = "Choose a card to lock or unlock"
			prompt.modulate = Color("dfbd76")
		"banish":
			prompt.text = "Choose a card to banish from this run"
			prompt.modulate = Color("ff8175")
		_:
			prompt.text = "Choose an upgrade"
			prompt.modulate = Color.WHITE

func update_upgrade_visual_state(index: int):
	if index >= upgrade_cards.size() or not upgrade_cards[index]:
		return
	var card = upgrade_cards[index]
	card.modulate = Color.WHITE
	var button = upgrade_buttons[index]
	var copy = button.get_node_or_null("CardText")
	if not copy:
		return
	var locked = index in locked_upgrades
	copy.text = ("LOCKED\n" if locked else "") + str(copy.get_meta("base_copy", copy.text))
	var style = button.get_meta("unlocked_style").duplicate()
	if locked:
		style.border_color = Color("dfbd76")
		style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)

func update_upgrade_displays():
	configure_choice_navigation()
	update_ui(offered_level, offered_stats)
	for i in range(upgrade_cards.size()):
		update_upgrade_visual_state(i)

func reset_reroll_resources():
	rerolls_remaining = 5
	banishes_remaining = 5
	locks_remaining = 5
	locked_upgrades.clear()
	# Don't clear banished_upgrades - they stay banished for the whole run
	update_reroll_button_texts()
