extends Sprite2D

const CLOUD_SHADER = preload("res://shaders/steam_cloud.gdshader")
const MAX_PARTICLES := 48
var age := 0.0
var motion_age := 0.0
var end_age := INF
var maximum_age := 8.0
var emission := 0.0
var particles: Array = []

func setup(radius: float, duration: float, reduced: bool) -> void:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(image)
	scale = Vector2(radius * 2.7, radius * 3.0)
	z_index = 51
	z_as_relative = false
	maximum_age = duration + 2.0
	var shader_material := ShaderMaterial.new()
	shader_material.shader = CLOUD_SHADER
	shader_material.set_shader_parameter("reduced", reduced)
	material = shader_material
	add_to_group("steam_clouds")
	for i in (10 if reduced else 16):
		_emit(reduced)

func _emit(reduced: bool) -> void:
	if particles.size() >= (28 if reduced else MAX_PARTICLES):
		return
	var angle := randf() * TAU
	var distance := sqrt(randf()) * 0.72
	particles.append({"p": Vector2(cos(angle), sin(angle)) * distance + Vector2(0, 0.25), "v": Vector2(randf_range(-0.12, 0.12), randf_range(-0.5, -0.28)), "r": randf_range(0.23, 0.31) * (1.15 if reduced else 1.0), "age": 0.0, "life": randf_range(1.6, 2.1), "phase": randf() * TAU})

func finish() -> void:
	end_age = minf(end_age, age)

func _process(delta: float) -> void:
	age += delta
	var reduced := bool(get_parent().get("reduced_effects"))
	motion_age += delta * (0.65 if reduced else 1.0)
	var dispersal := maxf(0.0, age - end_age)
	if age < end_age:
		emission += delta * (13.0 if reduced else 23.0)
		while emission >= 1.0:
			emission -= 1.0
			_emit(reduced)
	var alive: Array = []
	var density := PackedVector4Array()
	for particle in particles:
		particle.age += delta
		if particle.age >= particle.life:
			continue
		var swirl := sin(motion_age * 3.4 + particle.phase + particle.p.y * 4.0)
		particle.p += (particle.v + Vector2(swirl * (0.07 if reduced else 0.15), 0)) * delta
		particle.r += delta * 0.18
		var fade := pow(1.0 - float(particle.age) / float(particle.life), 0.65)
		density.append(Vector4(particle.p.x, particle.p.y, particle.r, fade))
		alive.append(particle)
	particles = alive
	material.set_shader_parameter("particle_count", density.size())
	density.resize(MAX_PARTICLES)
	material.set_shader_parameter("particles", density)
	material.set_shader_parameter("reduced", reduced)
	material.set_shader_parameter("age", age)
	material.set_shader_parameter("dispersal", dispersal)
	if dispersal >= 1.4 or age >= maximum_age:
		queue_free()
