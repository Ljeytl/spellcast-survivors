extends Node

const PATH = "user://presentation.cfg"
var show_fps := false
var fps_label: Label
var next_fps_update_msec := 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay = CanvasLayer.new()
	overlay.layer = 110
	add_child(overlay)
	fps_label = Label.new()
	fps_label.name = "FPSMeter"
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.add_theme_font_size_override("font_size", 18)
	fps_label.add_theme_color_override("font_color", Color.WHITE)
	fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	fps_label.add_theme_constant_override("shadow_offset_x", 2)
	fps_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(fps_label)
	fps_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	fps_label.offset_left = -120
	fps_label.offset_top = -58
	fps_label.offset_right = -12
	fps_label.offset_bottom = -36
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_label.hide()
	var config = ConfigFile.new()
	if config.load(PATH) != OK:
		return
	show_fps = config.get_value("display", "show_fps", false) == true
	fps_label.visible = show_fps
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

func set_show_fps(value: bool) -> Error:
	show_fps = value
	fps_label.visible = value
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	return save_value("display", "show_fps", value)

func _process(_delta: float):
	if not show_fps:
		return
	if Time.get_ticks_msec() >= next_fps_update_msec:
		next_fps_update_msec = Time.get_ticks_msec() + 250
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()
