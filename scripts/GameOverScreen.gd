extends Control

signal restart_game
signal return_to_menu

@onready var title_label: Label = $Background/Panel/VBoxContainer/TitleLabel
@onready var survival_time_label: Label = $Background/Panel/VBoxContainer/StatsContainer/SurvivalTimeContainer/SurvivalTimeLabel
@onready var level_label: Label = $Background/Panel/VBoxContainer/StatsContainer/LevelContainer/LevelLabel
@onready var enemies_killed_label: Label = $Background/Panel/VBoxContainer/StatsContainer/EnemiesKilledContainer/EnemiesKilledLabel
@onready var spells_cast_label: Label = $Background/Panel/VBoxContainer/StatsContainer/SpellsCastContainer/SpellsCastLabel
@onready var play_again_button: Button = $Background/Panel/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var main_menu_button: Button = $Background/Panel/VBoxContainer/ButtonContainer/MainMenuButton
@onready var panel: Panel = $Background/Panel
var kit_label: Label
var discovery_label: Label
var action_started = false
var keyboard_armed_at = 0
var last_stats: Dictionary = {}
var style_label: Label
var defeat_label: Label

func _ready():
	preload("res://scripts/BuildVersion.gd").attach(self)
	# Allow processing when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Check all node references and connect signals with null checks
	if play_again_button and play_again_button is Button:
		play_again_button.pressed.connect(_on_play_again_pressed)
	else:
		print("ERROR: play_again_button is null or not a Button, type: ", type_string(typeof(play_again_button)) if play_again_button else "null")
		
	if main_menu_button and main_menu_button is Button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	else:
		print("ERROR: main_menu_button is null or not a Button, type: ", type_string(typeof(main_menu_button)) if main_menu_button else "null")
	
	play_again_button.text = "RETRY"
	main_menu_button.text = "MENU"
	setup_run_summary()
	# Setup button hover effects
	setup_button_effects()
	
	# Setup title styling
	setup_title_styling()
	
	# Start hidden
	visible = false
	modulate.a = 0.0
	
	# Scale panel for animation with null check
	if panel:
		panel.scale = Vector2(0.8, 0.8)
	else:
		print("ERROR: panel is null")

func show_game_over(stats: Dictionary):
	# Ensure _ready() has been called before proceeding
	if not is_inside_tree():
		call_deferred("show_game_over", stats)
		return
	
	# Additional safety check: wait for next frame if @onready vars aren't ready
	if not title_label or not survival_time_label or not panel:
		call_deferred("show_game_over", stats)
		return
	
	action_started = false
	keyboard_armed_at = Time.get_ticks_msec() + 350
	get_viewport().gui_release_focus()
	visible = true
	display_stats(stats)
	animate_in()

func display_stats(stats: Dictionary):
	last_stats = stats.duplicate(true)
	var style = stats.get("style", {})
	var ranks = preload("res://scripts/StyleScore.gd").RANKS
	style_label.text = "SCORE  %d  ·  BEST RANK  %s" % [style.get("run_score", 0), ranks[clampi(int(style.get("peak_rank", 0)), 0, 8)]]
	if not style.get("eligible", false):
		style_label.text += "\nPractice run · not ranked"
	elif not style.get("saved", false):
		style_label.text += "\nScore could not be saved"
	var game = get_tree().get_first_node_in_group("game")
	var debug = game != null and game.interface_debug
	var won = stats.get("won", false)
	defeat_label.visible = not won and debug
	kit_label.visible = debug
	spells_cast_label.get_parent().visible = debug
	defeat_label.text = describe_final_hit(stats.get("final_hit", {}))
	title_label.text = "VICTORY!" if won else "GAME OVER"
	title_label.add_theme_color_override("font_color", Color("dfbd76") if won else Color("ff8175"))
	kit_label.text = "FINAL SPELL KIT\n" + "\n".join(stats.get("final_kit", [])) + "\nAutomatic Mana Bolt · Rank %d" % stats.get("mana_bolt_rank", 1)
	var discoveries = stats.get("discoveries", [])
	discovery_label.visible = debug or not discoveries.is_empty()
	discovery_label.text = "NEW DISCOVERIES\n" + (", ".join(discoveries) if not discoveries.is_empty() else "No new evolutions discovered this run.")
	# Format survival time
	var total_seconds = stats.get("survival_time", 0.0)
	var minutes = int(total_seconds / 60)
	var seconds = int(total_seconds) % 60
	
	# Update labels with null checks
	if survival_time_label:
		survival_time_label.text = "Time: %d:%02d" % [minutes, seconds]
	else:
		print("ERROR: survival_time_label is null")
	
	if level_label:
		level_label.text = "Level: {0}".format([stats.get("level", 1)])
	else:
		print("ERROR: level_label is null")
		
	if enemies_killed_label:
		enemies_killed_label.text = "Kills: {0}".format([stats.get("enemies_killed", 0)])
	else:
		print("ERROR: enemies_killed_label is null")
		
	if spells_cast_label:
		spells_cast_label.text = "Spells Cast: {0}".format([stats.get("spells_cast", 0)])
	else:
		print("ERROR: spells_cast_label is null")

