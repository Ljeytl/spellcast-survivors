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

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label = get_parent()
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.self_modulate.a = 0
	last_ticks = Time.get_ticks_usec()
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		var path = "res://assets/typecast/Keys/%s.png" % letter
		textures[letter] = load(path) if ResourceLoader.exists(path) else BLANK

	for code in range(33, 127):
		var path = "res://assets/typecast/Keys/u%04x.png" % code
		if ResourceLoader.exists(path):
			textures[String.chr(code)] = load(path)

func columns() -> int:
	return maxi(1, floori(maxf(STRIDE, size.x - 16) / STRIDE))

func key_position(index: int) -> Vector2:
	var available = maxf(KEY_SIZE, size.x - 16.0)
	var stride = clampf((available - KEY_SIZE) / maxf(1, letters.length() - 1), KEY_SIZE, STRIDE)
	var width = maxf(0, letters.length() - 1) * stride + KEY_SIZE
	var origin = (size.x - width) / 2 if width <= available else size.x - 8 - width
	return Vector2(origin + index * stride, 30)

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
	var height = 34 + STRIDE
	for piece in fragments:
		height = maxf(height, piece.floor_height)
	label.custom_minimum_size.y = height

func shatter(index: int):
	var origin = key_position(index)
	var texture = textures.get(letters[index].to_upper(), BLANK)
	for y in range(2):
		for x in range(2):
			if fragments.size() >= 64:
				fragments.pop_front()
			fragments.append({"texture": texture, "region": Rect2(x * 16, y * 16, 16, 16), "position": origin + Vector2(x, y) * (KEY_SIZE / 2), "velocity": Vector2((x * 2 - 1) * 65, -50 - y * 25), "age": 0.0, "floor_height": label.custom_minimum_size.y})

func finish_cast(_spell: String = ""):
	if letters.is_empty():
		return
	completion_remaining = 0.22
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
	var parent_tint = label.modulate
	modulate = Color(1.0 / maxf(parent_tint.r, 0.01), 1.0 / maxf(parent_tint.g, 0.01), 1.0 / maxf(parent_tint.b, 0.01))
	update_height()
	queue_redraw()

func _draw():
	if not is_instance_valid(manager):
		return
	var font = label.get_theme_font("font")
	for i in range(letters.length()):
		var key = letters[i].to_upper()
		var texture = textures.get(key, BLANK)
		var pos = key_position(i)
		var progress = clampf(ages[i] / DROP_SECONDS, 0, 1)
		pos.y -= 16 * (1 - progress) * (1 - progress)
		var tint = Color.WHITE
		if not manager.target_spell.is_empty() and (i >= manager.target_spell.length() or letters[i] != manager.target_spell[i]):
			tint = Color("ff8175")
		elif "No matching spell" in feedback or "unavailable" in feedback:
			tint = Color("ff8175")
		if completion_remaining > 0:
			tint = Color("79d9e8")
			tint.a = completion_remaining / 0.22
		draw_texture_rect(texture, Rect2(pos, Vector2.ONE * KEY_SIZE), false, tint)
		if texture == BLANK and key != " ":
			draw_string(font, pos + Vector2(0, 34), key, HORIZONTAL_ALIGNMENT_CENTER, KEY_SIZE, 27, Color("514f43"))
		elif key == " ":
			draw_line(pos + Vector2(15, 34), pos + Vector2(33, 34), Color("999587"), 2)
	for piece in fragments:
		draw_texture_rect_region(piece.texture, Rect2(piece.position, Vector2.ONE * (KEY_SIZE / 2)), piece.region, Color(1, 1, 1, 1 - piece.age / 0.32))

	var caption_y = float(label.get_parent().scroll_vertical)
	draw_rect(Rect2(0, caption_y, size.x, 26), Color("21382a"))
	draw_string(font, Vector2(8, caption_y + 19), fitted_caption(font), HORIZONTAL_ALIGNMENT_CENTER, maxf(1, size.x - 16), 18, Color("eee8d8"))

func visible_caption() -> String:
	if completion_remaining > 0:
		return "Cast!"
	if not manager.is_typing:
		return label.text
	var caption = "Cast: " + manager.target_spell if not manager.target_spell.is_empty() else "Type a learned spell"
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
