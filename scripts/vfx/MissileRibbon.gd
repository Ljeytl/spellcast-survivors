extends RefCounted

var samples: Array[Dictionary] = []
var time := 0.0
var width := 1.0
var finished := false
const LIFETIME := 0.20

func advance(dt: float) -> void:
	time += dt
	while not samples.is_empty() and time - float(samples[0].t) > LIFETIME:
		samples.pop_front()

func sample(position: Vector2, _direction: Vector2, scale: float) -> void:
	width = scale
	if not samples.is_empty() and position.distance_to(samples[-1].p) < 0.25:
		samples[-1] = {"p": position, "t": time}
		return
	samples.append({"p": position, "t": time})
	while samples.size() > 24:
		samples.pop_front()

func draw(buf: PackedByteArray, presenter) -> void:
	if samples.size() < 2:
		return
	var k: float = presenter.vfx.K
	var points: Array[Vector2] = []
	var strengths: Array[float] = []
	var head: Vector2 = samples[-1].p
	for i in samples.size():
		var age: float = time - float(samples[i].t)
		var strength := clampf(1.0 - age / LIFETIME, 0.0, 1.0)
		var p: Vector2 = samples[i].p
		var direction: Vector2 = (samples[mini(i + 1, samples.size() - 1)].p - samples[maxi(0, i - 1)].p).normalized()
		p += direction.orthogonal() * sin(age * 26.0 + time * 9.0) * (1.0 - strength) * 0.65 * width
		strength *= clampf(1.0 - p.distance_to(head) / (18.0 * width), 0.0, 1.0)
		if strength <= 0.001:
			continue
		points.append(p * k)
		strengths.append(strength)
	if points.size() < 2:
		return
	var bounds := Rect2(points[0], Vector2.ZERO)
	for p in points:
		bounds = bounds.expand(p)
	bounds = bounds.grow(1.5 * width * k).intersection(Rect2(Vector2(presenter.vfx._origin), Vector2(presenter.vfx._size)))
	if not bounds.has_area():
		return
	for y in range(floori(bounds.position.y), ceili(bounds.end.y)):
		for x in range(floori(bounds.position.x), ceili(bounds.end.x)):
			var pixel := Vector2(x, y)
			var best := 0.0
			var best_strength := 0.0
			for i in range(1, points.size()):
				var a := points[i - 1]
				var delta := points[i] - a
				var along := clampf((pixel - a).dot(delta) / maxf(delta.length_squared(), 0.001), 0.0, 1.0)
				var strength := lerpf(strengths[i - 1], strengths[i], along)
				var radius := (0.18 + 1.05 * strength) * width * k
				var coverage := clampf(radius + 0.45 - pixel.distance_to(a + delta * along), 0.0, 1.0)
				var alpha := coverage * strength * 0.78
				if alpha > best:
					best = alpha
					best_strength = strength
			if best > 0.01:
				var color := Color("#628de7").lerp(Color("#b59bff"), best_strength)
				color.a = best
				presenter._missile_pixel(buf, x, y, color)
