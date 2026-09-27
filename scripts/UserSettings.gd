extends Node

const PATH = "user://presentation.cfg"

func _ready():
	var config = ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for key in ["master", "sfx", "music"]:
		var value = config.get_value("audio", key, 1.0)
		if value is float or value is int:
			AudioManager.call("set_" + key + "_volume", clampf(float(value), 0, 1))
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		if config.has_section_key("display", "fullscreen"):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if config.get_value("display", "fullscreen") else DisplayServer.WINDOW_MODE_WINDOWED)
		if config.has_section_key("display", "vsync"):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if config.get_value("display", "vsync") else DisplayServer.VSYNC_DISABLED)

func save_value(section: String, key: String, value: Variant) -> Error:
	var config = ConfigFile.new()
	config.load(PATH)
	config.set_value(section, key, value)
	return config.save(PATH)
