extends Node2D

var soul := false
var radius := 24.0
var facing := 0.0
var clock := 0.0
var wake: Array[Vector2] = []
var initialized := false
var healing := false

func _ready() -> void:
	z_index = 6
	add_to_group("spirit_visuals")

func _process(dt: float) -> void:
	var host = get_parent()
	var vfx = get_node_or_null("/root/Vfx")
	if not soul:
		visible = not host.done and (vfx == null or vfx.presenter.enabled)
		if not visible:
			return
		radius = maxf(1.0, float(host.geo("radius", 24.0)))
		healing = false
	else:
		healing = host.healing
	clock = float(host.age)
	var direction: Vector2 = host.heading if soul else host.direction
	if direction.length_squared() < 0.001:
		direction = Vector2.from_angle(facing)
	if not initialized:
		facing = direction.angle()
		initialized = true
	else:
		facing = lerp_angle(facing, direction.angle(), 1.0 - exp(-dt * 12.0))
	if wake.is_empty() or global_position.distance_to(wake[0]) >= 4.0:
		wake.push_front(global_position)
		if wake.size() > 24:
			wake.pop_back()
	queue_redraw()

func body_contour(size: float, phase: float, mantle: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 64:
		var a := TAU * float(i) / 64.0
		var back := maxf(0.0, -cos(a))
		var ripple := sin(a * 5.0 + phase * 5.0) * back * 0.10
		var x := cos(a) * (1.0 + back * (0.8 + sin(a * 5.0 + phase * 3.0) * 0.45)) * size
		var y := sin(a) * (0.85 - back * 0.40 + ripple) * size * mantle
		points.append(Vector2(x, y).rotated(facing))
	return points

func _draw() -> void:
	if not initialized:
		return
	var vfx = get_node_or_null("/root/Vfx")
	var reduced: bool = vfx != null and vfx.reduced_effects
	var birth := smoothstep(0.0, 0.22, clock)
	var size := radius * (1.35 if soul else 1.45) * lerpf(0.35, 1.0, birth)
	var alpha := birth * (clampf((4.0 - clock) / 0.45, 0.0, 1.0) if soul else 1.0)
	var shade := Color("#263c70")
	var body := Color("#72c8e8")
	var light := Color("#daf5ff")
	var core := Color("#fffbe8")
	if soul:
		shade = Color("#24576a") if healing else Color("#45255f")
		body = Color("#70ddbf") if healing else Color("#b695eb")
		light = Color("#d6ffe7") if healing else Color("#e8dbff")
		core = Color("#fff3bb") if healing else Color("#e2f9ae")
	var axis := Vector2.from_angle(facing)
	var normal := axis.orthogonal()
	for ribbon in 3:
		var previous := Vector2.ZERO
		for i in 25:
			var t := float(i) / 24.0
			var center := -axis * size * t * 2.7
			if not wake.is_empty():
				var index := mini(int(t * 23.0), wake.size() - 1)
				center = to_local(wake[index]) - axis * size * t * 0.5
			center += normal * (float(ribbon - 1) * size * (0.25 + t * 0.45) + sin(clock * 6.0 - t * 5.0 + ribbon * 2.0) * size * t * 0.22)
			var width := maxf(0.5, size * (0.44 if ribbon == 1 else 0.26) * pow(1.0 - t, 1.2))
			if i > 0:
				draw_line(previous, center, Color(body if ribbon == 1 else light, alpha * (1.0 - t) * 0.5), width, true)
			previous = center
	if not reduced:
		draw_colored_polygon(body_contour(size * 1.18, clock, 1.02), Color(body, alpha * 0.08))
	draw_colored_polygon(body_contour(size, clock), Color(shade, alpha * 0.65))
	draw_colored_polygon(body_contour(size * 0.92, clock + 0.2, 0.91), Color(body, alpha * 0.72))
	draw_colored_polygon(body_contour(size * 0.68, clock + 0.4, 0.86), Color(light, alpha * 0.70))
	var brow := PackedVector2Array()
	for i in 25:
		var a := lerpf(-1.6, 1.6, float(i) / 24.0)
		brow.append((Vector2(cos(a) * size * 0.96, sin(a) * size * 0.65)).rotated(facing))
	draw_polyline(brow, Color(light, alpha * 0.85), 1.5, true)
	var inner := PackedVector2Array()
	for i in 32:
		var a := TAU * float(i) / 32.0
		inner.append(axis * size * (0.28 + cos(a) * 0.32) + normal * size * sin(a) * 0.34)
	draw_colored_polygon(inner, Color(core, alpha * 0.95))
	for sign_value in [-1.0, 1.0]:
		var eye := axis * size * 0.42 + normal * float(sign_value) * size * 0.22
		draw_line(eye - axis * size * 0.17, eye + axis * size * 0.09 - normal * float(sign_value) * size * 0.06, Color(shade, alpha * 0.9), size * 0.08, true)
	if soul and clock < 0.45 and not reduced:
		draw_arc(Vector2.ZERO, radius * (0.8 + clock * 2.0), 0, TAU, 48, Color(light, (1.0 - clock / 0.45) * 0.45), 1.5, true)
