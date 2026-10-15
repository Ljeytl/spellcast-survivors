extends SceneTree

const Body = preload("res://scripts/vfx/SpiritBody.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr(label)

func run() -> void:
	var body = Body.new()
	root.add_child(body)
	body.advance(0.0, Vector2(1000, 500), Vector2.RIGHT, 100.0, 0.0, false)
	check(body.points.size() == 11, "Backbone has eleven physical control points")
	check(body.points[0].is_equal_approx(Vector2(1032, 500)), "Initial placement anchors at the spawn rather than world origin")
	var resting: Vector2 = body.points[8]
	for i in range(120):
		body.advance(1.0 / 120.0, Vector2(1000, 500), Vector2.RIGHT, 100.0, i / 120.0, false)
	check(body.points[8].distance_to(resting) > 1.0, "Wind changes the body pose while hovering")
	var tail_before: Vector2 = body.points[10]
	body.advance(1.0 / 60.0, Vector2(1000, 500), Vector2.DOWN, 100.0, 1.0, false)
	var rigid_tail := Vector2(1000, 532) - Vector2.DOWN * 100
	check(body.points[10].distance_to(rigid_tail) > 10.0, "Tail lags a turn rather than instantly rotating with the head")
	check(body.points[10].distance_to(tail_before) < rigid_tail.distance_to(tail_before), "Turn preserves trailing inertia rather than snapping to the rigid pose")
	var finite := true
	var bounded := true
	for i in range(240):
		var phase := i / 60.0
		body.advance(0.2 if i == 120 else 1.0 / 60.0, Vector2(1000, 500) + Vector2(sin(phase), cos(phase)) * 80.0, Vector2.from_angle(phase * 2.0), 100.0, phase, false)
		for j in range(1, body.points.size()):
			finite = finite and body.points[j].is_finite()
			bounded = bounded and body.points[j].distance_to(body.points[j - 1]) <= 11.501
	check(finite, "Turning and a long frame preserve finite positions")
	check(bounded, "Backbone cannot stretch beyond its segment constraint")
	check(body.mesh.get_surface_count() == 1 and body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 77, "Physical pose produces a complete deforming mesh")
	body.advance(0.016, Vector2(5000, 4000), Vector2.RIGHT, 100.0, 5.0, false)
	check(body.points[10].distance_to(Vector2(4932, 4000)) < 2.0, "Teleport resets the pose instead of stretching across the map")
	var before = body.points.duplicate()
	body.advance(0.0, Vector2(5000, 4000), Vector2.RIGHT, 100.0, 5.0, false)
	check(body.points == before, "Zero elapsed time does not advance the simulation")
	body.free()
	print("Spirit body: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
