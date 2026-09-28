extends Control

signal extract_requested
signal continue_requested

var extract_button: Button
var continue_button: Button
var keyboard_armed_at = 0

func _ready():
	name = "ExtractionChoice"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.06, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 360
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	var title = Label.new()
	title.text = "20:00 SURVIVED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("dfbd76"))
	column.add_child(title)
	var description = Label.new()
	description.text = "Extract to bank your victory.\nContinue into endless survival.\nEnemies keep growing stronger."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	column.add_child(description)
	extract_button = Button.new()
	extract_button.name = "ExtractButton"
	extract_button.text = "EXTRACT"
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "CONTINUE"
	for button in [extract_button, continue_button]:
		button.custom_minimum_size.y = 54
		column.add_child(button)
	extract_button.pressed.connect(func(): extract_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	preload("res://scripts/BuildVersion.gd").attach(self)
	hide()

func open():
	keyboard_armed_at = Time.get_ticks_msec() + 350
	get_viewport().gui_release_focus()
	show()

func _input(event):
	if not visible or not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.keycode == KEY_TAB:
		if extract_button.has_focus():
			continue_button.grab_focus()
		else:
			extract_button.grab_focus()
		get_viewport().set_input_as_handled()
	if event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and (event.echo or Time.get_ticks_msec() < keyboard_armed_at):
		get_viewport().set_input_as_handled()
