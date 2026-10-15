extends SceneTree

const Flow = preload("res://tools/wisp-study/Flow.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(label)

func run() -> void:
	var flow = Flow.new()
	root.add_child(flow)
	flow.advance(0.05, Vector2(400, 300), Vector2.ZERO)
	check(flow.particles.size() > 0, "Hovering generates surrounding material")
	var core_before: Vector4 = flow.surface.material.get_shader_parameter("cells")[0]
	var material_before: Vector2 = flow.particles[0].position
	flow.advance(0.05, Vector2(400, 300), Vector2.ZERO)
	check(flow.particles[0].position.distance_to(material_before) > 0.1, "Shed material moves even when the core hovers")
	check(flow.surface.material.get_shader_parameter("cells")[0] != core_before, "Core changes shape internally while hovering")
	flow.scale = Vector2(2, 2)
	flow.advance(0.01, Vector2(410, 300), Vector2(100, 0))
	var field_point: Vector4 = flow.surface.material.get_shader_parameter("cells")[8]
	check(Vector2(field_point.x, field_point.y).is_equal_approx(flow.to_local(flow.particles[0].position)), "Inspection zoom preserves world-space material positions")
	for i in range(240):
		flow.advance(1.0 / 60.0, Vector2(410 + i, 300), Vector2(60, 0))
	check(flow.particles.size() <= 72, "Material simulation is bounded")
	check(flow.surface.material.get_shader_parameter("cell_count") <= 80, "Density field respects shader capacity")
	check(flow.particles.all(func(p): return p.position.is_finite() and p.velocity.is_finite()), "Particle motion remains finite")
	var emitted = flow.emission_index
	flow.arrive()
	for i in range(150):
		flow.advance(1.0 / 60.0, Vector2(650, 300), Vector2.ZERO)
	check(flow.emission_index == emitted, "Arrival stops new material emission")
	check(flow.particles.is_empty(), "Arrival leaves no permanent trail")
	check(flow.surface.material.get_shader_parameter("energy") == 0.0, "Arrival extinguishes the core and field")
	flow.heading = Vector2.LEFT
	flow.reset()
	check(flow.heading == Vector2.RIGHT, "Reset restores initial flow direction")
	check(flow.surface.material.get_shader_parameter("energy") == 1.0, "Reset immediately refreshes the rendered state")
	flow.advance(0.01, Vector2(1000, 500), Vector2.ZERO)
	check(flow.previous_origin == Vector2(1000, 500), "Reset starts at the new origin")
	var age = flow.phase
	flow.advance(0.0, Vector2(1000, 500), Vector2.ZERO)
	check(flow.phase == age, "Zero elapsed time preserves the simulation")
	flow.free()
	print("Wisp flow: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
