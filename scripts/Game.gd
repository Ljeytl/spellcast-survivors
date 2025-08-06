# Main game controller that manages game state, UI, and coordinates between all systems
# This is the central hub for SpellCast Survivors game logic
extends Node2D

# Enumeration for different game states to control game flow
enum GameState {
	PLAYING,     # Active gameplay with movement, combat, and spell casting
	LEVEL_UP,    # Player is selecting upgrades, game is paused
	GAME_OVER,   # Player has died, showing game over screen
	PAUSED       # Game is temporarily suspended via ESC key
}

# UI animation and visual effect constants
const HEALTH_BAR_ANIMATION_DURATION = 0.3  # How long health bar changes take to animate
const XP_BAR_ANIMATION_DURATION = 0.2      # How long XP bar changes take to animate
const HEALTH_HIGH_THRESHOLD = 60.0         # Above this %, health bar is green
const HEALTH_MEDIUM_THRESHOLD = 30.0       # Above this %, health bar is yellow (red below)
const XP_GLOW_THRESHOLD = 80.0             # Above this %, XP bar starts glowing
const GLOW_ANIMATION_DURATION = 0.5        # How long the XP bar glow animation takes
const CHEST_SPAWN_INTERVAL = 20.0          # How often chests spawn (seconds)
const MAX_CHESTS = 2                       # Maximum number of chests on screen
const ICON_SIZE = Vector2(32, 32)          # Standard size for spell slot icons

# Current game state - starts in PLAYING mode
var current_state: GameState = GameState.PLAYING
# Total time spent in this game session (used for survival scoring)
var game_time: float = 0.0

# Developer console system
var console_scene = preload("res://scenes/Console.tscn")
var console_instance: Control = null

# Preloaded script for damage number system
var damage_manager_scene = preload("res://scripts/DamageManager.gd")

# Core game nodes - set up automatically when scene loads
@onready var player: CharacterBody2D = $Player                                    # The player character
@onready var camera: Camera2D = $Camera2D                                        # Main game camera
@onready var hud: Control = $UI/HUD                                              # Heads-up display container
@onready var health_bar: ProgressBar = $UI/HUD/StatsPanel/HealthBar             # Player health display
@onready var health_label: Label = null                                         # Health text display (100/120)
@onready var xp_bar: ProgressBar = $UI/HUD/StatsPanel/XPBar                     # Experience point display
@onready var xp_label: Label = null                                             # XP text display (50/175)
@onready var spell_slots: Array = []                                             # Array of spell slot UI containers
@onready var typing_label: Label = null                                          # Label showing typed spell text
@onready var pause_overlay: ColorRect = $UI/PauseOverlay                        # Dark overlay when paused
@onready var spell_manager: Node = $SpellManager                                 # Handles spell casting logic
@onready var chest_manager: ChestManager = null                                  # Manages treasure chest spawning

# Timer and difficulty display elements
@onready var timer_label: Label = $UI/HUD/TimerPanel/TimerLabel                  # Shows survival time
@onready var difficulty_label: Label = $UI/HUD/TimerPanel/DifficultyLabel        # Shows current difficulty multiplier
@onready var timer_panel: Panel = $UI/HUD/TimerPanel                             # Timer panel for hover detection
@onready var difficulty_tooltip: Panel = $UI/HUD/DifficultyTooltip               # Tooltip showing detailed difficulty info
@onready var difficulty_tooltip_label: RichTextLabel = null                      # Rich text label inside tooltip

# Visual effect systems - created dynamically in _ready()
var camera_shake: CameraShake           # Handles screen shake effects for impacts
var particle_manager: ParticleManager   # Creates visual effects for spells and combat
var time_dilation_effect: TimeDilationEffect  # Slows time during spell typing
var object_pool: ObjectPool             # Reuses objects to improve performance

# UI screens - loaded and instantiated dynamically
var level_up_screen_scene = preload("res://scenes/LevelUpScreen.tscn")
var level_up_screen: Control

var game_over_screen_scene = preload("res://scenes/GameOverScreen.tscn")
var game_over_screen: Control

# Game session statistics for scoring
var enemies_killed: int = 0  # Total enemies defeated this session
var spells_cast: int = 0     # Total spells successfully cast this session

# Called when the scene is first loaded and ready to run
func _ready():
	
	# Add to game group for other nodes to find this main game controller
	add_to_group("game")
	
	# Start the background music for gameplay
	if is_instance_valid(AudioManager):
		AudioManager.play_music(AudioManager.SoundType.MUSIC_GAMEPLAY, true, 1.0)
	
	# Initialize all game systems in the correct order
	setup_all_systems()
	# Configure the spell slot UI with icons and labels
	setup_spell_slots()
	# Initialize developer console
	setup_console()
	

# Handle input events
func _input(event):
	if event is InputEventKey and event.pressed:
		# General input handling only - no more hotkey cheats!
		# All cheats are now hidden in the console (press ~ to access)
		match event.keycode:
			KEY_ESCAPE:
				if current_state == GameState.PLAYING:
					toggle_pause()

