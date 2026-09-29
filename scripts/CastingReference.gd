extends HFlowContainer

const STYLE = preload("res://scripts/GameplayReadability.gd")
var game: Node
var signature = ""
var entries: Dictionary = {}
var extensions: Dictionary = {}

func _ready():
	name = "CastingReference"
	game.spell_manager.spell_extended.connect(func(id, seconds): extensions[id] = {"seconds": seconds, "until": Time.get_ticks_msec() + 1200})
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = FlowContainer.ALIGNMENT_CENTER
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 4)

func _process(_delta):
	var manager = game.spell_manager
	var next = ""
	for slot in manager.get_all_spells():
		var info = manager.get_spell_info(slot)
		next += str(slot) + ":" + str(info.id) + ":" + str(info.display_name)
	if next != signature:
		signature = next
		rebuild()
	var states = preload("res://scripts/SpellDurationStatus.gd").collect(manager)
	for id in entries:
		var entry = entries[id]
		var caption = ""
		if states.has(id):
			caption = preload("res://scripts/SpellDurationStatus.gd").caption(states[id])
			if extensions.has(id) and Time.get_ticks_msec() < extensions[id].until:
				caption += " · +%ds" % ceili(extensions[id].seconds)
		entry.text = entry.get_meta("incantation") + ("\n" + caption if not caption.is_empty() else "")
		entry.tooltip_text = "Charges ready; time until the next charge expires" if id == "earth_shield" and states.has(id) else ("Longest remaining cast; × shows active casts" if states.has(id) and states[id].count > 1 else "")
	size.x = minf(1160, game.hud.size.x - 36)
	size.y = get_combined_minimum_size().y
	position = Vector2((game.hud.size.x - size.x) / 2, game.hud.size.y - size.y - 34)
	visible = not game.interface_debug and game.current_state == game.GameState.PLAYING
	if manager.is_typing and game.hud.get_node("TypingPanel").get_global_rect().intersects(get_global_rect()):
		visible = false

func rebuild():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	entries.clear()
	var manager = game.spell_manager
	for slot in manager.get_all_spells():
		var info = manager.get_spell_info(slot)
		var combination = manager.bonus_spells.has(slot)
		var label = Label.new()
		label.name = "Cast_" + str(info.id)
		label.text = str(info.display_name) if combination else "%d  %s" % [slot, info.display_name]
		label.set_meta("incantation", label.text)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", STYLE.GOLD if combination else STYLE.PAPER)
		var style = STYLE.panel_style(STYLE.GOLD if combination else Color("66705b"), Color("17231c"))
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		style.content_margin_left = 8
		style.content_margin_right = 8
		label.add_theme_stylebox_override("normal", style)
		add_child(label)
		entries[info.id] = label
