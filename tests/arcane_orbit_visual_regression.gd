extends SceneTree

const Visual = preload("res://scripts/vfx/ArcaneOrbitVisual.gd")
const Presenter = preload("res://scripts/vfx/VfxPresenter.gd")
var checks := 0
var failures := 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func run():
	await process_frame
	var vfx = root.get_node("Vfx")
	vfx.set_process(false)
	var presenter = Presenter.new(vfx)
	var visual = Visual.new()
	presenter._orbit_visuals.append(visual)
	for i in 20:
		visual.advance(1.0 / 60.0)
		visual.sample(Vector2.from_angle(i * 0.07) * 15.0, 6.3)
	check(visual.contact == 0.0, "Idle revolutions produce no contact pulse")
	check(visual.samples.size() >= 10 and visual.samples.size() <= 12, "Wake retains only the short sampled history")
	check(visual.samples[-1].p.distance_to(Vector2.from_angle(19 * 0.07) * 15.0) < 0.001, "Wake head follows actual orbital position")
	visual.pulse()
	check(visual.contact > 0.0, "Actual hit explicitly lights the leading edge")
	visual.advance(0.13)
	check(visual.contact == 0.0, "Hit pulse expires between shared rehit intervals")
	visual.finished = not OS.get_cmdline_user_args().has("known-bad-retained-wake")
	presenter.step(0.30 * vfx.fx_speed)
	check(visual.samples.is_empty() and presenter._orbit_visuals.is_empty(), "Expired body leaves no detached wake after its short fade")
	presenter._orbit_visuals.append(Visual.new())
	presenter.clear_transients()
	check(presenter._orbit_visuals.is_empty(), "Scene clear removes orbit wakes")
	var part = preload("res://scripts/engine/SpellPart.gd").new()
	var cast = preload("res://scripts/engine/GenericCast.gd").new()
	cast.plan = {"id": "arcane_orbit"}
	part.cast = cast
	part.def = {"geometry": {"radius": 42.0}}
	root.add_child(part)
	var state := {"kind": "projectile", "family": "sphere", "look": {"native": "arcane", "accent": ""}, "part": weakref(part), "last": Vector2.ZERO}
	presenter._parts[part.get_instance_id()] = state
	presenter._trail(part, state, Vector2.RIGHT, 1.0 / 60.0)
	presenter.clear_transients()
	check(not state.has("orbit_visual"), "Clearing live orbit removes stale material reference")
	presenter._trail(part, state, Vector2.RIGHT * 2.0, 1.0 / 60.0)
	check(presenter._orbit_visuals.size() == 1, "Live orbit resumes a registered wake after clear")
	vfx._stop = 0
	var before_sparks: int = vfx._sparks.size()
	presenter.part_hit(part, null, Vector2.RIGHT)
	check(state.orbit_visual.contact > 0.0, "Presenter routes real hit callback to orbit pulse")
	check(vfx._sparks.size() == before_sparks + 2 and vfx._stop == 0, "Orbit contact emits two flecks without sphere hitstop")
	presenter.step(0.13 * vfx.fx_speed)
	check(state.orbit_visual.contact == 0.0, "Contact after live clear still expires")
	state.look.accent = "fire"
	var before_smoke: int = vfx._smoke.size()
	presenter.part_finished(part, true)
	check(vfx._sparks.back()[6] == presenter.SPARK.fire and vfx._smoke.size() > before_smoke, "Fiery expiry retains keyword palette and puff")
	check(state.orbit_visual.finished and not presenter._parts.has(part.get_instance_id()), "Natural expiry releases the body and finishes its wake")
	cast.plan.id = "orbit"
	check(not Presenter._is_arcane_orbit(part), "Bare Orbit retains its own material")
	cast.plan.id = "arcane_orbit"
	cast.target_group = "player"
	check(not Presenter._is_arcane_orbit(part), "Hostile orbit retains its own material")
	check_material(vfx, presenter)
	part.free()
	cast.free()
	print("Arcane Orbit visual: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check_material(vfx, presenter) -> void:
	vfx._size = Vector2i(96, 96)
	vfx._origin = Vector2i.ZERO
	var visual = Visual.new()
	visual.radius = 7.0
	var previous := PackedByteArray()
	for phase in [0.0, 0.6]:
		visual.time = phase
		var pixels := PackedByteArray()
		pixels.resize(96 * 96 * 4)
		visual.draw_body(pixels, presenter, Vector2(48, 48) / vfx.K, "")
		var outer_alpha := 0.0
		var outer_count := 0
		var inner_alpha := 0.0
		var inner_count := 0
		var core_peak := 0
		var outside_pixels := 0
		var visible_pixels := 0
		for y in 96:
			for x in 96:
				var distance: float = Vector2(x - 48, y - 48).length() / (visual.radius * vfx.K)
				var alpha: int = pixels[(y * 96 + x) * 4 + 3]
				if alpha > 0:
					visible_pixels += 1
				if distance > 0.65 and distance <= 1.0:
					outer_alpha += alpha / 255.0
					outer_count += 1
				if distance >= 0.3 and distance < 0.55:
					inner_alpha += alpha / 255.0
					inner_count += 1
				if distance < 0.3:
					core_peak = maxi(core_peak, alpha)
				if distance > 1.0 and alpha > 0:
					outside_pixels += 1
		check(visible_pixels > 0 and outer_count > 0, "Material raster collects real body and outer samples")
		check(outer_alpha / outer_count < 0.3, "Outer whorl lets terrain dominate between moving arms")
		check(inner_count > 0 and inner_alpha / inner_count > 0.42, "Inner body retains concentrated magical mass")
		check(core_peak > 200, "Concentrated core remains legible through translucent whorl")
		check(outside_pixels == 0, "Material never expands outside gameplay body radius")
		if not previous.is_empty():
			check(previous != pixels, "Whorl material evolves in runtime phase")
		previous = pixels