# Master setup function that initializes all game systems
# Order matters here - some systems depend on others being ready first
func setup_all_systems():
	setup_ui()              # Initialize health/XP bars and typing display
	setup_player()          # Connect player signals and create level up/game over screens
	setup_camera()          # Position camera and create shake system
	setup_damage_manager()  # Create floating damage number system
	setup_particle_manager() # Create visual effects system
	setup_time_dilation()   # Create time slowdown system for spell casting
	setup_object_pool()     # Create object pooling for performance
	setup_chest_manager()   # Create treasure chest spawning system
	setup_audio_system()    # Verify audio system is working

# Set up the 6 spell slot UI elements with their icons, labels and styling
func setup_spell_slots():
	# The 6 spells available in the game, mapped to number keys 1-6
	var spell_names = ["bolt", "life", "ice blast", "earth shield", "lightning arc", "meteor shower"]
	var spell_slots_container = get_node_or_null("UI/HUD/SpellSlotsPanel/SpellSlots")
	if not spell_slots_container:
		return
		
	# Create and configure each of the 6 spell slots
	for i in range(6):
		var slot_container = spell_slots_container.get_child(i) if i < spell_slots_container.get_child_count() else null
		if slot_container:
			spell_slots.append(slot_container)
			setup_individual_spell_slot(slot_container, i, spell_names[i])

# Configure a single spell slot with its number, name, icon and styling
func setup_individual_spell_slot(slot_container: Node, index: int, spell_name: String):
	# Set up the spell icon (if present) - now it's inside a VBox
	var vbox = slot_container.get_node_or_null("VBox")
	var icon = vbox.get_node_or_null("Icon") if vbox else null
	if icon:
		icon.visible = true
		icon.custom_minimum_size = ICON_SIZE
	
	# Check if spell is unlocked using SpellManager
	var is_unlocked = true
	if spell_manager and spell_manager.has_method("is_spell_unlocked"):
		is_unlocked = spell_manager.is_spell_unlocked(index + 1)  # SpellManager uses 1-6 indexing
	
	# Set up the key number label
	var key_label = vbox.get_node_or_null("KeyLabel") if vbox else null
	if key_label:
		key_label.text = str(index + 1)
		key_label.modulate = Color.WHITE if is_unlocked else Color(0.6, 0.6, 0.6, 1.0)
	
	# Set up the level label
	var level_label = slot_container.get_node_or_null("LevelLabel")
	if level_label:
		if is_unlocked:
			update_spell_level_display(level_label, spell_name)
		else:
			level_label.text = "🔒"
			level_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	
	# Apply visual styling (background, borders, etc.)
	setup_spell_slot_styling(slot_container, not is_unlocked)

# Update the level display for a specific spell
func update_spell_level_display(level_label: Label, spell_name: String):
	if not level_label or not spell_manager:
		return
		
	var spell_level = 1
	
	# Handle mana bolt separately (auto-attack)
	if spell_name == "bolt":  # Mana Bolt is called "bolt" in the slot but "mana_bolt" in SpellManager  
		if "mana_bolt_level" in spell_manager:
			spell_level = spell_manager.mana_bolt_level
	else:
		# Check spell dictionary for other spells
		if "spells" in spell_manager:
			var spells = spell_manager.spells
			for slot in spells:
				var spell_info = spells[slot]
				if spell_info.get("name") == spell_name:
					spell_level = spell_info.get("level", 1)
					break
	
	# Update the label with level info
	level_label.text = str(spell_level)
	
	# Color code based on level (green for higher levels)
	if spell_level >= 5:
		level_label.modulate = Color(0.4, 1.0, 0.4, 1.0)  # Bright green
	elif spell_level >= 3:
		level_label.modulate = Color(0.8, 1.0, 0.6, 1.0)  # Light green  
	else:
		level_label.modulate = Color(1.0, 1.0, 0.6, 1.0)  # Yellow

# Refresh all spell level displays (called when spells are upgraded)
func refresh_spell_levels():
	var spell_names = ["bolt", "life", "ice blast", "earth shield", "lightning arc", "meteor shower"]
	
	for i in range(spell_slots.size()):
		if i < spell_names.size():
			var slot_container = spell_slots[i]
			var level_label = slot_container.get_node_or_null("LevelLabel")
			if level_label:
				update_spell_level_display(level_label, spell_names[i])

# Update the survival timer display
func update_timer_display():
	if not timer_label:
		return
	
	# Convert game_time to minutes:seconds format
	var total_seconds = int(game_time)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	
	# Format as MM:SS
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Color code based on time survived
	if total_seconds >= 900:  # 15+ minutes = gold
		timer_label.modulate = Color(1.0, 0.9, 0.3, 1.0)
	elif total_seconds >= 600:  # 10+ minutes = light green
		timer_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	elif total_seconds >= 300:  # 5+ minutes = yellow
		timer_label.modulate = Color(1.0, 1.0, 0.6, 1.0)
	else:  # Less than 5 minutes = white
		timer_label.modulate = Color.WHITE

