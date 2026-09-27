extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run():
	var settings = root.get_node("UserSettings")
	var audio = root.get_node("AudioManager")
	if "--write" in OS.get_cmdline_user_args():
		for key in ["master", "sfx", "music"]:
			check(settings.save_value("audio", key, 0.37) == OK, "Save " + key)
		check(settings.save_value("display", "fullscreen", false) == OK, "Save display mode")
		check(settings.save_value("display", "vsync", false) == OK, "Save vsync")
		check(preload("res://scripts/EffectPreferences.gd").save_reduced(true) == OK, "Save reduced effects without losing audio values")
	else:
		for key in ["master", "sfx", "music"]:
			check(is_equal_approx(audio.get(key + "_volume"), 0.37), "Fresh process loads " + key)
		var config = ConfigFile.new()
		config.load("user://presentation.cfg")
		check(not config.get_value("display", "fullscreen", true), "Display config survives restart")
		check(not config.get_value("display", "vsync", true), "Vsync config survives restart")
		if DisplayServer.get_name() != "headless":
			check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "Actual window mode restored")
			check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "Actual vsync restored")
		check(preload("res://scripts/EffectPreferences.gd").reduced(), "Reduced effects persists")
		var options = load("res://scenes/Options.tscn").instantiate()
		root.add_child(options)
		for row in ["MasterVolumeContainer/MasterSlider", "SFXContainer/SFXSlider", "MusicContainer/MusicSlider"]:
			check(is_equal_approx(options.get_node("OptionsPanel/VBoxContainer/" + row).value, 37), "Reopened control agrees: " + row)
		check(options.get_node("OptionsPanel/VBoxContainer/ReducedEffectsCheckBox").button_pressed, "Reduced effects control agrees")
		var player = audio.current_music_player
		audio.is_music_playing = true
		player.volume_db = -3
		audio.set_music_volume(0.5)
		check(is_equal_approx(player.volume_db, -3), "Music preference is not applied twice")
		for key in ["master", "sfx", "music"]:
			settings.save_value("audio", key, 1.0)
		settings.save_value("display", "vsync", true)
		preload("res://scripts/EffectPreferences.gd").save_reduced(false)
	print("UI settings restart: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
