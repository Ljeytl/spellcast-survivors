extends Node2D
## Rune circle drawn under the wizard while an incantation is typed.
## Every letter is a rune; rings fill at 3 / 6 / 9 runes; colour switches when the element is
## certain; ghost runes appear when the spell is certain; casting seals every ring and bursts.
## Animation uses real time, because typing slows Engine.time_scale.

const STATE = preload("res://scripts/CastingCircleState.gd")
const KEYWORDS = preload("res://scripts/KeywordRules.gd")
const SETTINGS = preload("res://scripts/EffectPreferences.gd")
const RING_RADII = [40.0, 51.0, 62.0, 73.0, 84.0]
const RUNE_SIZE = 5.0
const SATELLITE_ORBIT = 112.0
const SATELLITE_RADIUS = 21.0
const SATELLITE_RUNE = 5.0
const DRIFT = 0.18           # every ring drifts so the hat never hides the same slot
const COLORS = {
	"arcane": [Color("8fe9ff"), Color("b98cff")], "fire": [Color("ffd27a"), Color("ff5a1f")],
	"ice": [Color("e6fbff"), Color("5fb8ff")], "storm": [Color("fff6b0"), Color("8fa8ff")],
	"plague": [Color("d4ff8a"), Color("3fbf5a")], "holy": [Color("fff4c2"), Color("ffc94a")],
	"spirit": [Color("d8fff6"), Color("6fe0c8")], "steel": [Color("ffffff"), Color("9aa6c0")],
	"earth": [Color("f2dca0"), Color("b0793a")], "death": [Color("e0d0ff"), Color("6a4a9a")],
	"void": [Color("ffd6ff"), Color("8a2be2")], "neutral": [Color("e4defa"), Color("7a6aa8")],
}
const STROKES = [[0,-1,1,-.4],[0,-1,-1,-.4],[0,0,1,.5],[0,0,-1,.5],[0,1,1,.4],[0,1,-1,.4],[0,-.3,.8,-.9],[-.7,-.2,.7,-.2],[0,.2,-.8,1],[0,-1,.6,-1],[-.6,.6,.6,.6]]

var manager: Node
var sprite: Sprite2D
var front: Node2D
var reduced = false
var alphabet: Dictionary = {}
var glow_texture: GradientTexture2D
var state: Dictionary = {}
var good_runes = 0          # runes that still fit a spell; only these build rings
var last_text = ""
var runes: Array = []          # {ch, angle, pop, bad}
var satellites: Array = []     # {word, runes:[ch], flash, color}
var ring_rot: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var ring_flash: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var lock_flash = 0.0
var element_flash = 0.0
var error = 0.0
var glow = 0.0
var fade = 0.0
var burst = 0.0
var burst_mult = 1.0
var sealed = false
var awaiting_release = 0.0   # power-word casts charge briefly after typing ends; hold the circle
var shards: Array = []
var embers: Array = []
var color_a = COLORS.neutral[0]
var color_b = COLORS.neutral[1]
var clock = 0.0
var last_ticks = 0

func _init():
	name = "CastingCircle"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	front = Node2D.new()
	front.name = "CastingCircleFront"
	front.material = additive
	front.draw.connect(_draw_front)
	get_parent().add_child.call_deferred(front)
	get_parent().move_child.call_deferred(self, 0)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.4))
	glow_texture = GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	glow_texture.width = 128
	glow_texture.height = 128
	build_alphabet()
	reduced = SETTINGS.reduced()
	if manager:
		manager.manual_spell_released.connect(_on_released)
	last_ticks = Time.get_ticks_usec()

func build_alphabet():
	var letters = "abcdefghijklmnopqrstuvwxyz"
	for i in letters.length():
		var rng = RandomNumberGenerator.new()
		rng.seed = 31 + i * 977
		var count = 1 + rng.randi_range(0, 2)
		var picked: Array = []
		while picked.size() < count:
			var k = rng.randi_range(0, STROKES.size() - 1)
			if not k in picked:
				picked.append(k)
		alphabet[letters[i]] = {"strokes": picked.map(func(k): return STROKES[k]), "dot": rng.randf() < 0.3}