# Update the difficulty multiplier display
func update_difficulty_display():
	if not difficulty_label:
		return
	
	# Calculate current difficulty multipliers (same as in game logic)
	var health_mult = 1.0 + 0.15 * floor(game_time / 30.0)  # Every 30 seconds
	var speed_mult = 1.0 + 0.02 * floor(game_time / 120.0)  # Every 2 minutes
	var spawn_mult = 1.0 + 0.05 * floor(game_time / 45.0)   # Every 45 seconds
	
	# Calculate overall difficulty as average of multipliers
	var avg_difficulty = (health_mult + speed_mult + spawn_mult) / 3.0
	
	# Format difficulty display
	difficulty_label.text = "Difficulty: %.1fx" % avg_difficulty
	
	# Color code based on difficulty level
	if avg_difficulty >= 3.0:  # Very high difficulty = red
		difficulty_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
	elif avg_difficulty >= 2.0:  # High difficulty = orange
		difficulty_label.modulate = Color(1.0, 0.7, 0.4, 1.0)
	elif avg_difficulty >= 1.5:  # Medium difficulty = yellow
		difficulty_label.modulate = Color(1.0, 1.0, 0.6, 1.0)
	else:  # Low difficulty = light green
		difficulty_label.modulate = Color(0.8, 1.0, 0.8, 1.0)

# Set up the difficulty tooltip system
func setup_difficulty_tooltip():
	if difficulty_tooltip:
		difficulty_tooltip_label = difficulty_tooltip.get_node_or_null("TooltipLabel")
		difficulty_tooltip.visible = false
	
	# Add hover detection to the timer panel
	if timer_panel:
		timer_panel.mouse_entered.connect(_on_timer_panel_mouse_entered)
		timer_panel.mouse_exited.connect(_on_timer_panel_mouse_exited)

# Show difficulty tooltip when hovering over timer panel
func _on_timer_panel_mouse_entered():
	if difficulty_tooltip and difficulty_tooltip_label:
		update_difficulty_tooltip_content()
		difficulty_tooltip.visible = true
		
		# Animate tooltip appearance
		var tween = create_tween()
		difficulty_tooltip.modulate = Color.TRANSPARENT
		tween.tween_property(difficulty_tooltip, "modulate", Color.WHITE, 0.2)

# Hide difficulty tooltip when mouse leaves timer panel
func _on_timer_panel_mouse_exited():
	if difficulty_tooltip:
		var tween = create_tween()
		tween.tween_property(difficulty_tooltip, "modulate", Color.TRANSPARENT, 0.15)
		tween.tween_callback(func(): difficulty_tooltip.visible = false)

# Update the content of the difficulty tooltip with current values
func update_difficulty_tooltip_content():
	if not difficulty_tooltip_label:
		return
	
	# Calculate current difficulty multipliers
	var health_mult = 1.0 + 0.15 * floor(game_time / 30.0)
	var speed_mult = 1.0 + 0.02 * floor(game_time / 120.0)
	var spawn_mult = 1.0 + 0.05 * floor(game_time / 45.0)
	
	# Calculate next threshold times
	var next_health_time = (floor(game_time / 30.0) + 1) * 30.0
	var next_speed_time = (floor(game_time / 120.0) + 1) * 120.0
	var next_spawn_time = (floor(game_time / 45.0) + 1) * 45.0
	
	var content = "[center][b]Difficulty Scaling[/b][/center]\n\n"
	content += "[color=red]• Enemy Health: %.2fx[/color]\n" % health_mult
	content += "  [color=gray](+15% every 30s | Next: %ds)[/color]\n\n" % int(next_health_time - game_time)
	content += "[color=yellow]• Enemy Speed: %.2fx[/color]\n" % speed_mult
	content += "  [color=gray](+2% every 2min | Next: %ds)[/color]\n\n" % int(next_speed_time - game_time)
	content += "[color=green]• Spawn Rate: %.2fx[/color]\n" % spawn_mult
	content += "  [color=gray](+5% every 45s | Next: %ds)[/color]" % int(next_spawn_time - game_time)
	
	difficulty_tooltip_label.text = content

# Called every frame to update game time and handle input
func _process(delta):
	# Only advance game time while actively playing (not paused/level up/game over)
	if current_state == GameState.PLAYING:
		game_time += delta
	
	# Update timer and difficulty displays
	update_timer_display()
	update_difficulty_display()
	
	# Check for global input like pause key
	handle_input()

# Process global input that works in any game state
func handle_input():
	# ESC key toggles pause (only works during PLAYING or PAUSED states)
	if Input.is_action_just_pressed("ui_cancel"):  # ESC key
		toggle_pause()
	
	# Check for difficulty increase command (U key)
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_U):
		increase_difficulty_level()
	
	# Check for invincibility toggle (P key)
	if Input.is_key_pressed(KEY_P):
		toggle_invincibility()

