# Main game controller that manages game state, UI, and coordinates between all systems
# This is the central hub for SpellCast Survivors game logic
extends Node2D

# Enumeration for different game states to control game flow
enum GameState {
	PLAYING,     # Active gameplay with movement, combat, and spell casting
	LEVEL_UP,    # Player is selecting upgrades, game is paused
	GAME_OVER,   # Player has died, showing game over screen
	EXTRACTION,
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
var run_won: bool = false
var result_recorded: bool = false
var extraction_screen: Control
# Total time spent in this game session (used for survival scoring)
var game_time: float = 0.0
var pending_level_ups: Array[int] = []
var interface_debug = false
var style_session: Node

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
var discoveries_at_start: Array = []
var spells_cast: int = 0     # Total spells successfully cast this session

# Called when the scene is first loaded and ready to run
func _ready():
	camera.zoom = Vector2.ONE * preload("res://scripts/VisualDefaults.gd").CAMERA_ZOOM
	
	# Add to game group for other nodes to find this main game controller
	add_to_group("game")
	discoveries_at_start = CharacterManager.discovered_synergies.duplicate()
	
	# Start the background music for gameplay
	if is_instance_valid(AudioManager):
		AudioManager.play_music(AudioManager.SoundType.MUSIC_GAMEPLAY, true, 1.0)
	
	# Initialize all game systems in the correct order
	setup_all_systems()
	style_session = preload("res://scripts/StyleSession.gd").new()
	style_session.game = self
	add_child(style_session)
	var style_hud = preload("res://scripts/StyleHUD.gd").new()
	style_hud.session = style_session
	hud.add_child(style_hud)
	$MonsterManager.run_completed.connect(show_extraction_choice)
	extraction_screen = preload("res://scripts/ExtractionChoice.gd").new()
	extraction_screen.extract_requested.connect(extract_run)
	extraction_screen.continue_requested.connect(continue_endless)
	$UI.add_child(extraction_screen)
	# Configure the spell slot UI with icons and labels
	setup_spell_slots()
	update_spell_slot_lock_status()
	# Initialize developer console
	setup_console()
	var readability = preload("res://scripts/GameplayReadability.gd").new()
	readability.name = "GameplayReadability"
	add_child(readability)
	var inventory = preload("res://scripts/RunInventory.gd").new()
	inventory.game = self
	hud.add_child(inventory)
	var casting_reference = preload("res://scripts/CastingReference.gd").new()
	casting_reference.game = self
	hud.add_child(casting_reference)
	var direction = preload("res://scripts/BossDirection.gd").new()
	direction.game = self
	hud.add_child(direction)
	preload("res://scripts/BuildVersion.gd").attach(hud)
	preload("res://scripts/BuildVersion.gd").attach(pause_overlay)
	show_gameplay_feedback("Click a spell or press 1–6, then type its name. Space: any learned spell.")
	var xp_consolidation = preload("res://scripts/XPConsolidation.gd").new()
	xp_consolidation.name = "XPConsolidation"
	add_child(xp_consolidation)
	

# Master setup function that initializes all game systems
# Order matters here - some systems depend on others being ready first
func setup_all_systems():
	setup_ui()              # Initialize health/XP bars and typing display
	setup_player()          # Connect player signals and create level up/game over screens
	setup_camera()          # Position camera and create shake system
	setup_damage_manager()  # Create floating damage number system
	setup_particle_manager() # Create visual effects system
	preload("res://scripts/EffectPreferences.gd").apply(self, preload("res://scripts/EffectPreferences.gd").reduced())
	setup_time_dilation()   # Create time slowdown system for spell casting
	setup_object_pool()     # Create object pooling for performance
	setup_chest_manager()   # Create treasure chest spawning system
	setup_audio_system()    # Verify audio system is working

# Set up the 6 spell slot UI elements with their icons, labels and styling
func setup_spell_slots():
	var spell_slots_container = get_node_or_null("UI/HUD/SpellSlotsPanel/SpellSlots")
	if not spell_slots_container:
		return
	for i in range(spell_slots_container.get_child_count()):
		var slot_container = spell_slots_container.get_child(i)
		slot_container.visible = i < spell_manager.MAX_EQUIPPED_SPELLS
		if i < spell_manager.MAX_EQUIPPED_SPELLS:
			spell_slots.append(slot_container)
			slot_container.gui_input.connect(_on_spell_slot_input.bind(i + 1))
			for child in slot_container.find_children("*", "Control", true, false):
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Configure a single spell slot with its number, name, icon and styling
func setup_individual_spell_slot(slot_container: Node, index: int, spell_name: String):
	# Set up the spell icon (if present) - now it's inside a VBox
	var vbox = slot_container.get_node_or_null("VBox")
	var icon = vbox.get_node_or_null("Icon") if vbox else null
	if icon:
		icon.visible = false
		icon.custom_minimum_size = ICON_SIZE
	
