extends Control

const KEY_SIZE = 48.0
const STRIDE = 54.0
const DROP_SECONDS = 0.13
const BLANK = preload("res://assets/typecast/Logo/Blank Key.png")
var manager: Node
var label: Label
var letters = ""
var ages: Array[float] = []
var fragments: Array[Dictionary] = []
var textures: Dictionary = {}
var last_ticks = 0
var feedback = ""
var completion_remaining = 0.0
var completion_duration = 0.28
var completed_mega := false
var completion_count := 0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label = get_parent()
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.self_modulate.a = 0
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", 1)
	last_ticks = Time.get_ticks_usec()
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		var path = "res://assets/typecast/Keys/%s.png" % letter
		textures[letter] = load(path) if ResourceLoader.exists(path) else BLANK

	for code in range(33, 127):
		var path = "res://assets/typecast/Keys/u%04x.png" % code
		if ResourceLoader.exists(path):
			textures[String.chr(code)] = load(path)

# Layout (playtest 0.3.4: long incantations must wrap). Words wrap onto up to MAX_LINES lines at
# full key size; if that is not enough the keys shrink (down to MIN_KEY) before the oldest lines
# scroll away, so the newest key is always visible. A word longer than a line breaks mid-word.
const MAX_LINES = 3
const MIN_KEY = 20.0
const LINE_GAP = 6.0
var _layout_for := ""
var _key := KEY_SIZE
var _cols := 1
var _lines: Array = []   # [start, end) index ranges, one per line
var _first_line := 0
var max_lines := MAX_LINES   # the HUD lowers this when there is no room above the casting reference
var max_inner_width := 0.0   # the widest the prompt may grow (set by the HUD); heights follow it

## Line ranges for `text` when `cols` keys fit on a line.
static func wrap_lines(text: String, cols: int) -> Array:
	var lines: Array = []
	var n := text.length()
	var line_start := 0
	var i := 0
	while i < n:
		var j := i
		while j < n and text[j] != " ":
			j += 1
		var token_end := j + (1 if j < n else 0)   # a word and the space after it
		if i > line_start and (j - line_start) > cols:
			lines.append([line_start, i])
			line_start = i
		while (j - line_start) > cols:   # a word longer than a whole line
			lines.append([line_start, line_start + cols])
			line_start += cols
		i = token_end
	if line_start < n or lines.is_empty():
		lines.append([line_start, n])
	return lines

## Key size, columns and lines that fit `width`.
static func plan(text: String, width: float, line_cap: int = MAX_LINES) -> Dictionary:
	var key := KEY_SIZE
	while true:
		var cols := maxi(1, floori((width - 16.0 + 2.0) / (key + 2.0)))
		var lines := wrap_lines(text, cols)
		if lines.size() <= line_cap or key <= MIN_KEY:
			return {"key": key, "cols": cols, "lines": lines}
		key = maxf(MIN_KEY, key - 2.0)
	return {}

func _ensure_layout() -> void:
	var stamp := "%s|%d|%d" % [letters, int(size.x), max_lines]
	if stamp == _layout_for:
		return
	_layout_for = stamp
	var p := plan(letters, size.x, max_lines)
	_key = p.key
	_cols = p.cols
	_lines = p.lines
	_first_line = maxi(0, _lines.size() - max_lines)

func columns() -> int:
	_ensure_layout()
	return _cols

func fitted_key_size() -> float:
	_ensure_layout()
	return _key

func visible_lines() -> int:
	_ensure_layout()
	return mini(_lines.size(), max_lines)

func visible_start() -> int:
	_ensure_layout()
	return int(_lines[_first_line][0]) if not _lines.is_empty() else 0

func key_position(index: int) -> Vector2:
	_ensure_layout()
	var stride := _key + 2.0
	for l in range(_lines.size()):
		var a: int = _lines[l][0]
		var b: int = _lines[l][1]
		if index >= a and index < b or (l == _lines.size() - 1 and index >= a):
			var shown := b - a
			if b > a and b - 1 < letters.length() and letters[b - 1] == " " and l < _lines.size() - 1:
				shown -= 1   # a line's trailing space does not count for centring
			var width := maxf(0, shown - 1) * stride + _key
			return Vector2((size.x - width) / 2 + (index - a) * stride, 6 + (l - _first_line) * (_key + LINE_GAP))
	return Vector2(size.x / 2, 6)

func _ends_line(index: int) -> bool:
	_ensure_layout()
	for l in range(_lines.size() - 1):
		if int(_lines[l][1]) - 1 == index:
			return true
	return false

