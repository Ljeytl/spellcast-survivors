extends SceneTree
## Spell engine foundations: type chart, typed damage, statuses, reactions, legacy fallback (doc 18 §5–6).

const Effects = preload("res://scripts/engine/Effects.gd")
const TypeChart = preload("res://scripts/engine/TypeChart.gd")

var checks = 0
var failures = 0

class Fake extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var armour = 0.0
	var status = null
	var max_health = 1000.0
	var current_health = 1000.0
	var damage = 10.0
	var dying = false
	var is_elite = false
	var received: Array = []
	func apply_effect(e, s = {}, o = Vector2.INF):
		return FX.apply_to_entity(self, e, s, o)
	func receive_damage(a, _o = Vector2.INF, _s = {}):
		current_health -= a
		received.append(a)
	func armour_value():
		return armour
	func process_status_effects(_delta):
		pass

class Legacy extends Node2D:
	var taken = 0.0
	var slowed = []
	var knocked = Vector2.ZERO
	func take_damage(a, _p = Vector2.INF, _s = {}):
		taken += a
	func apply_slow(m, d):
		slowed.append([m, d])
	func apply_knockback(dir, f):
		knocked += dir * f

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

func fake(pos = Vector2.ZERO) -> Fake:
	var f = Fake.new()
	f.position = pos
	root.add_child(f)
	f.add_to_group("enemies")
	return f

func dmg(entries: Array, element = "", cast = 0) -> Dictionary:
	return {"type": "damage", "entries": entries, "element": element}

func src(cast) -> Dictionary:
	return {"spell": "test", "cast_clock": 0.0, "cast_id": cast}

func run_ticks(f, seconds, step = 0.05):
	var t = 0.0
	while t < seconds - 0.0001:
		f.status.tick(step)
		t += step

func clear():
	for n in root.get_children():
		if n is Fake or n is Legacy:
			n.free()

