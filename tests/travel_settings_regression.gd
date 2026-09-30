extends SceneTree

var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run():
	root.get_node("AudioManager").quitting = true
	var terrain = load("res://scripts/Background.gd").new()
	var cell = Vector2i(100, 200)
	var original = terrain.generate_layout(cell)
	var before = terrain.layout_generation_count
	for i in 100:
		check(terrain.layout_for(cell) == original, "cached layout identical")
	check(terrain.layout_generation_count - before == 1, "warm queries generate once (old implementation fails)")
	before = terrain.layout_generation_count
	for i in 10:
		terrain.generate_layout(cell)
	check(terrain.layout_generation_count - before == 10, "negative control uncached queries detected")
	for i in 2000:
		terrain.layout_for(Vector2i(i, -100))
	check(terrain.layouts.size() == terrain.MAX_CACHED_LAYOUTS, "cache bounded over long travel")
	check(terrain.layout_for(cell) == original, "evicted grove regenerates identically")
	terrain.free()
	var settings = root.get_node("UserSettings")
	var path = settings.PATH
	var existing = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var clean = load("res://scripts/UserSettings.gd").new()
	root.add_child(clean)
	check(not clean.show_fps and not clean.fps_label.visible, "fresh settings FPS off")
	clean.free()
	settings.set_show_fps(false)
	for geometry in [Vector2i(1280, 720), Vector2i(640, 720)]:
		root.size = geometry
		var options = load("res://scenes/Options.tscn").instantiate()
		options.called_from_pause = true
		root.add_child(options)
		await process_frame
		await process_frame
		var toggle = options.get_node("OptionsPanel/VBoxContainer/FPSCheckBox")
		check(not toggle.button_pressed, "options reflects off")
		toggle.button_pressed = true
		check(settings.show_fps and settings.fps_label.visible, "toggle immediately shows meter")
		await process_frame
		var screen_transform = root.get_final_transform() * settings.fps_label.get_global_transform_with_canvas()
		var screen_font_height = settings.fps_label.get_theme_font_size("font_size") * screen_transform.get_scale().y
		check(screen_font_height >= 17.5, "FPS font stays readable in screen pixels")
		var fps_rect = screen_transform * Rect2(Vector2.ZERO, settings.fps_label.size)
		check(fps_rect.position.x >= 0 and fps_rect.end.x <= geometry.x + 1 and fps_rect.position.y >= 0 and fps_rect.end.y <= geometry.y - 25, "FPS stays on screen above version")
		var previous_scale = settings.fps_root.scale
		settings.fps_root.scale = Vector2.ONE
		var broken_transform = root.get_final_transform() * settings.fps_label.get_global_transform_with_canvas()
		if geometry.x == 640:
			check(settings.fps_label.get_theme_font_size("font_size") * broken_transform.get_scale().y < 17.5, "negative control detects unscaled FPS root")
		settings.fps_root.scale = previous_scale
		var config = ConfigFile.new()
		config.load(path)
		check(config.get_value("display", "show_fps") == true, "toggle persisted")
		check(toggle.get_global_rect().size.y > 0, "toggle has layout")
		options.free()
		options = load("res://scenes/Options.tscn").instantiate()
		options.called_from_pause = true
		root.add_child(options)
		await process_frame
		toggle = options.get_node("OptionsPanel/VBoxContainer/FPSCheckBox")
		check(toggle.button_pressed, "reopening reflects on")
		var restarted = load("res://scripts/UserSettings.gd").new()
		root.add_child(restarted)
		check(restarted.show_fps and restarted.fps_label.visible, "new settings instance reloads persisted on")
		restarted.free()
		paused = true
		toggle.button_pressed = false
		check(not settings.fps_label.visible, "disable while paused")
		paused = false
		options.free()
	if existing == null:
		DirAccess.remove_absolute(path)
	else:
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_buffer(existing)
		file.close()
	print("Travel/settings regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
