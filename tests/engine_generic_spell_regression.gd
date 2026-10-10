extends SceneTree
## Generic spell runtime: every delivery, events, keywords, caps, fusion vs reactions (doc 18 §4–8).
## Casts run in manual mode against duck-typed enemies so every frame is deterministic.

const KP = preload("res://scripts/engine/KeywordParser.gd")
const Defs = preload("res://scripts/engine/SpellDefs.gd")
const Planner = preload("res://scripts/engine/CastPlanner.gd")
const GenericCast = preload("res://scripts/engine/GenericCast.gd")
const DT = 1.0 / 60.0

var checks = 0
var failures = 0
var caster: Node2D

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

func near(a, b, eps = 0.01) -> bool:
	return absf(float(a) - float(b)) <= eps

func foe(pos: Vector2, hp = 100000.0) -> Foe:
	var f = Foe.new()
	f.position = pos
	f.max_health = hp
	f.current_health = hp
	root.add_child(f)
	f.add_to_group("enemies")
	return f

func clear():
	for n in root.get_children():
		if n is Foe or n is Node2D and (n.name.begins_with("Part_") or n.get_script() == GenericCast):
			n.free()
	caster.global_position = Vector2.ZERO
	caster.health = 100.0

func cast(text: String, seconds: float = 3.0, seed_value: int = 1, opts: Dictionary = {}):
	var parsed = KP.parse(text, Defs.by_incantation().keys())
	if not parsed.ok:
		check(false, "parse " + text + ": " + parsed.error)
		return null
	var o = opts.duplicate()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	o.rng = rng
	var pl = Planner.plan(Defs.get_def(Defs.by_incantation()[parsed.spell]), parsed.bundle, o)
	check(pl.rejected.is_empty(), text + " plans cleanly: " + str(pl.rejected))
	var c = GenericCast.new()
	root.add_child(c)
	c.setup(pl, caster, root, {"spell": pl.id, "cast_clock": 0.0, "cast_id": randi()}, true, seed_value)
	if seconds > 0.0:
		c.run(seconds, DT, tick_all)
	return c

func tick_all(dt: float) -> void:
	for n in root.get_children():
		if n is Foe and n.status != null and is_instance_valid(n.status):
			n.status.tick(dt)

func parts_named(c, n) -> int:
	return c.hits_log.filter(func(h): return h.part == n).size()

