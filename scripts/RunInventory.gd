extends VBoxContainer

const STYLE = preload("res://scripts/GameplayReadability.gd")
var game: Node
var signature = ""
var cards: Dictionary = {}

func _ready():
	name = "RunInventory"
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)

func _process(_delta):
	var manager = game.spell_manager
	var next = str(game.player.passive_ranks)
	for info in manager.get_all_spells().values():
		next += str(info.id) + ":" + str(manager.get_spell_rank(info.id))
	if next != signature:
		signature = next
		rebuild()
	for id in cards:
		var card = cards[id]
		var selected = manager.is_typing and manager.target_spell == card.get_meta("incantation", "") and not manager.target_spell.is_empty()
		var style = card.get_theme_stylebox("normal") as StyleBoxFlat
		style.border_color = Color.WHITE if selected else card.get_meta("accent")
		style.set_border_width_all(2 if selected else 1)
	var hud = game.hud
	position = Vector2(18, maxf(116, game.timer_panel.get_rect().end.y + 10) if game.timer_panel.position.y > 18 else 116)
	size.x = minf(180 if hud.size.x < 700 else 420, hud.size.x - 36)
	for card in cards.values():
		var compact = hud.size.x < 700
		card.custom_minimum_size = Vector2(40, 32) if compact else Vector2(57, 51)
		var icon = card.get_node("Icon")
		icon.size = Vector2(18, 18) if compact else Vector2(32, 32)
		icon.position = Vector2(11, 1) if compact else Vector2(3, 1)
		if icon.has_node("Glyph"):
			icon.get_node("Glyph").add_theme_font_size_override("font_size", 9 if compact else 12)
		icon.queue_redraw()
		var label = card.get_node("Rank")
		label.position = Vector2(4, 20) if compact else Vector2(11, 30)
		label.add_theme_font_size_override("font_size", 10 if compact else 12)
	visible = not game.interface_debug and game.current_state == game.GameState.PLAYING and not (manager.is_typing and hud.size.x < 700)

func rebuild():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	cards.clear()
	add_spells("SPELLS", game.spell_manager.spells, STYLE.CYAN)
	add_spells("COMBINATIONS", game.spell_manager.bonus_spells, STYLE.GOLD)
	if not game.player.passive_ranks.is_empty():
		var row = section("PASSIVES", STYLE.MUTED)
		for family in game.player.passive_ranks:
			add_card(row, family, family.replace("_", " ").capitalize(), game.player.passive_ranks[family], -1, STYLE.MUTED)

func section(title: String, color: Color) -> HFlowContainer:
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 10)
	heading.add_theme_color_override("font_color", color)
	add_child(heading)
	var row = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 3)
	row.add_theme_constant_override("v_separation", 3)
	add_child(row)
	return row

func add_spells(title: String, spells: Dictionary, color: Color):
	if spells.is_empty():
		return
	var row = section(title, color)
	for slot in spells:
		var info = spells[slot]
		add_card(row, info.id, info.name, game.spell_manager.get_spell_rank(info.id), slot, color)

func add_card(row: Control, id: String, title: String, rank: int, slot: int, color: Color):
	var button = Button.new()
	button.name = "Item_" + id
	button.custom_minimum_size = Vector2(57, 51)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", STYLE.panel_style(color, Color("17231c")))
	button.tooltip_text = "%s · Rank %d" % [title, rank]
	if slot > 0:
		button.tooltip_text += "\nClick to type %s" % game.spell_manager.get_spell_info(slot).display_name
		button.pressed.connect(func(): game.spell_manager.activate_spell_slot(slot))
		if game.spell_manager.has_method("get_combination_ingredient_ranks"):
			var ingredients = game.spell_manager.get_combination_ingredient_ranks(id)
			for ingredient in ingredients:
				button.tooltip_text += "\n%s · Rank %d" % [game.spell_manager.get_spell_info(game.spell_manager.find_spell_slot(ingredient)).get("name", ingredient), ingredients[ingredient]]
	else:
		button.mouse_default_cursor_shape = Control.CURSOR_HELP
	button.set_meta("accent", color)
	button.set_meta("incantation", game.spell_manager.get_spell_info(slot).get("display_name", "") if slot > 0 else "")
	row.add_child(button)
	var icon = preload("res://scripts/InventoryIcon.gd").new()
	icon.name = "Icon"
	icon.item_id = id
	icon.passive = slot < 0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(3, 1)
	icon.size = Vector2(32, 32)
	button.add_child(icon)
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.name = "Rank"
	label.text = "Lv.%d" % rank
	label.add_theme_font_size_override("font_size", 12)
	label.position = Vector2(11, 30)
	button.add_child(label)
	cards[id] = button
