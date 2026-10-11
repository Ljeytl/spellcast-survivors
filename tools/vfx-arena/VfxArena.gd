extends Node2D
## VFX test arena (dev tool, not shipped in normal play).
##
## Same layout as tools/vfx-reference/spell_vfx_sandbox.html: the wizard on the
## left, six dummies where the sandbox puts its enemies, camera framing the same
## 192 x 108 sandbox units. Spells loop at the sandbox's cadence through the real
## spell engine (GenericCast), so what you see here is what the game draws.
##
## Keys: 1-9 pick a spell · B grass / sandbox-dark floor · Space pause ·
##       S slow-mo · P VFX on/off (placeholder art) · T on twos · R reset

const KP = preload("res://scripts/engine/KeywordParser.gd")
const Defs = preload("res://scripts/engine/SpellDefs.gd")
const Planner = preload("res://scripts/engine/CastPlanner.gd")
const GenericCast = preload("res://scripts/engine/GenericCast.gd")
const WPS := 1280.0 / 192.0
const ENEMY_TEX := preload("res://assets/typecast/Slime Enemies/Slime girl 1.png")
const WIZARD_TEX := preload("res://assets/typecast/Main Character/Wizard 2.0.png")
const BASE_ENEMIES := [Vector2(132, 36), Vector2(152, 50), Vector2(170, 32), Vector2(140, 72), Vector2(162, 80), Vector2(180, 60)]
const PLAYER_SU := Vector2(22, 56)
# The sandbox steps 1/60 s per animation frame, so on a 120 Hz display it runs at
# 2x. The arena mirrors what you saw there: sandbox spells fly at 2x their nominal
# speed and recast twice as often. (Vfx.FX_SPEED does the same for effect motion.)
const SANDBOX_TIME := 0.5

# Sandbox reference spells, rebuilt as spell-engine data with sandbox numbers
# (speeds and radii in sandbox units x WPS, speeds x2 for the 120 Hz sandbox).
static func arena_defs() -> Dictionary:
	return {
		"arena_fire_bolt": {"name": "Fire Bolt", "incantation": "arena fire bolt", "element": "fire", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 170 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}}}},
		"arena_fireball": {"name": "Fireball", "incantation": "arena fireball", "element": "fire", "acquire": "data_only", "root": "orb",
			"parts": {"orb": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 105 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "ball"}, "events": {"on_hit": {"part": "blast"}}},
				"blast": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": (9 * 1.4 + 3) * WPS},
				"payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}]}}},
		"arena_ember_spear": {"name": "Ember Spear", "incantation": "arena ember spear", "element": "fire", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 240 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_cinder_field": {"name": "Cinder Field", "incantation": "arena cinder field", "element": "fire", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "burn"}]}}},
	}

# label, incantation, cadence (s) — cadence from the sandbox's SPELLS[*].every
const MENU := [
	["Fire Bolt (sandbox: Fire > Fire Bolt)", "arena fire bolt", 0.55],
	["Fireball (sandbox: Fire > Fireball)", "arena fireball", 1.7],
	["Ember Spear (sandbox: Fire > Ember Spear)", "arena ember spear", 1.1],
	["Cinder Field (sandbox: Fire > Cinder Field)", "arena cinder field", 6.6],
	["fireball (game data)", "fireball", 1.7],
	["fiery spear (keyword accent)", "fiery spear", 1.1],
	["flame wall (game data)", "flame wall", 6.0],
	["spear (bare, arcane)", "spear", 1.1],
	["frost nova (no look yet: placeholder)", "frost nova", 2.2],
]

class Dummy extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var armour = 0.0
	var status = null
	var max_health = 1.0e9
	var current_health = 1.0e9
	var damage = 0.0
	var dying = false
	var velocity := Vector2.ZERO
	var home := Vector2.ZERO
	var phase := 0.0
	func apply_effect(e, s = {}, o = Vector2.INF):
		return FX.apply_to_entity(self, e, s, o)
	func receive_damage(_a, _o = Vector2.INF, _s = {}):
		pass
	func armour_value():
		return armour
	func process_status_effects(_d):
		pass
	func apply_knockback(_dir, _force):
		pass

class ArenaCaster extends Node2D:
	var health = 100.0
	var max_health = 100.0
	var velocity := Vector2.ZERO
	func heal(_a, _v = 1.0):
		pass

var caster: ArenaCaster
var dummies: Array = []
var cam: Camera2D
var hud: Label
var floor_node: Node2D
var current := 0
var cooldown := 0.0
var t := 0.0
var dark := false
var slow := false
var paused_cast := false
var seed_counter := 1

