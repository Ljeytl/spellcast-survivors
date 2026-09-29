extends Control

const MODEL = preload("res://scripts/StyleScore.gd")
const COLORS = [Color("a8b3ae"), Color("8ccf89"), Color("4ac8bc"), Color("6edafa"), Color("999bff"), Color("d399ff"), Color("e6a0ff"), Color("f4c879"), Color("ffe49b")]
var session: Node
var glyphs: Array[Texture2D] = []
var fills: Array[Texture2D] = []
var trough = preload("res://assets/ui/style-runes/meter_trough.tres")
var message = ""
var message_until = 0.0
var label: Label
var score_label: Label
var note: Label
var meter: TextureProgressBar
var badge: TextureRect
var rank_tween: Tween
var compact = false
var special: Label
var seal: TextureRect

func _ready():
	name = "StyleHUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank in MODEL.RANKS:
		glyphs.append(load("res://assets/ui/style-runes/rank_%s.tres" % rank.to_lower()))
	for fill in ["teal", "cyan", "blue_violet", "violet", "gold"]:
		fills.append(load("res://assets/ui/style-runes/fill_%s.tres" % fill))
	badge = TextureRect.new()
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(badge)
	meter = TextureProgressBar.new()
	meter.texture_under = trough
	meter.max_value = 1.0
	meter.step = 0.001
	meter.nine_patch_stretch = true
	add_child(meter)
	label = make_label(18)
	score_label = make_label(18)
	note = make_label(14)
	special = make_label(15)
	seal = TextureRect.new()
	seal.texture = preload("res://assets/ui/style-runes/spell_ready.tres")
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(seal)
	session.updated.connect(refresh)
	session.feedback.connect(on_feedback)
	get_parent().resized.connect(refresh)
	refresh()

func make_label(font_size: int) -> Label:
	var result = Label.new()
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.03, 0.95))
	result.add_theme_constant_override("shadow_offset_x", 2)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

func on_feedback(text: String, _promoted: bool):
	message = text
	message_until = session.clock + 1.5
	refresh()
	if _promoted and not session.game.particle_manager.reduced_effects:
		if rank_tween:
			rank_tween.kill()
		badge.pivot_offset = badge.size / 2.0
		badge.scale = Vector2.ONE * 1.14
		rank_tween = create_tween()
		rank_tween.tween_property(badge, "scale", Vector2.ONE, 0.22)

func refresh():
	if not is_instance_valid(badge):
		return
	compact = get_parent().size.x < 700
	var width = 176.0 if compact else 256.0
	size = Vector2(width, 138)
	position = Vector2(get_parent().size.x - width - 18, session.game.timer_panel.get_rect().end.y + 10)
	var rank = session.score.rank_index()
	badge.texture = glyphs[rank]
	badge.position = Vector2(-4, -5)
	badge.size = Vector2(72, 78) if compact else Vector2(96, 96)
	label.position = Vector2(60 if compact else 88, 5)
	label.size = Vector2(width - label.position.x, 26)
	label.text = "%s  ×%s" % [MODEL.RANKS[rank], str(session.score.multiplier())]
	label.modulate = COLORS[rank]
	score_label.position = Vector2(label.position.x, 32)
	score_label.size = Vector2(label.size.x, 28)
	score_label.add_theme_font_size_override("font_size", 16 if compact else 18)
	score_label.text = "SCORE %s" % format_score(session.score.run_score)
	meter.position = Vector2(0, 70)
	meter.size = Vector2(width, 28)
	meter.texture_progress = fills[0 if rank < 3 else 1 if rank == 3 else 2 if rank == 4 else 3 if rank < 7 else 4]
	meter.value = session.score.progress()
	note.position = Vector2(0, 103)
	note.size = Vector2(width, 24)
	note.text = message if session.clock < message_until else "COMBO %d" % int(session.score.combo) if session.score.combo > 0 else ""
	note.modulate = COLORS[rank]
	special.position = Vector2(0, 127)
	special.size = Vector2(width, 42)
	special.text = "ATOMIC\n1,500 combo" if session.atomic_available() else ""
	special.modulate = Color("ffe49b")
	seal.visible = session.atomic_available()
	seal.position = Vector2(width - 144, 124)
	seal.size = Vector2(44, 44)
	for child in get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func format_score(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (value / 1000.0)
	return str(value)
