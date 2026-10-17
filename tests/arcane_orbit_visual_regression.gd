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
	vfx._stop = 0
	var before_sparks: int = vfx._sparks.size()
	presenter.part_hit(part, null, Vector2.RIGHT)
	check(state.orbit_visual.contact > 0.0, "Presenter routes real hit callback to orbit pulse")
	check(vfx._sparks.size() == before_sparks + 2 and vfx._stop == 0, "Orbit contact emits two flecks without sphere hitstop")
	state.look.accent = "fire"
	var before_smoke: int = vfx._smoke.size()
	presenter.part_finished(part, true)
	check(vfx._sparks.back()[6] == presenter.SPARK.fire and vfx._smoke.size() > before_smoke, "Fiery expiry retains keyword palette and puff")
	check(state.orbit_visual.finished and not presenter._parts.has(part.get_instance_id()), "Natural expiry releases the body and finishes its wake")
	part.free()
	cast.free()
	print("Arcane Orbit visual: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