func run():
	caster = Caster.new()
	root.add_child(caster)
	deliveries()
	clear()
	data_spells()
	clear()
	keywords_runtime()
	clear()
	caps_and_safety()
	clear()
	fusion_and_reactions()
	clear()
	await lifecycle_cleanup()
	print("engine_generic_spell_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

func deliveries():
	# Projectile: bare spear pierces everything in its line, once each.
	var a = foe(Vector2(200, 0))
	var b = foe(Vector2(400, 0))
	var off = foe(Vector2(300, 200))
	var c = cast("spear", 2.0)
	check(near(a.taken(), 22) and near(b.taken(), 22), "Spear pierces and hits each enemy once for 22")
	check(off.received.is_empty(), "Spear misses enemies off its line")
	check(c.finished, "Spear ends at its range")
	clear()
	# Volume, expanding ring with knockback away.
	a = foe(Vector2(100, 0))
	b = foe(Vector2(0, -160))
	var far = foe(Vector2(300, 0))
	c = cast("nova", 1.0)
	check(near(a.taken(), 14) and near(b.taken(), 14) and far.received.is_empty(), "Nova hits inside 170 only")
	check(a.pushed.x > 0.0 and b.pushed.y < 0.0, "Nova pushes away from its centre")
	clear()
	# Field: periodic damage while standing in it.
	a = foe(Vector2(150, 0))
	c = cast("field", 3.5)
	check(a.received.size() >= 6 and a.received.size() <= 7 and near(a.received[0], 3), "Field ticks every 0.5 s for 3 s (got " + str(a.received.size()) + ")")
	clear()
	# Orbit: circles the caster, rehits every 0.5 s.
	a = foe(Vector2(90, 0))
	c = cast("orbit", 4.5)
	check(a.received.size() >= 3, "Orbit body rehits a nearby enemy (" + str(a.received.size()) + ")")
	check(c.finished, "Orbit ends at its lifetime")
	clear()
	# Trap: arms, waits, triggers when an enemy walks in.
	# With nothing around, the glyph lands ahead of the caster.
	c = cast("trap", 0.0)
	c.run(0.05, DT, tick_all)
	a = foe(Vector2(1000, 0))
	c.run(0.2, DT, tick_all)
	var glyph = c.parts[0]
	var glyph_pos = glyph.global_position
	c.run(1.0, DT, tick_all)
	check(a.received.is_empty() and not c.finished, "Trap waits while nothing is in it")
	a.global_position = glyph_pos + Vector2(20, 0)
	var bystander = foe(glyph_pos + Vector2(70, 0))
	c.run(0.5, DT, tick_all)
	check(near(a.taken(), 18) and near(bystander.taken(), 18), "Trap bursts on contact and hits the area")
	check(c.finished, "Trap is spent")
	clear()
	# Cast at an enemy, the glyph lands under it and springs once armed.
	a = foe(Vector2(300, 0))
	c = cast("trap", 0.3)
	check(a.received.is_empty(), "Trap does not spring before it arms")
	c.run(0.5, DT, tick_all)
	check(near(a.taken(), 18), "Trap under an enemy springs once armed")
	clear()
	# Trap expiry with nothing triggering.
	c = cast("trap", 0.0)
	c.run(0.05, DT, tick_all)
	foe(Vector2(2000, 0))
	c.run(9.0, DT, tick_all)
	check(c.finished and c.hits_log.is_empty(), "Unsprung trap expires quietly")
	clear()
	# Cone: front only.
	a = foe(Vector2(90, 0))
	b = foe(Vector2(-100, 0))
	var side = foe(Vector2(0, 100))
	c = cast("slash", 0.2)
	check(near(a.taken(), 16) and b.received.is_empty() and side.received.is_empty(), "Slash hits its 100° cone only")

func data_spells():
	# Fireball: orb hit + blast; blast hits neighbours.
	var a = foe(Vector2(300, 0))
	var b = foe(Vector2(360, 0))
	var c = cast("fireball", 2.0)
	check(near(a.taken(), 30 + 60), "Fireball: orb 30 + blast 60 on the target")
	check(near(b.taken(), 60), "Fireball blast hits a neighbour")
	clear()
	# Fireball with no enemies: blast where it expires.
	c = cast("fireball", 2.0)
	check(c.finished and c.spawned == 2, "Fireball bursts at its range when it hits nothing")
	clear()
	# Frost Nova: chill stacks and can freeze with enough stacks.
	a = foe(Vector2(120, 0))
	c = cast("frost nova", 1.0)
	check(a.status != null and a.status.chill_stacks() == 3, "Frost Nova applies 3 chill stacks")
	cast("frost nova", 1.0)
	check(a.status.has("frozen"), "Two Frost Novas freeze (5 stacks)")
	clear()
	# Tsunami: wide travelling wall from behind the caster.
	var mark = foe(Vector2(300, 0))
	a = foe(Vector2(450, 300))
	b = foe(Vector2(450, -300))
	c = cast("tsunami", 3.0)
	check(near(a.taken(), 80) and near(b.taken(), 80) and near(mark.taken(), 80), "Tsunami sweeps its full width once")
	check(mark.pushed.x > 0.0, "Tsunami carries enemies along its travel")
	clear()
	# Flame Wall: rehit 1 s, applies burn.
	a = foe(Vector2(220, 0))
	c = cast("flame wall", 0.3)
	var wall = c.parts[0]
	a.global_position = wall.global_position
	c.run(6.5, DT, tick_all)
	var direct = a.received.filter(func(x): return x >= 29.0)
	check(direct.size() >= 5 and direct.size() <= 7, "Flame Wall hits once per second (" + str(direct.size()) + ")")
	check(a.received.size() > direct.size(), "Flame Wall burns tick between hits")
	clear()
	# Lightning Rod: spear hits, rod strikes enemies around the struck one.
	a = foe(Vector2(300, 0))
	b = foe(Vector2(380, 60))
	c = cast("lightning rod", 5.0)
	check(c.hits_log.any(func(h): return h.part == "rod" or h.part == "strike"), "Lightning Rod strikes from the rod")
	check(b.received.size() >= 1 or a.received.size() >= 3, "Rod strikes keep landing (a=" + str(a.received.size()) + ", b=" + str(b.received.size()) + ")")
	clear()
	# Meteor Ring: held until something comes into range, then released one at a time.
	c = cast("meteor ring", 1.0)
	check(c.parts.size() == 8 and c.parts.all(func(p): return not p.released), "Meteor Ring: 8 meteors held in orbit")
	a = foe(Vector2(400, 0))
	c.run(0.05, DT, tick_all)
	var released = c.parts.filter(func(p): return p.released).size()
	check(released == 1, "Meteors release one at a time (" + str(released) + ")")
	c.run(3.0, DT, tick_all)
	check(parts_named(c, "impact") >= 8, "Every released meteor lands an impact")
	check(a.received.size() >= 8, "All meteors hit the target")
	clear()
	# Regrowth heals the caster (learnable self spell).
	caster.health = 50.0
	cast("regrowth", 0.1)
	check(near(caster.healed, 12.0) and near(caster.health, 62.0), "Regrowth heals 12")
	caster.healed = 0.0
	cast("mega regrowth", 1.0)
	check(near(caster.healed, 18.0), "MEGA Regrowth heals 18 after its charge")

func keywords_runtime():
	var a = foe(Vector2(300, 0))
	var up = foe(Vector2(300, 80))
	var down = foe(Vector2(300, -80))
	var c = cast("triple spear", 2.0)
	check(parts_named(c, "spear") >= 3 and c.spawned == 3, "TRIPLE spear fires three")
	check(near(a.taken(), 22 * 0.45), "Each copy deals 45%")
	clear()
	# Homing: target off-axis behind a curve.
	a = foe(Vector2(250, 250))
	var straight = cast("spear", 2.0)
	var straight_hits = a.received.size()
	clear()
	a = foe(Vector2(250, 250))
	caster.set("last_direction", Vector2.RIGHT)
	c = cast("homing fireball", 3.0)
	check(a.received.size() >= 1, "HOMING fireball reaches its target")
	clear()
	# Splitting: three splinters after the first hit, skipping the struck enemy.
	a = foe(Vector2(200, 0))
	var b = foe(Vector2(400, 0))
	var b2 = foe(Vector2(380, 150))
	c = cast("splitting fireball", 2.5)
	check(parts_named(c, "_split") >= 1, "SPLITTING splinters hit something")
	check(c.hits_log.filter(func(h): return h.part == "_split" and h.enemy == a.get_instance_id()).is_empty(), "Splinters skip the struck enemy")
	clear()
	# Exploding: blast on hit damages a neighbour the spear never touches.
	a = foe(Vector2(200, 0))
	b = foe(Vector2(200, 50))
	c = cast("exploding spear", 1.5)
	check(near(b.taken(), 11), "EXPLODING spear blasts a neighbour for 50%")
	clear()
	# Chaining: jumps to three other enemies, never back.
	a = foe(Vector2(200, 0))
	var ring = []
	for i in 4:
		ring.append(foe(Vector2(200, 0) + Vector2.RIGHT.rotated(-1.0 + i * 0.66) * 150.0))
	c = cast("chaining fireball", 3.0)
	var chain_hits = c.hits_log.filter(func(h): return h.part == "_chain")
	var ids = {}
	for h in chain_hits:
		ids[h.enemy] = true
	check(chain_hits.size() == 3 and ids.size() == 3 and not ids.has(a.get_instance_id()), "CHAINING hops to three new enemies (" + str(chain_hits.size()) + ")")
	clear()
	# Cascading: kill spawns a copy.
	a = foe(Vector2(200, 0), 10.0)
	b = foe(Vector2(500, 30))
	c = cast("cascading fireball", 3.0)
	check(a.dying and parts_named(c, "_cascade") >= 1, "CASCADING copies the spell on a kill")
	clear()
	# Twinned / repeating / delayed / charged timing.
	a = foe(Vector2(200, 0))
	c = cast("twinned spear", 2.0)
	check(a.received.size() == 2 and near(a.received[1], 22 * 0.8), "TWINNED casts a second at 80%")
	clear()
	a = foe(Vector2(100, 0))
	c = cast("repeating nova", 2.0)
	check(a.received.size() == 2 and near(a.received[1], 14 * 0.4), "REPEATING echoes at 40%")
	clear()
	a = foe(Vector2(200, 0))
	c = cast("delayed spear", 0.7)
	check(a.received.is_empty(), "DELAYED has not fired yet at 0.7 s")
	c.run(1.0, DT, tick_all)
	check(near(a.taken(), 22 * 1.15), "DELAYED fires for ×1.15")
	clear()
	a = foe(Vector2(200, 0))
	c = cast("mega spear", 0.3)
	check(a.received.is_empty(), "MEGA charges before release")
	c.run(1.0, DT, tick_all)
	check(near(a.taken(), 33), "MEGA spear lands for ×1.5")
	clear()
	# Targeting words.
	a = foe(Vector2(150, 0), 500.0)
	b = foe(Vector2(-400, 0), 5000.0)
	c = cast("hunting spear", 2.0)
	check(not b.received.is_empty() and a.received.is_empty(), "HUNTING aims at the toughest enemy, not the nearest")
	clear()
	var pack = []
	for i in 6:
		pack.append(foe(Vector2.RIGHT.rotated(i * TAU / 6.0) * 300.0))
	c = cast("triple scattered spear", 2.0)
	var struck = pack.filter(func(f): return not f.received.is_empty()).size()
	check(struck >= 2, "SCATTERED spreads copies over different enemies (" + str(struck) + ")")
	clear()
	# Force.
	a = foe(Vector2(120, 0))
	cast("pulling nova", 1.0)
	check(a.pushed.x < 0.0, "PULLING drags toward the centre")
	clear()
	# Self words.
	a = foe(Vector2(100, 0))
	caster.health = 100.0
	cast("sanguine spear", 1.0)
	check(near(caster.health, 90.0) and near(a.taken(), 22 * 1.6), "SANGUINE costs 10% health for ×1.6")
	clear()
	a = foe(Vector2(50, 0))
	cast("blinking nova", 0.5)
	check(caster.global_position.x < -100.0, "BLINKING moves the caster away from the nearest enemy")
	clear()
	# Size.
	a = foe(Vector2(220, 0))
	cast("nova", 1.0)
	check(a.received.is_empty(), "Nova does not reach 220")
	cast("gigantic nova", 1.0)
	check(not a.received.is_empty(), "GIGANTIC nova does")
	clear()
	# Ringed.
	for i in 3:
		foe(Vector2.RIGHT.rotated(i * TAU / 3.0 + 0.3) * 250.0)
	c = cast("ringed spear", 2.0)
	check(c.spawned == 3, "RINGED spear fires three outward")
	clear()
	# Element words on a generic spell.
	a = foe(Vector2(200, 0))
	cast("icy spear", 1.5)
	check(a.status != null and a.status.chill_stacks() == 1 and near(a.received[0], 22 + 3.3), "ICY spear adds water damage and one chill")
	clear()
	a = foe(Vector2(200, 0))
	a.element = "fire"
	cast("icy spear", 1.5)
	check(near(a.received[0], 22 + 3.3 * 1.25), "ICY share beats a fire enemy on the chart")
	clear()
	a = foe(Vector2(200, 0))
	cast("iron spear", 1.5)
	check(a.status.bleed_meter > 0.0, "IRON (earth) word bleeds")
	clear()
	a = foe(Vector2(200, 0))
	cast("toxic spear", 1.5)
	check(a.status.has("poison"), "TOXIC word poisons")
	clear()
	# Quick cast.
	a = foe(Vector2(200, 0))
	cast("spear", 1.5, 1, {"quick": true, "rank_power": 0.35})
	check(near(a.taken(), 22 * 0.35), "Quick cast deals 35%")

func b_list_clear():
	pass

func caps_and_safety():
	# A dense pack and every multiplying word: the spawn cap holds.
	for i in 60:
		foe(Vector2(200 + (i % 10) * 25, -120 + int(i / 10) * 40), 5.0)
	var c = cast("quadruple splitting exploding fireball", 4.0)
	check(c.spawned <= GenericCast.MAX_SPAWNS, "Spawn cap holds (" + str(c.spawned) + ")")
	check(c.finished, "A capped cast still finishes")
	clear()
	# No enemies at all: everything still resolves without errors.
	for text in ["spear", "nova", "field", "orbit", "slash", "fireball", "frost nova", "tsunami", "flame wall", "lightning rod", "triple homing spear", "chaining spear", "ringed field", "lined trap"]:
		c = cast(text, 10.0)
		check(c.finished, text + " finishes with no enemies")
		clear()
	# Enemy dies mid-flight: homing projectile does not crash and keeps going.
	var a = foe(Vector2(300, 0))
	c = cast("homing spear", 0.1)
	a.free()
	c.run(3.0, DT, tick_all)
	check(c.finished, "Losing the homing target is safe")
	clear()
	# Link depth: events cannot recurse past depth 3.
	var deep = {"id": "deep_test", "name": "Deep", "incantation": "deeptest", "element": "", "acquire": "data_only", "root": "a",
		"parts": {"a": {"delivery": "volume", "origin": "caster", "geometry": {"type": "disk", "radius": 50}, "payload": [{"type": "damage", "amount": 1}], "events": {"on_expire": {"part": "a"}}}}}
	check(Defs.register(deep).is_empty(), "Self-recursive test spell registers")
	foe(Vector2(10, 0))
	c = cast("deeptest", 2.0)
	check(c.finished and c.spawned == 4, "Event recursion stops at link depth 3 (" + str(c.spawned) + ")")
	Defs.unregister("deep_test")

func fusion_and_reactions():
	# One cast with fire and ice: both statuses coexist, no reaction (fusion).
	var a = foe(Vector2(200, 0))
	cast("icy fiery fireball", 1.0)
	check(a.status.chill_stacks() >= 1 and a.status.has("burn"), "ICY FIERY fireball: burn and chill coexist")
	check(not a.status.reactions_fired.has("thaw"), "Same cast does not react with itself")
	# A separate fire cast on the chilled enemy reacts.
	a.status.reaction_ready_at = 0.0
	cast("fireball", 1.0)
	check(a.status.reactions_fired.has("thaw"), "A second fire cast thaws the chill (reaction)")
	clear()
	# Type chart through a spell: fire beats plague.
	a = foe(Vector2(200, 0))
	a.element = "plague"
	cast("fireball", 2.0)
	check(a.received[0] > 30.0, "Fireball beats a plague enemy (" + str(a.received[0]) + ")")

func lifecycle_cleanup():
	clear()
	var target = foe(Vector2(60, 0))
	var c = cast("slash", 0.0)
	c.step(DT)
	check(c.finished and target.taken() > 0.0, "Instant slash resolves damage immediately")
	var damage = target.taken()
	var visuals = c.get_children()
	check(visuals.size() == 1, "Cast owns its completed slash visual")
	if not visuals.is_empty():
		check(visuals[0].done and float(visuals[0].get("visual_remaining")) > 0.0, "Instant slash retains a brief visual after damage resolves")
	c.manual = false
	await create_timer(0.3).timeout
	await process_frame
	check(not is_instance_valid(c), "Running cast frees itself after visual expiry")
	check(near(target.taken(), damage), "Visual linger never repeats slash damage")
	check(root.get_children().filter(func(n): return n.name.begins_with("Part_")).is_empty(), "Finished cast leaves no orphan parts in world")
	clear()
	c = cast("spear", 0.0)
	c.step(DT)
	check(c.parts.size() == 1, "Cancellation fixture has an active projectile")
	var part = weakref(c.parts[0]) if not c.parts.is_empty() else null
	c.queue_free()
	await process_frame
	await process_frame
	check(part != null and part.get_ref() == null, "Cancelling cast also frees its active projectile")
	clear()
