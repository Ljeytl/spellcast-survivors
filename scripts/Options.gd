extends Control

signal options_closed

var called_from_pause: bool = false

func _on_back_button_pressed():
	# Play button click sound
	if AudioManager:
		AudioManager.on_button_click()
	
	if called_from_pause:
		# Close options and return to pause menu
		options_closed.emit()
		queue_free()
	else:
		# Return to main menu (normal behavior)
		SceneManager.goto_scene("res://scenes/MainMenu.tscn")

func _on_master_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_master_volume(value / 100.0)

func _on_sfx_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("SFX") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_sfx_volume(value / 100.0)

func _on_music_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("Music") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)

func _on_fullscreen_check_box_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_v_sync_check_box_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)