func spell_table() -> Array:
	var table: Array = []
	if not manager:
		return table
	if not str(manager.target_spell).is_empty():
		for slot in manager.get_all_spells():
			var info = manager.get_spell_info(slot)
			if str(info.display_name) == manager.target_spell:
				table.append({"incantation": manager.target_spell, "element": str(info.get("element", "arcane"))})
		return table
	for slot in manager.get_all_spells():
		if not manager.is_spell_unlocked(slot):
			continue
		var info = manager.get_spell_info(slot)
		var element = str(info.get("element", "arcane"))
		table.append({"incantation": str(info.display_name).to_lower(), "element": element})
		var alias = str(info.name).to_lower().replace("_", " ")
		if alias != str(info.display_name).to_lower():
			table.append({"incantation": alias, "element": element})
	var session = manager.game_manager.style_session if manager.game_manager and "style_session" in manager.game_manager else null
	if is_instance_valid(session) and session.atomic_available():
		table.append({"incantation": "atomic", "element": "void"})
	return table

func power_words() -> Array:
	return KEYWORDS.DEFINITIONS.keys()

func refresh(text: String):
	var previous = state
	var table = spell_table()
	state = STATE.analyze(text, table, power_words())
	# Longest valid prefix: runes past it are drawn cracked.
	var good = state.rune_count
	if not state.valid:
		var length = text.length()
		while length > 0 and not STATE.analyze(text.substr(0, length), table, power_words()).valid:
			length -= 1
		good = int(STATE.analyze(text.substr(0, length), table, power_words()).rune_count)
		error = 1.0
	good_runes = good
	var count = state.rune_count
	# Completed power words fly from the ring into satellites.
	var words: Array = state.power_words
	while satellites.size() < words.size():
		var word = str(words[satellites.size()])
		satellites.append({"word": word, "runes": letters_of(word), "flash": 1.0, "color": KEYWORDS.cast_color(KEYWORDS.DEFINITIONS.get(word, {}))})
		runes.clear()
	while satellites.size() > words.size():
		satellites.pop_back()
	while runes.size() > count:
		runes.pop_back()
	for i in runes.size():
		runes[i].ch = str(state.runes)[i]
		runes[i].bad = i >= good
	while runes.size() < count:
		var i = runes.size()
		runes.append({"ch": str(state.runes)[i], "angle": slot_angle(i) - 0.6, "pop": 1.0, "bad": i >= good})
		if (i + 1) % STATE.RUNES_PER_RING == 0 and i < good:
			ring_flash[mini(STATE.ring_of(i), 4)] = 1.0
	if str(state.element) != "" and str(state.element) != str(previous.get("element", "")):
		element_flash = 1.0
	if str(state.spell) != "" and str(state.spell) != str(previous.get("spell", "")):
		lock_flash = 1.0

func slot_angle(i: int) -> float:
	var ring = STATE.ring_of(i)
	var j = i % STATE.RUNES_PER_RING
	return -PI / 2 + j * TAU / 3 + (PI / 3 if ring % 2 == 1 else 0.0) + ring_rot[mini(ring, 4)]

func radius_of(i: int) -> float:
	return RING_RADII[mini(STATE.ring_of(i), RING_RADII.size() - 1)]

func _on_released(_family: String, canonical: String, _typed: String):
	awaiting_release = 0.0
	burst = 1.0
	sealed = true
	burst_mult = float(KEYWORDS.for_incantation(canonical).get("power", 1.0))
	for i in runes.size():
		var r = runes[i]
		shards.append({"angle": r.angle, "radius": radius_of(i), "speed": 90.0 + randf() * 90.0 * burst_mult, "life": 1.0, "ch": r.ch})

