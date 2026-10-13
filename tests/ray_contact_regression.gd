extends SceneTree

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

## Beams run on the generic engine (doc 18 phase 2): each beam is a SpellPart, stepped by hand.
func adv(part, seconds: float) -> void:
	var dt = 1.0 / 60.0
	var whole = int(floor(seconds / dt + 0.000001))
	for i in whole:
		part.step(dt)
	if seconds - whole * dt > 0.000001:
		part.step(seconds - whole * dt)

## Pin a beam for a fixture: from the wizard, facing right, onto `enemy`, without turning.
func pin(part, enemy) -> void:
	part.beam_offset = Vector2.ZERO
	part.direction = Vector2.RIGHT
	part.target_ref = weakref(enemy)
	part.def = part.def.duplicate(true)
	part.def.aim = {"turn": 0.0}

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
		check(spells.cast_spell_by_type(spells.find_spell_slot(id)), "Cast " + id)
	for c in get_nodes_in_group("generic_casts"):
		c.manual = true
	beams = get_nodes_in_group("active_spell_channels")
	var reserved = {}
	for beam in beams:
		if beam.target_ref and beam.target_ref.get_ref():
			reserved[beam.target_ref.get_ref().get_instance_id()] = true
	check(beams.size() == 3 and reserved.size() == 3, "Focus and two Prism casts reserve three distinct targets")
	var prism = beams[1]
	pin(prism, enemies[0])
	var shape = enemies[1].get_node("HurtBox/HurtBoxShape")
	var half_height = shape.shape.size.y * absf(shape.global_scale.y) * 0.5
	var beam_radius = prism.geo("width") * 0.5
	enemies[1].global_position.y += half_height + beam_radius - 1
	enemies[4].global_position.y += half_height + beam_radius + 1
	if "--known-bad-contact" in OS.get_cmdline_user_args():
		shape.disabled = true
	adv(prism, 0.25)
	var tick = 10000 - enemies[0].current_health
	check(tick > 0, "Prism first tick lands")
	for index in range(4):
		check(is_equal_approx(enemies[index].current_health, 10000 - tick), "Prism first tick reaches target " + str(index))
	check(is_equal_approx(enemies[4].current_health, 10000), "Outside beam and hurtbox does not take damage")
	adv(prism, 0.25)
	for index in range(4):
		check(is_equal_approx(enemies[index].current_health, 10000 - tick * 2), "Prism second tick reaches target " + str(index))
	check(is_equal_approx(prism.beam_end.length(), 450), "Prism tip retains full reach")
	var focus = beams[0]
	pin(focus, enemies[0])
	adv(focus, 0.25)
	check(enemies[0].current_health < enemies[2].current_health, "Focus damages its first obstruction")
	check(focus.beam_end.length() < 80, "Focus ends at body contact rather than passing into center (%s)" % focus.beam_end.length())
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://builds/style-verification")
		root.get_texture().get_image().save_png("res://builds/style-verification/ray-contact.png")
	var dead = beams[2].target_ref.get_ref()
	var previous_direction = beams[2].direction
	var turn = float(beams[2].def.get("aim", {}).get("turn", 0.0))
	dead.dying = true
	adv(beams[2], 0.05)
	check(beams[2].target_ref.get_ref() != dead, "Dead target reservation is released")
	check(absf(previous_direction.angle_to(beams[2].direction)) <= turn * 0.05 + 0.0001, "Prism retargets within its slow turn limit")
	check(beams[2].target_ref.get_ref() != focus.target_ref.get_ref() and beams[2].target_ref.get_ref() != prism.target_ref.get_ref(), "Prism retarget selects an unreserved alternative")
	for index in range(1, enemies.size()):
		enemies[index].dying = true
	beams[2].target_ref = null
	adv(beams[2], 0.05)
	check(beams[2].target_ref != null and beams[2].target_ref.get_ref() == enemies[0], "One remaining enemy can be shared instead of wasting a channel")
	for enemy in enemies:
		enemy.dying = true
	adv(beams[2], 0.05)
	check(beams[2].target_ref == null and beams[2].is_style_channel_active(), "Empty retarget gap remains a bounded active channel")
	adv(beams[2], beams[2].remaining_life() + 0.05)
	check(not beams[2].is_style_channel_active(), "Channel stops on expiry")
	check(beams[2].done, "Expired damaging beam is removed")
	game.queue_free()
	await process_frame
	print("RAY_CONTACT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