	# Check if spell is unlocked using SpellManager
	var is_unlocked = true
	if spell_manager and spell_manager.has_method("is_spell_unlocked"):
		is_unlocked = spell_manager.is_spell_unlocked(index + 1)  # SpellManager uses 1-6 indexing
	
	if icon:
		icon.modulate = Color.WHITE if is_unlocked else Color(0.45, 0.45, 0.45, 0.4)

	# Set up the key number label
	var key_label = vbox.get_node_or_null("KeyLabel") if vbox else null
	if key_label:
		preload("res://scripts/AuthoredInterface.gd").apply_shortcut(key_label)
		key_label.text = str(index + 1)
		key_label.modulate = Color.WHITE if is_unlocked else Color(0.6, 0.6, 0.6, 1.0)
	
	var name_label = vbox.get_node_or_null("SpellName")
	if not name_label:
		name_label = Label.new()
		name_label.name = "SpellName"
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(name_label)
		name_label.minimum_size_changed.connect(_resize_spell_hud)
	var info = spell_manager.spells.get(index + 1, {})
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_unlocked else Control.CURSOR_ARROW
	name_label.text = info.get("name", "Empty")
	slot_container.visible = is_unlocked or interface_debug
	name_label.modulate = Color.WHITE if is_unlocked else Color("a6b4c8")
	# Set up the level label
	var level_label = slot_container.get_node_or_null("LevelLabel")
	if level_label:
		update_spell_level_display(level_label, spell_name)
		if is_unlocked:
			update_spell_level_display(level_label, spell_name)
		else:
			level_label.text = "Learn at level-up"
			level_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
	
