extends Control

signal closed

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = ColorRect.new()
	background.color = Color(0.1, 0.08, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 32)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title = Label.new()
	title.name = "CollectionTitle"
	title.text = "SPELL COLLECTION"
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)
	var summary = Label.new()
	summary.text = "Discovered recipes stay here. Earn each spell again during a new run."
	summary.add_theme_font_size_override("font_size", 24)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 24)
	scroll.add_child(entries)
	var count = 0
	for id in preload("res://scripts/SynergyCatalog.gd").RECIPES:
		if id not in CharacterManager.discovered_synergies:
			continue
		count += 1
		var recipe = preload("res://scripts/SynergyCatalog.gd").RECIPES[id]
		var entry = Label.new()
		entry.add_theme_font_size_override("font_size", 24)
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.text = recipe.name + "\n\n" + recipe.requirements + "\n\n" + recipe.description + "\n\nCast: Space → " + recipe.incantation + " → Enter"
		entries.add_child(entry)
	if count == 0:
		var empty = Label.new()
		empty.add_theme_font_size_override("font_size", 24)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.text = "No synergies discovered yet.\nExperiment with learned spells and watch your level-up choices."
		entries.add_child(empty)
	var back = Button.new()
	back.text = "BACK"
	back.add_theme_font_size_override("font_size", 24)
	back.custom_minimum_size.y = 50
	back.pressed.connect(close_collection)
	column.add_child(back)
	back.grab_focus()
	get_window().size_changed.connect(update_typography)
	update_typography.call_deferred()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_collection()

func close_collection():
	closed.emit()
	queue_free()

func update_typography():
	var scale_factor = float(get_window().size.x) / maxf(1.0, get_viewport_rect().size.x)
	for label in find_children("*", "Label", true, false):
		var pixels = 24.0 if label.name == "CollectionTitle" else 16.0
		label.add_theme_font_size_override("font_size", ceili(pixels / maxf(0.1, scale_factor)))
	for button in find_children("*", "Button", true, false):
		button.add_theme_font_size_override("font_size", ceili(16.0 / maxf(0.1, scale_factor)))