# Initialize the main UI elements (health bar, XP bar, typing display)
func setup_ui():
	# Set up health bar to show values from 0-100%
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = 100  # Start at full health
		
		# Allow the health bar to have child nodes for overheal display
		health_bar.clip_contents = false
		
		# Initialize health bar color to green (full health)
		update_health_bar_color(100.0)
	
	# Find and set up health label
	health_label = get_node_or_null("UI/HUD/StatsPanel/HealthLabel")
	if not health_label and health_bar:
		# Try to find it as a child of the health bar
		health_label = health_bar.get_node_or_null("HealthLabel")
	
	# Initialize health label text with actual player values
	if health_label and player:
		var current_health = player.current_health if "current_health" in player else 100
		var max_health = player.max_health if "max_health" in player else 100
		health_label.text = "{0}/{1}".format([int(current_health), int(max_health)])
	
	# Set up XP bar to show values from 0-100%
	if xp_bar:
		xp_bar.min_value = 0
		xp_bar.max_value = 100
		xp_bar.value = 0  # Start with no XP
	
	# Find and set up XP label
	xp_label = get_node_or_null("UI/HUD/StatsPanel/XPLabel")
	if not xp_label and xp_bar:
		# Try to find it as a child of the XP bar
		xp_label = xp_bar.get_node_or_null("XPLabel")
	
	# Find the typing label in the UI hierarchy and configure it
	typing_label = find_typing_label($UI)
	if typing_label:
		typing_label.text = ""  # Start with no text
		setup_typing_ui_style()  # Apply visual styling
		
		# Hide the typing UI initially (shown only when typing spells)
		hide_typing_ui()
	
	# Set up difficulty tooltip system
	setup_difficulty_tooltip()

func setup_player():
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.xp_changed.connect(_on_player_xp_changed)
		player.player_died.connect(_on_player_died)
		player.level_up.connect(_on_player_level_up)
		player.player_damaged.connect(_on_player_damaged)
		
		# Initialize UI with current player values
		if "current_health" in player and "max_health" in player:
			_on_player_health_changed(player.current_health, player.max_health, 0.0)
		if "current_xp" in player and "xp_needed" in player:
			_on_player_xp_changed(player.current_xp, player.xp_needed)
	
	# Connect spell manager signals
	if spell_manager:
		spell_manager.spell_queued.connect(_on_spell_queued)
		spell_manager.typing_started.connect(_on_typing_started) 
		spell_manager.typing_ended.connect(_on_typing_ended)
		spell_manager.spell_locked_error.connect(_on_spell_locked_error)
		
	# Create level up screen
	level_up_screen = level_up_screen_scene.instantiate()
	$UI.add_child(level_up_screen)
	level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	
	# Move level up screen to front (on top of other UI elements)
	$UI.move_child(level_up_screen, -1)
	print("Game: Level up screen added. Visible: ", level_up_screen.visible, " Modulate: ", level_up_screen.modulate)
	
	# Create game over screen
	game_over_screen = game_over_screen_scene.instantiate()
	$UI.add_child(game_over_screen)
	game_over_screen.restart_game.connect(_on_restart_game)
	game_over_screen.return_to_menu.connect(_on_return_to_menu)

func setup_camera():
	if camera and player:
		camera.enabled = true
		
		# Add camera to group so background system can find it
		camera.add_to_group("camera")
		
		# Position player and camera at viewport center
		var viewport_size = get_viewport().get_visible_rect().size
		var center_pos = viewport_size / 2
		
		player.global_position = center_pos
		camera.global_position = center_pos
		
		# Create camera shake system
		camera_shake = CameraShake.new()
		add_child(camera_shake)
		camera_shake.set_camera(camera)
		camera_shake.set_follow_target(player)

func _on_player_health_changed(new_health: float, max_health: float, overheal_amount: float):
	if not health_bar:
		return
		
	var health_percent = (new_health / max_health) * 100
	animate_progress_bar(health_bar, health_percent, HEALTH_BAR_ANIMATION_DURATION)
	update_health_bar_color(health_percent)
	
	# Show overheal as blue extension
	update_overheal_display(new_health, max_health, overheal_amount)
	
	# Update health text label to show current/max with overheal and timer
	if health_label:
		if overheal_amount > 0:
			# Show overheal with remaining time
			var time_remaining = player.get_overheal_time_remaining() if player and player.has_method("get_overheal_time_remaining") else 0.0
			health_label.text = "{0}/{1} (+{2}) [{3}s]".format([int(new_health), int(max_health), int(overheal_amount), int(time_remaining)])
		else:
			health_label.text = "{0}/{1}".format([int(new_health), int(max_health)])

func animate_progress_bar(progress_bar: ProgressBar, value: float, duration: float):
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", value, duration)

func update_health_bar_color(health_percent: float):
	var health_bar_fill = get_or_create_progress_bar_style(health_bar)
	
	if health_percent > HEALTH_HIGH_THRESHOLD:
		health_bar_fill.bg_color = Color.GREEN
	elif health_percent > HEALTH_MEDIUM_THRESHOLD:
		health_bar_fill.bg_color = Color.YELLOW
	else:
		health_bar_fill.bg_color = Color.RED

func get_or_create_progress_bar_style(progress_bar: ProgressBar) -> StyleBoxFlat:
	var style = progress_bar.get("theme_override_styles/fill")
	if not style:
		style = StyleBoxFlat.new()
		progress_bar.set("theme_override_styles/fill", style)
	return style