	# Apply visual styling (background, borders, etc.)
	setup_spell_slot_styling(slot_container, not is_unlocked)
	_resize_spell_hud.call_deferred()

# Update the level display for a specific spell
func update_spell_level_display(level_label: Label, spell_name: String):
	if not level_label or not spell_manager:
		return
	var rank = spell_manager.get_spell_rank(spell_name)
	level_label.text = "Rank %d" % rank if rank > 0 else "Learn at level-up"
	level_label.visible = interface_debug
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	level_label.offset_top = -26
	level_label.offset_left = 6
	level_label.offset_right = -6
	level_label.offset_bottom = -6
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	level_label.modulate = Color.GOLD if rank > 0 else Color.GRAY

func _resize_spell_hud():
	var panel = $UI/HUD/SpellSlotsPanel
	var grid = panel.get_node("SpellSlots") as GridContainer
	var count = 6 if interface_debug else maxi(1, spell_manager.spells.size())
	var width = minf(count * 124 + 20, $UI/HUD.size.x - 36)
	grid.columns = mini(count, maxi(1, int((width - 14) / 116)))
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var height = 100.0 if interface_debug else 76.0
	for card in spell_slots:
		if not card.visible:
			continue
		var name_label = card.get_node_or_null("VBox/SpellName")
		if not name_label:
			continue
		var available_width = (width - 20 - (grid.columns - 1) * 6) / grid.columns - 12
		var longest_word = 1.0
		for word in name_label.text.split(" "):
			longest_word = maxf(longest_word, name_label.get_theme_font("font").get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x)
		var name_size = clampi(floori(18 * available_width / longest_word), 14, 18)
		if name_label.get_theme_font_size("font_size") != name_size:
			name_label.add_theme_font_size_override("font_size", name_size)
		var rank_height = card.get_node("LevelLabel").get_minimum_size().y if interface_debug else 0.0
		var key_height = card.get_node("VBox/KeyLabel").get_minimum_size().y
		height = maxf(height, name_label.get_minimum_size().y + key_height + rank_height + 18)
		card.get_node("VBox").offset_bottom = -rank_height - 6
		card.get_node("LevelLabel").offset_top = -rank_height - 6
	for card in spell_slots:
		card.custom_minimum_size = Vector2(90, height)
	var rows = ceili(float(count) / grid.columns)
	panel.offset_top = -(height * rows + (rows - 1) * 6 + 32)
	panel.offset_bottom = -12
	panel.offset_left = -width / 2
	panel.offset_right = width / 2

func refresh_spell_levels():
	for i in range(spell_slots.size()):
		var level_label = spell_slots[i].get_node_or_null("LevelLabel")
		if level_label:
			update_spell_level_display(level_label, spell_manager.spells.get(i + 1, {}).get("id", ""))

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
	var manager = get_node_or_null("MonsterManager")
	if not manager:
		return
	var tier = manager.get_current_difficulty_level()
	difficulty_label.text = "Tier %d • Boss %02d:00" % [tier, mini(15, tier * 5)]
	if manager.endless_mode:
		difficulty_label.text = "Endless • %.1f× pressure" % manager.spawn_difficulty_multiplier()
	elif tier == 4:
		difficulty_label.text = "Tier 4 • Survive to 20:00"
	var bosses = get_tree().get_nodes_in_group("bosses").filter(func(enemy): return not enemy.dying)
	if not bosses.is_empty():
		difficulty_label.text = "%s • %d HP" % [bosses[0].encounter_name, ceili(bosses[0].current_health)]
	difficulty_label.modulate = Color("ff8175") if not bosses.is_empty() else Color("dfbd76")
	difficulty_label.visible = interface_debug or not bosses.is_empty()
	timer_panel.size = Vector2(minf(340 if difficulty_label.visible else 112, hud.size.x * 0.48), 92 if difficulty_label.visible else 48)
	timer_panel.position = Vector2(hud.size.x - timer_panel.size.x - 18, 18)
	if timer_panel.position.x < hud.get_node("StatsPanel").get_rect().end.x + 18:
		timer_panel.position.y = hud.get_node("StatsPanel").get_rect().end.y + 12

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
	if interface_debug and difficulty_tooltip and difficulty_tooltip_label:
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
	var manager = get_node_or_null("MonsterManager")
	if not manager:
		return
	var content = "[center][b]Difficulty[/b][/center]\n\n"
	content += "Monster tier: %d\n" % manager.get_current_difficulty_level()
	content += "Spawn interval: %.2fs\n\n" % manager.calculate_spawn_interval()
	content += "Normal and fast melee form the opening.\n"
	content += "Bosses arrive at 5, 10 and 15 minutes; extract or continue at 20.\n"
	content += "Ranged enemies join after ten minutes."
	difficulty_tooltip_label.text = content

func _process(delta):
	# Only advance game time while actively playing (not paused/level up/game over)
	if current_state == GameState.PLAYING:
		game_time = $MonsterManager.game_time
	
	# Update timer and difficulty displays
	update_timer_display()
	update_difficulty_display()
	
# Initialize the main UI elements (health bar, XP bar, typing display)
var typing_keycaps: Control

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
		var current_health = player.health if "health" in player else 100
		var max_health = player.max_health if "max_health" in player else 100
		health_label.text = "Health · {0}/{1}".format([health_amount_text(current_health), health_amount_text(max_health)])
	
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
		typing_label.minimum_size_changed.connect(_fit_typing_content)
		setup_typing_ui_style()  # Apply visual styling
		typing_keycaps = preload("res://scripts/TypingKeycaps.gd").new()
		typing_keycaps.manager = spell_manager
		typing_label.add_child(typing_keycaps)
		spell_manager.spell_cast.connect(typing_keycaps.finish_cast)
		spell_manager.manual_spell_released.connect(typing_keycaps.on_manual_release)
		
