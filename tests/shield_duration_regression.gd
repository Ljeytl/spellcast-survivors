extends SceneTree

var checks = 0
var failures = 0
var game
var player
var manager

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, label):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func cast():
	manager.cast_earthshield_spell(manager.find_spell_slot("earth_shield"))
	player.earth_shield.set_physics_process(false)

func target(offset: Vector2):
	var monsters = game.get_node("MonsterManager")
	var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
	enemy.set_physics_process(false)
	enemy.global_position = player.global_position + offset
	enemy.max_health = 10000
	enemy.current_health = 10000
	enemy.update_health_bar()
	return enemy

func clear_eruptions():
	for effect in get_nodes_in_group("earth_shield_eruptions"):
		effect.free()

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.player
	manager = game.spell_manager
	manager.set_process(false)
	player.set_physics_process(false)
	game.style_session.set_process(false)
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	check(manager.learn_spell("earth_shield"), "Shield can be acquired")
	var attacker = target(Vector2(75,0))
	var beside = target(Vector2(110,30))
	var behind = target(Vector2(-75,0))
	var far = target(Vector2(200,0))
	cast()
	check(player.earth_shield.charges.size()==1 and player.overheal==0,"Cast adds charge without bonus HP")
	check(player.earth_shield.charges[0].remaining==16,"Authored lifetime")
	player.earth_shield.advance(10)
	cast()
	check(player.earth_shield.charges.size()==2,"Recast stacks")
	check(player.earth_shield.charges[0].remaining==6 and player.earth_shield.charges[1].remaining==16,"Recast does not refresh old lifetime")
	var status = preload("res://scripts/SpellDurationStatus.gd").collect(manager)
	check(status.earth_shield.count==2 and status.earth_shield.seconds==6,"UI reports count and next expiry")
	check(preload("res://scripts/SpellDurationStatus.gd").caption(status.earth_shield).begins_with("2 charges"),"UI calls charges charges")
	if "--visual" in OS.get_cmdline_user_args():
		root.size = Vector2i(1280,720)
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/earth-shield-0136/charges.png")
	game.style_session.score.combo = 5000
	player.take_damage(999999,{"attacker":weakref(attacker),"source_position":attacker.global_position})
	check(player.health==100 and player.earth_shield.charges.size()==1,"Any hit fully blocked by one charge")
	check(player.last_damage_context.blocked and player.last_damage_context.health_loss==0,"Blocked context has no health loss")
	if "--known-bad-combo" in OS.get_cmdline_user_args():
		player.style_health_damaged.emit(1)
	check(game.style_session.score.combo==5000,"Blocked hit preserves combo")
	check(player.earth_shield.charges[0].remaining==16,"Oldest expiring charge consumed first")
	await process_frame
	var eruption = get_nodes_in_group("earth_shield_eruptions")[-1]
	eruption.set_physics_process(false)
	check(eruption.direction.dot(Vector2.RIGHT)>0.99,"Retaliation points toward attacker")
	eruption.age = 0
	eruption.hit_ids.clear()
	attacker.current_health = 10000
	beside.current_health = 10000
	if "--known-bad-direction" in OS.get_cmdline_user_args():
		eruption.direction = Vector2.LEFT
	eruption.advance(0.05)
	check(attacker.current_health==10000,"Damage waits for visible front")
	eruption.advance(0.17)
	check(attacker.current_health==9940 and beside.current_health==9940,"Directional eruption damages its cone")
	check(behind.current_health==10000 and far.current_health==10000,"Behind and outside reach remain unharmed")
	check(attacker.knockback_velocity.x>0,"Push is away from player")
	eruption.advance(0.02)
	check(attacker.current_health==9940,"One hit per eruption")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/earth-shield-0136/retaliation.png")
	clear_eruptions()
	player.take_damage(0)
	player.take_damage(-20)
	player.is_invincible=true
	player.take_damage(20)
	player.is_invincible=false
	check(player.earth_shield.charges.size()==1,"Zero negative and invincible hits do not consume")
	player.health=0
	player.take_damage(20)
	check(player.earth_shield.charges.size()==1,"Dead player does not consume")
	player.health=100
	player.earth_shield.advance(16)
	check(player.earth_shield.charges.is_empty(),"Lifetime expires protection")
	check(not preload("res://scripts/SpellDurationStatus.gd").collect(manager).has("earth_shield"),"Expired charges removed from UI")
	player.take_damage(5,{"source_position":attacker.global_position})
	check(player.health==95 and game.style_session.score.combo<5000,"Unprotected hit damages health and combo")
	player.health=100
	cast()
	player.touching_enemies=[attacker,behind]
	player.damage_timer=0
	player.process_enemy_contact_damage(0.1)
	check(player.earth_shield.charges.is_empty(),"Crowd consumes available charge")
	check(player.health==100-behind.base_damage,"One charge cannot absorb entire crowd tick")
	player.health=100
	game.style_session.score.combo=5000
	var score_model=preload("res://scripts/StyleScore.gd").new()
	score_model.combo=5000
	score_model.take_hit()
	player.touching_enemies=[attacker,behind,beside]
	player.damage_timer=0
	player.process_enemy_contact_damage(0.1)
	check(game.style_session.score.combo==score_model.combo,"Unshielded crowd applies one style penalty per contact tick")
	player.touching_enemies.clear()
	await process_frame
	clear_eruptions()
	player.health=100
	player.spell_damage_multiplier=2
	player.spell_size_multiplier=2
	player.spell_duration_multiplier=2
	manager.spells[manager.find_spell_slot("earth_shield")].level=3
	cast()
	var charge=player.earth_shield.charges[0]
	check(is_equal_approx(charge.damage,156),"Power and rank scale retaliation once")
	check(charge.reach==320 and charge.remaining==32,"Size and Duration scale useful properties")
	check(charge.travel_time==0.22,"Duration does not delay retaliation")
	var shot=load("res://scripts/EnemyProjectile.gd").new()
	shot.attacker=weakref(behind)
	shot.source_position=behind.global_position
	shot.direction=Vector2.RIGHT
	shot.position = player.global_position - Vector2(30,0)
	shot.damage = 200
	game.add_child(shot)
	shot.set_physics_process(false)
	shot._physics_process(0.1)
	check(player.health==100 and player.earth_shield.charges.is_empty(),"Actual projectile collision spends one charge")
	await process_frame
	eruption=get_nodes_in_group("earth_shield_eruptions")[-1]
	eruption.set_physics_process(false)
	check(eruption.direction.dot(Vector2.LEFT)>0.99,"Projectile retaliation uses shooter direction")
	clear_eruptions()
	cast()
	var explosive = target(Vector2(50,0))
	explosive.explosion_range = 150
	explosive.explosion_damage = 30
	explosive.create_explosion()
	check(player.health==100 and player.earth_shield.charges.is_empty(),"Explosion damage is blocked without recursion")
	await process_frame
	check(get_nodes_in_group("earth_shield_eruptions").size()==1,"Explosion produces one deferred retaliation")
	clear_eruptions()
	check(preload("res://scripts/BuildVersion.gd").text()=="v0.1.36 · Playtest","Version 0.1.36")
	if "--visual" in OS.get_cmdline_user_args():
		root.size = Vector2i(640,480)
		cast()
		await process_frame
		game.get_node("GameplayReadability").layout()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/earth-shield-0136/charges-640.png")
		game.pending_level_ups.append(2)
		game.show_next_level_up()
		var ui=game.level_up_screen
		ui.available_upgrades=[{"name":"Earth Shield+","effect":{"type":"spell_upgrade","spell":"earth_shield"}},ui.generic_upgrades.spell_duration.duplicate(true),ui.generic_upgrades.spell_area.duplicate(true)]
		ui.update_ui(2,{})
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/earth-shield-0136/upgrade-640.png")
		for button in ui.upgrade_buttons:
			check(button.get_global_rect().encloses(button.get_node("CardText").get_global_rect()),"Upgrade copy contained")
		var rank=manager.get_spell_rank("earth_shield")
		ui.upgrade_buttons[0].pressed.emit()
		await create_timer(0.4).timeout
		check(manager.get_spell_rank("earth_shield")==rank+1,"Upgrade selection increases shield rank")
		check(not ui.visible and game.current_state==game.GameState.PLAYING,"Upgrade returns to game")
	game.queue_free()
	await process_frame
	print("EARTH_SHIELD checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
