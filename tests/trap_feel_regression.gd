extends "res://tests/vfx_presenter_regression.gd"

const Template = preload("res://scripts/engine/SpellTemplate.gd")

func trap_cast(id: String, mutations: Dictionary = {}):
	var def: Dictionary
	if id == "trap":
		def = Defs.get_def("trap").duplicate(true)
	else:
		var info = {"id": id, "level": 1, "trigger_radius": 60.0, "trap_radius": 120.0, "arm_delay": 1.2 if id == "frost_sigil" else 0.8}
		def = Template.build(info, 55.0, {})
	var root_name = def.root
	if mutations.has("arming"):
		def.parts[root_name].timing.arming = mutations.arming
	if mutations.has("radius"):
		def.parts[root_name].geometry.radius = mutations.radius
	if mutations.has("activation"):
		def.parts.activate.propagation.linger = mutations.activation
	var c = GenericCast.new()
	root.add_child(c)
	c.setup(Planner.plan(def, {}, {}), caster, root, {}, true, 4)
	c.step(0.0)
	return c

func waiting_for_burst(c, enemy) -> bool:
	return enemy.taken() == 0 and c.parts.any(func(p): return p.part_name == "activate")

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	var camera = Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	await process_frame
	await process_frame
	caster = Caster.new()
	root.add_child(caster)
	var counts: Array = []
	for id in ["trap", "rune_trap", "frost_sigil"]:
		clear()
		var c = trap_cast(id)
		var rune = c.root_parts()[0]
		var origin = rune.global_position
		var arm = float(rune.def.timing.arming)
		var enemy = foe(origin)
		c.run(arm - 0.02, DT, tick_all)
		check(enemy.taken() == 0 and not rune.armed, id + " no premature trigger")
		enemy.position = origin + Vector2(rune.geo("radius") + rune.pad_for(enemy) + 0.1, 0)
		c.run(0.04, DT, tick_all)
		check(rune.armed and not rune.done, id + " outside trigger does not detonate")
		var burst_def: Dictionary = c.plan.parts.burst
		var burst_radius := float(burst_def.geometry.radius) + float(burst_def.geometry.get("pad", GenericCast.SpellPart.ENEMY_RADIUS))
		var inside = foe(origin - Vector2(burst_radius - 0.1, 0))
		var outside = foe(origin - Vector2(burst_radius + 0.1, 0))
		enemy.position = origin + Vector2(rune.geo("radius") + rune.pad_for(enemy) - 0.1, 0)
		c.step(DT)
		check(rune.done, id + " entering consumes trap")
		if id != "trap":
			check(waiting_for_burst(c, enemy), id + " native activation precedes damage")
			var activation = c.parts.filter(func(p): return p.part_name == "activate")[0]
			check(is_equal_approx(vfx.presenter._parts[activation.get_instance_id()].life, float(activation.def.propagation.linger)), id + " warning uses actual activation deadline")
			c.run(float(activation.def.propagation.linger) - activation.age - 0.02, DT, tick_all)
			check(waiting_for_burst(c, enemy), id + " activation holds until its actual deadline")
			c.run(0.04, DT, tick_all)
		else:
			c.step(DT)
		check(enemy.taken() > 0, id + " real burst contact")
		if id == "frost_sigil":
			check(c.parts.any(func(p): return p.part_name == "burst" and vfx.presents(p)), "Frost custom burst suppresses fallback damage disk")
		check(inside.taken() > 0 and outside.taken() == 0, id + " exact burst boundary separates inside and outside contacts")
		var damage = enemy.taken()
		if id == "frost_sigil":
			check(vfx._debris.is_empty() and vfx._decals.is_empty(), "Frost burst has no earth debris or scorch")
			check(not vfx.elements.shards.is_empty(), "Frost burst fractures into cold material")
		c.run(1.0, DT, tick_all)
		for i in 90:
			tick_all(DT)
		check(enemy.taken() == damage, id + " one damage per victim")
		if id == "frost_sigil":
			check(vfx.elements.shards.is_empty() and vfx._stars.is_empty() and vfx.presenter._hit_rings.is_empty(), "Frost fragments and burst boundary retire")
		clear()
		c = trap_cast(id)
		c.run(9.0, DT, tick_all)
		check(c.finished if id == "trap" else not c.root_parts().is_empty(), id + " native empty lifetime preserved")
		check(c.hits_log.is_empty() and vfx._debris.is_empty() and vfx.elements.shards.is_empty(), id + " empty lifetime never detonates")
		if id != "trap":
			var second = trap_cast(id)
			check(not c.root_parts().is_empty() and not second.root_parts().is_empty(), id + " recast retains existing trap")
	clear()
	var bad = trap_cast("trap", {"arming": 0.0})
	var victim = foe(bad.root_parts()[0].global_position)
	bad.run(0.2, DT, tick_all)
	check(victim.taken() > 0, "CONTROL early-arm mutation violates no-premature-contact invariant")
	clear()
	bad = trap_cast("trap", {"radius": 90.0})
	victim = foe(bad.root_parts()[0].global_position + Vector2(70, 0))
	bad.run(0.6, DT, tick_all)
	check(victim.taken() > 0, "CONTROL enlarged trigger catches baseline near miss")
	clear()
	bad = trap_cast("rune_trap", {"activation": 0.1})
	victim = foe(bad.root_parts()[0].global_position)
	bad.run(1.0, DT, tick_all)
	check(not waiting_for_burst(bad, victim), "CONTROL shortened activation violates the same waiting predicate")
	for reduced in [false, true]:
		clear()
		vfx.reduced_effects = reduced
		var c = trap_cast("frost_sigil")
		foe(c.root_parts()[0].global_position)
		c.run(1.62, DT, tick_all)
		counts.append(vfx.elements.shards.size())
	check(counts[1] > 0 and counts[1] < counts[0], "Reduced Frost burst preserves cue with fewer fragments")
	clear()
	vfx.presenter._heavy_landing(Vector2.ZERO, 12.0, "arcane", 0.8)
	check(not vfx._debris.is_empty() and not vfx._decals.is_empty(), "CONTROL legacy landing is rejected by cold-material invariant")
	print("TRAP_FEEL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
