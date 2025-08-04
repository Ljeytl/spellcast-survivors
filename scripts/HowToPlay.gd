extends Control

func _on_back_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()
	SceneManager.goto_scene("res://scenes/MainMenu.tscn")