## Width the prompt wants for this text, at most `max_width`: the longest wrapped line plus margins.
func preferred_width(max_width: float, margin: float) -> float:
	var p := plan(letters, max_width - margin, max_lines)
	var longest := 0
	for line in p.lines:
		longest = maxi(longest, int(line[1]) - int(line[0]))
	return minf(max_width, maxf(280.0, longest * (p.key + 2.0) + 16.0 + margin))

func sync(text: String, message: String):
	feedback = message
	if not manager.is_typing:
		if completion_remaining <= 0:
			clear_keys()
		return
	if completion_remaining > 0:
		completion_remaining = 0
		clear_keys()
	var common = 0
	while common < mini(letters.length(), text.length()) and letters[common] == text[common]:
		common += 1
	for index in range(letters.length() - 1, common - 1, -1):
		shatter(index)
	ages.resize(common)
	for index in range(common, text.length()):
		ages.append(0.0)
	letters = text
	update_height()
	queue_redraw()

func clear_keys():
	letters = ""
	ages.clear()
	fragments.clear()
	update_height()
	queue_redraw()

func update_height():
	# Measured against the width the prompt is about to take, not its current (stale) width, so the
	# box never flickers a row taller for one frame while it widens.
	var p := plan(letters, max_inner_width if max_inner_width > 0.0 else size.x, max_lines)
	var rows := mini(p.lines.size(), max_lines)
	var extra := (rows - 1) * (float(p.key) + LINE_GAP) - (KEY_SIZE - float(p.key))
	var height = (80.0 if not error_caption().is_empty() else 62.0) + maxf(0.0, extra)
	for piece in fragments:
		height = maxf(height, piece.floor_height)
	label.custom_minimum_size.y = height

func shatter(index: int):
	if index < visible_start():
		return
	var origin = key_position(index)
	var texture = textures.get(letters[index].to_upper(), BLANK)
	for y in range(2):
		for x in range(2):
			if fragments.size() >= 64:
				fragments.pop_front()
			fragments.append({"texture": texture, "region": Rect2(x * 16, y * 16, 16, 16), "size": fitted_key_size() / 2, "position": origin + Vector2(x, y) * (fitted_key_size() / 2), "velocity": Vector2((x * 2 - 1) * 65, -50 - y * 25), "age": 0.0, "floor_height": label.custom_minimum_size.y})

func on_manual_release(_family: String, canonical: String, typed: String):
	completed_mega = canonical.begins_with("mega ")
	if not manager.is_typing and completed_mega:
		letters = typed
		ages.resize(letters.length())
		ages.fill(1.0)
		update_height()
	if not manager.is_typing or not completed_mega:
		complete_incantation()
	var game = manager.game_manager
	# The VFX layer draws its own cast flash at the staff; the old burst of bolt stamps on top of it
	# read as stray bolts flying off every cast (playtest 14 Oct). Keep it only without the VFX layer.
	var vfx = get_node_or_null("/root/Vfx")
	var vfx_on = vfx != null and bool(vfx.get("_active")) and vfx.presenter != null and vfx.presenter.enabled
	if is_instance_valid(game) and is_instance_valid(game.particle_manager) and not vfx_on:
		var effect = game.particle_manager.create_spell_cast_effect(manager.player.global_position)
		if is_instance_valid(effect):
			effect.modulate = Color("ffe49b") if completed_mega else Color("79d9e8")
			if completed_mega:
				effect.scale *= 1.3

func finish_cast(spell: String = ""):
	if spell != "atomic":
		return
	completed_mega = false
	complete_incantation()

func complete_incantation():
	if letters.is_empty():
		return
	completion_duration = 0.40 if completed_mega else 0.28
	completion_remaining = completion_duration
	completion_count += 1
	get_parent().get_parent().get_parent().show()

func _process(_delta):
	var now = Time.get_ticks_usec()
	var delta = minf(float(now - last_ticks) / 1000000.0, 0.05)
	last_ticks = now
	if get_tree().paused:
		return
	for i in range(ages.size()):
		ages[i] += delta
	for piece in fragments:
		piece.age += delta
		piece.velocity.y += 380 * delta
		piece.position += piece.velocity * delta
	fragments = fragments.filter(func(piece): return piece.age < 0.32)
	if completion_remaining > 0:
		completion_remaining -= delta
		if completion_remaining <= 0 and not manager.is_typing:
			clear_keys()
			get_parent().get_parent().get_parent().hide()
	label.self_modulate.a = 0
	var parent_tint = label.modulate
	modulate = Color(1.0 / maxf(parent_tint.r, 0.01), 1.0 / maxf(parent_tint.g, 0.01), 1.0 / maxf(parent_tint.b, 0.01))
	update_height()
	queue_redraw()

