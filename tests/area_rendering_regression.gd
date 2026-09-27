extends SceneTree

class AreaCanvas extends Node2D:
	var known_bad = false
	func _draw():
		draw_rect(Rect2(0, 0, 640, 480), Color("41683b"))
		var points = PackedVector2Array([Vector2(200, 120), Vector2(440, 120), Vector2(440, 360), Vector2(200, 360), Vector2(200, 120)])
		if known_bad:
			for polygon in Geometry2D.offset_polyline(points, 35, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND):
				draw_colored_polygon(polygon, Color("d44b35", 0.48))
		else:
			preload("res://scripts/AreaArt.gd").fire_path(self, points, 35, 0.2)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.size = Vector2i(640, 480)
	root.content_scale_size = Vector2i(640, 480)
	var canvas = AreaCanvas.new()
	canvas.known_bad = "--known-bad-fill-hole" in OS.get_cmdline_user_args()
	root.add_child(canvas)
	await process_frame
	await RenderingServer.frame_post_draw
	var capture = root.get_texture().get_image()
	var center = capture.get_pixel(320, 240)
	var outside = capture.get_pixel(50, 240)
	var edge = capture.get_pixel(440, 240)
	var checks = [center.is_equal_approx(outside), edge.r > outside.r + 0.1, edge.g < outside.g]
	var failures = checks.count(false)
	DirAccess.make_dir_recursive_absolute("res://builds/evidence")
	capture.save_png("res://builds/evidence/firewalk-closed-path" + ("-negative" if canvas.known_bad else "") + ".png")
	print("Area rendering: 3 assertions, ", failures, " failures")
	quit(1 if failures else 0)
