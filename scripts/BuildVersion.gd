extends RefCounted

static func text() -> String:
	return "v%s · Playtest" % ProjectSettings.get_setting("application/config/version", "0.1.0")

static func attach(parent: Control) -> Label:
	var label = Label.new()
	label.name = "BuildVersion"
	label.text = text()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("b8c5aa"))
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.offset_left = -180
	label.offset_right = -12
	label.offset_top = -25
	label.offset_bottom = -5
	return label
