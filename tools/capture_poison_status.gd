extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or not args[0].begins_with("/"):
		quit(2)
		return
	var folder := args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	await setup()
	await create_timer(1.0).timeout
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(10000, 10000)
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	var foes := get_nodes_in_group("enemies")
	if foes.is_empty():
		quit(2)
		return
	var enemy = foes[0]
	for other in foes:
		if other != enemy:
			other.free()
	enemy.global_position = game.player.global_position + Vector2(160, 0)
	var damage: Array = []
	enemy.damage_feedback.connect(func(amount, _position, source): damage.append({"amount":amount,"source":source.duplicate(true),"movie_frame":Engine.get_frames_drawn()}))
	enemy.status.apply("poison", {"hit":40.0,"duration":4.0}, {"spell":"poison_status_fixture","cast_id":77})
	var stage := SubViewport.new()
	stage.size = root.size
	stage.world_2d = root.world_2d
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var frames: Array = []
	var max_bubbles := 0
	for frame in 120:
		await physics_frame
		await process_frame
		max_bubbles = maxi(max_bubbles, root.get_node("Vfx").elements.bubbles.size())
		stage.canvas_transform = root.get_canvas_transform()
		game.get_node("Background").queue_redraw()
		await RenderingServer.frame_post_draw
		if stage.get_texture().get_image().save_png("%s/%04d.png" % [folder,frame]) != OK:
			quit(2)
			return
		frames.append({"png":frame,"movie_frame":Engine.get_frames_drawn(),"health":enemy.current_health,"bubbles":root.get_node("Vfx").elements.bubbles.size()})
	var failures: Array = []
	if damage.is_empty() or enemy.current_health >= 10000 or max_bubbles == 0:
		failures.append("missing_actual_poison_or_feedback")
	FileAccess.open(folder + "/manifest.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":"Standalone stationary real enemy with directly applied poison; actual damage ticks, no Seeker body and no hostile-AI claim","fps":30,"frames":frames,"damage":damage,"final_health":enemy.current_health,"max_bubbles":max_bubbles,"failures":failures,"sound_grade":"U: not heard"},"\t"))
	print("POISON_STATUS ",JSON.stringify({"damage_events":damage.size(),"max_bubbles":max_bubbles,"failures":failures}))
	stage.queue_free()
	await teardown()
	quit(0 if failures.is_empty() else 1)