		# Hide the typing UI initially (shown only when typing spells)
		hide_typing_ui()
	
	# Set up difficulty tooltip system
	setup_difficulty_tooltip()

func setup_player():
	if player:
		player.add_child(preload("res://scripts/OrbitingStaff.gd").new())
		player.health_changed.connect(_on_player_health_changed)
		player.xp_changed.connect(_on_player_xp_changed)
		player.player_died.connect(_on_player_died)
		player.level_up.connect(_on_player_level_up)
		player.player_damaged.connect(_on_player_damaged)
		
		# Initialize UI with current player values
		if "health" in player and "max_health" in player:
			_on_player_health_changed(player.health, player.max_health, 0.0)
		if "xp" in player and "xp_to_next_level" in player:
			_on_player_xp_changed(player.xp, player.xp_to_next_level)
	
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
	game_over_screen.restart_game.connect(_on_return_to_tower)
	game_over_screen.return_to_menu.connect(_on_return_to_tower)

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

func health_amount_text(amount: float) -> String:
	return "<1" if amount > 0.0 and amount < 1.0 else str(int(maxf(0.0, amount)))

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
			health_label.text = "Health · {0}/{1} (+{2}) [{3}s]".format([health_amount_text(new_health), health_amount_text(max_health), health_amount_text(overheal_amount), int(time_remaining)])
		else:
			health_label.text = "Health · {0}/{1}".format([health_amount_text(new_health), health_amount_text(max_health)]) if interface_debug else "{0} / {1}".format([health_amount_text(new_health), health_amount_text(max_health)])

func animate_progress_bar(progress_bar: ProgressBar, value: float, duration: float):
	var previous_tween = progress_bar.get_meta("value_tween") if progress_bar.has_meta("value_tween") else null
	if previous_tween is Tween and previous_tween.is_valid():
		previous_tween.kill()
	var tween = create_tween()
	progress_bar.set_meta("value_tween", tween)
	tween.tween_property(progress_bar, "value", value, duration)

func update_health_bar_color(health_percent: float):
	if health_bar.has_node("AuthoredHealth"):
		return
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
	var authored = health_bar.get_node_or_null("AuthoredHealth")
	if authored:
		authored.shield_ratio = clampf(overheal_amount / maxf(1, max_health), 0, 1)
		return
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
		xp_label.text = "Level %d · XP %d/%d" % [player.level, int(current_xp), int(xp_needed)] if interface_debug else "Level %d · XP %d / %d" % [player.level, int(current_xp), int(xp_needed)]

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
	finish_run(false)

func show_extraction_choice():
	if current_state != GameState.PLAYING or player.health <= 0 or result_recorded:
		return
	if not $MonsterManager.awaiting_extraction:
		return
	change_state(GameState.EXTRACTION)
	spell_manager.cancel_typing()
	typing_keycaps.completion_remaining = 0
	hide_typing_ui()
	game_time = $MonsterManager.game_time
	update_timer_display()
	extraction_screen.open()

func extract_run():
	if current_state == GameState.EXTRACTION and player.health > 0:
		finish_run(true)

func continue_endless():
	if current_state != GameState.EXTRACTION or player.health <= 0:
		return
	extraction_screen.hide()
	$MonsterManager.continue_endless()
	change_state(GameState.PLAYING)

func finish_run(won: bool):
	if current_state == GameState.GAME_OVER:
		return
	typing_keycaps.completion_remaining = 0
	spell_manager.cancel_typing()
	run_won = won
	game_time = $MonsterManager.game_time
	$MonsterManager.run_finished = true
	$MonsterManager.spawn_timer.stop()
	pending_level_ups.clear()
	level_up_screen.hide()
	pause_overlay.hide()
	if is_instance_valid(extraction_screen):
		extraction_screen.hide()
	change_state(GameState.GAME_OVER)
	update_timer_display()
	show_game_over_screen()

func _on_upgrade_selected_stub(upgrade_data: Dictionary):
	# TODO: Handle upgrade selection when level up screen is implemented
	pass

func change_state(new_state: GameState):
	if current_state == GameState.GAME_OVER:
		return
	current_state = new_state
	if new_state in [GameState.GAME_OVER, GameState.EXTRACTION]:
		spell_manager.discard_pending_casts()
	
