extends Control

func _ready():
	$HowToPlayPanel/VBoxContainer/BackButton.grab_focus.call_deferred()
	$HowToPlayPanel/VBoxContainer/Instructions.focus_mode = Control.FOCUS_ALL
	preload("res://scripts/GameplayReadability.gd").setup_menu(self, "HowToPlayPanel")

func _on_back_button_pressed():
	if AudioManager:
		AudioManager.on_button_click()
	SceneManager.goto_scene("res://scenes/MainMenu.tscn", "HowToPlayButton")

func _layout_readable_menu():
	preload("res://scripts/GameplayReadability.gd").layout_menu(self, "HowToPlayPanel")

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()