func _process(_delta):
	var now = Time.get_ticks_usec()
	var dt = clampf((now - last_ticks) / 1000000.0, 0.0, 0.1)
	last_ticks = now
	clock += dt
	if not manager or not is_instance_valid(sprite):
		return
	var typing = bool(manager.is_typing)
	var text = str(manager.current_typing_text) if typing else ""
	if text != last_text:
		if typing and sealed:
			# A new incantation started while the last one is still bursting.
			start_fresh()
		if typing and last_text.is_empty() and fade <= 0.0:
			reduced = SETTINGS.reduced()
		if not typing and bool(state.get("complete", false)) and burst <= 0.0:
			awaiting_release = 0.8
			sealed = true
		elif typing or burst <= 0.0:
			refresh(text)
		last_text = text
	if awaiting_release > 0.0:
		awaiting_release = maxf(0.0, awaiting_release - dt)
		if awaiting_release <= 0.0 and burst <= 0.0:
			sealed = false
			refresh("")
	if not typing and burst <= 0.0 and awaiting_release <= 0.0 and fade <= 0.0 and shards.is_empty() and embers.is_empty():
		if not runes.is_empty() or not satellites.is_empty():
			reset()
		return
	if sealed and burst <= 0.0 and awaiting_release <= 0.0:
		reset()
	var k = 1.0 - pow(0.001, dt)   # frame-rate independent easing
	fade = move_toward(fade, 1.0 if typing or burst > 0.0 or awaiting_release > 0.0 else 0.0, dt * 5.0)
	var element = str(state.get("element", ""))
	var target = COLORS.get(element, COLORS.neutral) if element != "" else COLORS.neutral
	color_a = color_a.lerp(target[0], k * 0.9)
	color_b = color_b.lerp(target[1], k * 0.9)
	var mult = 1.0
	for s in satellites:
		mult *= float(KEYWORDS.DEFINITIONS.get(s.word, {}).get("power", 1.0))
	var charge = minf(1.5, (runes.size() / 13.0 + satellites.size() * 0.15) * mult)
	glow = lerpf(glow, charge + burst * 0.8, k * 0.8)
	error = maxf(0.0, error - dt * 2.4)
	burst = maxf(0.0, burst - dt * 1.4)
	lock_flash = maxf(0.0, lock_flash - dt * 2.4)
	element_flash = maxf(0.0, element_flash - dt * 2.0)
	for i in ring_flash.size():
		ring_flash[i] = maxf(0.0, ring_flash[i] - dt * 3.0)
	var spin = 1.0 + glow * 2.0 + burst * 10.0
	var full = good_runes / STATE.RUNES_PER_RING
	for r in ring_rot.size():
		var speed = DRIFT + (0.25 * spin if r < full or sealed else 0.0)
		ring_rot[r] += (-1.0 if r % 2 == 1 else 1.0) * speed * dt
	for i in runes.size():
		var r = runes[i]
		r.angle = lerp_angle(r.angle, slot_angle(i), k)
		r.pop = maxf(0.0, r.pop - dt * 3.0)
	for s in satellites:
		s.flash = maxf(0.0, s.flash - dt * 2.0)
	for s in shards:
		s.radius += s.speed * dt
		s.life -= dt * 1.4
	shards = shards.filter(func(s): return s.life > 0.0)
	if not reduced:
		var rate = glow * 30.0 * dt
		while rate > 0.0:
			if randf() < rate:
				embers.append({"pos": Vector2(randf_range(-14, 14), 4), "speed": randf_range(20, 45), "life": 1.0, "hue": randf() < 0.5})
			rate -= 1.0
	for e in embers:
		e.pos.y -= e.speed * dt
		e.pos.x += sin(e.pos.y * 0.15) * 0.4
		e.life -= dt * 0.9
	embers = embers.filter(func(e): return e.life > 0.0)
	queue_redraw()
	if is_instance_valid(front):
		front.queue_redraw()

static func letters_of(word: String) -> Array:
	var out: Array = []
	for i in word.length():
		out.append(word[i])
	return out

func start_fresh():
	runes.clear()
	satellites.clear()
	sealed = false
	ring_rot = [0.0, 0.0, 0.0, 0.0, 0.0]
	state = {}