	if hud.has_node("BuildVersion"):
		hud.get_node("BuildVersion").visible = current_state == GameState.PLAYING
	match current_state:
		GameState.PLAYING:
			get_viewport().gui_release_focus()
			get_tree().paused = false
			if pause_overlay:
				pause_overlay.visible = false
		GameState.PAUSED:
			if not spell_manager.is_typing and is_instance_valid(typing_keycaps):
				typing_keycaps.completion_remaining = 0
				typing_keycaps.clear_keys()
				hide_typing_ui()
			get_tree().paused = true
			if pause_overlay:
				pause_overlay.visible = true
				$UI/PauseOverlay/PauseMenu/VBoxContainer/ResumeButton.grab_focus.call_deferred()
		GameState.GAME_OVER:
			get_tree().paused = true
		GameState.LEVEL_UP:
			get_tree().paused = true
			if level_up_screen:
				level_up_screen.visible = true

	if current_state == GameState.PLAYING and $MonsterManager.awaiting_extraction:
		show_extraction_choice()
	elif current_state == GameState.PLAYING and not pending_level_ups.is_empty():
		show_next_level_up()
	sync_pause_state()

func sync_pause_state():
	get_tree().paused = current_state != GameState.PLAYING or (is_instance_valid(console_instance) and console_instance.visible)

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
			typing_label.modulate = Color("ff8175") if "Mismatch" in text or "No matching spell" in text or "unavailable" in text else Color("79d9e8")
		
		# Show/hide based on whether there's text to display
		if is_instance_valid(typing_keycaps):
			typing_keycaps.sync(spell_manager.current_typing_text, text)
		var should_show = text.length() > 0 or (is_instance_valid(typing_keycaps) and typing_keycaps.completion_remaining > 0)
		
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
			_fit_typing_content()
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

func _on_player_level_up(new_level: int, _player_stats: Dictionary):
	if current_state == GameState.GAME_OVER:
		return
	pending_level_ups.append(new_level)
	if current_state == GameState.PLAYING:
		show_next_level_up()

func queue_boss_reward() -> bool:
	if current_state == GameState.GAME_OVER:
		return false
	pending_level_ups.append(0)
	if current_state == GameState.PLAYING:
		show_next_level_up()
	return true

func show_next_level_up():
	if current_state not in [GameState.PLAYING, GameState.LEVEL_UP] or pending_level_ups.is_empty() or spell_manager.is_typing:
		return
	hide_typing_ui()
	var next_level = pending_level_ups.pop_front()
	update_spell_slot_lock_status()
	change_state(GameState.LEVEL_UP)
	if level_up_screen:
		level_up_screen.show_level_up(player.level if next_level == 0 else next_level, {
			"spell_damage_multiplier": player.spell_damage_multiplier,
			"cast_speed_multiplier": player.cast_speed_multiplier,
			"projectile_speed_multiplier": player.projectile_speed_multiplier,
			"spell_size_multiplier": player.spell_size_multiplier,
			"spell_duration_multiplier": player.spell_duration_multiplier,
			"passive_ranks": player.passive_ranks.duplicate(),
			"movement_speed_multiplier": player.movement_speed_multiplier,
			"max_health": player.max_health,
			"xp_range_multiplier": player.xp_range_multiplier
		})

		if next_level == 0:
			level_up_screen.title_label.text = "BOSS REWARD"
			level_up_screen.level_label.text = ""

func _on_upgrade_selected(upgrade_data: Dictionary):
	if current_state in [GameState.GAME_OVER, GameState.EXTRACTION, GameState.PAUSED]:
		return
	# Apply upgrade to player
	if player:
		if not player.apply_upgrade(upgrade_data):
			return
	
