# Main menu screen - entry point for the game with navigation buttons
# Shows Play, Options, How to Play, and Quit buttons
extends Control

# Called when the main menu scene loads
func _ready():
	# Start playing the menu background music
	if AudioManager:
		AudioManager.play_music(AudioManager.SoundType.MUSIC_MENU, true, 1.0)

# Start a new game - loads the main game scene
func _on_play_button_pressed():
	print("DEBUG: MainMenu Play button pressed")
	if is_instance_valid(AudioManager):
		AudioManager.on_button_click()  # Play button click sound
	print("DEBUG: MainMenu calling SceneManager.goto_scene")
	SceneManager.goto_scene("res://scenes/Game.tscn")  # Load game scene

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
	get_tree().quit()  # Close the application