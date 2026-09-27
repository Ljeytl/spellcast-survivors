extends SceneTree

var checks = 0
var failures = 0
var game

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

func spawn(id, boss = false):
	var manager = game.get_node("MonsterManager")
	var definition = manager.encounter_config.variants[id].duplicate(true)
	definition.id = id
	var enemy = manager.spawn_monster(definition, boss)
	if enemy != null:
		enemy.set_physics_process(false)
	return enemy

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var enemy = spawn("pursuer")
	enemy.position = game.player.position + Vector2(20, 0)
	game.player.touching_enemies = [enemy]
	game.player.damage_timer = 0
	var health = game.player.health
	game.player.process_enemy_contact_damage(0.1)
	check(game.player.health < health and enemy.recoil_remaining > 0, "Actual contact damage triggers recoil")
	check(enemy.recoil_velocity.x > 0, "Recoil points away from player")
	var recoil = enemy.recoil_remaining
	game.player.process_enemy_contact_damage(0.1)
	check(enemy.recoil_remaining == recoil, "Contact cooldown does not retrigger bounce")
	enemy.recoil_remaining = 0
	game.player.is_invincible = true
	game.player.damage_timer = 0
	game.player.process_enemy_contact_damage(0.1)
	check(enemy.recoil_remaining == 0, "Rejected contact damage causes no recoil")
	game.player.is_invincible = false
	game.player.touching_enemies.clear()
	var charger = spawn("charger")
	var boss = spawn("charger", true)
	charger.charge_remaining = 1
	boss.charge_remaining = 1
	charger.action_direction = Vector2.RIGHT
	boss.action_direction = Vector2.RIGHT
	charger.update_charge(0.1, Vector2.RIGHT, 600)
	boss.update_charge(0.1, Vector2.RIGHT, 600)
	check(boss.velocity.length() > charger.velocity.length(), "Pursuer boss dash faster than ordinary charger")
	boss.charge_remaining = 0
	boss.warning = 0.01
	boss.update_charge(0.02, Vector2.RIGHT, 600)
	check(boss.charge_remaining > 0.65, "Pursuer boss dash lasts longer")
	boss.position = game.player.position + Vector2(400, 0)
	boss.take_damage(100000, game.player.position)
	await process_frame
	await process_frame
	var rewards = get_nodes_in_group("boss_rewards")
	check(rewards.size() == 1, "Real boss defeat drops exactly one reward")
	var reward = rewards[0]
	var level = game.player.level
	check(reward.collect(), "Boss chest opens upgrade selection")
	check(not reward.collect(), "Boss chest cannot be collected twice")
	check(game.current_state == game.GameState.LEVEL_UP and paused, "Boss reward pauses play for choice")
	check(game.level_up_screen.title_label.text == "BOSS REWARD", "Boss reward is identified without pretending to gain a level")
	check(game.player.level == level, "Chest does not change player level")
	check(not game.level_up_screen.available_upgrades.is_empty(), "Boss reward offers valid choices")
	game.level_up_screen._on_upgrade_button_pressed(0)
	await create_timer(0.4, true, false, true).timeout
	check(game.current_state == game.GameState.PLAYING and not paused, "Selecting reward returns to gameplay")
	var screen = game.level_up_screen
	screen.generate_upgrade_options({}, level)
	for card in screen.current_upgrade_pool:
		screen.banished_upgrades.append(screen.get_upgrade_key(card))
	check(not screen.generate_upgrade_options({}, level).is_empty(), "Exhausted offer filters retain an actionable owned-spell upgrade")
	manager.run_finished = true
	var last_boss = spawn("charger", true)
	check(last_boss == null, "Run completion prevents new bosses")
	game.finish_run(true)
	check(not game.queue_boss_reward(), "Victory prevents a post-run reward screen")
	game.queue_free()
	await process_frame
	print("Pass2 rewards encounters: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
