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
	var potion_script = preload("res://scripts/HealthPotion.gd")
	for index in range(potion_script.MAX_DROPS):
		potion_script.try_drop(game, game.player.position + Vector2(200, 100), 0.0)
	var prior_potions = get_nodes_in_group("health_potions").size()
	boss.take_damage(100000, game.player.position)
	await process_frame
	await process_frame
	var rewards = get_nodes_in_group("boss_rewards")
	check(rewards.size() == 1, "Real boss defeat drops exactly one reward")
	check(get_nodes_in_group("style_pickups").size() == 3, "Boss defeat drops three style runes")
	var potions = get_nodes_in_group("health_potions")
	check(potions.size() == prior_potions + 1, "Boss guarantees exactly one potion even at ordinary drop cap")
	var boss_potion = potions.back()
	check(boss_potion.global_position.distance_to(rewards[0].global_position) == 48, "Potion visibly separated from boss chest")
	game.player.health = game.player.max_health
	check(not boss_potion.collect(), "Boss potion waits while healthy")
	game.player.health -= 20
	check(boss_potion.collect() and game.player.health == game.player.max_health - 10, "Boss potion heals 10 HP")
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
	game._on_player_level_up(game.player.level + 1, {})
	check(game.queue_boss_reward() and game.pending_level_ups.size() == 1, "Boss reward queues behind an existing XP level-up")
	game.level_up_screen._on_upgrade_button_pressed(0)
	await create_timer(0.4, true, false, true).timeout
	check(game.level_up_screen.title_label.text == "BOSS REWARD", "Queued chest follows XP choice")
	game.level_up_screen._on_upgrade_button_pressed(0)
	await create_timer(0.4, true, false, true).timeout
	check(game.current_state == game.GameState.PLAYING, "Both queued choices finish before resuming")
	var screen = game.level_up_screen
	screen.generate_upgrade_options({}, level)
	for card in screen.current_upgrade_pool:
		screen.banished_upgrades.append(screen.get_upgrade_key(card))
	screen.available_upgrades = screen.generate_upgrade_options({}, level)
	check(not screen.available_upgrades.is_empty(), "Exhausted offer filters retain an actionable recovery")
	check(screen.available_upgrades.all(func(card): return screen.get_upgrade_key(card) not in screen.banished_upgrades), "Fallback does not restore banished cards")
	manager.run_finished = true
	var last_boss = spawn("charger", true)
	check(last_boss == null, "Run completion prevents new bosses")
	game.finish_run(true)
	check(not game.queue_boss_reward(), "Victory prevents a post-run reward screen")
	game.queue_free()
	await process_frame
	print("Pass2 rewards encounters: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