	# Apply spell upgrades to spell manager if needed
	var effect = upgrade_data.get("effect", {})
	if effect.get("type") == "slowdown_duration":
		spell_manager.typing_slowdown_capacity += float(effect.value)
	if effect.get("type") == "mana_bolt_mastery":
		spell_manager.upgrade_spell("mana_bolt")
	if effect.get("type") == "spell_upgrade":
		if spell_manager and spell_manager.has_method("upgrade_spell"):
			var spell_name = effect.get("spell", "")
			spell_manager.upgrade_spell(spell_name)
	
	if effect.get("type") == "learn_spell":
		if not spell_manager.learn_spell(effect.get("spell", "")):
			return
	update_spell_slot_lock_status()
	var acknowledgement = upgrade_data.get("name", "Upgrade applied")
	if effect.get("type") == "learn_spell":
		var slot = spell_manager.find_spell_slot(effect.get("spell", ""))
		if slot > 0:
			var learned = spell_manager.get_spell_info(slot)
			var cast_hint = "Space" if slot > spell_manager.MAX_EQUIPPED_SPELLS else str(slot)
			acknowledgement = learned.name + " learned · Press %s, then type %s" % [cast_hint, learned.display_name]
	elif effect.get("type") == "spell_upgrade":
		acknowledgement += " · Rank %d" % spell_manager.get_spell_rank(effect.get("spell", ""))
	else:
		acknowledgement += " · " + str(upgrade_data.get("description", "")).split(" (Currently:")[0]
	show_gameplay_feedback(acknowledgement if interface_debug or effect.get("type") == "learn_spell" else str(upgrade_data.get("name", "Upgrade applied")))
	
	if pending_level_ups.is_empty():
		change_state(GameState.PLAYING)
	else:
		show_next_level_up.call_deferred()

func show_game_over_screen():
	if result_recorded:
		return
	if not is_instance_valid(game_over_screen) or not game_over_screen.is_inside_tree():
		show_game_over_screen.call_deferred()
		return
	result_recorded = true
	
	# Process game end for character progression
	if CharacterManager:
		var player_level = player.level if player else 1
		CharacterManager.process_game_end(game_time, player_level, enemies_killed, spells_cast)
	
	if game_over_screen and is_instance_valid(game_over_screen):
		var stats = {
			"won": run_won,
			"final_hit": player.last_damage_context.duplicate(true) if player else {},
			"survival_time": game_time,
			"level": player.level if player else 1,
			"enemies_killed": enemies_killed,
			"spells_cast": spells_cast,
			"final_kit": spell_manager.get_all_spells().values().map(func(info): return "%s · Rank %d" % [info.name, spell_manager.get_spell_rank(info.id)]),
			"mana_bolt_rank": spell_manager.get_spell_rank("mana_bolt"),
			"discoveries": CharacterManager.discovered_synergies.filter(func(id): return id not in discoveries_at_start).map(func(id): return preload("res://scripts/SynergyCatalog.gd").RECIPES[id].name)
		}
		stats["style"] = style_session.finish(stats)
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
## Ordinary kills happen constantly in a horde; only a boss death shakes the camera.
func create_enemy_death_effect(position: Vector2, boss: bool = false):
	if particle_manager:
		particle_manager.create_enemy_death_effect(position)
		if boss:
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
	
	# Add console to UI layer so it appears on top of the game
	var ui_layer = $UI
	if ui_layer:
		ui_layer.add_child(console_instance)
		print("Console added to UI layer")
	else:
		# Fallback: create a dedicated console CanvasLayer
		var console_layer = CanvasLayer.new()
		console_layer.layer = 100  # High layer to ensure it's on top
		console_layer.name = "ConsoleLayer"
		add_child(console_layer)
		console_layer.add_child(console_instance)
		print("Console added to new CanvasLayer")
	
	# Ensure console is completely hidden on startup
	if console_instance:
		console_instance.visible = false
		var console_panel = console_instance.get_node("ConsolePanel")
		if console_panel:
			console_panel.visible = false
			console_panel.position.y = -300.0  # Start off-screen
	
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
	var background = slot_container.get_node_or_null("SlotBackground")
	if not background:
		background = Panel.new()
		background.name = "SlotBackground"
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_container.add_child(background)
		slot_container.move_child(background, 0)  # Move to back
	
