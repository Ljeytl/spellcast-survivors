extends Node2D

const ADVECTION = preload("res://shaders/spirit_advection.gdshader")
const HYBRID = preload("res://shaders/spirit_hybrid.gdshader")
const FIELD_SIZE := 512
const MODEL_REVISION := "2b0bee3"

var soul := false
var radius := 24.0
var facing := 0.0
var clock := 0.0
var material_clock := 0.0
var initialized := false
var healing := false
var form := "hybrid"
var impact_age := -10.0
var sprite: Sprite2D
var fields: Array[SubViewport] = []
var passes: Array[ShaderMaterial] = []
var read_index := 0
var field_origin := Vector2.ZERO
var field_span := 1.0
var old_source := Vector2.ZERO
var field_ready := false
var pending := false
var queued_origin := Vector2.ZERO
var queued_span := 1.0
var queued_source := Vector2.ZERO
var gaze := Vector2(0.25, 0.05)
var simulation_steps := 0

func _ready() -> void:
	z_index = 6
	top_level = true
	add_to_group("spirit_visuals")
	for index in range(2):
		var viewport := SubViewport.new()
		viewport.size = Vector2i(FIELD_SIZE, FIELD_SIZE)
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.use_hdr_2d = true
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(viewport)
		fields.append(viewport)
		var rect := ColorRect.new()
		rect.size = Vector2(FIELD_SIZE, FIELD_SIZE)
		var material := ShaderMaterial.new()
		material.shader = ADVECTION
		rect.material = material
		viewport.add_child(rect)
		passes.append(material)
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = fields[read_index].get_texture()
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = HYBRID
	add_child(sprite)
	RenderingServer.frame_post_draw.connect(_finish_step)

func pulse() -> void:
	impact_age = float(get_parent().age)

func _process(dt: float) -> void:
	var host = get_parent()
	var vfx = get_node_or_null("/root/Vfx")
	visible = (soul or not host.done) and (vfx == null or vfx.presenter.enabled)
	global_position = host.global_position
	if not visible:
		field_ready = false
		return
	if not soul:
		radius = maxf(1.0, float(host.geo("radius", 24.0)))
		healing = bool(host.get("returning_life"))
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
		facing = lerp_angle(facing, direction.angle(), 1.0 - exp(-dt * 4.5))
	var desired := "hybrid"
	if vfx != null and vfx.spirit_form_override in ["ghost", "wisp", "hybrid"]:
		desired = vfx.spirit_form_override
	if desired != form:
		form = desired
		field_ready = false
	var reduced: bool = vfx != null and vfx.reduced_effects
	var motion_scale := 0.55 if reduced else 1.0
	material_clock += dt * (0.45 if reduced else 1.0)
	gaze = gaze.lerp(Vector2(direction.x * 0.65, direction.y * 0.48), 1.0 - exp(-dt * 13.0))
	var emergence := smoothstep(0.0, 0.18, clock)
	var contact := maxf(0.0, 1.0 - (clock - impact_age) / 0.16)
	var span := radius * 12.0
	sprite.scale = Vector2.ONE * span / FIELD_SIZE
	var tint := Color.WHITE
	if soul or healing:
		tint = Color(0.87, 1.0, 0.88) if healing else Color(1.0, 0.85, 1.0)
	var fade := clampf((float(host.LIFE) - clock) / 0.4, 0.0, 1.0) if soul else 1.0
	sprite.modulate = Color(tint * (1.0 + contact * 0.06), lerpf(0.65, 1.0, emergence) * fade)
	if not field_ready:
		field_origin = global_position - Vector2.ONE * span * 0.5
		field_span = span
		old_source = global_position
	sprite.position = field_origin + Vector2.ONE * field_span * 0.5 - global_position
	var material: ShaderMaterial = sprite.material
	material.set_shader_parameter("field", fields[read_index].get_texture())
	material.set_shader_parameter("origin", field_origin + Vector2.ONE * (field_span - span) * 0.5)
	material.set_shader_parameter("span", span)
	material.set_shader_parameter("hybrid", 0.0 if form == "wisp" else 1.0)
	material.set_shader_parameter("faceCenter", global_position)
	material.set_shader_parameter("faceHeading", Vector2.from_angle(facing))
	material.set_shader_parameter("faceRadius", radius * 0.85)
	material.set_shader_parameter("faceGaze", Vector3(gaze.x, gaze.y, sqrt(maxf(0.12, 1.0 - gaze.length_squared()))))
	material.set_shader_parameter("faceBlink", pow(maxf(0.0, cos(material_clock * 1.1 + 1.5)), 70.0))
	material.set_shader_parameter("silhouette", 0.0)
	if dt > 0.0 and not pending and DisplayServer.get_name() != "headless":
		_queue_step(minf(dt, 0.05) * motion_scale, span)

func _queue_step(dt: float, span: float) -> void:
	queued_origin = global_position - Vector2.ONE * span * 0.5
	queued_span = span
	queued_source = global_position
	var write_index := 1 - read_index
	var material := passes[write_index]
	material.set_shader_parameter("previous", fields[read_index].get_texture() if field_ready else null)
	material.set_shader_parameter("origin", queued_origin)
	material.set_shader_parameter("oldOrigin", field_origin)
	material.set_shader_parameter("span", span)
	material.set_shader_parameter("oldSpan", field_span)
	material.set_shader_parameter("source", global_position)
	material.set_shader_parameter("oldSource", old_source)
	material.set_shader_parameter("heading", Vector2.from_angle(facing))
	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("dt", dt if field_ready else 0.15)
	material.set_shader_parameter("trailWidth", 1.0 if form == "wisp" else 1.65)
	material.set_shader_parameter("reach", 1.0)
	material.set_shader_parameter("clock", material_clock)
	material.set_shader_parameter("reset", not field_ready)
	fields[write_index].render_target_update_mode = SubViewport.UPDATE_ONCE
	pending = true

func _finish_step() -> void:
	if not pending:
		return
	read_index = 1 - read_index
	passes[read_index].set_shader_parameter("previous", null)
	field_origin = queued_origin
	field_span = queued_span
	old_source = queued_source
	field_ready = true
	pending = false
	simulation_steps += 1
	sprite.texture = fields[read_index].get_texture()
