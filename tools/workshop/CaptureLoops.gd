extends SceneTree

const Fixture = preload("res://tools/workshop/PreviewFixture.gd")
const OUT = "res://builds/spell-gallery/"
const FPS = 30
var fixture = Fixture.new()

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		push_error("Capture requires workshop isolation")
		quit(2)
		return
	run.call_deferred()

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.size = Vector2i(960, 600)
	root.content_scale_size = Vector2i(1280, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute(OUT)
	fixture.settings.scenery = false
	await fixture.setup(root, "bolt")
	var entries = fixture.catalog()
	var filter = ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			filter = argument.trim_prefix("--only=")
	if not filter.is_empty():
		entries = entries.filter(func(entry): return entry.id == filter)
	assert(not entries.is_empty())
	for entry in entries:
		await fixture.setup(root, entry.id)
		entry.start_frame = Engine.get_frames_drawn()
		entry.poster = entry.id + ".png"
		var poster_time = {"meteor_shower": 0.85, "rune_trap": 0.85, "frost_sigil": 1.5, "ember_trail": 3.0, "plague_seed": 1.2, "soul_bloom": 1.2}.get(entry.id, 0.15)
		if entry.group == "Particles":
			poster_time = minf(fixture.duration * 0.25, 0.15)
		var frame_count = ceili(fixture.duration * FPS)
		for frame in range(frame_count):
			await process_frame
			fixture.advance(1.0 / FPS)
			await RenderingServer.frame_post_draw
			if frame == floori(poster_time * FPS):
				var error = root.get_texture().get_image().save_png(OUT + entry.poster)
				if error != OK:
					push_error("Could not save gallery poster")
					quit(2)
					return
		entry.end_frame = Engine.get_frames_drawn()
		entry.duration = float(entry.end_frame - entry.start_frame) / FPS
		entry.video = entry.id + ".mp4"
		entry.gif = entry.id + ".gif"
		print("LOOP ", entry.id, " ", entry.duration, " seconds")
	var output = FileAccess.open(OUT + "loops.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(entries, "  "))
	print("LOOPS COMPLETE ", entries.size())
	quit()
