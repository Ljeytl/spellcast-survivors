extends VBoxContainer
## End-of-run damage chart. One bar per spell (total damage, including the DoTs it applied), then one
## bar per damage-over-time effect across all spells. Arrow keys or the mouse select a bar; the line
## underneath shows its detail (casts, per cast, kills, DoT parts; or which spells fed an effect).
## Raw/elemental split is tracked by telemetry but deliberately not shown here.

const SPELL_DAMAGE = preload("res://scripts/engine/SpellDamage.gd")
const TYPE_CHART = preload("res://scripts/engine/TypeChart.gd")
const RECIPES = preload("res://scripts/SynergyCatalog.gd").RECIPES
const PAPER = Color("eee8d8")
const MUTED = Color("8f9a86")
const EFFECT_COLORS = {"bleed": Color("d0564e"), "hemorrhage": Color("a83a3a"), "burn": Color("ff9a5a"), "poison": Color("a8c46a"), "frostbite": Color("8ce6ee"), "overload": Color("b58cff"), "thaw": Color("8ce6ee"), "toxic flare": Color("a8c46a"), "shock arc": Color("f4ed96")}

var detail: Label
var rows: Array[Control] = []

## style = StyleSession.finish() result: damage_by_spell, damage_by_effect, kills_by_spell, casts_by_spell.
func populate(style: Dictionary) -> bool:
	for child in get_children():
		child.queue_free()
	rows.clear()
	var totals: Dictionary = style.get("damage_by_spell", {})
	var effects: Dictionary = style.get("damage_by_effect", {})
	var kills: Dictionary = style.get("kills_by_spell", {})
	var casts: Dictionary = style.get("casts_by_spell", {})
	var grand = 0.0
	for value in totals.values():
		grand += float(value)
	if grand <= 0.0:
		return false
	add_theme_constant_override("separation", 6)
	add_heading("DAMAGE BY SPELL")
	var ids = totals.keys()
	ids.sort_custom(func(a, b): return float(totals[a]) > float(totals[b]))
	var top = float(totals[ids[0]])
	for id in ids:
		var amount = float(totals[id])
		if amount < 1.0:
			continue
		add_row(spell_name(id), amount, top, spell_color(id), spell_detail(id, amount, grand, effects.get(id, {}), int(kills.get(id, 0)), int(casts.get(id, 0))))
	# Effects across all spells: total bleed, burn, poison…
	var by_effect := {}
	for id in effects:
		for via in effects[id]:
			if not by_effect.has(via):
				by_effect[via] = {}
			by_effect[via][id] = float(effects[id][via])
	if not by_effect.is_empty():
		add_heading("DAMAGE OVER TIME & REACTIONS")
		var names = by_effect.keys()
		names.sort_custom(func(a, b): return sum(by_effect[a]) > sum(by_effect[b]))
		for via in names:
			var amount = sum(by_effect[via])
			if amount >= 1.0:
				add_row(str(via).capitalize(), amount, top, EFFECT_COLORS.get(via, MUTED), effect_detail(str(via), by_effect[via]))
	detail = Label.new()
	detail.name = "DamageDetail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", MUTED)
	detail.text = "Arrow keys or hover a bar for details."
	add_child(detail)
	for i in rows.size():
		if i > 0:
			rows[i].focus_neighbor_top = rows[i].get_path_to(rows[i - 1])
		if i < rows.size() - 1:
			rows[i].focus_neighbor_bottom = rows[i].get_path_to(rows[i + 1])
	return true

static func sum(values: Dictionary) -> float:
	var total = 0.0
	for v in values.values():
		total += float(v)
	return total

func add_heading(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("dfbd76"))
	add_child(label)

func add_row(title: String, amount: float, top: float, color: Color, info: String):
	var row = Button.new()
	row.name = "DamageRow_" + title.replace(" ", "_").replace("/", "_")
	row.flat = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size.y = 30
	row.set_meta("detail", info)
	var line = HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 10)
	row.add_child(line)
	var name_label = Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 150
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", PAPER)
	line.add_child(name_label)
	var track = Control.new()
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(track)
	var bar = ColorRect.new()
	bar.name = "Bar"
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(bar)
	var ratio = clampf(amount / maxf(top, 1.0), 0.0, 1.0)
	track.resized.connect(func():
		bar.position = Vector2(0, track.size.y * 0.2)
		bar.size = Vector2(maxf(3.0, track.size.x * ratio), track.size.y * 0.6))
	var value = Label.new()
	value.text = group_digits(int(round(amount)))
	value.custom_minimum_size.x = 70
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", PAPER)
	line.add_child(value)
	row.focus_entered.connect(show_detail.bind(row))
	row.mouse_entered.connect(show_detail.bind(row))
	add_child(row)
	rows.append(row)

func show_detail(row: Control):
	if is_instance_valid(detail):
		detail.text = str(row.get_meta("detail", ""))
		detail.add_theme_color_override("font_color", PAPER)

func spell_detail(id: String, amount: float, grand: float, parts: Dictionary, kills: int, casts: int) -> String:
	var bits: Array[String] = ["%s: %s damage (%d%% of total)" % [spell_name(id), group_digits(int(round(amount))), int(round(100.0 * amount / grand))]]
	if casts > 0:
		bits.append("cast %d times · %s per cast" % [casts, group_digits(int(round(amount / casts)))])
	if kills > 0:
		bits.append("%d kills" % kills)
	var vias = parts.keys()
	vias.sort_custom(func(a, b): return float(parts[a]) > float(parts[b]))
	for via in vias:
		if float(parts[via]) >= 1.0:
			bits.append("%s %s" % [via, group_digits(int(round(float(parts[via]))))])
	return " · ".join(bits)

func effect_detail(via: String, by_spell: Dictionary) -> String:
	var ids = by_spell.keys()
	ids.sort_custom(func(a, b): return float(by_spell[a]) > float(by_spell[b]))
	var bits: Array[String] = ["%s: %s total" % [via.capitalize(), group_digits(int(round(sum(by_spell))))]]
	for id in ids:
		bits.append("%s %s" % [spell_name(id), group_digits(int(round(float(by_spell[id]))))])
	return " · ".join(bits)

func spell_name(id: String) -> String:
	var fixed = {"mana_bolt": "Magic Missile", "atomic": "Atomic", "other": "Other"}
	if fixed.has(id):
		return fixed[id]
	if RECIPES.has(id):
		return str(RECIPES[id].name)
	var data = get_tree().root.get_node_or_null("DataManager") if is_inside_tree() else null
	return str(data.get_spell_data(id).get("name", id)) if data else id.capitalize()

func spell_color(id: String) -> Color:
	if id in ["other", "atomic"]:
		return MUTED
	return TYPE_CHART.color(SPELL_DAMAGE.profile(id).element)

static func group_digits(n: int) -> String:
	var text = str(absi(n))
	var out = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if n < 0 else "") + text + out
