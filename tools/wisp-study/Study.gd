extends Node2D

var flow
var clock := 0.0
var label: Label
var previous := Vector2.ZERO
var paused := false
var last_stage := -1

func _ready() -> void:
	flow = preload("res://tools/wisp-study/Flow.gd").new()
	add_child(flow)
	var camera := Camera2D.new()
	camera.position = Vector2(640, 400)
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	if OS.has_feature("web"):
		flow.reduced = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('reduced') || ''")) != ""
	label = Label.new()
	label.position = Vector2(36, 28)
	label.add_theme_font_size_override("font_size", 22)
	var overlay := CanvasLayer.new()
	add_child(overlay)
	overlay.add_child(label)
	print("FLOW_READY")

func _process(dt: float) -> void:
	if paused:
		return
	clock += dt
	if clock >= 14.0:
		clock = 0.0
		flow.reset()
	var center := Vector2(640, 400)
	var position := center
	var stage := 0
	if clock >= 3.0 and clock < 6.0:
		var t := (clock - 3.0) / 3.0
		position = center + Vector2(smoothstep(0.0, 1.0, t) * 220.0, 0)
		stage = 1
	elif clock >= 6.0 and clock < 9.0:
		var a := (clock - 6.0) / 3.0 * PI
		position = center + Vector2(cos(a), sin(a) * 0.55) * 220.0
		stage = 2
	elif clock >= 9.0:
		position = center + Vector2(-220, 0)
		stage = 3 if clock < 11.0 else 4
		if clock >= 11.0:
			flow.arrive()
	var velocity := (position - previous) / maxf(dt, 0.001) if previous != Vector2.ZERO and clock > dt else Vector2.ZERO
	previous = position
	flow.advance(dt, position, velocity)
	label.text = "WISP MATERIAL STUDY · %s\nAnimated core + circulating, shedding material · 2× inspection view\nSpace: pause/resume · R: reset · prototype, not gameplay" % ["HOVER", "ACCELERATE", "TURN", "SETTLE", "ARRIVE"][stage]
	if last_stage != stage:
		last_stage = stage
		print("FLOW_STAGE:", stage)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			paused = not paused
			label.text = "PAUSED\n" + label.text if paused else label.text.trim_prefix("PAUSED\n")
			print("FLOW_PAUSED:", paused)
		if event.keycode == KEY_R:
			clock = 0.0
			paused = false
			last_stage = -1
			print("FLOW_RESET")
			previous = Vector2.ZERO
			flow.reset()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 800), Color("#14262c"))
	for x in range(0, 1280, 40):
		draw_line(Vector2(x, 130), Vector2(x, 800), Color(0.3, 0.5, 0.5, 0.06))
	for y in range(160, 800, 40):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.3, 0.5, 0.5, 0.06))