func update_overheal_display(current_health: float, max_health: float, overheal_amount: float):
	# Create or manage overheal bar overlay
	var overheal_bar = health_bar.get_node_or_null("OverhealBar")
	
	if overheal_amount > 0:
		# Create overheal bar if it doesn't exist
		if not overheal_bar:
			overheal_bar = ProgressBar.new()
			overheal_bar.name = "OverhealBar"
			health_bar.add_child(overheal_bar)
			
			# Position and size the overheal bar to overlay the health bar
			overheal_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overheal_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Style the overheal bar with blue background
			var overheal_bg_style = StyleBoxFlat.new()
			overheal_bg_style.bg_color = Color.TRANSPARENT
			overheal_bar.set("theme_override_styles/background", overheal_bg_style)
			
			var overheal_fill_style = StyleBoxFlat.new()
			overheal_fill_style.bg_color = Color(0.2, 0.6, 1.0, 0.7)  # Light blue with transparency
			overheal_bar.set("theme_override_styles/fill", overheal_fill_style)
		
		# Configure overheal bar values
		overheal_bar.visible = true
		overheal_bar.min_value = 100  # Start where health bar ends
		var max_overheal_display = 200  # Show up to 200% total (100% health + 100% overheal)
		overheal_bar.max_value = max_overheal_display
		
		# Calculate overheal percentage
		var health_percent = (current_health / max_health) * 100
		var total_percent = ((current_health + overheal_amount) / max_health) * 100
		overheal_bar.value = min(total_percent, max_overheal_display)
		
		# Keep normal health bar at just the health portion
		health_bar.value = health_percent
	elif overheal_bar:
		# Hide overheal bar when no overheal
		overheal_bar.visible = false
		
		# Reset health bar to normal
		var health_percent = (current_health / max_health) * 100
		health_bar.value = health_percent
		update_health_bar_color(health_percent)


func _on_player_xp_changed(current_xp: float, xp_needed: float):
	if not xp_bar:
		return
		
	var xp_percent = (current_xp / xp_needed) * 100
	animate_progress_bar(xp_bar, xp_percent, XP_BAR_ANIMATION_DURATION)
	update_xp_bar_effects(xp_percent)
	
	# Update XP text label
	if xp_label:
		xp_label.text = "{0}/{1}".format([int(current_xp), int(xp_needed)])

func update_xp_bar_effects(xp_percent: float):
	var xp_bar_fill = get_or_create_progress_bar_style(xp_bar)
	
	if xp_percent > XP_GLOW_THRESHOLD:
		create_xp_glow_effect(xp_bar_fill)
	else:
		xp_bar_fill.bg_color = Color.BLUE

func create_xp_glow_effect(style: StyleBoxFlat):
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(style, "bg_color", Color.GOLD, GLOW_ANIMATION_DURATION)
	glow_tween.tween_property(style, "bg_color", Color.ORANGE, GLOW_ANIMATION_DURATION)

func _on_player_died():
	change_state(GameState.GAME_OVER)
	show_game_over_screen()

func _on_upgrade_selected_stub(upgrade_data: Dictionary):
	# TODO: Handle upgrade selection when level up screen is implemented
	pass

func change_state(new_state: GameState):
	current_state = new_state
	
	match current_state:
		GameState.PLAYING:
			get_tree().paused = false
			if pause_overlay:
				pause_overlay.visible = false
		GameState.PAUSED:
			get_tree().paused = true
			if pause_overlay:
				pause_overlay.visible = true
		GameState.GAME_OVER:
			get_tree().paused = true
		GameState.LEVEL_UP:
			get_tree().paused = true
			if level_up_screen:
				level_up_screen.visible = true

func toggle_pause():
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
	elif current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

func update_typing_display(text: String):
	# Try to find typing label if it's null
	if not typing_label or not is_instance_valid(typing_label):
		typing_label = find_typing_label($UI)
	
	if typing_label and is_instance_valid(typing_label):
		typing_label.text = text
		# Only set modulate if the label is still valid
		if is_instance_valid(typing_label) and typing_label.has_method("set_modulate"):
			typing_label.modulate = Color.WHITE  # Reset color in case it was changed
		
		# Show/hide based on whether there's text to display
		var should_show = text.length() > 0
		
		# Only hide/show the specific typing containers, not all UI
		var typing_area = typing_label.get_parent()  # TypingArea
		var typing_panel = typing_area.get_parent() if typing_area else null  # TypingPanel
		
		if typing_panel and typing_panel.name == "TypingPanel":
			typing_panel.visible = should_show
		elif typing_area and typing_area.name == "TypingArea":
			typing_area.visible = should_show
		else:
			# Fallback: just show/hide the label itself
			typing_label.visible = should_show
		
		# Position typing UI in upper screen when visible
		if should_show:
			position_typing_ui_upper_screen()
	else:
		# Falalback: print to console if UI still not found
		print("Typing display: ", text)

func setup_damage_manager():
	# Create damage manager
	var damage_manager = Node.new()
	damage_manager.name = "DamageManager"
	damage_manager.set_script(damage_manager_scene)
	add_child(damage_manager)

# Function to show damage numbers (called by projectiles)
func show_damage_number(pos: Vector2, damage: float):
	var damage_manager = get_node_or_null("DamageManager")
	if damage_manager and damage_manager.has_method("show_damage"):
		damage_manager.show_damage(pos, damage)

func _on_player_level_up(new_level: int, player_stats: Dictionary):
	# Refresh spell slot UI to show newly unlocked spells
	update_spell_slot_lock_status()
	
	change_state(GameState.LEVEL_UP)
	if level_up_screen:
		level_up_screen.show_level_up(new_level, player_stats)