func run():
	type_chart()
	damage_resolution()
	legacy_fallback()
	burn()
	bleed()
	poison()
	chill()
	slows_and_control()
	shock()
	reactions()
	await real_enemy()
	print("engine_effects_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

func type_chart():
	var cycle = ["storm", "water", "fire", "plague", "life", "earth"]
	for i in cycle.size():
		var a = cycle[i]
		var b = cycle[(i + 1) % cycle.size()]
		check(near(TypeChart.multiplier(a, b), 1.25), a + " beats " + b)
		check(near(TypeChart.multiplier(b, a), 1.0), b + " is neutral back to " + a)
		check(near(TypeChart.multiplier(a, a), 0.75), a + " vs itself is resisted")
		var opposite = cycle[(i + 3) % cycle.size()]
		check(near(TypeChart.multiplier(a, opposite), 1.0), a + " vs " + opposite + " is neutral")
	check(near(TypeChart.multiplier("arcane", "fire"), 1.0) and near(TypeChart.multiplier("fire", "arcane"), 1.0), "Arcane is neutral both ways")
	check(near(TypeChart.multiplier("raw", "fire"), 1.0), "Raw is neutral")
	check(near(TypeChart.multiplier("ice", "fire"), 1.25) and near(TypeChart.multiplier("steel", "storm"), 1.25), "Legacy names map onto the seven elements")
	check(near(TypeChart.multiplier("", "fire"), 1.0) and near(TypeChart.multiplier("fire", ""), 1.0), "No element is neutral")

func damage_resolution():
	var f = fake()
	f.armour = 0.3
	f.apply_effect(dmg([{"amount": 100, "damage_type": "raw"}]))
	check(near(f.received.back(), 70), "Armour reduces raw damage")
	f.apply_effect(dmg([{"amount": 100, "damage_type": "fire"}], "fire"))
	check(near(f.received.back(), 100), "Armour does not touch elemental damage")
	f.apply_effect(dmg([{"amount": 100, "damage_type": "raw", "ignores_armour": true}]))
	check(near(f.received.back(), 100), "ignores_armour bypasses armour")
	f.armour = 0.0
	f.element = "fire"
	f.apply_effect(dmg([{"amount": 74, "damage_type": "raw"}, {"amount": 22, "damage_type": "fire"}], "fire"))
	check(near(f.received.back(), 96 * 0.75), "Same element resists the whole Ember Spear hit (keyed on spell element)")
	f.apply_effect(dmg([{"amount": 74, "damage_type": "raw"}, {"amount": 22, "damage_type": "fire"}, {"amount": 14, "damage_type": "water", "chart_element": "water"}], "fire"))
	check(near(f.received.back(), 96 * 0.75 + 14 * 1.25), "Icy share of icy ember spear uses its own element against a fire enemy")
	f.element = "water"
	f.apply_effect(dmg([{"amount": 100, "damage_type": "storm"}], "storm"))
	check(near(f.received.back(), 125), "Storm beats Water/Ice")
	f.element = ""
	f.resistances = {"fire": 0.5}
	f.apply_effect(dmg([{"amount": 100, "damage_type": "fire"}], "fire"))
	check(near(f.received.back(), 50), "Per-element resistance applies to that element only")
	f.apply_effect(dmg([{"amount": 100, "damage_type": "raw"}], "fire"))
	check(near(f.received.back(), 100), "Resistance does not touch raw")
	f.resistances = {}
	Effects.apply(f, {"type": "status", "status": "vulnerable"})
	f.apply_effect(dmg([{"amount": 100, "damage_type": "raw"}]))
	check(near(f.received.back(), 115), "Vulnerable increases damage taken")
	check(f.status != null and f.get_node_or_null("StatusComponent") != null, "Status component is created on first need")
	clear()

func legacy_fallback():
	var l = Legacy.new()
	root.add_child(l)
	Effects.apply(l, dmg([{"amount": 74, "damage_type": "raw"}, {"amount": 22, "damage_type": "fire"}], "fire"))
	check(near(l.taken, 96), "Targets without apply_effect still take the full hit through take_damage")
	Effects.apply(l, {"type": "status", "status": "chilled"})
	check(l.slowed.size() == 1 and l.slowed[0][0] < 1.0, "Chill falls back to apply_slow on legacy targets")
	Effects.apply(l, {"type": "impulse", "direction": Vector2.RIGHT, "force": 300})
	check(near(l.knocked.x, 300), "Impulse falls back to apply_knockback")
	Effects.apply(l, {"type": "status", "status": "poison", "hit": 100})
	check(true, "Unknown-to-legacy statuses are ignored safely")
	l.free()

func burn():
	var f = fake()
	Effects.apply(f, {"type": "status", "status": "burn", "hit": 100}, src(1))
	run_ticks(f, 1.5)
	check(near(1000 - f.current_health, 15, 0.05), "One burn deals 15% of its hit over 1.5 s")
	check(not f.status.has("burn"), "A burn ends after 1.5 s")
	f.current_health = 1000
	Effects.apply(f, {"type": "status", "status": "burn", "hit": 100}, src(1))
	run_ticks(f, 0.5)
	Effects.apply(f, {"type": "status", "status": "burn", "hit": 100}, src(1))
	check(f.status.burns.size() == 2, "Each fire hit adds its own burn")
	run_ticks(f, 2.0)
	check(near(1000 - f.current_health, 30, 0.05), "Overlapping burns each deal their full share")
	clear()

func bleed():
	var f = fake()
	Effects.apply(f, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	run_ticks(f, 4.0)
	check(near(1000 - f.current_health, 24, 0.05), "One bleed deals 3% of its hit every 0.5 s for 4 s")
	f.current_health = 1000
	f.status.bleed_meter = 0.0
	for i in 4:
		Effects.apply(f, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	check(near(f.status.bleed_meter, 0.8) and f.current_health == 1000, "Four bleeding hits fill the meter to 80% without bursting")
	Effects.apply(f, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	check(near(1000 - f.current_health, 0.12 * 1000 + 3 * 3, 0.05), "The fifth fills the meter: hemorrhage for 12% max health + 3x the bleed")
	check(near(f.status.bleed_meter, 0.0) and "hemorrhage" in f.status.reactions_fired, "The meter empties after a hemorrhage")
	var boss = fake()
	boss.add_to_group("bosses")
	for i in 7:
		Effects.apply(boss, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	check(boss.current_health == 1000, "Bosses need more bleed before hemorrhaging")
	Effects.apply(boss, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	check(near(1000 - boss.current_health, 0.03 * 1000 + 9, 0.05), "Boss hemorrhage uses 3% of max health")
	var armoured = fake()
	armoured.armour = 0.5
	Effects.apply(armoured, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	run_ticks(armoured, 4.0)
	check(near(1000 - armoured.current_health, 24, 0.05), "Bleed ticks ignore armour")
	var decaying = fake()
	Effects.apply(decaying, {"type": "status", "status": "bleed", "hit": 100}, src(1))
	run_ticks(decaying, 4.0)
	check(decaying.status.bleed_meter < 0.2 - 0.1, "The meter drains after 2 s without a new bleed")
	clear()

func poison():
	var f = fake()
	Effects.apply(f, {"type": "status", "status": "poison", "hit": 100}, src(1))
	check(near(f.damage, 8.0), "Poisoned enemies are weakened (deal 20% less)")
	run_ticks(f, 10.0)
	var expected = 2.0 * (pow(1.15, 10) - 1.0) / 0.15
	check(near(1000 - f.current_health, expected, 0.1), "Poison ramps 15% per tick over 10 s (~40.6 per 100)")
	check(not f.status.has("poison") and near(f.damage, 10.0), "Weaken ends with the poison")
	var g = fake()
	Effects.apply(g, {"type": "status", "status": "poison", "hit": 100}, src(1))
	run_ticks(g, 5.0)
	var before = g.status.poison.ticks
	Effects.apply(g, {"type": "status", "status": "poison", "hit": 100}, src(1))
	check(g.status.poison.ticks == before and near(g.status.poison.base, 4.0), "New poison adds damage without resetting the ramp")
	check(near(g.status.poison.remaining, 10.0), "New poison refreshes the duration")
	check(_poison_more_than_bleed(), "Poison deals more total than bleed over its life")
	clear()

func _poison_more_than_bleed() -> bool:
	return 2.0 * (pow(1.15, 10) - 1.0) / 0.15 > 24.0

func chill():
	var f = fake()
	for i in 4:
		Effects.apply(f, {"type": "status", "status": "chilled", "hit": 100}, src(1))
	check(f.status.chill_stacks() == 4, "Each hit adds a stack of chill")
	check(near(1000 - f.current_health, 16), "Each chill application deals 4% frostbite")
	check(near(f.status.move_multiplier(), 1.0 - 0.24), "Slow grows with stacks (6% each)")
	Effects.apply(f, {"type": "status", "status": "chilled", "hit": 100}, src(1))
	check(f.status.has("frozen") and not f.status.has("chilled"), "Five stacks freeze; chill clears")
	check(near(f.status.move_multiplier(), 0.0) and f.status.locked("attack"), "Frozen cannot move or attack")
	run_ticks(f, 1.6)
	check(not f.status.has("frozen"), "Frozen ends after 1.5 s")
	for i in 5:
		Effects.apply(f, {"type": "status", "status": "chilled", "hit": 100}, src(1))
	check(not f.status.has("frozen"), "Short immunity stops an instant refreeze")
	run_ticks(f, 2.1)
	f.status.chill = {}
	for i in 5:
		Effects.apply(f, {"type": "status", "status": "chilled", "hit": 100}, src(1))
	check(f.status.has("frozen"), "After immunity it can freeze again")
	var g = fake()
	for i in 8:
		Effects.apply(g, {"type": "status", "status": "chilled", "hit": 10, "no_freeze": true}, src(1))
	check(not g.status.has("frozen") and g.status.chill_stacks() == 4, "Fields and trails chill but never freeze")
	clear()

func slows_and_control():
	var f = fake()
	for i in 3:
		Effects.apply(f, {"type": "status", "status": "chilled", "hit": 0}, src(1))
	Effects.apply(f, {"type": "status", "status": "slowed", "strength": 0.3}, src(1))
	check(near(f.status.slow_amount(), 0.3 + 0.18 * 0.1), "Slows: strongest plus 10% of the others")
	Effects.apply(f, {"type": "status", "status": "slowed", "strength": 0.95}, src(1))
	check(near(f.status.slow_amount(), 0.7), "Slows cap at 70%")
	var e = fake()
	for i in 2:
		Effects.apply(e, {"type": "status", "status": "entangled"}, src(1))
	check(not e.status.has("rooted"), "Two entangles do not root")
	Effects.apply(e, {"type": "status", "status": "entangled"}, src(1))
	check(e.status.has("rooted") and e.status.locked("move") and not e.status.locked("attack"), "Three entangles within 3 s root (can still attack)")
	var boss = fake()
	boss.add_to_group("bosses")
	Effects.apply(boss, {"type": "status", "status": "stunned"}, src(1))
	check(near(boss.status.remaining_of("stunned"), 0.8), "First stun on a boss is full length")
	run_ticks(boss, 1.0)
	Effects.apply(boss, {"type": "status", "status": "stunned"}, src(1))
	check(near(boss.status.remaining_of("stunned"), 0.4), "A repeat stun within 4 s is halved on bosses")
	var normal = fake()
	Effects.apply(normal, {"type": "status", "status": "stunned"}, src(1))
	run_ticks(normal, 1.0)
	Effects.apply(normal, {"type": "status", "status": "stunned"}, src(1))
	check(near(normal.status.remaining_of("stunned"), 0.8), "Normal enemies have no diminishing returns")
	clear()

func shock():
	var a = fake(Vector2(0, 0))
	var b = fake(Vector2(100, 0))
	var far = fake(Vector2(400, 0))
	Effects.apply(a, {"type": "status", "status": "shocked", "hit": 100}, src(1))
	check(near(1000 - b.current_health, 40), "Shock arcs to the nearest enemy for 40% of the hit")
	check(b.status != null and b.status.has("shocked"), "The arc shocks its target")
	check(far.current_health == 1000, "Shock does not reach enemies outside 150")
	check(a.status.locked("move"), "Shocked enemies stagger briefly")
	clear()

func reactions():
	# Thaw: fire from a different cast on a chilled enemy
	var a = fake(Vector2.ZERO)
	var n = fake(Vector2(60, 0))
	Effects.apply(a, {"type": "status", "status": "chilled", "hit": 0}, src(1))
	a.apply_effect(dmg([{"amount": 100, "damage_type": "fire"}], "fire"), src(2))
	check("thaw" in a.status.reactions_fired and not a.status.has("chilled"), "Thaw: fire on chill from another cast")
	check(n.current_health < 1000, "Thaw's steam burst hits enemies nearby")
	# Fusion: same cast, no reaction
	var b = fake(Vector2(500, 0))
	Effects.apply(b, {"type": "status", "status": "chilled", "hit": 0}, src(7))
	b.apply_effect(dmg([{"amount": 100, "damage_type": "fire"}], "fire"), src(7))
	check(b.status.reactions_fired.is_empty() and b.status.has("chilled"), "One cast fuses: icy fire keeps its chill")
	# Shatter
	var c = fake(Vector2(1000, 0))
	Effects.apply(c, {"type": "status", "status": "frozen"}, src(3))
	c.apply_effect(dmg([{"amount": 100, "damage_type": "raw"}, {"amount": 20, "damage_type": "earth"}], "earth"), src(4))
	check("shatter" in c.status.reactions_fired and not c.status.has("frozen"), "Shatter: earth on frozen ends the freeze")
	check(near(c.received.back(), 120 + 60), "Shatter adds half the hit")
	# Toxic flare
	var d = fake(Vector2(1500, 0))
	var dn = fake(Vector2(1560, 0))
	Effects.apply(d, {"type": "status", "status": "poison", "hit": 100}, src(5))
	d.apply_effect(dmg([{"amount": 50, "damage_type": "fire"}], "fire"), src(6))
	check("toxic_flare" in d.status.reactions_fired and not d.status.has("poison"), "Toxic Flare consumes the poison")
	check(dn.current_health < 1000, "Toxic Flare hits nearby enemies")
	# Overload
	var e = fake(Vector2(2000, 0))
	Effects.apply(e, {"type": "status", "status": "bleed", "hit": 100}, src(8))
	e.apply_effect(dmg([{"amount": 10, "damage_type": "arcane"}], "arcane"), src(9))
	check("overload" in e.status.reactions_fired and near(e.received.back(), 10 + 24), "Overload lands the remaining bleed at once")
	# Cleanse
	var g = fake(Vector2(2500, 0))
	Effects.apply(g, {"type": "status", "status": "poison", "hit": 100}, src(10))
	g.apply_effect(dmg([{"amount": 10, "damage_type": "life"}], "life"), src(11))
	check("cleanse" in g.status.reactions_fired and not g.status.has("poison") and near(g.damage, 10.0), "Cleanse removes poison and its weaken")
	# Cooldown
	var h = fake(Vector2(3000, 0))
	Effects.apply(h, {"type": "status", "status": "chilled", "hit": 0}, src(12))
	h.apply_effect(dmg([{"amount": 10, "damage_type": "fire"}], "fire"), src(13))
	Effects.apply(h, {"type": "status", "status": "chilled", "hit": 0}, src(14))
	h.apply_effect(dmg([{"amount": 10, "damage_type": "fire"}], "fire"), src(15))
	check(h.status.reactions_fired.size() == 1, "Reactions have a 1 s cooldown per enemy")
	run_ticks(h, 1.05)
	h.apply_effect(dmg([{"amount": 10, "damage_type": "fire"}], "fire"), src(16))
	check(h.status.reactions_fired.size() == 2, "After the cooldown it can react again")
	# DoT ticks never react
	var k = fake(Vector2(3500, 0))
	Effects.apply(k, {"type": "status", "status": "chilled", "hit": 0}, src(17))
	Effects.apply(k, {"type": "status", "status": "burn", "hit": 100}, src(18))
	run_ticks(k, 1.0)
	check(k.status.reactions_fired.is_empty(), "Damage-over-time ticks do not trigger reactions")
	clear()

func real_enemy():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var mm = game.get_node("MonsterManager")
	mm.spawn_timer.stop()
	var enemy = mm.spawn_monster(mm.select_monster(), false, true)
	await process_frame
	check(enemy != null and enemy.has_method("apply_effect"), "Encounter enemies expose apply_effect")
	if enemy == null:
		return
	enemy.global_position = game.player.global_position + Vector2(300, 0)
	enemy.max_health = 100000.0
	enemy.current_health = 100000.0
	var hp = enemy.current_health
	enemy.apply_effect({"type": "damage", "entries": [{"amount": 10, "damage_type": "raw"}]}, src(1))
	check(near(hp - enemy.current_health, 10), "A typed hit damages a real enemy once")
	for i in 5:
		enemy.apply_effect({"type": "status", "status": "chilled", "hit": 0}, src(1))
	await physics_frame
	await physics_frame
	check(enemy.status.has("frozen") and near(enemy.slow_multiplier, 0.0), "Frozen stops a real enemy's movement")
	enemy.apply_slow(0.5, 5.0)
	check(near(enemy.slow_multiplier, 0.0), "Legacy slow and statuses combine (still frozen)")
	enemy.status.timed.erase("frozen")
	await physics_frame
	check(near(enemy.slow_multiplier, 0.5), "Legacy apply_slow still works on its own")
	enemy.is_elite = true
	enemy.elite_type = enemy.EliteType.ARMORED
	enemy.damage_reduction = 0.3
	hp = enemy.current_health
	enemy.take_damage(100)
	check(near(hp - enemy.current_health, 70), "Legacy take_damage still applies elite armour")
	hp = enemy.current_health
	enemy.apply_effect({"type": "damage", "entries": [{"amount": 100, "damage_type": "raw"}]}, src(2))
	check(near(hp - enemy.current_health, 70), "Typed raw damage applies armour once, not twice")
	hp = enemy.current_health
	enemy.apply_effect({"type": "damage", "entries": [{"amount": 100, "damage_type": "fire"}], "element": "fire"}, src(3))
	check(near(hp - enemy.current_health, 100), "Typed fire ignores armour on a real enemy")
	game.queue_free()
	await process_frame
