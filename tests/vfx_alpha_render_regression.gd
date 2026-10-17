extends SceneTree

var failures := 0
var checks := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(64, 64)
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func render(shader: Shader, overlay: Color, under: Color) -> Color:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(8, 8)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var sprite := Sprite2D.new()
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(overlay)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var zero := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	zero.fill(Color(0, 0, 0, 0))
	mat.set_shader_parameter("heat_tex", ImageTexture.create_from_image(zero))
	mat.set_shader_parameter("water_tex", ImageTexture.create_from_image(zero))
	var below := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	below.fill(under)
	mat.set_shader_parameter("under_tex", ImageTexture.create_from_image(below))
	sprite.material = mat
	viewport.add_child(sprite)
	for frame in 6:
		await process_frame
		await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().get_pixel(4, 4)
	viewport.queue_free()
	return result

func run() -> void:
	root.get_node("AudioManager").quitting = true
	var shader := preload("res://shaders/vfx_heat.gdshader")
	var low: Color = await render(shader, Color(0.6, 0.8, 1.0, 0.18), Color.TRANSPARENT)
	check(low.a > 0.15 and low.a < 0.21, "Native shader preserves low-alpha glass interior")
	var opaque: Color = await render(shader, Color(0.2, 0.5, 0.8, 1.0), Color.RED)
	check(absf(opaque.r - 0.2) < 0.01 and absf(opaque.g - 0.5) < 0.01 and absf(opaque.b - 0.8) < 0.01 and opaque.a > 0.99, "Opaque effects keep their existing color")
	var over: Color = await render(shader, Color(0, 0, 1, 0.25), Color(1, 0, 0, 1))
	check(over.a > 0.99 and absf(over.r - 0.75) < 0.03 and absf(over.b - 0.25) < 0.03, "Glass correctly composites over existing opaque effects")
	var broken := Shader.new()
	broken.code = "shader_type canvas_item; void fragment() { vec4 c = texture(TEXTURE, UV); COLOR = c.a > 0.5 ? c : vec4(0.0); }"
	var rejected: Color = await render(broken, Color(0.6, 0.8, 1.0, 0.18), Color.TRANSPARENT)
	check(rejected.a < 0.01, "Known-bad half-alpha cutoff demonstrably loses the glass interior")
	print("VFX alpha native render: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
