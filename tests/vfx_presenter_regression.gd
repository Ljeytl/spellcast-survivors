extends SceneTree
## VFX presenter contract (docs/VFX_EVENTS.md): spell-engine events become
## chunky-magic VFX, and VFX never change gameplay.

const KP = preload("res://scripts/engine/KeywordParser.gd")
const Defs = preload("res://scripts/engine/SpellDefs.gd")
const Planner = preload("res://scripts/engine/CastPlanner.gd")
const GenericCast = preload("res://scripts/engine/GenericCast.gd")
const DT = 1.0 / 60.0

var checks = 0
var failures = 0
var caster: Node2D
var vfx

class Foe extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var armour = 0.0
	var status = null
	var max_health = 100000.0
	var current_health = 100000.0
	var damage = 10.0
	var dying = false
	var received: Array = []
	var pushed := Vector2.ZERO
	func apply_effect(e, s = {}, o = Vector2.INF):
		return FX.apply_to_entity(self, e, s, o)
	func receive_damage(a, _o = Vector2.INF, _s = {}):
		current_health -= a
		received.append(a)
		if current_health <= 0.0:
			dying = true
	func armour_value():
		return armour
	func process_status_effects(_d):
		pass
	func apply_knockback(dir, force):
		pushed += dir * force
	func taken() -> float:
		var t = 0.0
		for a in received:
			t += a
		return t

class Caster extends Node2D:
	var health = 100.0
	var max_health = 100.0
	var healed = 0.0
	func heal(a, _v = 1.0):
		healed += a
		health = minf(max_health, health + a)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func foe(pos: Vector2) -> Foe:
	var f = Foe.new()
	f.position = pos
	root.add_child(f)
	f.add_to_group("enemies")
	return f

func clear():
	for n in root.get_children():
		if n is Foe or n is Node2D and (n.name.begins_with("Part_") or n.get_script() == GenericCast):
			n.free()
	vfx.clear()
	vfx.presenter._parts.clear()

func cast(text: String, seconds: float, seed_value: int = 1):
	var parsed = KP.parse(text, Defs.by_incantation().keys())
	var o = {}
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	o.rng = rng
	var pl = Planner.plan(Defs.get_def(Defs.by_incantation()[parsed.spell]), parsed.bundle, o)
	var c = GenericCast.new()
	root.add_child(c)
	c.setup(pl, caster, root, {"spell": pl.id, "cast_clock": 0.0, "cast_id": 1}, true, seed_value)
	# one step starts the cast (parts spawn on the first step)
	c.run(maxf(seconds, DT), DT, tick_all)
	return c

func tick_all(dt: float) -> void:
	for n in root.get_children():
		if n is Foe and n.status != null and is_instance_valid(n.status):
			n.status.tick(dt)
	vfx._tick(dt)