func _ready():
	for id in arena_defs():
		var d: Dictionary = arena_defs()[id].duplicate(true)
		d.id = id
		Defs.register(d)
	floor_node = ArenaFloor.new()
	floor_node.arena = self
	add_child(floor_node)
	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * preload("res://scripts/VisualDefaults.gd").CAMERA_ZOOM
	cam.position = Vector2(96, 54) * WPS
	add_child(cam)
	cam.make_current()
	caster = ArenaCaster.new()
	caster.position = PLAYER_SU * WPS
	var ws := Sprite2D.new()
	ws.texture = WIZARD_TEX
	ws.scale = Vector2(2, 2)
	ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ws.offset = Vector2(0, -WIZARD_TEX.get_height() * 0.5)
	caster.add_child(ws)
	add_child(caster)
	for i in BASE_ENEMIES.size():
		var d := Dummy.new()
		d.home = BASE_ENEMIES[i] * WPS
		d.position = d.home
		d.phase = i * 1.7
		var s := Sprite2D.new()
		s.texture = ENEMY_TEX
		s.scale = Vector2(2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -ENEMY_TEX.get_height() * 0.5)
		d.add_child(s)
		add_child(d)
		d.add_to_group("enemies")
		dummies.append(d)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)
	_update_hud()

func _process(delta: float):
	t += delta
	for d in dummies:
		# sandbox drift: hx + sin(ph + T*0.7)*5, hy + cos(ph*1.3 + T*0.5)*3  (sandbox units)
		var p: Vector2 = d.home + Vector2(sin(d.phase + t * 0.7) * 5.0, cos(d.phase * 1.3 + t * 0.5) * 3.0) * WPS
		d.velocity = (p - d.position) / maxf(delta, 0.0001)
		d.position = p
		if d.status != null and is_instance_valid(d.status):
			d.status.tick(delta)
	if paused_cast:
		return
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = float(MENU[current][2]) * SANDBOX_TIME
		cast(str(MENU[current][1]))

func cast(text: String):
	var parsed = KP.parse(text, Defs.by_incantation().keys())
	if not parsed.ok:
		push_warning("arena: cannot parse " + text)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_counter
	seed_counter += 1
	var plan = Planner.plan(Defs.get_def(Defs.by_incantation()[parsed.spell]), parsed.bundle, {"rng": rng})
	var c = GenericCast.new()
	add_child(c)
	c.setup(plan, caster, self, {"spell": plan.id, "cast_clock": t, "cast_id": seed_counter}, false, seed_counter)

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < MENU.size():
		select(k - KEY_1)
	elif k == KEY_B:
		dark = not dark
		floor_node.queue_redraw()
	elif k == KEY_SPACE:
		paused_cast = not paused_cast
	elif k == KEY_S:
		slow = not slow
		Engine.time_scale = 0.25 if slow else 1.0
	elif k == KEY_P:
		var v = get_node_or_null("/root/Vfx")
		if v:
			v.presenter.enabled = not v.presenter.enabled
	elif k == KEY_T:
		var v2 = get_node_or_null("/root/Vfx")
		if v2:
			v2.on_twos = not v2.on_twos
	elif k == KEY_R:
		select(current)
	_update_hud()

func select(i: int):
	current = i
	cooldown = 0.0
	for n in get_children():
		if n is GenericCast:
			n.queue_free()
	var v = get_node_or_null("/root/Vfx")
	if v:
		v.clear()
		v.presenter._parts.clear()
	for d in dummies:
		if d.status != null and is_instance_valid(d.status):
			d.status.queue_free()
			d.status = null
	_update_hud()

func _update_hud():
	var v = get_node_or_null("/root/Vfx")
	var lines := ["VFX ARENA   " + str(MENU[current][0])]
	var menu := []
	for i in MENU.size():
		menu.append(str(i + 1) + " " + str(MENU[i][0]).split(" (")[0])
	lines.append("  ".join(menu))
	lines.append("B floor: %s   Space %s   S slow-mo %s   P VFX %s   T twos %s   R reset" % [
		"dark" if dark else "grass", "paused" if paused_cast else "casting", "on" if slow else "off",
		"on" if v and v.presenter.enabled else "off", "on" if v and v.on_twos else "off"])
	hud.text = "\n".join(lines)

class ArenaFloor extends Node2D:
	const ART = "res://assets/typecast/"
	var arena
	var tiles: Array = []
	func _ready():
		z_index = -100
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for i in range(1, 10):
			tiles.append(load(ART + "Level Tiles/Grass Tile %d.png" % i))
	func _draw():
		var wps := 1280.0 / 192.0
		if arena.dark:
			# sandbox floorPx: vn(x*.35, y*.35) + hs(x,y)*.25 -> three tones, one rect per sandbox px
			var V = preload("res://scripts/vfx/Vfx.gd")
			for y in range(-10, 120):
				for x in range(-20, 212):
					var n: float = V.vn(x * 0.35, y * 0.35) + V.hs(x, y) * 0.25
					var c := Color("#25222c") if n > 0.82 else (Color("#1b1820") if n < 0.25 else Color("#1f1c25"))
					draw_rect(Rect2(Vector2(x, y) * wps, Vector2.ONE * wps), c)
		else:
			for y in range(-2, 8):
				for x in range(-2, 13):
					var idx := posmod(x * 7 + y * 13, tiles.size())
					draw_texture_rect(tiles[idx], Rect2(Vector2(x, y) * 128.0, Vector2.ONE * 128.0), false, Color(0.72, 0.78, 0.72))
