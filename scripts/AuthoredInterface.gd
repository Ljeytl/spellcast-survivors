extends RefCounted

const KEY = preload("res://assets/typecast/Logo/Blank Key.png")
const WORN_KEY = preload("res://assets/typecast/Logo/Base Key Variant 5.png")
const KEY_INK = Color("514f43")
const MENU_FONT = preload("res://assets/typecast/Keys/menu-font.fnt")

static func key_style(tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = WORN_KEY
	style.modulate_color = tint
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(edge, 7)
		style.set_content_margin(edge, 12 if edge in [SIDE_LEFT, SIDE_RIGHT] else 8)
	return style

static func menu_button_style(fill: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func apply_buttons(theme: Theme):
	theme.set_font("font", "Button", MENU_FONT)
	theme.set_font("font", "CheckBox", MENU_FONT)
	theme.set_font_size("font_size", "CheckBox", 24)
	theme.set_font_size("font_size", "Button", 32)
	theme.set_stylebox("normal", "Button", menu_button_style(Color.TRANSPARENT))
	theme.set_stylebox("hover", "Button", menu_button_style(Color("314b38"), Color("dfbd76")))
	theme.set_stylebox("pressed", "Button", menu_button_style(Color("17231c"), Color("79d9e8")))
	theme.set_stylebox("disabled", "Button", menu_button_style(Color.TRANSPARENT))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(0.55, 0.55, 0.55))

static func apply_heading(label: Label, font_size: int = 36):
	label.add_theme_font_override("font", MENU_FONT)
	label.add_theme_font_size_override("font_size", maxi(32, font_size))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

static func decorate_menu(control: Control):
	for label in control.find_children("*", "Label", true, false):
		if "title" in str(label.name).to_lower():
			apply_heading(label)
		elif label.name in ["AudioLabel", "GraphicsLabel"]:
			apply_heading(label, 20)
	for button in control.find_children("*", "Button", true, false):
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

static func apply_shortcut(label: Label):
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(28, 28)
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
