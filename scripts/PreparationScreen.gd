extends Control
## Tower screen before a Woodland run: pick up to six spells and order them.
## Slot 1 is ready at the start; the rest open at Preparation.ACTIVATION_LEVELS.

signal confirmed
signal closed

const PREP = preload("res://scripts/Preparation.gd")
const COPY = preload("res://scripts/UpgradeCopy.gd")
const ART = preload("res://scripts/AuthoredInterface.gd")
const READABILITY = preload("res://scripts/GameplayReadability.gd")
const PREVIEW = preload("res://scripts/SpellBookPreview.gd")
const TYPE_CHART = preload("res://scripts/engine/TypeChart.gd")
const SPELL_DAMAGE = preload("res://scripts/engine/SpellDamage.gd")

var slots: Array = []
var selected_slot = 0
var slot_buttons: Array[Button] = []
var spell_buttons: Dictionary = {}
var hint: Label
var begin: Button

func _ready():
	slots = PREP.load_slots()
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
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title = Label.new()
	title.name = "PreparationTitle"
	title.text = "PREPARE YOUR SPELLBOOK"
	ART.apply_heading(title, 36)
	column.add_child(title)
	var summary = Label.new()
	summary.text = "Slot 1 is ready from the start. The rest open in order as you level up — those levels give the spell instead of a power-up."
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 20)
	column.add_child(summary)
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	column.add_child(body)
	body.add_child(build_slot_column())
	body.add_child(build_catalog())
	hint = Label.new()
	hint.name = "PreparationHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", READABILITY.MUTED)
	column.add_child(hint)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	var back = add_action(actions, "BACK", close_screen)
	back.name = "BackButton"
	begin = add_action(actions, "BEGIN RUN", begin_run)
	begin.name = "BeginButton"
	begin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refresh()
	begin.grab_focus.call_deferred()
	get_window().size_changed.connect(update_typography)
	update_typography.call_deferred()

func build_slot_column() -> Control:
	var box = VBoxContainer.new()
	box.custom_minimum_size.x = 380
	box.add_theme_constant_override("separation", 8)
	var heading = Label.new()
	heading.text = "YOUR ORDER"
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", READABILITY.GOLD)
	box.add_child(heading)
	for i in PREP.SLOTS:
		var button = Button.new()
		button.name = "Slot%d" % (i + 1)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(select_slot.bind(i))
		box.add_child(button)
		slot_buttons.append(button)
	var tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	box.add_child(tools)
	add_action(tools, "Move up", move_selected.bind(-1), 20)
	add_action(tools, "Move down", move_selected.bind(1), 20)
	add_action(tools, "Clear", clear_selected, 20)
	return box

func build_catalog() -> Control:
	var scroll = ScrollContainer.new()
	scroll.name = "SpellCatalog"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for id in PREP.base_ids():
		var button = Button.new()
		button.name = "Spell_" + id
		button.custom_minimum_size = Vector2(0, 104)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(assign_spell.bind(id))
		var row = HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 8
		row.offset_right = -8
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		button.add_child(row)
		var preview = PREVIEW.new()
		preview.spell_id = id
		preview.custom_minimum_size = Vector2(80, 80)
		preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(preview)
		var text = Label.new()
		text.name = "Copy"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 17)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.text = "%s\n%s\n%s" % [spell_name(id), COPY.SPELLS.get(id, ""), element_line(id)]
		row.add_child(text)
		text.resized.connect(fit_cards.call_deferred)
		grid.add_child(button)
		spell_buttons[id] = button
	return scroll

func add_action(parent: Control, label: String, action: Callable, font_size: int = 28) -> Button:
	var button = Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size", font_size)
	button.custom_minimum_size.y = 46
	button.pressed.connect(action)
	parent.add_child(button)
	return button

## Short card line: the element, then only what differs from a pure hit of it ("Water/Ice · 60% raw",
## "Earth/Steel · 90% raw · bleed", "Arcane").
func element_line(id: String) -> String:
	var profile = SPELL_DAMAGE.profile(id)
	var parts: Array[String] = [TYPE_CHART.display_name(profile.element)]
	if SPELL_DAMAGE.deals_damage(id):
		for kind in profile.damage:
			var share = int(round(float(profile.damage[kind]) * 100.0))
			if str(kind) == "raw":
				parts.append("%d%% raw" % share)
			elif TYPE_CHART.normalize(str(kind)) != profile.element:
				parts.append("%d%% %s" % [share, TYPE_CHART.display_name(str(kind))])
		var statuses = SPELL_DAMAGE.status_line(id)
		if not statuses.is_empty():
			parts.append(statuses)
	return "  ·  ".join(parts)

