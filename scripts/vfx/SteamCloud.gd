extends Sprite2D

const CLOUD_SHADER = preload("res://shaders/steam_cloud.gdshader")
var age := 0.0
var motion_age := 0.0
var end_age := INF
var maximum_age := 8.0

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
	shader_material.set_shader_parameter("pixel_grid", Vector2(radius * 2.7, radius * 3.0) / 3.0)
	material = shader_material
	add_to_group("steam_clouds")

func finish() -> void:
	end_age = minf(end_age, age)

func _process(delta: float) -> void:
	age += delta
	var reduced := bool(get_parent().get("reduced_effects"))
	motion_age += delta * (0.65 if reduced else 1.0)
	material.set_shader_parameter("reduced", reduced)
	material.set_shader_parameter("motion_age", motion_age)
	var dispersal := maxf(0.0, age - end_age)
	material.set_shader_parameter("age", age)
	material.set_shader_parameter("dispersal", dispersal)
	if dispersal >= 1.4 or age >= maximum_age:
		queue_free()
