extends Control

signal closed

const COPY = preload("res://scripts/UpgradeCopy.gd")
const ART = preload("res://scripts/AuthoredInterface.gd")
const READABILITY = preload("res://scripts/GameplayReadability.gd")
const PREVIEW = preload("res://scripts/SpellBookPreview.gd")
static var RECIPES: Dictionary = preload("res://scripts/SynergyCatalog.gd").RECIPES  # data/recipes.json
const KEYWORD_CATALOG = preload("res://scripts/KeywordCatalog.gd")
const TYPE_CHART = preload("res://scripts/engine/TypeChart.gd")
const SPELL_DAMAGE = preload("res://scripts/engine/SpellDamage.gd")

var entries: VBoxContainer
var catalog_ids: Array[String] = []
var keyword_ids: Array[String] = []
var back: Button
# Pages (playtest: the keyword section was one wall). Every card is built once; a tab shows one page.
const PAGES := [["spells", "SPELLS"], ["shape", "SHAPE WORDS"], ["flight", "FLIGHT & HIT WORDS"], ["element", "ELEMENT WORDS"], ["special", "SPECIAL WORDS"], ["chart", "ELEMENT CHART"]]
const PAGE_OF_CATEGORY := {"tier": "shape", "power": "shape", "size": "shape", "count": "shape", "twin": "shape", "arrangement": "shape",
	"motion": "flight", "duration": "flight", "timing": "flight", "contact": "flight", "force": "flight", "target": "flight",
	"self": "special", "sacrifice": "special", "wild": "special", "payoff": "special"}
var _page := "spells"
var page_buttons := {}
var current_page := "spells"

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
	summary.text = "All keywords, spells & combinations. Prepare up to six spells at the Woodland doorway before a run."
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 20)
	column.add_child(summary)
	var tabs = HFlowContainer.new()
	tabs.name = "PageTabs"
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 6)
	column.add_child(tabs)
	for pg in PAGES:
		var b = Button.new()
		b.name = "Page_" + str(pg[0])
		b.text = str(pg[1])
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		var id: String = pg[0]
		b.pressed.connect(func(): show_page(id))
		tabs.add_child(b)
		page_buttons[id] = b
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
	show_page("spells")
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
	_page = "shape"
	add_heading("KEYWORDS")
	add_note("Say keywords before a spell name, in any order: \"fiery double bolt\". Words of different kinds combine; more words of one kind add less each. If a word can't change that spell, its rune cracks and the spell casts without it. Not accepted by Magic Missile or Atomic.")
	# Generated from data/keywords.json (KeywordCatalog): one card per kind of word, then one per element.
	for cat in KEYWORD_CATALOG.categories():
		_page = str(PAGE_OF_CATEGORY.get(str(cat.id), "special"))
		for word in cat.words:
			keyword_ids.append(word)
		var first: String = cat.words[0]
		var lines: Array = cat.words.map(func(w): return KEYWORD_CATALOG.word_line(w))
		add_entry("keyword_" + str(cat.id), str(cat.name).to_upper(), "for example %s bolt" % first,
			str(cat.promise) + "\n" + "\n".join(lines),
			"Keyword · always available · no slot", false)
	_page = "element"
	add_note(KEYWORD_CATALOG.element_promise())
	for group in KEYWORD_CATALOG.elements():
		for word in group.words:
			keyword_ids.append(word)
		var lines: Array = group.words.map(func(w): return KEYWORD_CATALOG.word_line(w))
		add_entry("keyword_" + str(group.element), "%s WORDS" % str(group.name).to_upper(), "for example %s bolt" % group.words[0],
			"\n".join(lines), "Element keyword · always available · no slot", false)
	_page = "spells"
	add_heading("SPELLS & COMBINATIONS")
	for id in load("res://scripts/SpellManager.gd").BASE_SPELL_IDS:
		var data = get_tree().root.get_node("DataManager").get_spell_data(id)
		add_entry(id, data.name, data.get("incantation", id.replace("_", " ")), with_element(id, COPY.SPELLS.get(id, "")), "Default starter · prepare it in the Woodland doorway" if id == "bolt" else "Prepare it in the Woodland doorway")
	add_entry("mana_bolt", "Magic Missile", "", with_element("mana_bolt", "Automatically fires at nearby enemies."), "Automatic · no active slot")
	var discoveries = get_tree().root.get_node("CharacterManager").discovered_synergies
	for id in RECIPES:
		var recipe = RECIPES[id]
		if not recipe.get("enabled", true):
			continue
		var ingredients: Array[String] = []
		for ingredient in recipe.ingredients:
			ingredients.append(ingredient_name(ingredient))
		var status = "Discovered" if id in discoveries else "Undiscovered"
		add_entry(id, recipe.name, recipe.incantation, with_element(id, COPY.EVOLUTIONS.get(id, "")), "%s · Bonus spell · no active slot\n%s\nReach rank 8 in both ingredients, then choose this combination." % [status, " + ".join(ingredients)])
	_page = "chart"
	add_element_chart()
	# The page notes: one line on each keyword page so it reads on its own.
	for pg in ["flight", "special"]:
		var tip = Label.new()
		tip.text = "Say keywords before a spell name, in any order: \"swift piercing bolt\"."
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.add_theme_font_size_override("font_size", 20)
		tip.set_meta("page", pg)
		entries.add_child(tip)
		entries.move_child(tip, 0)

