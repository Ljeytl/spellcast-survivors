extends RefCounted

const WAKE_LIFE := 0.18
var samples: Array[Dictionary] = []
var time := 0.0
var radius := 7.0
var direction := Vector2.RIGHT
var contact := 0.0
var finished := false
var phase := 0.0

func advance(dt: float) -> void:
	time += dt
	contact = maxf(0.0, contact - dt)
	while not samples.is_empty() and time - float(samples[0].t) > WAKE_LIFE:
		samples.pop_front()

func sample(position: Vector2, body_radius: float) -> void:
	radius = body_radius
	if not samples.is_empty():
		var delta: Vector2 = position - samples[-1].p
		if delta.length() > 0.001:
			direction = delta.normalized()
	samples.append({"p": position, "t": time})
	while samples.size() > 24:
		samples.pop_front()
	var length := 0.0
	for i in range(samples.size() - 1, 0, -1):
		length += Vector2(samples[i].p).distance_to(samples[i - 1].p)
		if length > radius * 2.0:
			samples = samples.slice(i)
			break

func pulse() -> void:
	contact = 0.12

func draw_wake(buf: PackedByteArray, presenter) -> void:
	if samples.size() < 2:
		return
	var k: float = presenter.vfx.K
	for i in range(1, samples.size()):
		var age: float = time - float(samples[i].t)
		var strength := clampf(1.0 - age / WAKE_LIFE, 0.0, 1.0)
		var a: Vector2 = samples[i - 1].p * k
		var b: Vector2 = samples[i].p * k
		var normal := (b - a).normalized().orthogonal()
		var width := maxf(0.5, radius * k * 0.17 * strength)
		var steps := maxi(1, ceili(a.distance_to(b)))
		for j in range(steps):
			var p := a.lerp(b, float(j) / steps)
			for side in range(-ceili(width), ceili(width) + 1):
				var color := Color("#8267df").lerp(Color("#bdc2ff"), strength)
				color.a = strength * 0.58 * clampf(width + 0.5 - absf(side), 0.0, 1.0)
				var q := p + normal * side
				presenter._missile_pixel(buf, roundi(q.x), roundi(q.y), color)

func draw_body(buf: PackedByteArray, presenter, position: Vector2, accent: String) -> void:
	var k: float = presenter.vfx.K
	var r := radius * k
	var center := position * k
	var rotation := time * 5.0 + phase
	var pulse_strength := contact / 0.12
	for y in range(-ceili(r), ceili(r) + 1):
		for x in range(-ceili(r), ceili(r) + 1):
			var offset := Vector2(x, y)
			var distance := offset.length() / maxf(r, 0.001)
			if distance > 1.0:
				continue
			var angle := offset.angle()
			var flow := sin(angle - rotation + distance * 5.0)
			var band := (pow(maxf(0.0, flow), 6.0) + pow(maxf(0.0, -flow), 3.0) * 0.3) * smoothstep(0.12, 0.4, distance)
			var nucleus := Vector2.from_angle(rotation * 0.7) * r * 0.13
			var core := pow(maxf(0.0, 1.0 - offset.distance_to(nucleus) / (r * 0.33)), 1.5)
			var edge := smoothstep(0.82, 0.96, distance)
			var leading := pow(maxf(0.0, offset.normalized().dot(direction)), 6.0) * edge
			var color := Color("#6530cf").lerp(Color("#ac7bf5"), band)
			color = color.lerp(Color("#edf2ff"), maxf(core, band * 0.15))
			color = color.lerp(Color("#e9e4ff"), leading * (0.3 + pulse_strength * 0.7))
			var taper := 1.0 - smoothstep(0.55, 1.0, distance)
			var body := 1.0 - smoothstep(0.3, 0.75, distance)
			color.a = clampf(body * 0.72 + band * (0.55 + taper * 0.4) + core * 0.96 + leading * pulse_strength * 0.5, 0.0, 0.96)
			if accent != "" and edge > 0.5:
				color = presenter.RIM[accent]
				color.a = 0.85
			presenter._missile_pixel(buf, roundi(center.x) + x, roundi(center.y) + y, color)
