extends "res://tests/engine_generic_spell_regression.gd"

func run():
	caster = Caster.new()
	root.add_child(caster)
	var vfx = root.get_node("Vfx")
	vfx._active = true
	var info = root.get_node("DataManager").get_spell_data("mana_bolt")
	info.incantation = "mana missile"
	Defs.register(preload("res://scripts/engine/SpellTemplate.gd").build(info, 8.0, {}))
	for phrase in ["mana missile", "burning mana missile", "freezing mana missile"]:
		var results: Array = []
		for enabled in [true, false]:
			clear()
			vfx.clear()
			vfx.presenter.enabled = enabled
			var enemy = foe(Vector2(140, 0))
			var c = cast(phrase, 0.6)
			check(enemy.taken() > 0, phrase + " damages")
			results.append([enemy.taken(), c.hits_log.size(), enemy.pushed])
		check(results[0] == results[1], phrase + " presentation preserves contacts, damage and force")
	clear()
	vfx.clear()
	vfx.presenter.enabled = true
	foe(Vector2(1000, 0))
	var c = cast("mana missile", 0.0)
	c.advance(0.01)
	var part = c.parts[0]
	check(vfx.presenter._is_magic_missile(part), "Friendly missile uses diamond presentation")
	var st = vfx.presenter._parts[part.get_instance_id()]
	var sparks_before: int = vfx._sparks.size()
	vfx.presenter._trail(part, st, Vector2(3, 0), 1.0 / 60.0)
	check(vfx._sparks.size() == sparks_before, "Ribbon replaces scattered flight sparks")
	check(st.has("missile_ribbon"), "Flight owns a ribbon history")
	var ribbon = st.missile_ribbon
	ribbon.advance(0.04)
	ribbon.sample(Vector2(5, 2), Vector2.RIGHT, 1.0)
	ribbon.advance(0.04)
	ribbon.sample(Vector2(10, 4), Vector2.RIGHT, 1.0)
	check(ribbon.samples.size() == 3, "Ribbon retains multiple flight positions")
	check(ribbon.samples[1].p == Vector2(5, 2), "Ribbon retains the curved path rather than a fixed tail")
	vfx._origin = Vector2i.ZERO
	vfx._size = Vector2i(64, 64)
	var buf := PackedByteArray()
	buf.resize(64 * 64 * 4)
	vfx.presenter._draw_magic_missile(buf, Vector2(32, 32) / vfx.K, Vector2.RIGHT, part, "")
	var transparent_pixels := 0
	var opaque_pixels := 0
	for i in range(3, buf.size(), 4):
		if buf[i] > 0 and buf[i] < 255:
			transparent_pixels += 1
		if buf[i] == 255:
			opaque_pixels += 1
	check(transparent_pixels > 10, "Diamond writes slightly translucent facets")
	check(opaque_pixels == 0, "Facets preserve edge translucency")
	var ribbon_buf := PackedByteArray()
	ribbon_buf.resize(64 * 64 * 4)
	ribbon.draw(ribbon_buf, vfx.presenter)
	check(ribbon_buf.count(0) < ribbon_buf.size(), "Visible curved ribbon rasterizes into the viewport")
	vfx._origin = Vector2i(1000000, 1000000)
	ribbon_buf.fill(0)
	ribbon.draw(ribbon_buf, vfx.presenter)
	check(ribbon_buf.count(0) == ribbon_buf.size(), "Fully offscreen ribbon leaves the viewport untouched")
	vfx._origin = Vector2i(10, 0)
	ribbon.draw(ribbon_buf, vfx.presenter)
	check(ribbon_buf.count(0) < ribbon_buf.size(), "Ribbon crossing a shifted viewport edge still renders")
	vfx._origin = Vector2i.ZERO
	vfx._stop = 0
	var stars_before: int = vfx._stars.size()
	vfx.presenter.part_hit(part, null, part.global_position)
	check(vfx._stars.size() - stars_before == 1, "One compact glint replaces duplicated contact stars")
	check(vfx._stop == 0, "Passive missile contact does not stop gameplay")
	vfx.presenter.part_finished(part, false)
	check(ribbon.finished and not ribbon.samples.is_empty(), "Contact retains a fading detached ribbon")
	vfx.presenter.step(0.3 * vfx.fx_speed)
	check(vfx.presenter._missile_ribbons.is_empty(), "Detached ribbon expires without leaking")
	c.target_group = "player"
	check(not vfx.presenter._is_magic_missile(part), "Hostile presentation remains separate")
	clear()
	vfx.clear()
	print("Magic Missile feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
