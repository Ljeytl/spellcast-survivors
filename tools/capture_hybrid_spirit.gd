extends SceneTree

const SPIRIT = preload("res://scripts/vfx/SpiritVisual.gd")
const OUT := "res://builds/hybrid-spirit/"
var stage: SubViewport
var hosts: Array[Node2D] = []
var frame := 0
var frame_times: Array[float] = []
var checks := 0
var failures := 0

class Host extends Node2D:
	var age := 0.0
	var done := false
	var direction := Vector2.RIGHT
	var heading := Vector2.RIGHT
	var healing := true
	var LIFE := 100.0
	var velocity := Vector2.ZERO
	var visual_radius := 43.7
	func geo(_key, _default):
		return visual_radius

func _initialize() -> void:
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	root.hide()
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func run() -> void:
	if not root.is_node_ready():
		await root.ready
	root.get_node("AudioManager").quitting = true
	root.get_node("Vfx").set_process(false)
	DirAccess.make_dir_recursive_absolute(OUT)
	var connections_before := RenderingServer.frame_post_draw.get_connections().size()
	stage = SubViewport.new()
	stage.size = Vector2i(1280, 850)
	stage.disable_3d = true
	stage.world_2d = World2D.new()
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var background := ColorRect.new()
	background.size = Vector2(1280, 850)
	background.color = Color(0.13, 0.205, 0.17)
	stage.add_child(background)
	var count := maxi(2, int(OS.get_environment("SPIRIT_CAPTURE_COUNT")))
	for i in range(count):
		var host := Host.new()
		host.position = Vector2(300 + (i % 4) * 240, 280 + (i / 4) * 240)
		stage.add_child(host)
		var visual = SPIRIT.new()
		visual.soul = i == 1
		visual.radius = host.visual_radius
		host.add_child(visual)
		visual.set_process(false)
		hosts.append(host)
	for index in range(180):
		var started := Time.get_ticks_usec()
		var dt := 1.0 / 60.0
		for i in range(hosts.size()):
			var host = hosts[i]
			host.age += dt
			var target := Vector2(300 + (i % 4) * 240, 280 + (i / 4) * 240)
			if index >= 35 and index < 85:
				target += Vector2(180, -80)
			elif index >= 85 and index < 130:
				target += Vector2(-180, 70)
			var acceleration: Vector2 = (target - host.position) * 30.0 - host.velocity * (2.0 * sqrt(30.0) * 0.88)
			host.velocity += acceleration * dt
			host.position += host.velocity * dt
			if host.velocity.length() > 22.0:
				host.direction = host.velocity.normalized()
				host.heading = host.direction
			if OS.get_environment("SPIRIT_FORCE_RESET") == "1":
				host.get_child(0).field_ready = false
			host.get_child(0)._process(dt)
		await process_frame
		await RenderingServer.frame_post_draw
		if index > 30:
			frame_times.append((Time.get_ticks_usec() - started) / 1000.0)
		if index == 70:
			var visual = hosts[0].get_child(0)
			var density: Image = visual.fields[visual.read_index].get_texture().get_image()
			var history := 0.0
			for distance in [1.8, 2.2, 2.6, 3.0]:
				var point: Vector2 = hosts[0].position - hosts[0].direction * visual.radius * distance
				var uv: Vector2 = (point - visual.field_origin) / visual.field_span
				history = maxf(history, density.get_pixelv(Vector2i(uv * 512.0)).r)
			check(history > 0.04, "Trail retains advected history beyond the current source")
			print("HISTORY_DENSITY ", history)
		if index in [30, 70, 105, 170] and OS.get_environment("SPIRIT_FORCE_RESET") != "1":
			var image := stage.get_texture().get_image()
			check(image != null and not image.is_empty(), "Native viewport has pixels")
			if image != null:
				image.save_png(OUT + "native-%03d.png" % index)
	for host in hosts:
		var visual = host.get_child(0)
		check(visual.simulation_steps >= 170, "Material actually advanced on the GPU")
		var image: Image = visual.fields[visual.read_index].get_texture().get_image()
		var center := image.get_pixel(256, 256)
		check(center.r > 0.01 and center.r < 1.01, "Density contains simulated material")
		print("FIELD_CENTER ", center, " steps=", visual.simulation_steps)
	var visual = hosts[0].get_child(0)
	var steps: int = visual.simulation_steps
	await process_frame
	await RenderingServer.frame_post_draw
	check(visual.simulation_steps == steps, "Paused host does not advance the material")
	var vfx = root.get_node("Vfx")
	vfx.presenter.enabled = false
	visual._process(0.016)
	check(not visual.visible and not visual.field_ready, "Hidden presentation resets stale history")
	vfx.presenter.enabled = true
	vfx.spirit_form_override = "wisp"
	visual._process(0.016)
	await process_frame
	await RenderingServer.frame_post_draw
	check(visual.visible and visual.form == "wisp" and visual.field_ready, "Resume seeds the selected material")
	vfx.spirit_form_override = "hybrid"
	hosts[0].visual_radius *= 2.0
	visual._process(0.016)
	await process_frame
	await RenderingServer.frame_post_draw
	check(visual.form == "hybrid" and is_equal_approx(visual.field_span, visual.radius * 12.0), "Resize and form switch update field coordinates together")
	vfx.spirit_form_override = "auto"
	frame_times.sort()
	print("FRAME_INTERVAL_MS count=", count, " median=", frame_times[frame_times.size() / 2], " p95=", frame_times[int(frame_times.size() * 0.95)])
	stage.queue_free()
	await process_frame
	check(get_nodes_in_group("spirit_visuals").is_empty(), "Capture frees all visual fields")
	check(RenderingServer.frame_post_draw.get_connections().size() == connections_before, "Host cleanup disconnects GPU callbacks")
	print("Native hybrid capture: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
