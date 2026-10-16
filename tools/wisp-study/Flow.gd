extends Node2D

const LIMIT := 72
const SHADER = preload("res://tools/wisp-study/flow.gdshader")
var particles: Array = []
var phase := 0.0
var accumulator := 0.0
var emission_index := 0
var arrival_age := -1.0
var heading := Vector2.RIGHT
var reduced := false
var surface: MeshInstance2D
var previous_origin := Vector2.ZERO
var initialized := false

func _ready() -> void:
	surface = MeshInstance2D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(400, 300)
	surface.mesh = quad
	surface.material = ShaderMaterial.new()
	surface.material.shader = SHADER
	add_child(surface)

func reset() -> void:
	particles.clear()
	phase = 0.0
	accumulator = 0.0
	emission_index = 0
	arrival_age = -1.0
	heading = Vector2.RIGHT
	initialized = false
	if surface != null:
		_upload(Vector2.ZERO)

func arrive() -> void:
	if arrival_age < 0.0:
		arrival_age = 0.0

func advance(dt: float, origin: Vector2, velocity: Vector2) -> void:
	global_position = origin
	if not initialized:
		previous_origin = origin
		initialized = true
	var elapsed := minf(dt, 0.1)
	var steps := maxi(1, int(ceil(elapsed * 120.0)))
	var step := elapsed / steps
	if velocity.length() > 5.0:
		heading = Vector2.from_angle(lerp_angle(heading.angle(), velocity.angle(), 1.0 - exp(-elapsed * 9.0)))
	for sub in range(steps):
		phase += step
		if arrival_age >= 0.0:
			arrival_age += step
		var center := previous_origin.lerp(origin, float(sub + 1) / steps)
		accumulator += step * (30.0 if reduced else 45.0)
		while accumulator >= 1.0 and arrival_age < 0.0:
			accumulator -= 1.0
			_emit(center, velocity)
		for p in particles:
			p.age += step
			var offset: Vector2 = p.position - center
			var distance := maxf(offset.length(), 1.0)
			var tangent := Vector2(-offset.y, offset.x) / distance
			var curl := Vector2(sin(p.position.y * 0.05 + phase * 2.0), cos(p.position.x * 0.04 - phase * 1.6))
			var flow := tangent * 62.0 * exp(-distance / 70.0) + curl * (7.0 if reduced else 13.0) - heading * 22.0
			if arrival_age >= 0.0:
				flow += -offset * 7.0
			p.velocity = p.velocity.lerp(flow, 1.0 - exp(-step * 5.0))
			p.position += p.velocity * step
		particles = particles.filter(func(p): return p.age < p.life)
	previous_origin = origin
	_upload(velocity)

func _emit(center: Vector2, velocity: Vector2) -> void:
	var seed := emission_index * 2.399963
	var angle := heading.angle() + PI + sin(phase * 2.1) * 0.55
	var radial := Vector2.from_angle(angle)
	particles.append({"position": center + radial * 7.0, "velocity": radial * 18.0 + velocity * 0.18, "age": 0.0, "life": 0.9, "seed": seed})
	emission_index += 1
	if particles.size() > LIMIT:
		particles.pop_front()

func _upload(velocity: Vector2) -> void:
	var cells: Array[Vector4] = []
	var core_energy := 1.0 if arrival_age < 0.0 else 1.0 - smoothstep(0.0, 0.50, arrival_age)
	var normal := Vector2(-heading.y, heading.x)
	var stretch := clampf(velocity.length() / 180.0, 0.0, 0.6)
	for i in range(8):
		var t := float(i) / 7.0
		var bend := sin(phase * 2.1 - t * 3.5) * (2.0 + t * 5.0)
		var local := (heading * (5.0 - t * (24.0 + stretch * 9.0)) + normal * bend) * core_energy
		var radius := (4.0 + sin(t * PI) * 7.0) * (1.0 + sin(phase * 2.5 - t * 4.0) * 0.12)
		cells.append(Vector4(local.x, local.y, radius * maxf(core_energy, 0.01), (0.32 + sin(t * PI) * 0.20) * core_energy))
	for p in particles:
		var t: float = p.age / p.life
		var local: Vector2 = to_local(p.position)
		var density := pow(1.0 - t, 1.6) * 0.30
		cells.append(Vector4(local.x, local.y, lerpf(22.0, 2.0, t) * (1.0 + sin(phase * 2.0 - t * 5.0) * 0.14), density))
	var count := cells.size()
	while cells.size() < 80:
		cells.append(Vector4.ZERO)
	surface.material.set_shader_parameter("cells", cells)
	surface.material.set_shader_parameter("cell_count", count)
	surface.material.set_shader_parameter("phase", phase)
	surface.material.set_shader_parameter("energy", 1.0 if arrival_age < 0.0 else 1.0 - smoothstep(0.55, 1.1, arrival_age))