	var normal_style = StyleBoxFlat.new()
	
	# Different styling for locked vs unlocked spells
	if is_locked:
		normal_style.bg_color = Color("111c2b")  # Darker background for locked spells
		normal_style.border_color = Color("26384c")  # Gray border for locked spells
	else:
		normal_style.bg_color = Color("25382b")  # Normal background
		normal_style.border_color = Color("66705b")  # White border for unlocked spells
	
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.corner_radius_top_left = 0
	normal_style.corner_radius_top_right = 0
	normal_style.corner_radius_bottom_left = 0
	normal_style.corner_radius_bottom_right = 0
	
	background.set("theme_override_styles/panel", normal_style)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

# Update all spell slots to reflect current lock/unlock status
func update_spell_slot_lock_status():
	for i in range(spell_slots.size()):
		var info = spell_manager.spells.get(i + 1, {})
		setup_individual_spell_slot(spell_slots[i], i, info.get("id", ""))
		spell_slots[i].tooltip_text = ("Click or press %d, then type: %s" % [i + 1, info.display_name]) if not info.is_empty() else "Learn a spell when you level up (six equipped spells maximum)"

func _on_spell_slot_input(event: InputEvent, slot: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spell_slots[slot - 1].accept_event()
		spell_manager.activate_spell_slot(slot)

func show_gameplay_feedback(text: String):
	var interface = get_node_or_null("GameplayReadability")
	if interface:
		interface.show_feedback(text)

func highlight_spell_slot(slot_index: int):
	for i in range(spell_slots.size()):
		var background = spell_slots[i].get_node_or_null("SlotBackground")
		if background:
			var style = background.get_theme_stylebox("panel")
			style.bg_color = Color("244350") if i == slot_index else (Color("25382b") if spell_manager.is_spell_unlocked(i + 1) else Color("111c2b"))
			style.border_color = Color("79d9e8") if i == slot_index else (Color("66705b") if spell_manager.is_spell_unlocked(i + 1) else Color("26384c"))

func clear_spell_slot_highlights():
	highlight_spell_slot(-1)

# Spell Manager signal handlers
func _on_spell_queued(spell_name: String, slot: int):
	# Handle spell being queued for casting
	highlight_spell_slot(slot - 1)  # Convert to 0-based index

func _on_typing_started():
	time_dilation_effect.set_typing_visual(true)
	$UI/HUD/TypingPanel/SlowdownStatus.show()

func _on_typing_ended():
	time_dilation_effect.set_typing_visual(false)
	$UI/HUD/TypingPanel/SlowdownStatus.hide()
	clear_spell_slot_highlights()
	if current_state == GameState.PLAYING and not pending_level_ups.is_empty():
		_show_pending_after_typing.call_deferred()

func _show_pending_after_typing():
	if current_state == GameState.PLAYING:
		show_next_level_up()

func _on_spell_locked_error(spell_name: String, required_level: int, current_level: int):
	# Show error message when player tries to use locked spell
	var error_msg = "Learn %s from a level-up choice first." % spell_name
	
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
	typing_label.add_theme_font_size_override("font_size", 22)
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
	

func update_typing_slowdown(remaining: float, _capacity: float):
	var status = $UI/HUD/TypingPanel/SlowdownStatus
	var instruction = "Enter casts" if spell_manager.space_casting else "Finish name to cast"
	status.text = ("Focus %.1fs" % remaining if remaining > 0.0 else "Normal speed")
	if interface_debug:
		status.text += " · " + instruction + " · Esc cancels"

func _fit_typing_content():
	var area = typing_label.get_parent() as ScrollContainer
	var box = area.get_parent() as Control
	var letter_count = typing_keycaps.letters.length() if is_instance_valid(typing_keycaps) else 4
	box.size = Vector2(minf(maxf(280.0, letter_count * 50.0 + 48.0), $UI/HUD.size.x - 36.0), 120.0 if not typing_keycaps.error_caption().is_empty() else 102.0)
	area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.offset_top = 30.0
	area.offset_bottom = -8.0
	area.offset_left = 12.0
	area.offset_right = -12.0
	var backing = StyleBoxFlat.new()
	backing.bg_color = Color(0.035, 0.06, 0.07, 0.65)
	backing.set_corner_radius_all(8)
	box.add_theme_stylebox_override("panel", backing)
	position_typing_ui_upper_screen()

func _scroll_typing_to_end():
	var area = typing_label.get_parent() as ScrollContainer
	area.scroll_vertical = int(area.get_v_scroll_bar().max_value)

func position_typing_ui_upper_screen():
	if not typing_label:
		return
	var screen_size = $UI/HUD.size
	var panel = typing_label.get_parent().get_parent() as Control
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var y = screen_size.y-panel.size.y-130.0
	var reference = $UI/HUD.get_node_or_null("CastingReference")
	if reference and reference.size.y > 0:
		y = minf(y, reference.position.y-panel.size.y-10.0)
	panel.position = Vector2((screen_size.x-panel.size.x)/2, y)

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
	if $UI.has_node("Options"):
		return
	# Open the options screen while keeping the game paused
	var options_scene = preload("res://scenes/Options.tscn")
	var options_instance = options_scene.instantiate()
	options_instance.called_from_pause = true
	options_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI.add_child(options_instance)
	preload("res://scripts/GameplayReadability.gd").apply_theme(options_instance)
	preload("res://scripts/GameplayReadability.gd").fit_root(options_instance)
	
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
	if current_state == GameState.PAUSED:
		pause_overlay.visible = true
		$UI/PauseOverlay/PauseMenu/VBoxContainer/OptionsButton.grab_focus.call_deferred()

# Increase difficulty level (cheat command)
func increase_difficulty_level():
	
	# Add 60 seconds to game time (equivalent to 1 difficulty level)
	# This affects multiple scaling systems:
	# - Health multiplier increases every 30 seconds
	# - Speed multiplier increases every 60 seconds
	# - Damage/spawn rate increases every 45 seconds
	var difficulty_jump = 60.0
	
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

func set_interface_debug(enabled: bool):
	interface_debug = enabled
	difficulty_tooltip.visible = false
	update_difficulty_display()
	_on_player_health_changed(player.health, player.max_health, player.overheal)
	_on_player_xp_changed(player.xp, player.xp_to_next_level)
	update_spell_slot_lock_status()
	if is_instance_valid(level_up_screen):
		level_up_screen.update_upgrade_displays()
	if is_instance_valid(game_over_screen) and not game_over_screen.last_stats.is_empty():
		game_over_screen.display_stats(game_over_screen.last_stats)
	if has_node("GameplayReadability"):
		$GameplayReadability.layout()

func interface_debug_report() -> String:
	update_difficulty_tooltip_content()
	var lines: Array[String] = [difficulty_tooltip_label.text, "PLAYER STATS", JSON.stringify({"spell_power": player.spell_damage_multiplier, "spell_size": player.spell_size_multiplier, "spell_duration": player.spell_duration_multiplier, "attack_speed": player.cast_speed_multiplier, "projectile_speed": player.projectile_speed_multiplier, "passives": player.passive_ranks, "move_speed": player.movement_speed_multiplier, "max_health": player.max_health, "pickup_range": player.xp_range_multiplier}, "  ")]
	lines.append("UPGRADE DETAILS")
	for card in level_up_screen.current_upgrade_pool:
		lines.append(str(card.name) + ": " + str(card.description))
	lines.append("SPELL DETAILS")
	for id in spell_manager.spell_catalog:
		var info = spell_manager.spell_catalog[id]
		lines.append(str(info.name) + ": " + str(info.get("role", "")))
	lines.append("SYNERGY DETAILS · Bonus spells retain ingredients and use no active slot")
	for recipe in preload("res://scripts/SynergyCatalog.gd").RECIPES.values():
		lines.append(recipe.name + ": " + recipe.requirements + " " + recipe.description)
	if not game_over_screen.last_stats.is_empty():
		lines.append("LAST RUN\n" + JSON.stringify(game_over_screen.last_stats, "  "))
	return "\n".join(lines)

func _on_return_to_tower():
	SceneManager.goto_scene("res://scenes/Tower.tscn")