func _on_upgrade_selected(upgrade_data: Dictionary):
	# Apply upgrade to player
	if player:
		player.apply_upgrade(upgrade_data)
	
	# Apply spell upgrades to spell manager if needed
	var effect = upgrade_data.get("effect", {})
	if effect.get("type") == "spell_upgrade":
		if spell_manager and spell_manager.has_method("upgrade_spell"):
			var spell_name = effect.get("spell", "")
			spell_manager.upgrade_spell(spell_name)
	
	# Refresh spell level displays in the HUD
	refresh_spell_levels()
	
	# Resume game
	change_state(GameState.PLAYING)

func show_game_over_screen():
	
	# Process game end for character progression
	if CharacterManager:
		var player_level = player.level if player else 1
		CharacterManager.process_game_end(game_time, player_level, enemies_killed, spells_cast)
	
	if game_over_screen and is_instance_valid(game_over_screen):
		# Ensure the game over screen is properly initialized
		if not game_over_screen.is_inside_tree():
			print("ERROR: game_over_screen is not in scene tree yet")
			call_deferred("show_game_over_screen")
			return
		var stats = {
			"survival_time": game_time,
			"level": player.level if player else 1,
			"enemies_killed": enemies_killed,
			"spells_cast": spells_cast
		}
		game_over_screen.show_game_over(stats)
	else:
		print("ERROR: game_over_screen is null or invalid")

func _on_restart_game():
	# Use SceneManager's restart function which handles pause state
	SceneManager.restart_current_scene()

func _on_return_to_menu():
	# Simple return - let SceneManager handle everything
	SceneManager.goto_scene("res://scenes/MainMenu.tscn")

func increment_enemies_killed():
	enemies_killed += 1

func increment_spells_cast():
	spells_cast += 1

# Camera shake functions
func shake_light():
	if camera_shake:
		camera_shake.shake_light()

func shake_medium():
	if camera_shake:
		camera_shake.shake_medium()

func shake_heavy():
	if camera_shake:
		camera_shake.shake_heavy()

# Called when player takes damage
func _on_player_damaged():
	shake_heavy()

func setup_particle_manager():
	# Create and setup the particle manager
	particle_manager = ParticleManager.new()
	particle_manager.z_index = 100  # Ensure particles render above other elements
	add_child(particle_manager)

# Particle effect functions
func create_enemy_death_effect(position: Vector2):
	if particle_manager:
		particle_manager.create_enemy_death_effect(position)
		shake_medium()

func create_spell_cast_effect(position: Vector2):
	if particle_manager:
		particle_manager.create_spell_cast_effect(position)

func create_xp_collect_effect(position: Vector2):
	if particle_manager:
		particle_manager.create_xp_collect_effect(position)

func create_spell_impact_effect(position: Vector2):
	if particle_manager:
		particle_manager.create_spell_impact_effect(position)

func create_heal_effect(position: Vector2):
	if particle_manager:
		particle_manager.create_heal_effect(position)

func create_powerful_spell_effect(position: Vector2, spell_name: String):
	if particle_manager:
		particle_manager.create_powerful_spell_effect(position, spell_name)
		# Trigger screen shake for powerful spells
		if spell_name in ["meteor shower", "lightning arc"]:
			shake_heavy()

func setup_time_dilation():
	# Create and setup the time dilation effect system
	time_dilation_effect = TimeDilationEffect.new()
	add_child(time_dilation_effect)

# Time dilation functions for spell casting
func start_time_dilation():
	if time_dilation_effect:
		time_dilation_effect.start_time_dilation()

func end_time_dilation():
	if time_dilation_effect:
		time_dilation_effect.end_time_dilation()

func is_time_dilated() -> bool:
	if time_dilation_effect:
		return time_dilation_effect.is_active()
	return false

func setup_console():
	# Create developer console (hidden cheat system)
	console_instance = console_scene.instantiate()
	add_child(console_instance)
	print("Console system loaded - press ~ to access hidden commands")

func setup_object_pool():
	# Create and setup the object pooling system
	object_pool = ObjectPool.new()
	add_child(object_pool)
	
	# Register pools for commonly spawned objects
	var spell_projectile_scene = preload("res://scenes/SpellProjectile.tscn")
	var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
	var xp_orb_scene = preload("res://scenes/XPOrb.tscn")
	
	object_pool.register_pool("SpellProjectile", spell_projectile_scene, 50)
	object_pool.register_pool("DamageNumber", damage_number_scene, 30)
	object_pool.register_pool("XPOrb", xp_orb_scene, 20)

func get_pooled_object(type_name: String) -> Node:
	# Get an object from the pool
	if object_pool:
		return object_pool.get_object(type_name)
	return null

func setup_chest_manager():
	# Create and setup the chest management system
	chest_manager = ChestManager.new()
	add_child(chest_manager)
	chest_manager.chest_spawn_interval = CHEST_SPAWN_INTERVAL
	chest_manager.max_chests = MAX_CHESTS

