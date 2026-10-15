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
var sprite: Sprite2D

func _ready() -> void:
	z_index = 6
	add_to_group("spirit_visuals")
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = FLOW_SHADER
	add_child(sprite)

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
	rotation = facing
	var desired := "wisp" if soul else "ghost"
	if vfx != null and vfx.spirit_form_override in ["ghost", "wisp"]:
		desired = vfx.spirit_form_override
	if form != desired:
		form = desired
		sprite.texture = load(WISP_TEXTURE if form == "wisp" else GHOST_TEXTURE)
		sprite.offset = Vector2(-sprite.texture.get_width() * 0.18, 0.0)
	var reduced: bool = vfx != null and vfx.reduced_effects
	var emergence := smoothstep(0.0, 0.18, clock)
	var contact := maxf(0.0, 1.0 - (clock - impact_age) / 0.16)
	var base_scale := radius * 4.8 / float(sprite.texture.get_width())
	var breath := sin(clock * 4.0) * (0.01 if reduced else 0.025)
	sprite.scale = Vector2(base_scale, base_scale * (1.0 + breath)) * lerpf(0.70, 1.0, emergence) * (1.0 + contact * 0.06)
	var tint := Color.WHITE
	if soul:
		tint = Color(0.87, 1.0, 0.88) if healing else Color(1.0, 0.85, 1.0)
	var fade := clampf((float(host.LIFE) - clock) / 0.4, 0.0, 1.0) if soul else 1.0
	sprite.modulate = Color(tint, lerpf(0.65, 1.0, emergence) * fade)
	sprite.material.set_shader_parameter("phase", clock)
	sprite.material.set_shader_parameter("flow_amount", 0.005 if reduced else 0.018)
