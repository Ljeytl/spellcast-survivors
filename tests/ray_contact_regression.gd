extends SceneTree

const Afterglow = preload("res://scripts/TacticalSpellEffect.gd").BeamAfterglow
var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	var spells = game.spell_manager
	spells.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	var enemies: Array = []
	for index in range(5):
		var definition = monsters.encounter_config.variants.pursuer.duplicate(true)
		definition.id = "pursuer"
		var enemy = monsters.spawn_monster(definition)
		enemy.set_physics_process(false)
		enemy.global_position = game.player.global_position + Vector2(80 + 70 * index, 0)
		enemy.current_health = 10000
		enemies.append(enemy)
	spells.spells.clear()
	spells.bonus_spells.clear()
	spells.acquired_spells.clear()
	for id in ["focus_ray", "ember_spear", "prism_ray"]:
		check(spells.learn_spell(id), "Learn " + id)
	var beams: Array = []
	for id in ["focus_ray", "prism_ray", "prism_ray"]:
		check(spells.cast_build_spell(spells.find_spell_slot(id)), "Cast " + id)
		beams = get_nodes_in_group("active_spell_channels")
		for beam in beams:
			beam.set_physics_process(false)
	var reserved = {}
	for beam in beams:
		reserved[beam.target_ref.get_ref().get_instance_id()] = true
	check(reserved.size() == 3, "Focus and two Prism casts reserve three distinct targets")
	var prism = beams[1]
	prism.info.beam_origin_offset = Vector2.ZERO
	prism.direction = Vector2.RIGHT
	prism.target_ref = weakref(enemies[0])
	prism.info.beam_turn_speed = 0.0
	var shape = enemies[1].get_node("HurtBox/HurtBoxShape")
	var half_height = shape.shape.size.y * absf(shape.global_scale.y) * 0.5
	enemies[1].global_position.y += half_height + prism.beam_radius() - 1
	enemies[4].global_position.y += half_height + prism.beam_radius() + 1
	if "--known-bad-contact" in OS.get_cmdline_user_args():
		shape.disabled = true
	prism.advance(0.25)
	for index in range(4):
		check(is_equal_approx(enemies[index].current_health, 10000 - prism.damage), "Prism first tick reaches target " + str(index))
	check(is_equal_approx(enemies[4].current_health, 10000), "Outside beam and hurtbox does not take damage")
	prism.advance(0.25)
	for index in range(4):
		check(is_equal_approx(enemies[index].current_health, 10000 - prism.damage * 2), "Prism second tick reaches target " + str(index))
	check(is_equal_approx(prism.beam_end.length(), 450), "Prism tip retains full reach")
	var focus = beams[0]
	focus.info.beam_origin_offset = Vector2.ZERO
	focus.direction = Vector2.RIGHT
	focus.target_ref = weakref(enemies[0])
	focus.advance(0.25)
	check(enemies[0].current_health < enemies[2].current_health, "Focus damages its first obstruction")
	check(focus.beam_end.length() < 80, "Focus ends at body contact rather than passing into center")
	if "--screenshots" in OS.get_cmdline_user_args():
		for beam in beams:
			beam.queue_redraw()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://builds/style-verification")
		root.get_texture().get_image().save_png("res://builds/style-verification/ray-contact.png")
	var dead = beams[2].target_ref.get_ref()
	var previous_direction = beams[2].direction
	dead.dying = true
	beams[2].advance(0.05)
	check(beams[2].target_ref.get_ref() != dead, "Dead target reservation is released")
	check(absf(previous_direction.angle_to(beams[2].direction)) <= 0.01251, "Prism retargets within its slow turn limit")
	check(beams[2].target_ref.get_ref() != focus.target_ref.get_ref() and beams[2].target_ref.get_ref() != prism.target_ref.get_ref(), "Prism retarget selects an unreserved alternative")
	for index in range(1, enemies.size()):
		enemies[index].dying = true
	beams[2].target_ref = null
	beams[2].advance(0.05)
	check(beams[2].target_ref.get_ref() == enemies[0], "One remaining enemy can be shared instead of wasting a channel")
	for enemy in enemies:
		enemy.dying = true
	prism.advance(0.05)
	check(prism.target_ref == null and prism.is_style_channel_active(), "Empty retarget gap remains a bounded active channel")
	prism.advance(prism.remaining + 0.05)
	check(not prism.is_style_channel_active(), "Channel stops on expiry")
	check(prism.is_queued_for_deletion(), "Expired damaging beam is removed")
	var glows = game.get_children().filter(func(node): return node is Afterglow)
	check(glows.size() == 1, "Expiry produces one short visual afterglow")
	check(not glows[0].is_in_group("active_spell_channels"), "Afterglow cannot sustain style")
	glows[0]._process(0.13)
	check(glows[0].is_queued_for_deletion(), "Afterglow ends after 120 milliseconds")
	game.queue_free()
	await process_frame
	print("RAY_CONTACT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
