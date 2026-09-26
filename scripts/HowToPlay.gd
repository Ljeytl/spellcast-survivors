extends Control

func _ready():
	preload("res://scripts/GameplayReadability.gd").setup_menu(self, "HowToPlayPanel")

func _on_back_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()
	SceneManager.goto_scene("res://scenes/MainMenu.tscn")

func _layout_readable_menu():
	preload("res://scripts/GameplayReadability.gd").layout_menu(self, "HowToPlayPanel")
