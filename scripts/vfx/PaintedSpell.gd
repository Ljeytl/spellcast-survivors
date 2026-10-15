extends Sprite2D

const STROKE_SHADER = preload("res://shaders/painted_spell.gdshader")
static var blank: ImageTexture
var slash := false
var age := 0.0
var radius := 1.0

func setup(is_slash: bool, size: float, span: float = 1.0, flip: int = 1) -> void:
	slash = is_slash
	radius = size
	if blank == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		blank = ImageTexture.create_from_image(image)
	texture = blank
	material = ShaderMaterial.new()
	material.shader = STROKE_SHADER
	material.set_shader_parameter("slash", slash)
	material.set_shader_parameter("span", span)
	material.set_shader_parameter("flip", float(flip))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_index = 6
	add_to_group("painted_spells")
	if slash:
		scale = Vector2.ONE * radius * 2.08

func _process(delta: float) -> void:
	var vfx = get_node("/root/Vfx")
	visible = vfx.presenter.enabled
	if slash:
		age += delta
		if age >= 0.27:
			queue_free()
	else:
		var host = get_parent()
		visible = visible and not host.done
		age = float(host.age)
		radius = maxf(1.0, float(host.geo("radius", 10.0)))
		rotation = Vector2(host.direction).angle()
		scale = Vector2(radius * 8.0, radius * 3.0)
		offset = Vector2(-0.30, 0.0)
	material.set_shader_parameter("age", age)
	material.set_shader_parameter("reduced", vfx.reduced_effects)
