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

func fitted_key_size() -> float:
	return minf(KEY_SIZE, maxf(20.0, (size.x - 16.0) / maxf(1, letters.length()) - 2.0))

func visible_start() -> int:
	return maxi(0, letters.length() - maxi(1, int((size.x - 16.0) / 22.0)))

func key_position(index: int) -> Vector2:
	var key_size = fitted_key_size()
	var stride = key_size + 2.0
	var width = maxf(0, letters.length() - visible_start() - 1) * stride + key_size
	return Vector2((size.x - width) / 2 + (index-visible_start()) * stride, 6)

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
	var height = 62.0
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
	if is_instance_valid(game) and is_instance_valid(game.particle_manager):
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
		var texture = textures.get(key, BLANK)
		var pos = key_position(i)
		var progress = clampf(ages[i] / DROP_SECONDS, 0, 1)
		pos.y -= 16 * (1 - progress) * (1 - progress)
		var tint = typed_letter_tint(i)
		if completion_remaining > 0:
			tint = Color("ffe49b") if completed_mega else Color("79d9e8")
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
		draw_string(font, Vector2(8, caption_y + 60), error_caption(), HORIZONTAL_ALIGNMENT_CENTER, maxf(1, size.x - 16), 14, Color("ff8175"))

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

func typed_letter_tint(index: int) -> Color:
	var tint = Color("dfbd76") if letters.begins_with("mega ") and index < 4 else Color.WHITE
	if not manager.target_spell.is_empty():
		var target = manager.target_spell
		if ("mega " + target).begins_with(letters) or letters.begins_with("mega "):
			target = "mega " + target
		if index >= target.length() or letters[index] != target[index]:
			return Color("ff8175")
	elif "No matching spell" in feedback or "unavailable" in feedback:
		return Color("ff8175")
	return tint
