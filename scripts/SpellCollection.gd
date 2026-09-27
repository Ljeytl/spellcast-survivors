extends Control

signal closed

const COPY = preload("res://scripts/UpgradeCopy.gd")
const ART = preload("res://scripts/AuthoredInterface.gd")
const READABILITY = preload("res://scripts/GameplayReadability.gd")
const PREVIEW = preload("res://scripts/SpellBookPreview.gd")
const RECIPES = preload("res://scripts/SynergyCatalog.gd").RECIPES

var entries: VBoxContainer
var catalog_ids: Array[String] = []
var back: Button

func _ready():
	READABILITY.apply_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = ColorRect.new()
	background.color = READABILITY.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title = Label.new()
	title.name = "CollectionTitle"
	title.text = "NECRONOMICON"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ART.apply_heading(title, 36)
	column.add_child(title)
	var summary = Label.new()
	summary.text = "All spells & combinations. Learn spells during a run to cast them."
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 20)
	column.add_child(summary)
	var scroll = ScrollContainer.new()
	scroll.name = "CatalogScroll"
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 16)
	scroll.add_child(entries)
	populate()
	back = Button.new()
	back.text = "BACK"
	back.add_theme_font_size_override("font_size", 32)
	back.custom_minimum_size.y = 50
	back.pressed.connect(close_collection)
	column.add_child(back)
	scroll.grab_focus.call_deferred()
	get_window().size_changed.connect(update_typography)
	update_typography.call_deferred()

func populate():
	for id in load("res://scripts/SpellManager.gd").BASE_SPELL_IDS:
		var data = get_tree().root.get_node("DataManager").get_spell_data(id)
		add_entry(id, data.name, data.get("incantation", id.replace("_", " ")), COPY.SPELLS.get(id, ""), "Starting spell" if id == "bolt" else "Learn during a run")
	add_entry("mana_bolt", "Mana Bolt", "", "Automatically fires at nearby enemies.", "Automatic · no active slot")
	var discoveries = get_tree().root.get_node("CharacterManager").discovered_synergies
	for id in RECIPES:
		var recipe = RECIPES[id]
		if not recipe.get("enabled", true):
			continue
		var ingredients: Array[String] = []
		for ingredient in recipe.ingredients:
			ingredients.append(ingredient_name(ingredient))
		var status = "Discovered" if id in discoveries else "Undiscovered"
		add_entry(id, recipe.name, recipe.incantation, COPY.EVOLUTIONS.get(id, ""), "%s · Bonus spell · no active slot\n%s\nLearn both ingredients, then choose this combination." % [status, " + ".join(ingredients)])

func add_entry(id: String, spell_name: String, incantation: String, description: String, status: String):
	catalog_ids.append(id)
	var card = PanelContainer.new()
	card.name = "Entry_" + id
	card.add_theme_stylebox_override("panel", READABILITY.panel_style(READABILITY.GOLD))
	entries.add_child(card)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var preview = PREVIEW.new()
	preview.spell_id = id
	preview.custom_minimum_size = Vector2(80, 80)
	row.add_child(preview)
	var text = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var heading = Label.new()
	heading.text = spell_name
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ART.apply_heading(heading, 28)
	text.add_child(heading)
	for line in [description, ("Type: " + incantation) if not incantation.is_empty() else "", status]:
		if line.is_empty():
			continue
		var label = Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 20)
		text.add_child(label)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		var scroll = find_child("CatalogScroll", true, false) as ScrollContainer
		var amount = 0
		match event.keycode:
			KEY_DOWN: amount = 60
			KEY_UP: amount = -60
			KEY_PAGEDOWN: amount = int(scroll.size.y * 0.85)
			KEY_PAGEUP: amount = -int(scroll.size.y * 0.85)
			KEY_HOME: amount = -int(scroll.get_v_scroll_bar().max_value)
			KEY_END: amount = int(scroll.get_v_scroll_bar().max_value)
		if amount != 0:
			scroll.scroll_vertical += amount
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_collection()

func close_collection():
	closed.emit()
	queue_free()

func update_typography():
	if get_parent() is Control:
		scale = Vector2.ONE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		READABILITY.fit_root(self)

func ingredient_name(id: String) -> String:
	var data = get_tree().root.get_node("DataManager").get_spell_data(id)
	return str(data.get("name", id.replace("_", " ").capitalize()))