func reset():
	runes.clear()
	satellites.clear()
	shards.clear()
	sealed = false
	burst = 0.0
	awaiting_release = 0.0
	ring_rot = [0.0, 0.0, 0.0, 0.0, 0.0]
	state = {}
	good_runes = 0
	queue_redraw()
	if is_instance_valid(front):
		front.queue_redraw()

func draw_rune(canvas: CanvasItem, ch: String, center: Vector2, angle: float, size: float, width: float, color: Color):
	var xf = Transform2D(angle + PI / 2, center)
	if ch == " ":
		canvas.draw_circle(center, width * 1.3, color)
		return
	var glyph = alphabet.get(ch)
	if glyph == null:
		return
	canvas.draw_line(xf * Vector2(0, -size), xf * Vector2(0, size), color, width, true)
	for s in glyph.strokes:
		canvas.draw_line(xf * Vector2(s[0] * size * 0.6, s[1] * size), xf * Vector2(s[2] * size * 0.6, s[3] * size), color, width, true)
	if glyph.dot:
		canvas.draw_circle(xf * Vector2(size * 0.55, 0), width * 0.9, color)

func faded(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0) * fade)

func _draw():
	if fade <= 0.0 and burst <= 0.0:
		return
	var jitter = Vector2.ZERO if reduced else Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (error * 3.0)
	draw_set_transform(jitter)
	# Aura under the wizard
	var aura = 34.0 + minf(1.3, glow) * 70.0
	draw_texture_rect(glow_texture, Rect2(-aura, -aura, aura * 2, aura * 2), false, faded(color_b, 0.15 + glow * 0.5))
	if element_flash > 0.0:
		draw_arc(Vector2.ZERO, 30.0 + (1.0 - element_flash) * 110.0, 0, TAU, 64, faded(color_a, element_flash), 3.0 * element_flash, true)
	var count = runes.size()
	var lit = mini(good_runes, count)
	var total = int(state.get("total_runes", lit))
	var ring_count = int(ceil(float(maxi(lit, total)) / STATE.RUNES_PER_RING))
	var locked = str(state.get("spell", "")) != ""
	for r in mini(ring_count, RING_RADII.size()):
		var radius = RING_RADII[r]
		var filled = clampi(lit - r * STATE.RUNES_PER_RING, 0, STATE.RUNES_PER_RING)
		var whole = filled == STATE.RUNES_PER_RING or sealed
		var start = -PI / 2 + (PI / 3 if r % 2 == 1 else 0.0) + ring_rot[r]
		var flash = ring_flash[r]
		if whole:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 72, faded(color_b, 0.75 + flash * 0.25), 1.6 + flash * 3.0, true)
			for t in 24:
				var a = start + t * TAU / 24
				var inner = radius + 3.0
				var outer = radius + (8.0 if t % 3 == 0 else 5.0)
				draw_line(Vector2.from_angle(a) * inner, Vector2.from_angle(a) * outer, faded(color_a, 0.6), 1.0, true)
		elif filled > 0:
			draw_arc(Vector2.ZERO, radius, start - 0.3, start + (filled - 1) * TAU / 3 + 0.3, 32, faded(color_b, 0.7), 1.4, true)
		if not whole and locked:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 72, faded(color_b, 0.12), 1.0, true)
		if flash > 0.0:
			draw_arc(Vector2.ZERO, radius + (1.0 - flash) * 14.0, 0, TAU, 72, faded(color_a, flash), 2.5 * flash, true)
		if lock_flash > 0.0:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 72, faded(color_a, lock_flash * 0.8), 2.0 * lock_flash, true)
	# Ghost runes once the spell is certain
	if locked and burst <= 0.0:
		var spell = str(state.spell)
		for i in range(count, spell.length()):
			var a = slot_angle(i)
			var pulse = 0.4 + 0.2 * sin(clock * 8.0) if i == count else 0.16
			draw_rune(self, spell[i], Vector2.from_angle(a) * radius_of(i), a, RUNE_SIZE * 0.85, 1.0, faded(color_b, pulse * (1.0 - lock_flash * 0.6)))
	# Typed runes
	var forming = bool(state.get("forming_power_word", false))
	for i in count:
		var r = runes[i]
		var size = RUNE_SIZE * (1.0 + r.pop * 0.7)
		var color = Color("ff4a4a") if r.bad else color_a
		if forming:
			continue
		draw_rune(self, r.ch, Vector2.from_angle(r.angle) * radius_of(i), r.angle, size, 1.6, faded(color, 0.95))
	if error > 0.0 and count < 15:
		var p = Vector2.from_angle(slot_angle(count)) * radius_of(count)
		var red = Color(1.0, 0.29, 0.29, error * fade)
		draw_line(p + Vector2(-5, -7), p + Vector2(2, 0), red, 1.6, true)
		draw_line(p + Vector2(2, 0), p + Vector2(-2, 7), red, 1.6, true)
	draw_set_transform(Vector2.ZERO)

