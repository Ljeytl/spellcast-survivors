# Main menu screen - entry point for the game with navigation buttons
# Shows Play, Options, How to Play, and Quit buttons
extends Control

# Called when the main menu scene loads
func _ready():
	preload("res://scripts/BuildVersion.gd").attach(self)
	get_window().title = ProjectSettings.get_setting("application/config/display_name")
	$MenuPanel/VBoxContainer/QuitButton.visible = not OS.has_feature("web")
	$MenuPanel/VBoxContainer.get_node(SceneManager.menu_focus_name).grab_focus.call_deferred()
	preload("res://scripts/GameplayReadability.gd").setup_menu(self, "MenuPanel")
	preload("res://scripts/AuthoredInterface.gd").add_menu_art(self)
	var scores = Button.new()
	scores.name = "ScoresButton"
	scores.text = "HIGH SCORES"
	scores.custom_minimum_size.y = 44
	scores.pressed.connect(_on_scores_pressed)
	$MenuPanel/VBoxContainer.add_child(scores)
	$MenuPanel/VBoxContainer.move_child(scores, $MenuPanel/VBoxContainer/QuitButton.get_index())
	$MenuPanel/VBoxContainer/Spacer.custom_minimum_size.y = 12
	_layout_readable_menu()
	# Start playing the menu background music
	if AudioManager:
		AudioManager.play_music(AudioManager.SoundType.MUSIC_MENU, true, 1.0)

# Start a new game - loads the main game scene
func _on_play_button_pressed():
	if is_instance_valid(AudioManager):
		AudioManager.on_button_click()  # Play button click sound
	SceneManager.goto_scene("res://scenes/Tower.tscn")  # Load game scene

# Open the options/settings screen
func _on_options_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()  # Play button click sound
	SceneManager.goto_scene("res://scenes/Options.tscn")  # Load options scene

# Open the tutorial/instructions screen
func _on_how_to_play_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()  # Play button click sound
	SceneManager.goto_scene("res://scenes/HowToPlay.tscn")  # Load tutorial scene

# Exit the game application
func _on_quit_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()  # Play button click sound
	AudioManager.request_quit()

func _on_collection_pressed():
	var collection = preload("res://scripts/SpellCollection.gd").new()
	add_child(collection)
	$MenuPanel.hide()
	collection.closed.connect(func():
		$MenuPanel.show()
		$MenuPanel/VBoxContainer/CollectionButton.grab_focus()
	)


func _layout_readable_menu():
	preload("res://scripts/GameplayReadability.gd").layout_menu(self, "MenuPanel")
	$MenuPanel/VBoxContainer/CollectionButton.add_theme_font_size_override("font_size", 28 if size.x < 600 else 32)

func _on_scores_pressed():
	var board = preload("res://scripts/StyleLeaderboard.gd").new()
	add_child(board)
	$MenuPanel.hide()
	board.closed.connect(func():
		$MenuPanel.show()
		$MenuPanel/VBoxContainer/ScoresButton.grab_focus()
	)
