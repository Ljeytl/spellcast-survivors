extends RefCounted

const KEY = preload("res://assets/typecast/Logo/Blank Key.png")
const WORN_KEY = preload("res://assets/typecast/Logo/Base Key Variant 5.png")
const KEY_INK = Color("514f43")

static func key_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = WORN_KEY
	style.modulate_color = tint
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(edge, 7)
		style.set_content_margin(edge, 12 if edge in [SIDE_LEFT, SIDE_RIGHT] else 8)
	return style

static func apply_buttons(theme: Theme):
	theme.set_stylebox("normal", "Button", key_style())
	theme.set_stylebox("hover", "Button", key_style(Color("fff3cb")))
	theme.set_stylebox("pressed", "Button", key_style(Color("abd4ca")))
	theme.set_stylebox("disabled", "Button", key_style(Color("a5aa9e")))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", KEY_INK)
	theme.set_color("font_disabled_color", "Button", Color("62675c"))

static func apply_shortcut(label: Label):
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(36, 36)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", KEY_INK)
	var style = key_style()
	style.texture = KEY
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(edge, 5)
	label.add_theme_stylebox_override("normal", style)

static func add_menu_art(control: Control):
	var background = control.get_node("Background")
	if background.has_node("AuthoredGrass"):
		return
	var grass = TextureRect.new()
	grass.name = "AuthoredGrass"
	grass.texture = preload("res://assets/typecast/Level Tiles/Grass Tile 3.png")
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.modulate = Color(0.3, 0.36, 0.3)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(grass)
	grass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mascot = TextureRect.new()
	mascot.name = "RestingSlime"
	mascot.texture = preload("res://assets/typecast/Slime Enemies/Slime boi 1 flower sleep.png")
	mascot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.custom_minimum_size = Vector2(0, 38)
	control.get_node("MenuPanel/VBoxContainer").add_child(mascot)