func setup_spell_slot_styling(slot_container: Node, is_locked: bool = false):
	# Setup styling for spell slot containers
	# Add a background panel to the slot container
	var background = Panel.new()
	slot_container.add_child(background)
	slot_container.move_child(background, 0)  # Move to back
	
	var normal_style = StyleBoxFlat.new()
	
	# Different styling for locked vs unlocked spells
	if is_locked:
		normal_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)  # Darker background for locked spells
		normal_style.border_color = Color(0.4, 0.4, 0.4, 0.8)  # Gray border for locked spells
	else:
		normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Normal background
		normal_style.border_color = Color.WHITE  # White border for unlocked spells
	
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.corner_radius_top_left = 5
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 5
	
	background.set("theme_override_styles/panel", normal_style)
	background.anchors_preset = Control.PRESET_FULL_RECT

# Update all spell slots to reflect current lock/unlock status
func update_spell_slot_lock_status():
	var spell_names = ["bolt", "life", "ice blast", "earth shield", "lightning arc", "meteor shower"]
	
	for i in range(spell_slots.size()):
		if i < spell_names.size():
			var slot_container = spell_slots[i]
			var label = slot_container.get_node_or_null("VBox/Label")
			if not label:
				label = slot_container.get_node_or_null("Label")
			
			if label:
				# Check if spell is unlocked
				var is_unlocked = true
				if spell_manager and spell_manager.has_method("is_spell_unlocked"):
					is_unlocked = spell_manager.is_spell_unlocked(i + 1)
				
				# Update label text and color
				var spell_name = spell_names[i]
				if is_unlocked:
					label.text = str(i + 1) + "\n" + spell_name
					label.modulate = Color.WHITE
				else:
					label.text = str(i + 1) + "\n🔒 " + spell_name
					label.modulate = Color(0.6, 0.6, 0.6, 1.0)

func highlight_spell_slot(slot_index: int):
	# Highlight a specific spell slot
	for i in range(spell_slots.size()):
		var slot_container = spell_slots[i]
		var background = slot_container.get_child(0) if slot_container.get_child_count() > 0 else null
		if background and background is Panel:
			var style = background.get("theme_override_styles/panel")
			if style:
				if i == slot_index:
					# Highlight selected slot
					style.bg_color = Color(0.8, 0.6, 0.2, 0.9)
					style.border_color = Color.GOLD
					
					# Add pulsing animation
					var tween = create_tween()
					tween.set_loops()
					tween.tween_property(style, "bg_color", Color(1.0, 0.8, 0.3, 0.9), 0.5)
					tween.tween_property(style, "bg_color", Color(0.8, 0.6, 0.2, 0.9), 0.5)
				else:
					# Reset other slots
					style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
					style.border_color = Color.WHITE

func clear_spell_slot_highlights():
	# Clear all spell slot highlights
	for slot_container in spell_slots:
		var background = slot_container.get_child(0) if slot_container.get_child_count() > 0 else null
		if background and background is Panel:
			var style = background.get("theme_override_styles/panel")
			if style:
				style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
				style.border_color = Color.WHITE

# Spell Manager signal handlers
func _on_spell_queued(spell_name: String, slot: int):
	# Handle spell being queued for casting
	highlight_spell_slot(slot - 1)  # Convert to 0-based index

func _on_typing_started():
	# Handle typing mode starting
	pass  # Spell slot is already highlighted from _on_spell_queued

func _on_typing_ended():
	# Handle typing mode ending
	clear_spell_slot_highlights()

func _on_spell_locked_error(spell_name: String, required_level: int, current_level: int):
	# Show error message when player tries to use locked spell
	var error_msg = "🔒 {0} requires level {1}!\n(You're level {2})".format([spell_name.capitalize(), required_level, current_level])
	
	# Try to find typing label if it's null
	if not typing_label:
		typing_label = find_typing_label($UI)
	
	if typing_label and is_instance_valid(typing_label):
		typing_label.text = error_msg
		if is_instance_valid(typing_label) and typing_label.has_method("set_modulate"):
			typing_label.modulate = Color.ORANGE_RED
		
		# Clear error message after 2 seconds
		var tree = get_tree()
		if tree and is_inside_tree():
			tree.create_timer(2.0).timeout.connect(func(): 
				if typing_label and is_instance_valid(typing_label):
					typing_label.text = ""
					if is_instance_valid(typing_label) and typing_label.has_method("set_modulate"):
						typing_label.modulate = Color.WHITE
			)
	else:
		# Fallback: just print to console if UI isn't available
		print(error_msg)

func find_typing_label(node: Node) -> Label:
	if not node:
		return null
	
	# Check if this node is the typing label
	if node.name == "TypingLabel" and node is Label:
		return node as Label
	
	# Search children recursively
	for child in node.get_children():
		var result = find_typing_label(child)
		if result:
			return result
	
	return null

func get_node_path_to(target_node: Node) -> String:
	var path_parts = []
	var current = target_node
	
	while current and current != self:
		path_parts.push_front(current.name)
		current = current.get_parent()
	
	return "/".join(path_parts)