## Damage dealt to a fixed line of foes by `text`, with the presenter on or off.
func damage_profile(text: String, presenting: bool) -> Array:
	clear()
	vfx.presenter.enabled = presenting
	var foes = [foe(Vector2(150, 0)), foe(Vector2(300, 10)), foe(Vector2(450, -10))]
	cast(text, 2.5, 7)
	var out = []
	for f in foes:
		out.append(snappedf(f.taken(), 0.001))
	return out

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	var cam = Camera2D.new()
	root.add_child(cam)
	cam.make_current()
	caster = Caster.new()
	root.add_child(caster)
	await process_frame
	await process_frame
	check(vfx._active, "Vfx active with a camera")

	# Read-only contract: identical damage with and without VFX presenting.
	for text in ["fiery spear", "fireball", "spear", "flame wall"]:
		var on = damage_profile(text, true)
		var off = damage_profile(text, false)
		check(on == off, "VFX never change gameplay: " + text + " " + str(on) + " vs " + str(off))
	vfx.presenter.enabled = true

	var cinder_info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/spells.json")).spells.cinder_field
	cinder_info.incantation = "cinder field"
	Defs.register(preload("res://scripts/engine/LegacyBridge.gd").build(cinder_info, 8.0, {}))
	for item in [["cinder field", "cinder"], ["flame wall", "default"]]:
		clear()
		foe(Vector2(150, 0))
		cast(item[0], 0.1)
		check(vfx._fields.any(func(field): return field.get("profile", "default") == item[1]), "Fire presentation routed by spell: " + item[0])
	clear()
	var seeker_info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/spells.json")).spells.seeker
	seeker_info.incantation = "seeker"
	Defs.register(preload("res://scripts/engine/LegacyBridge.gd").build(seeker_info, 8.0, {}))
	foe(Vector2(150, 0))
	var seeker_cast = cast("seeker", 0.1)
	var spirit_visual = seeker_cast.parts[0].get_child(0)
	spirit_visual._process(0.1)
	check(spirit_visual.is_in_group("spirit_visuals") and spirit_visual.visible, "Live Seeker owns its full-resolution spirit")
	seeker_cast.parts[0].def.geometry.radius = 48.0
	spirit_visual._process(0.1)
	check(is_equal_approx(spirit_visual.radius, 48.0), "Seeker body follows changed spell geometry")
	vfx.presenter.enabled = false
	spirit_visual._process(0.1)
	check(not spirit_visual.visible, "Disabling presenter hides Seeker body")
	vfx.presenter.enabled = true
	spirit_visual._process(0.1)
	check(spirit_visual.visible, "Re-enabling presenter restores Seeker body")
	clear()
	check(get_nodes_in_group("spirit_visuals").is_empty(), "Freeing Seeker casts removes all spirit children")
	var neutral_field = vfx.field(0, 0, 8, 1)
	check(neutral_field.profile == "default", "Unspecified fire fields preserve their existing profile")

	# Fiery spear: native arcane body + fire accent; presented, trail flames, cast flash.
	clear()
	foe(Vector2(300, 0))
	var c = cast("flaming spear", 0.0)   # FLAMING adds fire damage and burns (FIERY is damage only)
	var spear = null
	for p in c.parts:
		spear = p
	check(spear != null and vfx.presents(spear), "Fiery spear is presented (placeholder art skipped)")
	check(not vfx._stars.is_empty(), "Cast flash at the staff (designed star)")
	var look = vfx.presenter.look_of(c.plan)
	check(look.native == "arcane" and look.accent == "fire", "Keyword element is the accent, native element owns the body")
	c.run(0.2, DT, tick_all)
	check(vfx._f_count > 0, "Accent fire trail emits flames")
	c.run(1.0, DT, tick_all)
	check(vfx._flashes.size() + vfx._stars.size() + vfx._debris.size() > 0 or vfx._f_count > 20, "Pierce contact makes a fire burst")

	# Burning status shows faint embers on the enemy, never flames (playtest: statuses stay subtle).
	var burning = 0
	for sp in vfx._sparks:
		var pal: Array = sp[6]
		if not pal.is_empty() and pal[0].a < 0.99:
			burning += 1
	check(burning > 0, "Burning enemy gets see-through embers")

	# Fireball: orb (ball family) -> blast volume -> big impact with ring, debris, scorch, VFX-only hit-stop.
	clear()
	foe(Vector2(250, 0))
	var ts = Engine.time_scale
	c = cast("fireball", 0.0)
	check(vfx.presenter.family_of(c.parts[0]) == "ball", "Fireball orb uses the ball body")
	c.run(1.5, DT, tick_all)
	check(not vfx._rings.is_empty() or not vfx._debris.is_empty(), "Fireball blast: shockwave ring and debris")
	check(vfx._decals.size() >= 1, "Fireball blast leaves a scorch decal")
	check(Engine.time_scale == ts and not paused, "Impact hit-stop never touches game time")

	# Ice look: water spells with a cold status. Frost nova = crystals along the live front.
	clear()
	foe(Vector2(120, 0))
	c = cast("frost nova", 0.0)
	var nova = null
	for p in c.parts:
		nova = p
	check(nova != null and vfx.presents(nova), "Frost nova is presented (ice look)")
	check(vfx.presenter.look_of(c.plan).native == "ice", "Water + chilled payload resolves to the Ice look")
	c.run(0.15, DT, tick_all)
	check(vfx.elements.flakes.size() > 0 and vfx.elements.crystals.is_empty(), "Ice nova is a frost wave: snowflakes off the front, no crystal wall")
	var before: int = vfx.elements.flakes.size()
	c.run(0.6, DT, tick_all)
	check(vfx.elements.flakes.size() > before and vfx.elements.crystals.is_empty(), "Where the wave stops: a burst of snow, no crystals")

	# Water (no cold status): Tsunami is a wall of water goo on the travelling hitbox.
	clear()
	foe(Vector2(120, 0))
	c = cast("tsunami", 0.0)
	var wave = null
	for p in c.parts:
		wave = p
	check(wave != null and vfx.presents(wave) and vfx.presenter.look_of(c.plan).native == "water", "Tsunami is presented with the Water look")
	c.run(0.2, DT, tick_all)
	vfx._draw_water()
	check(vfx._water_used, "Tsunami accumulates water goo for the shaders")
	check(not vfx._debris.is_empty(), "Tsunami throws droplets off its leading edge")

	# Shapes on the bare (arcane) spells: slash smear, rune trap, orbiters, arcane nova/field.
	for spell in ["slash", "trap", "orbit", "nova", "field"]:
		clear()
		foe(Vector2(90, 0))
		c = cast(spell, 0.0)
		var shown = false
		for p in c.parts:
			shown = shown or vfx.presents(p)
		if spell == "slash":
			shown = shown or not vfx.elements.slashes.is_empty()
		check(shown, "Bare %s is presented (arcane look), no placeholder art" % spell)

	clear()
	var chilled = foe(Vector2.ZERO)
	chilled.apply_effect({"type": "status", "status": "chilled", "stacks": 1, "duration": 5.0})
	var cold_counts: Array = []
	for reduced in [false, true]:
		vfx.reduced_effects = reduced
		vfx.elements.flakes.clear()
		seed(42)
		for i in 600:
			vfx.presenter._chilled(DT)
		cold_counts.append(vfx.elements.flakes.size())
		var off_body = not vfx.elements.flakes.is_empty()
		for flake in vfx.elements.flakes:
			off_body = off_body and absf(float(flake[0])) > 3.0 and int(flake[6]) == 0
		check(off_body, "Cold status emits small flakes beside the body")
	check(cold_counts[1] > 0 and cold_counts[1] < cold_counts[0], "Reduced effects lowers cold status emission without hiding the cue")
	vfx.reduced_effects = false

	clear()
	c = cast("trap", 0.0)
	var trap = c.parts[0]
	trap.armed = true
	trap.age = 1.0
	var neutral = {"cols": [[Color.WHITE, Color.WHITE], [Color.WHITE, Color.WHITE]]}
	var rune_pixels = PackedByteArray()
	rune_pixels.resize(vfx._size.x * vfx._size.y * 4)
	vfx.presenter._draw_trap(rune_pixels, trap, neutral)
	c.plan.id = "frost_sigil"
	var frost_pixels = PackedByteArray()
	frost_pixels.resize(rune_pixels.size())
	vfx.presenter._draw_trap(frost_pixels, trap, neutral)
	var rune_shape: Array = []
	var frost_shape: Array = []
	for i in range(3, rune_pixels.size(), 4):
		rune_shape.append(rune_pixels[i] > 0)
		frost_shape.append(frost_pixels[i] > 0)
	check(rune_shape.has(true) and frost_shape.has(true), "Both armed trap identities render visible pixels")
	check(rune_shape != frost_shape, "Frost Sigil differs from Rune Trap by silhouette, not just colour")

	# Keyword visuals (plan 5.2) and reactions (plan 5.3).
	clear()
	foe(Vector2(120, 0))
	c = cast("fiery tsunami", 0.25)
	check(vfx.presenter.look_of(c.plan).accent == "fire" and not vfx.elements.mists.is_empty(), "Fiery tsunami: water body, fire accent, the wall steams")
	clear()
	foe(Vector2(120, 0))
	c = cast("charged fireball", 0.0)
	check(not vfx.presenter._charges.is_empty(), "Charged cast gathers energy at the staff before release")
	clear()
	foe(Vector2(120, 0))
	c = cast("sanguine spear", 0.0)
	check(not vfx._debris.is_empty(), "Sanguine cast spills blood at the caster")

	# Every engine element has a look; anything unknown keeps the placeholder art.
	clear()
	foe(Vector2(120, 0))
	c = cast("spear", 0.0)
	var bare = c.plan.duplicate(true)
	bare.element = "earth"
	var all_built = true
	for el in ["", "arcane", "fire", "water", "storm", "earth", "plague", "life"]:
		bare.element = el
		all_built = all_built and vfx.presenter.look_of(bare).native != ""
	check(all_built, "Every engine element resolves to a built look")
	bare.element = "made_up"
	check(vfx.presenter.look_of(bare).native == "", "Unknown elements resolve to no look: placeholder art stays")

	clear()
	print("vfx_presenter_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
