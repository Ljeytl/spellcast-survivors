extends MeshInstance2D

const SEGMENTS := 10
const ROWS := 6
var points: Array[Vector2] = []
var velocities: Array[Vector2] = []
var last_anchor := Vector2.ZERO
var last_width := 0.0
var root_heading := Vector2.RIGHT

func advance(dt: float, anchor: Vector2, heading: Vector2, width: float, phase: float, reduced: bool) -> void:
	var front := anchor + heading * width * 0.32
	var segment := width / SEGMENTS
	if points.is_empty() or last_anchor.distance_to(front) > width * 4.0 or absf(last_width - width) > width * 0.35:
		points.clear()
		velocities.clear()
		for i in range(SEGMENTS + 1):
			points.append(front - heading * segment * i)
			velocities.append(Vector2.ZERO)
		last_anchor = front
		root_heading = heading
	last_width = width
	var elapsed := minf(dt, 0.1)
	var steps := maxi(1, int(ceil(elapsed / (1.0 / 120.0))))
	var step := elapsed / steps
	for sub in range(steps):
		root_heading = Vector2.from_angle(lerp_angle(root_heading.angle(), heading.angle(), 1.0 - exp(-step * 9.0)))
		points[0] = last_anchor.lerp(front, float(sub + 1) / steps)
		for i in range(1, SEGMENTS + 1):
			var softness := float(i) / SEGMENTS
			var target := points[i - 1] - heading * segment
			var wind := heading.orthogonal() * (sin(phase * 3.2 - i * 0.8) + sin(phase * 1.9 + i * 0.5) * 0.45)
			var force := (target - points[i]) * 65.0 + wind * width * softness * (0.65 if reduced else 3.2)
			velocities[i] = (velocities[i] + force * step) * exp(-7.0 * step)
			points[i] += velocities[i] * step
			var separation := points[i] - points[i - 1]
			var previous_axis := -root_heading if i == 1 else (points[i - 1] - points[i - 2]).normalized()
			var bend := wrapf(separation.angle() - previous_axis.angle(), -PI, PI)
			var bend_limit := lerpf(0.08, 0.30, softness)
			var axis := previous_axis.rotated(clampf(bend, -bend_limit, bend_limit))
			points[i] = points[i - 1] + axis * clampf(separation.length(), segment * 0.85, segment * 1.15)
	last_anchor = front
	_rebuild(width, phase, reduced)

func _rebuild(width: float, phase: float, reduced: bool) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(SEGMENTS + 1):
		var tangent := points[maxi(0, i - 1)] - points[mini(SEGMENTS, i + 1)]
		if tangent.length_squared() < 0.001:
			tangent = Vector2.RIGHT.rotated(global_rotation)
		var forward := tangent.normalized()
		var normal := Vector2(-forward.y, forward.x)
		var looseness := smoothstep(0.15, 1.0, float(i) / SEGMENTS)
		for row in range(ROWS + 1):
			var v := float(row) / ROWS
			var flutter := sin(phase * 4.3 - i * 0.65 + row * 0.9) * looseness * width * (0.008 if reduced else 0.035)
			var world := points[i] + normal * ((v - 0.5) * width + flutter)
			var local := to_local(world)
			vertices.append(Vector3(local.x, local.y, 0))
			uvs.append(Vector2(1.0 - float(i) / SEGMENTS, v))
			if i < SEGMENTS and row < ROWS:
				var a := i * (ROWS + 1) + row
				var b := a + ROWS + 1
				indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var surface := ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = surface