func setup_typing_ui_style():
	if not typing_label:
		return
	
	# Make sure the HUD stays visible but typing panel starts hidden
	var hud = $UI/HUD
	if hud:
		hud.visible = true
		hud.modulate = Color.WHITE
	
	# Style the typing label itself
	if is_instance_valid(typing_label) and typing_label.has_method("set_modulate"):
		typing_label.modulate = Color.WHITE
	typing_label.add_theme_color_override("font_color", Color.WHITE)
	typing_label.add_theme_font_size_override("font_size", 20)
	typing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	typing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	

func hide_typing_ui():
	if not typing_label:
		return
	
	# Only hide the specific typing containers, not all UI
	var typing_area = typing_label.get_parent()  # TypingArea
	var typing_panel = typing_area.get_parent() if typing_area else null  # TypingPanel
	
	if typing_panel and typing_panel.name == "TypingPanel":
		typing_panel.visible = false
	elif typing_area and typing_area.name == "TypingArea":
		typing_area.visible = false
	else:
		# Fallback: just hide the label itself
		typing_label.visible = false
	

func position_typing_ui_upper_screen():
	if not typing_label:
		return
	
	# Get screen dimensions
	var screen_size = get_viewport().get_visible_rect().size
	
	# Position in upper center of screen (25% down from top)
	var typing_ui_position = Vector2(screen_size.x / 2, screen_size.y * 0.25)
	
	# Find the typing panel (parent container) to position it
	var typing_panel = typing_label.get_parent().get_parent()  # TypingArea -> TypingPanel
	if typing_panel and typing_panel is Control:
		var control = typing_panel as Control
		control.position = typing_ui_position - control.size / 2  # Center the panel on the position
	

func print_ui_structure(node: Node, indent: String = ""):
	if not node:
		return
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_ui_structure(child, indent + "  ")

func setup_audio_system():
	# AudioManager is already autoloaded, just ensure it's initialized
	if AudioManager:
		print("AudioManager connected to Game scene")
		# You can add any game-specific audio setup here if needed
	else:
		print("WARNING: AudioManager not found in Game scene")

# Audio event helpers for other systems to use
func play_chest_open_sound():
	if AudioManager:
		AudioManager.on_chest_open()

func play_item_pickup_sound():
	if AudioManager:
		AudioManager.play_sound(AudioManager.SoundType.PICKUP_ITEM)

# Pause menu button handlers
func _on_pause_resume_pressed():
	toggle_pause()  # Resume the game

func _on_pause_options_pressed():
	# Open the options screen while keeping the game paused
	var options_scene = preload("res://scenes/Options.tscn")
	var options_instance = options_scene.instantiate()
	get_tree().current_scene.add_child(options_instance)
	
	# Tell options it was called from pause menu
	options_instance.called_from_pause = true
	
	# Hide the pause menu while options are open
	pause_overlay.visible = false
	
	# Connect to options back signal to return to pause menu
	options_instance.options_closed.connect(_on_options_closed)

func _on_pause_restart_pressed():
	# Restart the current game
	_on_restart_game()

func _on_pause_main_menu_pressed():
	# Return to main menu
	_on_return_to_menu()

func _on_options_closed():
	# Show pause menu again when options are closed
	if current_state == GameState.PAUSED:
		pause_overlay.visible = true

# Increase difficulty level (cheat command)
func increase_difficulty_level():
	
	# Add 60 seconds to game time (equivalent to 1 difficulty level)
	# This affects multiple scaling systems:
	# - Health multiplier increases every 30 seconds
	# - Speed multiplier increases every 60 seconds
	# - Damage/spawn rate increases every 45 seconds
	var difficulty_jump = 60.0
	game_time += difficulty_jump
	
	# Also add the same time to monster manager if it exists
	var monster_manager = get_node_or_null("MonsterManager")
	if monster_manager and monster_manager.has_method("add_game_time"):
		monster_manager.add_game_time(difficulty_jump)
	
	# Fallback to old EnemyManager for compatibility (now disabled)
	# var enemy_manager = get_node_or_null("EnemyManager")
	# if enemy_manager and enemy_manager.has_method("add_game_time"):
	#	enemy_manager.add_game_time(difficulty_jump)
	
	# Calculate current difficulty multipliers for display
	var health_mult = 1.0 + 0.15 * floor(game_time / 30.0)
	var speed_mult = 1.0 + 0.02 * floor(game_time / 120.0)
	var damage_mult = 1.0  # No damage scaling
	
	print("Difficulty increased! Time: {0}s | Health: {1:.1f}x | Speed: {2:.2f}x | Damage: {3:.1f}x".format([int(game_time), health_mult, speed_mult, damage_mult]))

# Toggle invincibility (cheat command)
func toggle_invincibility():
	if not player:
		return
	
	# Toggle invincibility status on player
	if player.has_method("toggle_invincibility"):
		player.toggle_invincibility()
	elif player.has_method("set_invincible"):
		# Try alternative method name
		var is_invincible = player.get("is_invincible") if "is_invincible" in player else false
		player.set_invincible(not is_invincible)
	else:
		# If player doesn't have invincibility methods, add it via script
		if not "is_invincible" in player:
			player.set("is_invincible", false)
		
		var current_invincible = player.get("is_invincible")
		player.set("is_invincible", not current_invincible)
		
		var status = "ON" if not current_invincible else "OFF"
		# Invincibility toggled silently
