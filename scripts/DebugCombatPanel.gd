extends CanvasLayer
## F4 debug panel: live damage per spell (last 10 s and last 60 s), run totals, kills, casts and rank,
## plus active effects, enemies alive and enemy health scaling. Reads CombatTelemetry and StyleSession.

const TOGGLE_KEY = KEY_F4
const REFRESH_SECONDS = 0.25

var telemetry: Node
var panel: PanelContainer
var label: Label
var _refresh = 0.0

func _ready():
	layer = 90
	panel = PanelContainer.new()
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -560
	panel.offset_right = -12
	panel.offset_top = 12
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.82)
	style.set_content_margin_all(10)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	label = Label.new()
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Menlo", "Consolas", "DejaVu Sans Mono", "monospace"])
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 13)
	panel.add_child(label)
	add_child(panel)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()

func _process(delta):
	if not panel.visible or not telemetry:
		return
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = REFRESH_SECONDS
	label.text = build_text()

func build_text() -> String:
	var game = telemetry.game
	var session = game.style_session
	var manager = game.spell_manager
	var t = telemetry.game_time()
	var lines: Array[String] = []
	lines.append("DEBUG  %02d:%02d  level %d  enemies %d  enemy HP ×%.2f  power ×%.2f" % [int(t) / 60, int(t) % 60, game.player.level, get_tree().get_nodes_in_group("enemies").size(), telemetry.health_multiplier(), game.player.spell_damage_multiplier])
	var flow = telemetry.recent_flow(60.0)
	lines.append("LAST 60s  avg time to kill %.1fs  kills/min %.0f  spawned/min %.0f  XP/min %.0f" % [flow.ttk, flow.kills_per_min, flow.spawned_per_min, flow.xp_per_min])
	lines.append("%-15s %4s %7s %7s %9s %6s %5s %5s" % ["SPELL", "RANK", "DPS10", "DPS60", "TOTAL", "KILLS", "CASTS", "SHARE"])
	var dps10 = telemetry.recent_dps(10.0)
	var dps60 = telemetry.recent_dps(60.0)
	var totals: Dictionary = session.damage_by_spell
	var kills: Dictionary = session.kills_by_spell
	var grand = 0.0
	for spell in totals:
		grand += float(totals[spell])
	var spells = totals.keys()
	for id in manager.get_unlocked_spell_names():
		if id not in spells:
			spells.append(id)
	spells.sort_custom(func(a, b): return float(totals.get(a, 0.0)) > float(totals.get(b, 0.0)))
	for spell in spells:
		var info = manager.spell_catalog.get(spell, {})
		var display = "Magic Missile" if spell == "mana_bolt" else str(info.get("name", spell))
		lines.append("%-15s %4s %7.0f %7.0f %9.0f %6d %5d %4.0f%%" % [display.substr(0, 15), str(manager.get_spell_rank(spell)) if spell in manager.get_unlocked_spell_names() else "-", float(dps10.get(spell, 0.0)), float(dps60.get(spell, 0.0)), float(totals.get(spell, 0.0)), int(kills.get(spell, 0)), int(telemetry.casts_by_spell.get(spell, 0)), 100.0 * float(totals.get(spell, 0.0)) / maxf(1.0, grand)])
	var active = {}
	for effect in get_tree().get_nodes_in_group("build_spell_effects"):
		if not effect.is_queued_for_deletion() and effect.get("info") is Dictionary:
			var id = str(effect.info.get("id", "?"))
			active[id] = int(active.get(id, 0)) + 1
	var hosts = 0
	for effect in get_tree().get_nodes_in_group("build_spell_effects"):
		if effect.get("infections") is Array:
			hosts += effect.infections.size()
	lines.append("ACTIVE  " + ", ".join(active.keys().map(func(k): return "%s ×%d" % [k, active[k]])) + ("  infected %d" % hosts if hosts > 0 else ""))
	lines.append("F4 hides · logs: " + (telemetry.log_path if not telemetry.log_path.is_empty() else "off (debug builds or --telemetry=path)"))
	return "\n".join(lines)
