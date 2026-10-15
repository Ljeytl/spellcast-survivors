extends Node2D

const GHOST_TEXTURE := "res://assets/vfx/spirits/ghost.png"
const WISP_TEXTURE := "res://assets/vfx/spirits/wisp.png"
const FLOW_SHADER = preload("res://shaders/spirit_flow.gdshader")

var soul := false
var radius := 24.0
var facing := 0.0
var clock := 0.0
var initialized := false
var healing := false
var form := ""
var impact_age := -10.0
var body: MeshInstance2D
var wake_texture: GradientTexture2D
var released := false
var release_age := 0.0
var release_opacity := 1.0
var delivered := false
var destination := Vector2.ZERO
var release_origin := Vector2.ZERO
var wake_samples: Array = []
var wake_origin := Vector2.ZERO
var wake_initialized := false

func _ready() -> void:
	z_index = 6
	add_to_group("spirit_visuals")
	body = preload("res://scripts/vfx/SpiritBody.gd").new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body.material = ShaderMaterial.new()
	body.material.shader = FLOW_SHADER
	add_child(body)
	if soul:
		_make_wake()

func pulse() -> void:
	impact_age = float(get_parent().age)

func _process(dt: float) -> void:
	var host = get_parent()
	var vfx = get_node_or_null("/root/Vfx")
	if not soul:
		visible = not host.done and (vfx == null or vfx.presenter.enabled)
		if not visible:
			return
		radius = maxf(1.0, float(host.geo("radius", 24.0)))
		healing = false
	elif not released:
		healing = host.healing
	if released:
		clock += dt
		release_age += dt
		if release_age >= 0.8:
			queue_free()
			return
		if delivered:
			global_position = release_origin.lerp(destination, smoothstep(0.0, 0.22, release_age))
	else:
		clock = float(host.age)
	var direction: Vector2 = Vector2.from_angle(facing) if released else (host.heading if soul else host.direction)
	if direction.length_squared() < 0.001:
		direction = Vector2.from_angle(facing)
	if not initialized:
		facing = direction.angle()
		initialized = true
	else:
		facing = lerp_angle(facing, direction.angle(), 1.0 - exp(-dt * 12.0))
	rotation = facing
	var desired := "wisp" if soul else "ghost"
	if vfx != null and vfx.spirit_form_override in ["ghost", "wisp"]:
		desired = vfx.spirit_form_override
	if form != desired:
		form = desired
		body.texture = load(WISP_TEXTURE if form == "wisp" else GHOST_TEXTURE)
	var reduced: bool = vfx != null and vfx.reduced_effects
	var emergence := smoothstep(0.0, 0.18, clock)
	var contact := maxf(0.0, 1.0 - (clock - impact_age) / 0.16)
	var body_width := radius * 4.8 * lerpf(0.70, 1.0, emergence) * (1.0 + contact * 0.06)
	var tint := Color.WHITE
	if soul:
		tint = Color(0.87, 1.0, 0.88) if healing else Color(1.0, 0.85, 1.0)
	var fade := 1.0
	if soul:
		fade = release_opacity * (1.0 - smoothstep(0.10, 0.42, release_age)) if released else clampf((float(host.LIFE) - clock) / 0.4, 0.0, 1.0)
		if released and delivered:
			body_width *= lerpf(1.0, 0.45, smoothstep(0.08, 0.42, release_age))
		_update_wake(dt, reduced)
	body.modulate = Color(tint, lerpf(0.65, 1.0, emergence) * fade)
	body.advance(dt, global_position, Vector2.from_angle(facing), body_width, clock, reduced)
	body.material.set_shader_parameter("phase", clock)
	body.material.set_shader_parameter("flow_amount", 0.002 if reduced else 0.004)

func _make_wake() -> void:
	var texture := GradientTexture2D.new()
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = Gradient.new()
	texture.gradient.colors = PackedColorArray([Color(0.75, 1.0, 0.92, 0.30), Color(0.3, 0.65, 0.8, 0.0)])
	wake_texture = texture

func finish(arrived: bool, at: Vector2) -> void:
	if released:
		return
	var host = get_parent()
	clock = float(host.age)
	release_opacity = clampf((float(host.LIFE) - clock) / 0.4, 0.0, 1.0)
	healing = host.healing
	facing = host.heading.angle()
	delivered = arrived
	destination = at
	release_origin = global_position
	released = true
	reparent(host.get_parent())
	add_to_group("spirit_remnants")

func _update_wake(dt: float, reduced: bool) -> void:
	if not wake_initialized:
		wake_origin = global_position
		wake_initialized = true
		return
	for sample in wake_samples:
		sample[1] += dt
		var curl: Vector2 = sample[2] * sin(sample[1] * 11.0 + sample[3]) * (10.0 if reduced else 28.0)
		sample[0] += (curl + sample[2].orthogonal() * 8.0) * dt
	wake_samples = wake_samples.filter(func(sample): return sample[1] < 0.5)
	if not released:
		var distance := wake_origin.distance_to(global_position)
		var steps := mini(48, int(distance / (10.0 if reduced else 5.0)))
		for i in range(steps):
			var fraction := float(i + 1) / float(steps)
			wake_samples.append([wake_origin.lerp(global_position, fraction), dt * (1.0 - fraction), Vector2.from_angle(facing + PI / 2.0), clock * 2.0])
		if steps > 0:
			wake_origin = global_position
	while wake_samples.size() > 64:
		wake_samples.pop_front()
	queue_redraw()

func _draw() -> void:
	if not soul or wake_texture == null:
		return
	for sample in wake_samples:
		var t: float = clampf(sample[1] / 0.5, 0.0, 1.0)
		var drift: Vector2 = sample[2] * sin(t * PI) * 5.0
		var center := to_local(sample[0] + drift)
		var size := lerpf(18.0, 30.0, t)
		var tint := Color(0.87, 1.0, 0.88) if healing else Color(1.0, 0.85, 1.0)
		tint.a = sin(t * PI) * 0.30
		draw_texture_rect(wake_texture, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, tint)
