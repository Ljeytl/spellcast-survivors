extends SceneTree

const Presenter = preload("res://scripts/vfx/VfxPresenter.gd")
const Part = preload("res://scripts/engine/SpellPart.gd")
var checks := 0
var failures := 0
var vfx

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func buffer() -> PackedByteArray:
	var pixels = PackedByteArray()
	pixels.resize(vfx._size.x * vfx._size.y * 4)
	return pixels

func seed_transients(p):
	p._hit_rings = [[0.0, 0.0, 8.0, 0.0, 0.35, [[Color.WHITE, Color.WHITE], [Color.WHITE, Color.WHITE]]]]
	p._lasers = [[Vector2.ZERO, Vector2.RIGHT, 10.0, 1.0, 0.0, 0.32, [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE], "arcane"]]

func row_span(pixels: PackedByteArray) -> Vector2i:
	var first := -1
	var last := -1
	var y: int = -vfx._origin.y
	for x in vfx._size.x:
		if pixels[(y * vfx._size.x + x) * 4 + 3] > 0:
			if first < 0:
				first = x
			last = x
	return Vector2i(first, last)

func run():
	if not root.is_node_ready():
		await root.ready
	await process_frame
	vfx = root.get_node("Vfx")
	vfx.set_process(false)
	vfx._size = Vector2i(192, 192)
	vfx._origin = Vector2i(-96, -96)
	for hz in [30, 60, 120]:
		var p = Presenter.new(vfx)
		seed_transients(p)
		for frame in hz / 5:
			p.step(vfx.fx_speed / float(hz))
			p.draw_statuses(buffer())
			p.draw_statuses(buffer())
		check(p._hit_rings.size() == 1 and p._lasers.size() == 1, "Effects survive 0.2 seconds at %d Hz with redraws" % hz)
		if p._hit_rings.size() == 1 and p._lasers.size() == 1:
			check(is_equal_approx(p._hit_rings[0][3], 0.2) and is_equal_approx(p._lasers[0][4], 0.2), "Redrawing does not advance effect time")
		p.step(0.13 * vfx.fx_speed)
		check(p._hit_rings.size() == 1 and p._lasers.is_empty(), "Ray expires before landing ring at 0.33 seconds")
		p.step(0.03 * vfx.fx_speed)
		check(p._hit_rings.is_empty() and p._lasers.is_empty(), "Both effects expire without drawing")
	seed_transients(vfx.presenter)
	vfx.clear()
	check(vfx.presenter._hit_rings.is_empty() and vfx.presenter._lasers.is_empty(), "Scene effect reset removes landing rings and ray afterimages")
	var p = Presenter.new(vfx)
	var part = Part.new()
	root.add_child(part)
	p._parts[part.get_instance_id()] = {"kind": "projectile", "family": "sphere", "look": {"native": "arcane", "accent": ""}, "part": weakref(part), "last": Vector2.ZERO}
	for scale in [0.75, 1.0, 1.42, 2.4]:
		part.def = {"geometry": {"type": "body", "radius": 42.0 * scale}}
		var pixels = buffer()
		p.draw_bodies(pixels)
		var span = row_span(pixels)
		var visible_radius: float = (span.y - span.x + 1) * vfx.CELL * 0.5
		check(span.x >= 0 and absf(visible_radius - part.geo("radius")) <= vfx.CELL * 2, "Arcane orb drawn radius matches geometry at %.2fx" % scale)
	part.life_total = 2.0
	part.age = 1.675
	var meteor := {"kind": "meteor", "part": weakref(part), "age": 0.0, "life": 2.0, "r": 8.0, "sky": Vector2(-30, -70)}
	p._parts[part.get_instance_id()] = meteor
	p.draw_bodies(buffer())
	check(is_equal_approx(meteor.age, part.age), "Meteor drawing catches up to gameplay without a VFX step")
	check(is_equal_approx(p._meteor_k(meteor), 0.25), "Meteor accelerates: halfway through descent covers a quarter of its distance")
	part.age = 2.0
	p._meteor_fall(part, meteor, Vector2.ZERO, 0.0)
	check(is_equal_approx(p._meteor_k(meteor), 1.0), "Meteor reaches impact when gameplay reaches impact despite skipped VFX time")
	part.free()
	print("VFX timing/scale: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
