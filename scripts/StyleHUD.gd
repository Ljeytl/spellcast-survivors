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
var rail: TextureRect
var endcap: TextureRect
var pulse_kind := ""
var pulse_count := 0
var pulse_tween: Tween
var keyword_stamp: Label
var keyword_tween: Tween

func _ready():
	name = "StyleHUD"
	keyword_stamp = make_label(14)
	keyword_stamp.modulate = Color("ffe49b")
	keyword_stamp.hide()
	session.keyword_awarded.connect(on_keyword_awarded)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank in MODEL.RANKS:
		glyphs.append(load("res://assets/ui/style-runes/rank_%s.tres" % rank.to_lower()))
	for fill in ["teal", "cyan", "blue_violet", "violet", "gold"]:
		fills.append(load("res://assets/ui/style-runes/fill_%s.tres" % fill))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	badge = TextureRect.new()
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(badge)
	meter = TextureProgressBar.new()
	meter.texture_under = atlas_region(Rect2(785, 676, 206, 38))
	meter.max_value = 1.0
	meter.step = 0.001
	meter.nine_patch_stretch = true
	add_child(meter)
	rail = make_texture(atlas_region(Rect2(233, 642, 284, 110)))
	endcap = make_texture(atlas_region(Rect2(616, 608, 104, 174)))
	move_child(badge, get_child_count() - 1)
	label = make_label(18)
	score_label = make_label(14)
	score_label.name = "RunScore"
	remove_child(score_label)
	get_parent().add_child(score_label)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	score_label.modulate = Color("b8c5aa")
	note = make_label(14)
	special = make_label(15)
	seal = TextureRect.new()
	seal.texture = preload("res://assets/ui/style-runes/spell_ready.tres")
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(seal)
	session.updated.connect(refresh)
	session.style_event.connect(on_style_event)
	get_parent().resized.connect(refresh)
	refresh()

func atlas_region(region: Rect2) -> AtlasTexture:
	var texture = AtlasTexture.new()
	texture.atlas = preload("res://assets/ui/style-runes/style-runes-v1.png")
	texture.region = region
	return texture

func make_texture(texture: Texture2D) -> TextureRect:
	var sprite = TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sprite)
	return sprite

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

func show_cast_fizzle():
	on_keyword_awarded("", 1.0)
	keyword_stamp.text = "No target"
	keyword_stamp.modulate = Color("ff8175")

func on_keyword_awarded(word: String, multiplier: float):
	keyword_stamp.modulate = Color("ffe49b")
	keyword_stamp.text = "%s ×%.1f" % [word, multiplier]
	keyword_stamp.show()
	keyword_stamp.modulate.a = 1.0
	if keyword_tween:
		keyword_tween.kill()
	keyword_tween = create_tween()
	keyword_tween.tween_interval(0.4)
	keyword_tween.tween_property(keyword_stamp, "modulate:a", 0.0, 0.2)
	keyword_tween.tween_callback(keyword_stamp.hide)

func on_style_event(kind: String, amount: float, promoted: bool):
	if kind == "gain" and amount <= 0.0:
		return
	pulse_kind = kind
	pulse_count += 1
	if pulse_tween:
		pulse_tween.kill()
	var color = Color("ff8175") if kind == "hit" else Color("ffe49b") if promoted or kind == "atomic" else Color("79d9e8")
	meter.modulate = color
	rail.modulate = color
	note.modulate = color
	pulse_tween = create_tween().set_parallel(true)
	for item in [meter, rail, note]:
		pulse_tween.tween_property(item, "modulate", Color.WHITE, 0.30 if kind == "hit" else 0.22)
	if not session.game.particle_manager.reduced_effects:
		if rank_tween:
			rank_tween.kill()
		badge.pivot_offset = badge.size / 2.0
		badge.scale = Vector2.ONE * (1.14 if promoted else 0.90 if kind == "hit" else 1.04)
		rank_tween = create_tween()
		rank_tween.tween_property(badge, "scale", Vector2.ONE, 0.22)
	refresh()

func refresh():
	if not is_instance_valid(badge):
		return
	compact = get_parent().size.x < 700
	var width = 208.0 if compact else 316.0
	var top = session.game.timer_panel.get_rect().end.y + 10
	if compact:
		top = maxf(top, get_parent().get_node("StatsPanel").get_rect().end.y + 14)
	position = Vector2(get_parent().size.x - width - 18, top)
	var rank = session.score.rank_index()
	var badge_size = 76.0 if compact else 104.0
	var bar_x = badge_size * 0.70
	var bar_width = width - bar_x - 16.0
	var bar_y = badge_size * 0.5 - 13.0
	badge.texture = glyphs[rank]
	badge.position = Vector2(-5, -4)
	badge.size = Vector2.ONE * badge_size
	rail.position = Vector2(bar_x, bar_y - 9)
	rail.size = Vector2(bar_width, 44)
	endcap.position = Vector2(width - 19, bar_y - 13)
	endcap.size = Vector2(23, 52)
	meter.position = Vector2(bar_x, bar_y)
	meter.size = Vector2(bar_width, 26)
	var fill_index = 0 if rank < 3 else 1 if rank == 3 else 2 if rank == 4 else 3 if rank < 7 else 4
	var fill_regions = [Rect2(1062, 678, 176, 27), Rect2(1318, 678, 177, 27), Rect2(53, 869, 176, 27), Rect2(310, 869, 175, 27), Rect2(566, 869, 175, 27)]
	if meter.get_meta("fill_index", -1) != fill_index:
		meter.texture_progress = atlas_region(fill_regions[fill_index])
		meter.set_meta("fill_index", fill_index)
	meter.tint_progress = Color(0.55, 0.62, 0.6) if rank == 0 else Color(0.65, 0.85, 0.65) if rank == 1 else Color.WHITE
	meter.value = session.score.progress()
	label.position = Vector2(bar_x + 8, bar_y - 34)
	label.size = Vector2(bar_width - 8, 24)
	label.add_theme_font_size_override("font_size", 14 if compact else 17)
	label.text = "×%s" % str(session.score.multiplier())
	label.modulate = COLORS[rank]
	var stats = get_parent().get_node("StatsPanel")
	score_label.position = Vector2(stats.position.x + 6, stats.get_rect().end.y + 5)
	score_label.size = Vector2(minf(stats.size.x, maxf(0, position.x - score_label.position.x - 12)) if compact else stats.size.x, 22)
	score_label.text = "Score %d" % session.score.run_score
	note.position = Vector2(bar_x, bar_y + 33)
	note.size = Vector2(bar_width, 22)
	note.text = "COMBO %s" % format_score(session.score.combo_score)
	keyword_stamp.position = Vector2(0, note.position.y + 24)
	keyword_stamp.size = Vector2(width, 20)
	special.position = Vector2(0, note.position.y + note.size.y + 28)
	special.size = Vector2(width, 42)
	# Charge pips: lit when castable (S or better), dim while banked below S.
	var charges = session.score.atomic_charges
	special.text = ("ATOMIC " + "●".repeat(charges) + "○".repeat(session.Score.ATOMIC_MAX_CHARGES - charges)) if charges > 0 else ""
	special.modulate.a = 1.0 if session.atomic_available() else 0.45
	special.modulate = Color("ffe49b")
	seal.visible = session.atomic_available()
	seal.position = Vector2(width - 150, special.position.y - 3)
	seal.size = Vector2(44, 44)
	size = Vector2(width, special.position.y + special.size.y)
	for child in get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func format_score(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (value / 1000.0)
	return str(value)
