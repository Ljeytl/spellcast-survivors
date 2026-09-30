extends SceneTree
var checks = 0
var failures = 0
var game
var manager
var known_bad = "--known-bad" in OS.get_cmdline_user_args()
var interactive = "--interactive" in OS.get_cmdline_user_args()
func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()
func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func settle():
	for i in 3:
		await process_frame
func capture(name):
	if DisplayServer.get_name() == "headless" or known_bad:
		return
	await RenderingServer.frame_post_draw
	var out = "res://builds/casting-feel"
	DirAccess.make_dir_recursive_absolute(out)
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func type_spell(text):
	if manager.is_typing:
		manager.cancel_typing()
	manager.casting_clock += 1
	manager.start_freeform_typing()
	manager.current_typing_text = text
	game.style_session.observe_text(text)
	game.update_typing_display(text)
func run():
	root.get_node("AudioManager").quitting = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640,720) if "--narrow" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	if not interactive:
		root.set_flag(Window.FLAG_NO_FOCUS,true)
		root.position = Vector2i(5000,5000)
	if "--menu" in OS.get_cmdline_user_args():
		root.get_node("SceneManager").goto_scene("res://scenes/MainMenu.tscn")
		return
	game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run",true)
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	game.player.is_invincible = true
	game.player.xp_to_next_level = 1000000
	manager.mana_bolt_timer = 1000000
	for id in ["meteor_shower","regeneration","plague_seed","earth_shield","focus_ray"]:
		manager.learn_spell(id)
	var encounters = game.get_node("MonsterManager")
	encounters.set_process(false)
	encounters.spawn_timer.stop()
	for index in 6:
		var data = encounters.encounter_config.variants.pursuer.duplicate(true)
		data.id = "pursuer"
		var enemy = encounters.spawn_monster(data,false,true)
		if enemy:
			enemy.position = game.player.position + Vector2.from_angle(index*TAU/6)*220
			enemy.current_health = 1000000
			enemy.max_health = 1000000
			enemy.set_physics_process(false)
	await settle()
	if interactive:
		print("Interactive 0.1.45 fixture ready")
		return
	manager.set_process(false)
	game.player.set_physics_process(false)
	var session = game.style_session
	type_spell("bolt")
	var count = session.score.manual_casts
	check(manager.cast_freeform_spell("bolt"),"normal accepted")
	check(session.score.manual_casts == count+1 and manager.pending_keyword_casts.is_empty(),"normal releases immediately")
	type_spell("mega bolt")
	count = session.score.manual_casts
	check(manager.cast_freeform_spell("mega bolt"),"MEGA committed")
	check(not manager.is_typing,"commit restores movement mode")
	if known_bad:
		session.score.manual_casts += 1
	check(session.score.manual_casts == count,"no score before release")
	if known_bad:
		session.score.manual_casts -= 1
	check(manager.pending_keyword_casts.size()==1,"one immutable pending cast")
	await capture("charge-start")
	manager.advance_pending_casts(0.06)
	await capture("charge-middle")
	check(session.score.manual_casts==count,"no early release")
	check(game.time_dilation_effect.screen_overlay.color.a == 0.0,"release closes typing dim")
	var pending = manager.pending_keyword_casts[0]
	var original_damage = pending.stats.spell_damage_multiplier
	game.player.spell_damage_multiplier = 7
	manager.spells[1].level = 4
	type_spell("regeneration")
	check(is_equal_approx(game.time_dilation_effect.screen_overlay.color.a,0.035),"real typing sets light world dim")
	check(game.time_dilation_effect.layer < game.get_node("UI").layer,"dim below HUD")
	manager.cancel_typing()
	check(manager.pending_keyword_casts.size()==1,"later Escape keeps committed cast")
	check(pending.info.level==1 and pending.stats.spell_damage_multiplier==original_damage,"spell rank and stats frozen")
	game.change_state(game.GameState.PAUSED)
	manager.advance_pending_casts(1)
	check(manager.pending_keyword_casts.size()==1,"pause freezes release")
	game.change_state(game.GameState.PLAYING)
	manager.advance_pending_casts(0.061)
	check(manager.pending_keyword_casts.is_empty() and session.score.manual_casts==count+1,"release scores original receipt after newer attempt")
	check(game.player.spell_damage_multiplier==7,"release preserves live stats")
	var bolts = game.get_children().filter(func(node): return node is Area2D and node.get("projectile_type")=="bolt")
	check(bolts.any(func(node): return is_equal_approx(node.damage, 40.0*original_damage*1.5)),"emitted projectile uses committed power and rank")
	check(bolts.any(func(node): return is_equal_approx(float(node.get_meta("cast_size_snapshot",0)),1.5)),"emitted projectile keeps committed size")
	check(game.hud.get_node("StyleHUD").keyword_stamp.text=="MEGA ×1.1","separate MEGA style stamp")
	await capture("charge-release")
	var awarded = session.score.run_score
	manager.advance_pending_casts(1)
	check(session.score.run_score==awarded,"no duplicate award")
	type_spell("mega regeneration")
	check(manager.cast_freeform_spell("mega regeneration"),"first rapid cast")
	type_spell("mega earth shield")
	check(manager.cast_freeform_spell("mega earth shield"),"second rapid cast")
	check(manager.pending_keyword_casts.size()==2,"rapid casts have independent payloads")
	manager.advance_pending_casts(0.121)
	check(manager.active_healing_effects.size()>0,"queued regeneration effect exists")
	check(game.player.earth_shield.charges.size()>0,"queued shield effect exists")
	type_spell("mega bolt")
	manager.cast_freeform_spell("mega bolt")
	type_spell("regeneration")
	await settle()
	var before_time = manager.pending_keyword_casts[0].remaining
	manager._process(0.01)
	check(is_equal_approx(before_time-manager.pending_keyword_casts[0].remaining,0.05),"charge uses real gameplay time during next slowdown")
	manager.advance_pending_casts(0.08)
	manager.cancel_typing()
	type_spell("mega not owned")
	check(not manager.cast_freeform_spell("mega not owned") and manager.pending_keyword_casts.is_empty(),"invalid no pending")
	for enemy in get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
	type_spell("mega plague seed")
	check(not manager.cast_freeform_spell("mega plague seed"),"plague preflight rejects no host")
	check(manager.is_typing and manager.pending_keyword_casts.is_empty(),"failed preflight keeps incantation")
	check(game.typing_keycaps.error_caption()=="No target in range","preflight error rendered")
	await capture("preflight-no-target")
	for enemy in game.get_children():
		if enemy.get("current_health") != null:
			enemy.add_to_group("enemies")
	type_spell("mega plague seed")
	check(manager.cast_freeform_spell("mega plague seed"),"plague commits with host")
	for enemy in get_nodes_in_group("enemies"):
		enemy.remove_from_group("enemies")
	count = session.score.manual_casts
	type_spell("bolt")
	manager.advance_pending_casts(0.121)
	check(session.score.manual_casts==count,"lost plague target awards no style")
	check(manager.current_typing_text=="bolt","fizzle preserves next incantation")
	check(game.hud.get_node("StyleHUD").keyword_stamp.text=="No target","fizzle has visible feedback")
	var Score = load("res://scripts/StyleScore.gd")
	var a = Score.new()
	var award = a.award_cast("bolt","mega bolt",2,0,1)
	check(award.keyword_multiplier==1.1,"MEGA scoring multiplier")
	check(award.points==int(floor((10+2*8+0.5*8*8)*(1+0.25+0.5)*1.1+0.5)),"multiplier after bonuses before rounding")
	check(a.award_cast("bolt","mega bolt",2,0,1).is_empty(),"duplicate receipt remains zero")
	game.hud.get_node("StyleHUD").keyword_stamp.hide()
	for geometry in [Vector2i(1280,720),Vector2i(640,720),Vector2i(480,800)]:
		root.size=geometry
		game.get_node("GameplayReadability").layout()
		for text in ["bolt","mega meteor shower","mega regeneration","mega "+"x".repeat(100)]:
			type_spell(text)
			await settle()
			game._fit_typing_content()
			var panel = game.hud.get_node("TypingPanel")
			if known_bad:
				panel.position = game.hud.size/2-panel.size/2
			check(not panel.get_rect().intersects(Rect2(game.hud.size/2-Vector2(30,50),Vector2(60,100))),"typing avoids wizard body")
			var reference=game.hud.get_node("CastingReference")
			check(not panel.get_rect().intersects(reference.get_rect()),"typing avoids full spell reference")

			check(game.hud.get_rect().encloses(panel.get_rect()),"strip contained")
			var keys=game.typing_keycaps
			check(keys.key_position(keys.letters.length()-1).x+keys.fitted_key_size()<=keys.size.x,"last key contained")
			if text.length()<40:
				check(keys.visible_start()==0,"known incantation fully visible")
				await capture("final-%s-%s" % [geometry.x,text.replace(" ","-")])
	type_spell("mega bolt")
	manager.cast_freeform_spell("mega bolt")
	game.player.health=0
	manager.advance_pending_casts(0.2)
	check(manager.pending_keyword_casts.is_empty(),"death discards pending")
	game.player.health=100
	type_spell("mega bolt")
	manager.cast_freeform_spell("mega bolt")
	game.change_state(game.GameState.EXTRACTION)
	check(manager.pending_keyword_casts.is_empty(),"extraction discards pending")
	game.free()
	await process_frame
	print("Casting feel: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
