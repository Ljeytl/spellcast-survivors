extends "res://tools/capture_spell_gallery.gd"

func _initialize():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(10000, 10000)
	root.hide()
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.size = Vector2i(1280, 850)
	root.content_scale_size = root.size
	root.get_node("AudioManager").quitting = true
	for spell in ["bolt", "ice_blast"]:
		await setup()
		await create_timer(1.0).timeout
		var vfx = root.get_node("Vfx")
		vfx.clear()
		game.camera_shake.follow_offset = game.camera.global_position - game.player.global_position
		game.camera_shake.set_process(true)
		var stage := SubViewport.new()
		stage.size = root.size
		stage.world_2d = root.world_2d
		stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(stage)
		game.spell_manager.learn_spell(spell)
		assert(game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot(spell)))
		var folder: String = "res://builds/impact-feedback/" + spell
		DirAccess.make_dir_recursive_absolute(folder)
		var saved_pair := false
		for frame in 100:
			await physics_frame
			await process_frame
			stage.canvas_transform = root.get_canvas_transform()
			game.get_node("Background").queue_redraw()
			await RenderingServer.frame_post_draw
			if frame % 2 == 0:
				assert(stage.get_texture().get_image().save_png(folder + "/%04d.png" % (frame / 2)) == OK)
			if not saved_pair and not vfx.impact_light.pulses.is_empty():
				paused = true
				vfx.impact_light.visible = false
				await RenderingServer.frame_post_draw
				assert(stage.get_texture().get_image().save_png(folder + "/before.png") == OK)
				vfx.impact_light.visible = true
				await RenderingServer.frame_post_draw
				assert(stage.get_texture().get_image().save_png(folder + "/after.png") == OK)
				paused = false
				saved_pair = true
		assert(saved_pair)
		print("IMPACT_CAPTURE ", spell, " light_hit=", saved_pair)
		stage.queue_free()
		await teardown()
	quit()
