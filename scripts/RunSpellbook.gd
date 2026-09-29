extends Control

signal closed
signal cast_requested(slot: int)

var game: Node
var panel: PanelContainer
var entries: VBoxContainer
var spell_buttons: Dictionary = {}
var close_button: Button
var notice: Label
const COPY = preload("res://scripts/UpgradeCopy.gd")
const ART = preload("res://scripts/AuthoredInterface.gd")
const READABILITY = preload("res://scripts/GameplayReadability.gd")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	READABILITY.apply_theme(self)
	var shade = ColorRect.new()
	shade.color = Color(0.06, 0.1, 0.08, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", READABILITY.panel_style(READABILITY.GOLD))
	add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title = Label.new()
	title.text = "SPELLBOOK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ART.apply_heading(title, 36)
	column.add_child(title)
	notice = Label.new()
	notice.name = "CastNotice"
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color", READABILITY.GOLD)
	notice.hide()
	column.add_child(notice)
	var scroll = ScrollContainer.new()
	scroll.name = "BuildScroll"
	scroll.follow_focus = true
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 12)
	scroll.add_child(entries)
	close_button = Button.new()
	close_button.text = "BACK"
	close_button.custom_minimum_size.y = 48
	close_button.pressed.connect(close)
	column.add_child(close_button)
	get_window().size_changed.connect(layout)
	layout()
	populate()
	close_button.grab_focus()

func layout():
	READABILITY.fit_root(self)
	panel.size = Vector2(minf(760, size.x - 36), maxf(200, size.y - 48))
	panel.position = (size - panel.size) / 2

func text_row(text: String, color: Color = READABILITY.PAPER):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	entries.add_child(label)
	return label

func section(text: String):
	var label = text_row(text, READABILITY.GOLD)
	label.add_theme_font_size_override("font_size", 24)

func populate():
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	spell_buttons.clear()
	var manager = game.spell_manager
	section("Active spells · %d / 6" % manager.spells.size())
	text_row("Choose a spell, then type its incantation to cast.", READABILITY.MUTED)
	add_spell_rows(manager.spells)
	section("Combination spells · no slots")
	if manager.bonus_spells.is_empty():
		text_row("Discover combinations as you level up.", READABILITY.MUTED)
	else:
		add_spell_rows(manager.bonus_spells)
	section("Passives · %d / 6" % game.player.passive_ranks.size())
	var families = game.player.passive_ranks.keys()
	families.sort()
	for family in families:
		text_row("%s · Rank %d" % [passive_name(family), game.player.passive_ranks[family]])
	if families.is_empty():
		text_row("No passive upgrades yet.", READABILITY.MUTED)
	section("Automatic attack")
	text_row("Magic Missile · Rank %d" % manager.get_spell_rank("mana_bolt"))

func add_spell_rows(spells: Dictionary):
	var slots = spells.keys()
	slots.sort()
	for slot in slots:
		var info = spells[slot]
		var button = Button.new()
		button.name = "Cast_" + str(info.id)
		button.text = str(info.get("name", info.get("display_name", info.id)))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 32)
		button.custom_minimum_size.y = 48
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(func(): cast_requested.emit(slot))
		entries.add_child(button)
		button.resized.connect(func(): ART.fit_words(button, button.size.x - 24))
		spell_buttons[slot] = button
		var description = COPY.EVOLUTIONS.get(info.id, COPY.SPELLS.get(info.id, ""))
		text_row("Type: %s · Rank %d\n%s" % [info.display_name, game.spell_manager.get_spell_rank(info.id), description])

func spell_name(id: String) -> String:
	var info = get_tree().root.get_node("DataManager").get_spell_data(id)
	return str(info.get("name", id.replace("_", " ").capitalize()))

func passive_name(family: String) -> String:
	return {"spell_duration": "Spell Duration", "spell_damage": "Spell Power", "movement_speed": "Movement speed", "max_health": "Max health", "xp_range": "Pickup radius", "projectile_speed": "Velocity", "slowdown_duration": "Slowdown duration", "mana_bolt": "Magic Missile mastery", "mana_bolt_mastery": "Magic Missile mastery", "spell_area": "Spell Size", "multicast": "Multicast", "xp_gain": "XP gain", "luck": "Luck", "crit_chance": "Critical chance", "crit_damage": "Critical damage", "enemy_population": "Enemy population"}.get(family, family.replace("_", " ").capitalize())

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func close():
	closed.emit()
	queue_free()

func show_notice(message: String):
	notice.text = message
	notice.show()