func _draw():
	if not is_instance_valid(manager):
		return
	var font = label.get_theme_font("font")
	for i in range(visible_start(), letters.length()):
		var key = letters[i].to_upper()
		if key == " " and _ends_line(i):
			continue   # a wrapped line's trailing space is not drawn
		var texture = textures.get(key, BLANK)
		var pos = key_position(i)
		var progress = clampf(ages[i] / DROP_SECONDS, 0, 1)
		pos.y -= 16 * (1 - progress) * (1 - progress)
		var tint = typed_letter_tint(i)
		if completion_remaining > 0:
			var wc := word_class(i)
			tint = Color("ff5a4a") if wc == "rejected" else (Color("ffe49b") if completed_mega or wc == "keyword" else Color("79d9e8"))
			tint.a = clampf(completion_remaining / completion_duration * 1.8, 0.0, 1.0)
			if not manager.game_manager.particle_manager.reduced_effects:
				pos.y -= (1.0 - completion_remaining / completion_duration) * (20 if completed_mega else 10)
		draw_texture_rect(texture, Rect2(pos, Vector2.ONE * fitted_key_size()), false, tint)
		if texture == BLANK and key != " ":
			draw_string(font, pos + Vector2(0, 34), key, HORIZONTAL_ALIGNMENT_CENTER, KEY_SIZE, 27, Color("514f43"))
		elif key == " ":
			draw_line(pos + Vector2(15, 34), pos + Vector2(33, 34), Color("999587"), 2)
	for piece in fragments:
		draw_texture_rect_region(piece.texture, Rect2(piece.position, Vector2.ONE * piece.size), piece.region, Color(1, 1, 1, 1 - piece.age / 0.32))

	var caption_y = float(label.get_parent().scroll_vertical)
	if not error_caption().is_empty():
		draw_string(font, Vector2(8, caption_y + 72 + maxf(0.0, (visible_lines() - 1) * (fitted_key_size() + LINE_GAP) - (KEY_SIZE - fitted_key_size()))), error_caption(), HORIZONTAL_ALIGNMENT_CENTER, maxf(1, size.x - 16), 14, Color("ff8175"))

func error_caption() -> String:
	for error in ["No target in range", "Mismatch", "unavailable", "No matching spell"]:
		if error in feedback:
			return error
	return ""

func visible_caption() -> String:
	if completion_remaining > 0:
		return ""
	if not manager.is_typing:
		return label.text
	var caption = manager.target_spell if not manager.target_spell.is_empty() else ""
	if " · " in feedback:
		var status = feedback.substr(feedback.find(" · ") + 3)
		caption = caption + " · " + status if not manager.target_spell.is_empty() else status
	return caption

func fitted_caption(font: Font) -> String:
	var text = visible_caption()
	var available = maxf(1, size.x - 16)
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x <= available:
		return text
	while text.length() > 1 and font.get_string_size(text + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x > available:
		text = text.left(text.length() - 1)
	return text + "…"

## What the typed word under this letter is: "keyword" (gold), "rejected" (it cracked on the last
## cast: red) or "" (the spell name / not a word). Every keyword lights, not only MEGA (playtest).
func word_class(index: int) -> String:
	if index < 0 or index >= letters.length() or letters[index] == " ":
		return ""
	var start := index
	while start > 0 and letters[start - 1] != " ":
		start -= 1
	var stop := index
	while stop < letters.length() and letters[stop] != " ":
		stop += 1
	var word := letters.substr(start, stop - start).to_lower()
	var KP = preload("res://scripts/engine/KeywordParser.gd")
	word = str(KP.data().get("aliases", {}).get(word, word))
	if not (KP.is_keyword(word) or word == "mega" or word == str(KP.data().get("quick", {}).get("word", "quick"))):
		return ""
	# a word that also starts a spell name ("arcane orbit") is the spell's while the rest matches it
	if stop < letters.length() and manager.has_method("legacy_incantations"):
		var rest := letters.substr(start).to_lower()
		for inc in manager.legacy_incantations():
			if str(inc).contains(" ") and rest.begins_with(str(inc)):
				return ""
	var cracked: Array = []
	if manager.get("last_cracked") != null:
		cracked.append_array(manager.last_cracked)
	if manager.get("last_parse") is Dictionary:
		cracked.append_array(manager.last_parse.get("rejected", []))
	for r in cracked:
		if str(r.get("word", "")) == word:
			return "rejected"
	return "keyword"

func typed_letter_tint(index: int) -> Color:
	var tint = Color("dfbd76") if word_class(index) == "keyword" else Color.WHITE
	if not manager.target_spell.is_empty():
		var target = manager.target_spell
		if ("mega " + target).begins_with(letters) or letters.begins_with("mega "):
			target = "mega " + target
		if index >= target.length() or letters[index] != target[index]:
			return Color("ff8175")
	elif "No matching spell" in feedback or "unavailable" in feedback:
		return Color("ff8175")
	return tint