## Shows one page of the book; arrow keys left / right flip pages.
func show_page(id: String):
	current_page = id
	for child in entries.get_children():
		child.visible = str(child.get_meta("page", "spells")) == id
	for pid in page_buttons:
		page_buttons[pid].button_pressed = pid == id
	var scroll = find_child("CatalogScroll", true, false) as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0

## Element chart (doc 18 §6.5): six elements in a cycle, each +25% against the next, -25% against itself.
func add_element_chart():
	add_heading("ELEMENTS")
	add_note("Every spell has an element. Against an enemy of the element it beats, it deals +25%. Against an enemy of its own element, -25%. Everything else is normal. Woodland enemies have no element; Frost elites are Water/Ice. Elemental enemies arrive in later realms.")
	for element in TYPE_CHART.CYCLE:
		add_note(TYPE_CHART.matchup_line(element), TYPE_CHART.color(element))
	add_note(TYPE_CHART.matchup_line("arcane") + ". Arcane also partly pierces armoured enemies.", TYPE_CHART.color("arcane"))
	add_note("Damage is part raw (the spell's weight) and part elemental. Enemies resist each type separately. Bleed is its own type.")

func add_note(text: String, color: Color = READABILITY.PAPER):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.set_meta("page", _page)
	entries.add_child(label)

func with_element(id: String, description: String) -> String:
	var element = SPELL_DAMAGE.describe(id)
	return description if element.is_empty() else description + "\n" + element

func add_heading(text: String):
	var label = Label.new()
	label.name = "Heading_" + text.to_lower().replace(" ", "_").replace("&", "and")
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", READABILITY.GOLD)
	label.set_meta("page", _page)
	entries.add_child(label)

func add_entry(id: String, spell_name: String, incantation: String, description: String, status: String, spell: bool = true):
	if spell:
		catalog_ids.append(id)
	var card = PanelContainer.new()
	card.name = "Entry_" + id
	card.add_theme_stylebox_override("panel", READABILITY.panel_style(READABILITY.GOLD))
	card.set_meta("page", _page)
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
	heading.resized.connect(func(): ART.fit_words(heading, heading.size.x))
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
		if event.keycode in [KEY_LEFT, KEY_RIGHT]:
			var ids: Array = PAGES.map(func(pg): return pg[0])
			var i = ids.find(current_page)
			show_page(ids[posmod(i + (1 if event.keycode == KEY_RIGHT else -1), ids.size())])
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
	var heading = find_child("CollectionTitle", true, false)
	if heading:
		heading.add_theme_font_size_override("font_size", mini(36, int((size.x - 48) / 14.0)))

func ingredient_name(id: String) -> String:
	var data = get_tree().root.get_node("DataManager").get_spell_data(id)
	return str(data.get("name", id.replace("_", " ").capitalize()))
