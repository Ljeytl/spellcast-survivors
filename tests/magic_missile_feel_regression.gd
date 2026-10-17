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
	check(vfx.presenter._is_magic_missile(part), "Friendly missile uses glass presentation")
	var st = vfx.presenter._parts[part.get_instance_id()]
	vfx.presenter._trail(part, st, Vector2(3, 0), 1.0 / 60.0)
	vfx.presenter._trail(part, st, Vector2(6, 1), 1.0 / 60.0)
	check(st.get("missile_wake", []).size() >= 2, "Wake records the curved flight path")
	vfx.presenter._trail(part, st, Vector2(6, 1), 0.3)
	check(st.get("missile_wake", []).size() <= 1, "Stationary history expires instead of retaining a fixed tail")
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
	check(transparent_pixels > 10, "Body writes actual translucent alpha")
	check(opaque_pixels == 0, "Body does not become an opaque sprite")
	vfx._stop = 0
	var stars_before: int = vfx._stars.size()
	vfx.presenter.part_hit(part, null, part.global_position)
	check(vfx._stars.size() - stars_before == 1, "Unmodified contact has one compact pop")
	check(vfx._stop == 0, "Passive missile contact does not stop gameplay")
	c.target_group = "player"
	check(not vfx.presenter._is_magic_missile(part), "Hostile presentation remains separate")
	clear()
	vfx.clear()
	print("Magic Missile feel: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
