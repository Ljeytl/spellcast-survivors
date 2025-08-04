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

func _ready():
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
	
	visible = true
	display_stats(stats)
	animate_in()

func display_stats(stats: Dictionary):
	# Format survival time
	var total_seconds = stats.get("survival_time", 0.0)
	var minutes = int(total_seconds / 60)
	var seconds = int(total_seconds) % 60
	
	# Update labels with null checks
	if survival_time_label:
		survival_time_label.text = "Survival Time: %d:%02d" % [minutes, seconds]
	else:
		print("ERROR: survival_time_label is null")
	
	if level_label:
		level_label.text = "Level Reached: {0}".format([stats.get("level", 1)])
	else:
		print("ERROR: level_label is null")
		
	if enemies_killed_label:
		enemies_killed_label.text = "Enemies Killed: {0}".format([stats.get("enemies_killed", 0)])
	else:
		print("ERROR: enemies_killed_label is null")
		
	if spells_cast_label:
		spells_cast_label.text = "Spells Cast: {0}".format([stats.get("spells_cast", 0)])
	else:
		print("ERROR: spells_cast_label is null")

func animate_in():
	# Fade in background
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Scale in panel with slight delay and bounce (with null check)
	if panel:
		var scale_tween = create_tween()
		scale_tween.tween_interval(0.2)
		scale_tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.3)
		scale_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)
	else:
		print("ERROR: panel is null in animate_in()")
	
	# Animate title with a dramatic shake
	animate_title()

func _on_play_again_pressed():
	if is_instance_valid(AudioManager):
		AudioManager.on_button_click()
	restart_game.emit()

func _on_main_menu_pressed():
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

func _on_button_hover(button: Button):
	if AudioManager:
		AudioManager.on_button_hover()
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_exit(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func animate_title():
	# Dramatic title animation with shake and glow (with null check)
	if not title_label:
		print("ERROR: title_label is null in animate_title()")
		return
		
	var title_tween = create_tween()
	title_tween.set_parallel(true)
	
	# Shake effect
	var original_pos = title_label.position
	for i in range(5):
		var shake_offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		title_tween.tween_property(title_label, "position", original_pos + shake_offset, 0.05)
		title_tween.tween_property(title_label, "position", original_pos, 0.05)
	
	# Scale pulse
	title_tween.tween_property(title_label, "scale", Vector2(1.2, 1.2), 0.3)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.2)

func _input(event):
	# Allow Enter or Space to restart quickly
	if visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_play_again_pressed()
		elif event.keycode == KEY_ESCAPE:
			_on_main_menu_pressed()