func setup_run_summary():
	var content = $Background/Panel/VBoxContainer
	var stats = content.get_node("StatsContainer")
	stats.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for row in stats.get_children():
		row.get_child(0).hide()
		row.get_child(1).add_theme_font_size_override("font_size", 18)
	var scroll = ScrollContainer.new()
	scroll.name = "RunSummaryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	content.move_child(scroll, content.get_node("HSeparator2").get_index())
	var summary = VBoxContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_theme_constant_override("separation", 16)
	scroll.add_child(summary)
	style_label = Label.new()
	style_label.name = "StyleResult"
	defeat_label = Label.new()
	defeat_label.name = "DefeatCause"
	kit_label = Label.new()
	kit_label.name = "FinalKit"
	discovery_label = Label.new()
	discovery_label.name = "Discoveries"
	for label in [style_label, defeat_label, kit_label, discovery_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("eee8d8"))
		summary.add_child(label)
	content.add_theme_constant_override("separation", 12)

func describe_final_hit(context: Dictionary) -> String:
	var cause = "Damage source not recorded"
	var source = str(context.get("source", ""))
	match context.get("kind", "unknown"):
		"contact":
			var count = int(context.get("count", 1))
			cause = "Contact with %d enemies" % count if count > 1 else "Enemy contact"
		"projectile":
			cause = (source + " projectile") if not source.is_empty() else "Enemy projectile"
		"blast":
			cause = (source + " area blast") if not source.is_empty() else "Enemy area blast"
	var amount = " · %.1f damage taken" % float(context.damage) if context.has("damage") else ""
	if context.get("overheal_loss", 0.0) > 0:
		amount += " (%.1f health + %.1f bonus health)" % [context.get("health_loss", 0.0), context.overheal_loss]
	return "FINAL HIT\n" + cause + amount

func _input(event):
	if visible and event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if event.echo or Time.get_ticks_msec() < keyboard_armed_at:
			get_viewport().set_input_as_handled()

func animate_in():
	panel.scale = Vector2.ONE
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _on_play_again_pressed():
	if action_started:
		return
	action_started = true
	if is_instance_valid(AudioManager):
		AudioManager.on_button_click()
	restart_game.emit()

func _on_main_menu_pressed():
	if action_started:
		return
	action_started = true
	if AudioManager:
		AudioManager.on_button_click()
	return_to_menu.emit()

func setup_button_effects():
	# Connect hover signals for visual feedback with null checks
	if play_again_button and play_again_button is Button:
		play_again_button.mouse_entered.connect(func(): _on_button_hover(play_again_button))
		play_again_button.mouse_exited.connect(func(): _on_button_exit(play_again_button))
		
	if main_menu_button and main_menu_button is Button:
		main_menu_button.mouse_entered.connect(func(): _on_button_hover(main_menu_button))
		main_menu_button.mouse_exited.connect(func(): _on_button_exit(main_menu_button))

func setup_title_styling():
	# Make title larger and more dramatic with null check
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.RED)
	else:
		print("ERROR: title_label is null in setup_title_styling()")

func _on_button_hover(_button: Button):
	if AudioManager:
		AudioManager.on_button_hover()

func _on_button_exit(_button: Button):
	pass

func _unhandled_key_input(event):
	# Allow Enter or Space to restart quickly
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and Time.get_ticks_msec() < keyboard_armed_at:
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			_on_play_again_pressed()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_main_menu_pressed()
