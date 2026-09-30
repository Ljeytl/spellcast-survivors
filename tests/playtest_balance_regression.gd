extends SceneTree

const Targeting = preload("res://scripts/SpellTargeting.gd")
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
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.player.set_physics_process(false)
	var spells = game.spell_manager
	spells.set_process(false)
	spells.active_healing_effects.clear()
	spells.spells[2] = spells.spell_catalog.regeneration.duplicate(true)
	spells.spells[2].level = 1
	game.player.health = 1
	spells.cast_life_spell(2)
	spells.process_healing_effects(1.0)
	check(is_equal_approx(game.player.health, 4), "Regen heals three HP during first second")
	spells.process_healing_effects(4.0)
	check(is_equal_approx(game.player.health, 16), "Regen heals fifteen total over five seconds")
	spells.process_healing_effects(1.0)
	check(is_equal_approx(game.player.health, 16), "Regen stops after five seconds")
	manager.game_time = 300
	manager.check_boss_milestones()
	var boss_one = get_nodes_in_group("enemies").filter(func(e): return e.boss)[0]
	check(is_equal_approx(boss_one.current_health, 1200), "Boss one spawns with final 1200 HP")
	manager.game_time = 600
	manager.check_boss_milestones()
	var boss_two = get_nodes_in_group("enemies").filter(func(e): return e.boss and e.variant == "charger")[0]
	check(is_equal_approx(boss_two.current_health, 1800), "Boss two spawns with final 1800 HP")
	boss_two.charge_remaining = 1.0
	boss_two.action_direction = Vector2.RIGHT
	boss_two.update_charge(0.01, Vector2.RIGHT, 200)
	check(is_equal_approx(boss_two.velocity.length(), 600), "Boss two charge is 600")
	boss_two.slow_multiplier = 0.5
	boss_two.update_charge(0.01, Vector2.RIGHT, 200)
	check(is_equal_approx(boss_two.velocity.length(), 300), "Charge still respects slows")
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await process_frame
	var definition = manager.encounter_config.variants.pursuer.duplicate(true)
	definition.id = "pursuer"
	var enemy = manager.spawn_monster(definition)
	enemy.set_physics_process(false)
	enemy.global_position = game.player.global_position + Vector2(20, 0)
	enemy.current_health = 500
	var trap = preload("res://scripts/TacticalSpellEffect.gd").new()
	trap.configure(spells.spell_catalog.rune_trap.duplicate(true), spells.spell_catalog.rune_trap.damage, game.player, enemy)
	game.add_child(trap)
	trap.set_process(false)
	trap.age = 1
	trap.advance_trap()
	check(is_equal_approx(enemy.current_health, 460), "Trap deals forty damage")
	trap.advance_trap()
	check(is_equal_approx(enemy.current_health, 460), "Trap cannot trigger twice")
	check(enemy.knockback_velocity == Vector2.ZERO, "Trap does not add knockback")
	check(Targeting.meteor_weight(100, 100, 0) > Targeting.meteor_weight(500, 100, 0), "Closer enemies have higher weight")
	check(Targeting.meteor_weight(100, 500, 0) > Targeting.meteor_weight(100, 30, 0), "Stronger enemies have higher weight")
	check(Targeting.meteor_weight(100, 100, 1) < Targeting.meteor_weight(100, 100, 0), "Covered enemies have lower weight")
	var viewport = root.get_visible_rect()
	check(Targeting.select_meteor(self, game.player.global_position, viewport) == enemy, "Visible enemy eligible")
	enemy.global_position += Vector2(100000, 0)
	check(Targeting.select_meteor(self, game.player.global_position, viewport) == null, "Offscreen enemy excluded")
	enemy.global_position = game.player.global_position + Vector2(60, 0)
	var far_enemy = manager.spawn_monster(definition)
	far_enemy.set_physics_process(false)
	far_enemy.global_position = game.player.global_position + Vector2(300, 0)
	far_enemy.current_health = enemy.current_health
	seed(412)
	var near_count = 0
	var far_count = 0
	for index in range(500):
		var selected = Targeting.select_meteor(self, game.player.global_position, viewport)
		near_count += int(selected == enemy)
		far_count += int(selected == far_enemy)
	check(near_count > far_count and far_count > 0, "Weighted rolls favor closer enemy without excluding farther enemy")
	var covered_count = 0
	for index in range(500):
		var selected = Targeting.select_meteor(self, game.player.global_position, viewport, {enemy.get_instance_id(): 3.0})
		covered_count += int(selected == enemy)
	check(covered_count < near_count, "Repeated area coverage changes actual selection frequency")
	enemy.global_position = game.player.global_position + Vector2(60, 0)
	far_enemy.queue_free()
	await process_frame
	spells.learn_spell("meteor_shower")
	var meteor_slot = spells.find_spell_slot("meteor_shower")
	var counts = [3, 4, 5, 6, 7, 8, 9, 10]
	for rank in range(1, 9):
		spells.spells[meteor_slot].level = rank
		spells.cast_meteor_shower_spell(meteor_slot)
		var warnings = get_nodes_in_group("spell_projectiles").filter(func(n): return n.projectile_type == "warning")
		check(warnings.size() == counts[rank - 1], "Meteor real cast count at rank %d" % rank)
		var radius = 110 if rank < 3 else (195 if rank < 6 else 280)
		check(warnings.all(func(n): return is_equal_approx(n.effect_radius, radius)), "Meteor visible geometry at rank %d" % rank)
		check(is_equal_approx(spells.calculate_spell_damage(spells.spells[meteor_slot]), 25), "Meteor ranks do not also increase damage")
		for warning in warnings:
			warning.free()
	spells.spells[meteor_slot].level = 2
	check(preload("res://scripts/UpgradeCopy.gd").rank_description("meteor_shower", spells).contains("radius"), "Real upgrade copy describes area rank")
	spells.spells[meteor_slot].level = 1
	check(preload("res://scripts/UpgradeCopy.gd").rank_description("meteor_shower", spells) == "Drop one extra meteor.", "Real upgrade copy describes count rank only")
	spells.learn_spell("returning_blade")
	var blade_slot = spells.find_spell_slot("returning_blade")
	spells.spells[blade_slot].level = 1
	enemy.global_position = game.player.global_position + Vector2(0, -150)
	enemy.current_health = 500
	spells.cast_build_spell(blade_slot)
	var first_volley = get_nodes_in_group("cross_blade_volleys").back()
	for blade in first_volley.get_children():
		blade.set_physics_process(false)
		blade.advance(0.4)
	check(is_equal_approx(enemy.current_health, 480), "Actual triangle volley hits outbound with one weaker blade")
	for blade in first_volley.get_children():
		blade.advance(2.0)
	check(is_equal_approx(enemy.current_health, 460), "Actual triangle volley hits again on return")
	first_volley.free()
	for rank in range(1, 9):
		spells.spells[blade_slot].level = rank
		spells.cast_build_spell(blade_slot)
		var volleys = get_nodes_in_group("cross_blade_volleys")
		var volley = volleys.back()
		var blades = volley.get_children()
		var count = 3 if rank == 1 else (4 if rank < 6 else (5 if rank < 8 else 6))
		check(blades.size() == count, "Blade count at rank %d" % rank)
		for index in range(count):
			check(is_equal_approx(blades[index].damage, 20), "Each blade is weaker, independent of count rank")
			var next = blades[(index + 1) % count]
			check(is_equal_approx(fposmod(next.direction.angle() - blades[index].direction.angle(), TAU), TAU / count), "Blades form evenly spaced polygon")
		if rank == 2:
			check(blades.all(func(b): return is_equal_approx(absf(b.direction.x), absf(b.direction.y))), "Four blades form X rather than plus")
		if rank == 8:
			check(is_equal_approx(blades[0].info.blade_radius, 29) and is_equal_approx(blades[0].outbound_distance, 460), "Size and range ranks reach authored values")
		volley.free()
	spells.spells[blade_slot].level = 8
	spells.upgrade_spell("returning_blade")
	check(spells.get_spell_rank("returning_blade") == 8, "Finite progression cannot upgrade into no-op ranks")
	spells.spells[meteor_slot].level = 8
	var screen = game.level_up_screen
	for roll in range(30):
		var cards = screen.generate_upgrade_options({}, 20)
		check(not cards.any(func(card): return card.effect.get("type", "") == "spell_upgrade" and card.effect.get("spell", "") in ["returning_blade", "meteor_shower"]), "Level-up UI excludes capped spell ranks")
	for index in range(4):
		spells.cast_build_spell(blade_slot)
	check(get_nodes_in_group("cross_blade_volleys").filter(func(n): return not n.is_queued_for_deletion()).size() == 3, "Active limit counts volleys, not individual blades")
	await process_frame
	var live_volleys = get_nodes_in_group("cross_blade_volleys")
	check(live_volleys.size() == 3 and live_volleys.all(func(v): return v.get_child_count() == 6), "Oldest volley and all its children are removed")
	for v in live_volleys:
		for blade in v.get_children():
			blade.advance(10.0)
	await process_frame
	await process_frame
	check(get_nodes_in_group("cross_blade_volleys").is_empty(), "Completed volleys and their children expire")
	for pair in [[0, 1.0], [180, 1.0], [300, 1.2], [600, 1.65], [780, 2.0], [1020, 10.0 / 3.0], [1200, 4.5]]:
		manager.game_time = pair[0]
		check(is_equal_approx(manager.spawn_difficulty_multiplier(), pair[1]), "Spawn curve passes authored pacing milestone")
		manager.game_time = pair[0] - 0.001
		var before = manager.spawn_difficulty_multiplier()
		manager.game_time = pair[0] + 0.001
		check(absf(manager.spawn_difficulty_multiplier() - before) < 0.001, "Spawn curve continuous across milestone")
	manager.game_time = 1020
	check(is_equal_approx(manager.spawn_difficulty_multiplier(), 10.0 / 3.0), "Minute seventeen reaches requested interval compression")
	game.queue_free()
	await process_frame
	print("Playtest balance: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
