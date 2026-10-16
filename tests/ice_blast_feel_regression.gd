extends "res://tests/engine_generic_spell_regression.gd"

func run():
	caster = Caster.new()
	root.add_child(caster)
	var vfx = root.get_node("Vfx")
	vfx._active = true
	var info = root.get_node("DataManager").get_spell_data("ice_blast")
	info.incantation = "ice blast"
	Defs.register(preload("res://scripts/engine/SpellTemplate.gd").build(info, 8.0, {}))
	for phrase in ["ice blast", "burning ice blast"]:
		var results: Array = []
		for enabled in [true, false]:
			clear()
			vfx.clear()
			vfx.presenter.enabled = enabled
			var enemy = foe(Vector2(140, 0))
			var c = cast(phrase, 0.4)
			check(enemy.taken() > 0, phrase + " damages")
			check(enemy.pushed.length() > 0, phrase + " pushes")
			check(enemy.status != null and enemy.status.chill_stacks() > 0, phrase + " chills")
			results.append([enemy.taken(), enemy.pushed, enemy.status.chill_stacks()])
			if not enabled:
				check(not c.has_meta("ice_contact_feedback"), "Disabled presentation emits no custom feedback")
			if enabled and phrase == "ice blast":
				check(c.has_meta("ice_contact_feedback"), "Native contact feedback runs")
				check(not vfx.elements.shards.is_empty(), "Native contact shatters")
		check(results[0] == results[1], phrase + " presentation preserves damage, push and chill")
	clear()
	vfx.clear()
	vfx.presenter.enabled = true
	var c = cast("ice blast", 0.0)
	c.advance(0.01)
	var part = c.parts[0]
	check(vfx.presenter._is_ice_blast(part), "Friendly Ice Blast uses refinement")
	vfx.presenter._ice_blast_contact(part, Vector2.ZERO)
	check(vfx._stop > 0, "First contact delivers feedback")
	vfx._stop = 0
	vfx.presenter._ice_blast_contact(part, Vector2.ZERO)
	check(vfx._stop == 0, "Simultaneous contacts share feedback window")
	c.clock += 0.13
	vfx.presenter._ice_blast_contact(part, Vector2.ZERO)
	check(vfx._stop > 0, "Later contact feedback resumes")
	c.target_group = "player"
	check(not vfx.presenter._is_ice_blast(part), "Hostile presentation stays separate")
	clear()
	vfx.clear()
	print("Ice Blast feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
