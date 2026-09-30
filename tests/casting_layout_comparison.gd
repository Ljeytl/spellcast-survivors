extends SceneTree
var game
func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()
func settle():
	for i in 5:
		await process_frame
func run():
	root.get_node("AudioManager").quitting = true
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run", true)
	root.add_child(game)
	current_scene = game
	var manager = game.spell_manager
	manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	for id in ["ember_trail", "arcane_orbit", "earth_shield", "focus_ray", "regeneration"]:
		manager.learn_spell(id)
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	for index in 8:
		var definition = monsters.encounter_config.variants.pursuer.duplicate(true)
		definition.id = "pursuer"
		var enemy = monsters.spawn_monster(definition, false, true)
		if enemy:
			enemy.position = game.player.position + Vector2.from_angle(index * TAU / 8) * 180
			enemy.set_physics_process(false)
	var out = "res://builds/casting-layout"
	DirAccess.make_dir_recursive_absolute(out)
	for geometry in [Vector2i(1280,720),Vector2i(640,720)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		await settle()
		manager.start_freeform_typing()
		for text in ["bolt", "mega meteor shower", "mega chain lightning"]:
			manager.current_typing_text = text
			game.update_typing_display(text)
			game.update_typing_slowdown(1.5, 1.5)
			await settle()
			var panel = game.hud.get_node("TypingPanel")
			for placement in ["baseline", "lower-center", "below-wizard", "above-wizard"]:
				if placement == "baseline":
					game.position_typing_ui_upper_screen()
				else:
					var backing = StyleBoxFlat.new()
					backing.bg_color = Color(0.035,0.06,0.07,0.65)
					backing.corner_radius_top_left = 8
					backing.corner_radius_top_right = 8
					backing.corner_radius_bottom_left = 8
					backing.corner_radius_bottom_right = 8
					panel.add_theme_stylebox_override("panel",backing)
					panel.position.x = (game.hud.size.x-panel.size.x)/2
					panel.position.y = game.hud.size.y-panel.size.y-145 if placement == "lower-center" else game.hud.size.y/2+55 if placement == "below-wizard" else game.hud.size.y/2-panel.size.y-65
				game.time_dilation_effect.screen_overlay.color.a = 0.15 if placement == "baseline" else 0.035
				await settle()
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(out.path_join("%s-%s-%s.png" % [geometry.x,placement,text.replace(" ","-")]))
	game.free()
	quit()