func _draw_front():
	if fade <= 0.0 and burst <= 0.0 and shards.is_empty() and embers.is_empty():
		return
	# Wizard glow: an additive copy of the sprite, brighter as the cast charges.
	if is_instance_valid(sprite) and sprite.texture and glow > 0.05:
		front.draw_set_transform(sprite.position, 0.0, sprite.scale)
		front.draw_texture(sprite.texture, -sprite.texture.get_size() / 2.0, Color(color_a.r, color_a.g, color_a.b, minf(0.55, glow * 0.35) * fade))
		front.draw_set_transform(Vector2.ZERO)
	for e in embers:
		var c = color_a if e.hue else color_b
		front.draw_rect(Rect2(e.pos + Vector2(0, -20), Vector2(2, 2)), Color(c.r, c.g, c.b, e.life * fade))
	# Power-word satellites orbit the wizard
	var forming = bool(state.get("forming_power_word", false))
	var orbiting = satellites.size() + (1 if forming else 0)
	for i in orbiting:
		var center = Vector2.from_angle(clock * 0.7 + i * TAU / maxf(1.0, orbiting)) * SATELLITE_ORBIT
		var letters: Array = satellites[i].runes if i < satellites.size() else letters_of(str(state.runes))
		var color: Color = satellites[i].color if i < satellites.size() else color_a
		var flash = float(satellites[i].flash) if i < satellites.size() else 0.0
		front.draw_arc(center, SATELLITE_RADIUS + flash * 8.0, 0, TAU, 32, Color(color.r, color.g, color.b, 0.8 * fade), 1.4 + flash * 2.0, true)
		front.draw_line(Vector2(0, -10), center, Color(color.r, color.g, color.b, 0.25 * fade), 1.0, true)
		for j in letters.size():
			var a = clock * 1.6 + j * TAU / maxf(4.0, letters.size())
			draw_rune(front, str(letters[j]), center + Vector2.from_angle(a) * SATELLITE_RADIUS, a, SATELLITE_RUNE, 1.4, Color(color.r, color.g, color.b, fade))
	# Cast: shockwave scaled by power, runes flung outward
	if burst > 0.0:
		var scale_power = minf(1.8, burst_mult)
		front.draw_arc(Vector2.ZERO, 50.0 + (1.0 - burst) * 140.0 * scale_power, 0, TAU, 96, Color(color_a.r, color_a.g, color_a.b, burst), 3.0 * burst * scale_power, true)
		if not reduced:
			front.draw_texture_rect(glow_texture, Rect2(Vector2(-120, -120) * scale_power, Vector2(240, 240) * scale_power), false, Color(color_a.r, color_a.g, color_a.b, burst * burst * 0.6))
	for s in shards:
		draw_rune(front, s.ch, Vector2.from_angle(s.angle) * s.radius, s.angle, RUNE_SIZE, 1.6, Color(color_a.r, color_a.g, color_a.b, s.life))
