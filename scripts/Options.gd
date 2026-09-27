extends Control

signal options_closed

var called_from_pause: bool = false
var save_status: Label
const EFFECTS = preload("res://scripts/EffectPreferences.gd")

func _ready():
	$OptionsPanel/VBoxContainer/ReducedEffectsCheckBox.set_pressed_no_signal(EFFECTS.reduced())
	preload("res://scripts/GameplayReadability.gd").setup_menu(self, "OptionsPanel")
	var column = $OptionsPanel/VBoxContainer
	for spec in [["MasterVolumeContainer/MasterSlider", AudioManager.master_volume], ["SFXContainer/SFXSlider", AudioManager.sfx_volume], ["MusicContainer/MusicSlider", AudioManager.music_volume]]:
		var slider = column.get_node(spec[0])
		slider.set_value_no_signal(spec[1] * 100)
		var value_label = Label.new()
		value_label.name = "Value"
		value_label.custom_minimum_size.x = 48
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slider.get_parent().add_child(value_label)
		value_label.text = "%d%%" % slider.value
		slider.value_changed.connect(func(value): value_label.text = "%d%%" % value)
	column.get_node("FullscreenCheckBox").set_pressed_no_signal(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	column.get_node("VSyncCheckBox").visible = not OS.has_feature("web")
	column.get_node("VSyncCheckBox").set_pressed_no_signal(DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED)
	save_status = Label.new()
	save_status.name = "SaveStatus"
	save_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status.add_theme_font_size_override("font_size", 16)
	save_status.hide()
	column.add_child(save_status)
	column.move_child(save_status, column.get_node("BackButton").get_index())
	column.get_node("MasterVolumeContainer/MasterSlider").grab_focus.call_deferred()

func _input(event):
	var game = get_tree().get_first_node_in_group("game")
	if game and is_instance_valid(game.console_instance) and game.console_instance.visible:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

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
		SceneManager.goto_scene("res://scenes/MainMenu.tscn", "OptionsButton")

func _on_master_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_master_volume(value / 100.0)
	show_save_result(UserSettings.save_value("audio", "master", value / 100.0))

func _on_sfx_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("SFX") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_sfx_volume(value / 100.0)
	show_save_result(UserSettings.save_value("audio", "sfx", value / 100.0))

func _on_music_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	if AudioServer.get_bus_index("Music") != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	# Also update AudioManager if available
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)
	show_save_result(UserSettings.save_value("audio", "music", value / 100.0))

func _on_fullscreen_check_box_toggled(button_pressed):
	show_save_result(UserSettings.save_value("display", "fullscreen", button_pressed))
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_v_sync_check_box_toggled(button_pressed):
	show_save_result(UserSettings.save_value("display", "vsync", button_pressed))
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _layout_readable_menu():
	preload("res://scripts/GameplayReadability.gd").layout_menu(self, "OptionsPanel")

func _on_reduced_effects_toggled(value: bool):
	var result = EFFECTS.save_reduced(value)
	show_save_result(result)
	EFFECTS.apply(get_tree().current_scene, value)

func show_save_result(result: Error):
	if not is_instance_valid(save_status):
		return
	save_status.visible = result != OK
	save_status.text = "Could not save settings. Changes apply for this session."