## Cards grow to fit their wrapped text.
func fit_cards():
	for id in spell_buttons:
		var copy = spell_buttons[id].find_child("Copy", true, false) as Label
		spell_buttons[id].custom_minimum_size.y = maxf(104.0, copy.get_line_count() * copy.get_line_height() + 20.0)

func spell_name(id: String) -> String:
	if id.is_empty():
		return ""
	var data = get_tree().root.get_node("DataManager").get_spell_data(id)
	return str(data.get("name", id.replace("_", " ").capitalize()))

func select_slot(index: int):
	selected_slot = index
	refresh()

## Puts the spell in the selected slot. A spell already prepared elsewhere swaps places.
func assign_spell(id: String):
	if selected_slot == 0 and not PREP.can_start(id):
		hint.text = "%s can't open — slot 1 is your only spell until level 2, so it needs to attack." % spell_name(id)
		return
	var previous = slots.find(id)
	if previous == 0 and not PREP.can_start(str(slots[selected_slot])):
		hint.text = "Slot 1 needs an attack. Put a different attack in slot 1 first."
		return
	if previous >= 0:
		slots[previous] = slots[selected_slot]
	slots[selected_slot] = id
	selected_slot = mini(selected_slot + 1, PREP.SLOTS - 1)
	refresh()

func move_selected(direction: int):
	var target = selected_slot + direction
	if target < 0 or target >= PREP.SLOTS:
		return
	var moving = str(slots[selected_slot])
	var other = str(slots[target])
	if (target == 0 and not PREP.can_start(moving)) or (selected_slot == 0 and not PREP.can_start(other)):
		hint.text = "Slot 1 needs an attack — it's your only spell until level 2."
		return
	slots[target] = moving
	slots[selected_slot] = other
	selected_slot = target
	refresh()

func clear_selected():
	if selected_slot == 0:
		hint.text = "Slot 1 can't be empty — you need something to cast."
		return
	slots[selected_slot] = ""
	refresh()

func refresh():
	for i in slot_buttons.size():
		var id = str(slots[i])
		var level = PREP.ACTIVATION_LEVELS[i]
		var when = "Start" if level == 1 else "Lv %d" % level
		slot_buttons[i].text = "%s   %s" % [when, spell_name(id) if not id.is_empty() else "— empty · power-up instead —"]
		var accent = READABILITY.GOLD if i == selected_slot else Color("66705b")
		for state in ["normal", "hover", "focus", "pressed"]:
			slot_buttons[i].add_theme_stylebox_override(state, READABILITY.panel_style(accent))
	for id in spell_buttons:
		var at = slots.find(id)
		var blocked = selected_slot == 0 and not PREP.can_start(id)
		spell_buttons[id].modulate = Color(1, 1, 1, 0.45) if blocked else Color.WHITE
		var accent = READABILITY.CYAN if at >= 0 else Color("66705b")
		for state in ["normal", "hover", "focus", "pressed"]:
			spell_buttons[id].add_theme_stylebox_override(state, READABILITY.panel_style(accent.lightened(0.25) if state in ["hover", "focus"] else accent))
		var copy = spell_buttons[id].find_child("Copy", true, false) as Label
		copy.text = "%s%s\n%s\n%s" % [spell_name(id), "   · slot %d" % (at + 1) if at >= 0 else "", COPY.SPELLS.get(id, ""), element_line(id)]
	fit_cards.call_deferred()
	hint.text = "Choose a spell for %s. Picking a spell that's already prepared swaps it." % ("slot 1 (must attack)" if selected_slot == 0 else "slot %d" % (selected_slot + 1))

func begin_run():
	PREP.save_slots(slots)
	confirmed.emit()

func close_screen():
	PREP.save_slots(slots)
	closed.emit()
	queue_free()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_screen()

func update_typography():
	if not is_inside_tree():
		return
	if get_parent() is Control:
		scale = Vector2.ONE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		READABILITY.fit_root(self)
