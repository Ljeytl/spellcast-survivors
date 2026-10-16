extends "res://tools/capture_spell_gallery.gd"

var checks := 0
var failures := 0
var stage: SubViewport

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	root.hide()
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", label)

func shot(label: String):
	game.camera.force_update_scroll()
	stage.canvas_transform = root.get_canvas_transform()
	game.get_node("Background").queue_redraw()
	await RenderingServer.frame_post_draw
	check(stage.get_texture().get_image().save_png("res://builds/cast-camera/" + label + ".png") == OK, "Saved " + label)

func type_word(text: String):
	var manager = game.spell_manager
	manager.space_casting = true
	manager.start_freeform_typing()
	for ch in text:
		var event := InputEventKey.new()
		event.keycode = KEY_SPACE if ch == " " else KEY_A + ch.unicode_at(0) - 97
		event.unicode = ch.unicode_at(0)
		event.pressed = true
		manager.handle_key_input(event)
		await create_timer(0.05, true, false, true).timeout
	await create_timer(0.15, true, false, true).timeout

func run():
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("AudioManager").quitting = true
	DirAccess.make_dir_recursive_absolute("res://builds/cast-camera")
	await setup()
	await create_timer(1.0).timeout
	var shaker = game.camera_shake
	var origin: Vector2 = game.camera.global_position
	shaker._process(1.0 / 60.0)
	check(game.camera.global_position.distance_to(origin) > 1.0, "Known-bad preview framing produces follow drift")
	game.camera.global_position = origin
	shaker.follow_offset = origin - game.player.global_position
	shaker._process(1.0 / 60.0)
	check(game.camera.global_position.distance_to(origin) < 0.01, "Aligned preview follow target removes drift")
	shaker.shake_impact(11.0, 0.26)
	var peak := 0.0
	for i in 30:
		shaker._process(1.0 / 60.0)
		peak = maxf(peak, game.camera.offset.length())
	check(peak > 0.0 and peak <= sqrt(2.0) * 11.0, "Impact shake is bounded and nonzero")
	check(game.camera.offset.length() < 0.01, "Impact shake returns to baseline")
	shaker.reduced_effects = true
	shaker.shake_impact(11.0, 0.26)
	shaker._process(1.0 / 60.0)
	check(game.camera.offset.length() < 0.01, "Reduced effects suppress impact shake")
	shaker.reduced_effects = false
	shaker.set_process(true)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	stage = SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var manager = game.spell_manager
	check(manager.learn_spell("lightning"), "Learn Lightning")
	var circle = game.player.get_node("CastingCircle")
	await type_word("lightning")
	check(circle.runes.size() == 9, "Plain Lightning builds nine letter runes")
	check(circle.satellites.is_empty(), "Plain Lightning creates no keyword satellite")
	await shot("plain-typed")
	check(manager.cast_freeform_spell("lightning"), "Plain typed spell releases")
	check(manager.pending_keyword_casts.is_empty(), "Plain release has no Mega charge")
	check(is_equal_approx(manager.last_generic_cast.plan.parts.mark.geometry.radius, 100.0), "Plain cast keeps base radius")
	await create_timer(0.05, true, false, true).timeout
	await shot("plain-release")
	await create_timer(1.5, true, false, true).timeout
	check(circle.satellites.is_empty() and circle.shards.is_empty(), "Plain casting effects clear")
	await type_word("mega lightning")
	check(circle.satellites.size() == 1 and circle.satellites[0].word == "mega", "Mega creates exactly one keyword satellite")
	await shot("mega-typed")
	check(manager.cast_freeform_spell("mega lightning"), "Mega typed spell queues")
	check(manager.pending_keyword_casts.size() == 1, "Mega alone creates charge phase")
	await shot("mega-charge")
	manager.advance_pending_casts(0.5)
	check(manager.pending_keyword_casts.is_empty(), "Mega charge releases")
	check(manager.last_generic_cast.plan.parts.mark.geometry.radius > 100.0, "Mega release has enlarged radius")
	await create_timer(1.5, true, false, true).timeout
	check(circle.satellites.is_empty() and circle.shards.is_empty(), "Mega casting effects clear")
	stage.queue_free()
	await teardown()
	print("CAST_CAMERA: %d checks, %d failures; peak=%f" % [checks, failures, peak])
	quit(1 if failures else 0)
