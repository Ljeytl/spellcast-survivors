extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func definition(manager, id: String) -> Dictionary:
	var data = manager.encounter_config.variants[id].duplicate(true)
	data["id"] = id
	return data

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	manager.game_time = 0.0
	check(manager.get_available_variants(0).size() == 1, "Opening begins with consistent pursuers")
	check(manager.encounter_config.variants.size() == 12, "Twelve distinct variants exist")
	for family in ["grunt", "runner", "brute", "shooter"]:
		var count = 0
		for data in manager.encounter_config.variants.values():
			if data.family == family:
				count += 1
		check(count == 3, "%s has three variants" % family)
	for second in range(600):
		for data in manager.get_available_variants(second):
			check(data.family != "shooter", "No ranged enemy before ten minutes")
	check(manager.get_available_variants(600).any(func(data): return data.id == "marksman"), "Marksman unlocks at ten minutes")
	check(manager.get_available_variants(720).size() == 12, "All variants become available by twelve minutes")
	var grunt = manager.calculate_monster_stats(definition(manager, "pursuer"))
	var runner = manager.calculate_monster_stats(definition(manager, "sprinter"))
	check(ceil(grunt.health / 15.0) in [2.0, 3.0], "Grunts require two to three starting passive hits")
	check(runner.health <= 15 and runner.speed >= grunt.speed * 2.0 and runner.speed <= grunt.speed * 3.0, "Sprinter trades durability for 2–3x speed")
	manager.game_time = 900.0
	check(manager.calculate_monster_stats(definition(manager, "pursuer")).health > grunt.health, "Health grows when passive attack is not upgraded")
	for boundary in [300, 600, 900, 1200]:
		manager.game_time = boundary - 0.01
		manager.check_boss_milestones()
		check(manager.spawned_bosses.size() == boundary / 300 - 1, "Boss never arrives early")
		manager.game_time = boundary
		manager.check_boss_milestones()
		manager.check_boss_milestones()
		check(manager.spawned_bosses.size() == boundary / 300, "Boss milestone dispatches once")
	check(get_nodes_in_group("bosses").size() == 4, "Bosses coexist when earlier ones are alive")
	check(manager.get_current_difficulty_level() == 4, "Living bosses do not prevent tier advancement")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	manager.monsters_alive = 0
	manager.game_time = 0.0
	var shield = manager.spawn_monster(definition(manager, "shieldbearer"))
	shield.set_physics_process(false)
	shield.facing = Vector2.RIGHT
	var health = shield.current_health
	shield.take_damage(10, shield.global_position + Vector2(100, 0))
	check(is_equal_approx(health - shield.current_health, 6.5), "Frontal shield reduces but never blocks damage completely")
	health = shield.current_health
	shield.take_damage(10, shield.global_position - Vector2(100, 0))
	check(is_equal_approx(health - shield.current_health, 10.0), "Flanking bypasses shield")
	health = shield.current_health
	shield.take_damage(10)
	check(is_equal_approx(health - shield.current_health, 10.0), "Area damage works without an elemental key")
	for id in ["pursuer", "flanker", "skirmisher", "sprinter", "charger", "swarmer", "juggernaut", "slammer", "marksman", "fan_caster", "mortar"]:
		var enemy = manager.spawn_monster(definition(manager, id))
		check(enemy != null and enemy.variant == id, "Instantiated behavior %s" % id)
		enemy.set_physics_process(false)
		enemy.position = game.player.position + Vector2(300, 0)
		enemy.action_time = 0
		enemy._physics_process(0.016)
		check(enemy.velocity.is_finite(), "Movement remains finite for %s" % id)
		if id == "flanker":
			check(absf(enemy.velocity.y) > 0.1, "Flanker approaches at an angle")
		if id == "skirmisher":
			enemy.position = game.player.position + Vector2(100, 0)
			enemy.behavior_time = 2.1
			enemy._physics_process(0.016)
			check(enemy.velocity.x > 0, "Skirmisher retreats during its disengage phase")
		if id == "juggernaut":
			check(enemy.current_health > grunt.health * 3 and enemy.speed < grunt.speed, "Juggernaut trades speed for durability")
		if id == "slammer":
			enemy.position = game.player.position + Vector2(100, 0)
			var before = get_nodes_in_group("enemy_projectiles").size()
			enemy._physics_process(0.016)
			check(enemy.velocity == Vector2.ZERO and get_nodes_in_group("enemy_projectiles").size() == before + 1, "Slammer stops and warns before an area strike")

		if id in ["charger", "marksman", "fan_caster", "mortar"]:
			check(enemy.warning > 0, "Special attack has a readable wind-up for %s" % id)
		if id in ["marksman", "fan_caster", "mortar"]:
			var before = get_nodes_in_group("enemy_projectiles").size()
			enemy.update_ranged(1.0, Vector2.LEFT, 300)
			var expected = 3 if id == "fan_caster" else 1
			check(get_nodes_in_group("enemy_projectiles").size() - before == expected, "Correct attack pattern for %s" % id)
	var before_count = manager.monsters_alive
	manager.spawn_monster(definition(manager, "swarmer"))
	check(manager.monsters_alive == before_count + 3, "Swarmers arrive in a group of three")
	var charger = get_nodes_in_group("enemies").filter(func(enemy): return enemy.variant == "charger")[0]
	charger.update_charge(1.0, Vector2.LEFT, 300.0)
	charger.update_charge(0.1, Vector2.RIGHT, 300.0)
	check(charger.velocity.x < 0, "Charge keeps its telegraphed direction when the player moves")
	var xp_before = get_nodes_in_group("xp_orbs").size()
	shield.take_damage(10000)
	shield.take_damage(10000)
	await process_frame
	await process_frame
	check(get_nodes_in_group("xp_orbs").size() == xp_before + 1, "Repeated lethal hits award XP only once")
	var Hazard = load("res://scripts/EnemyProjectile.gd")
	var shot = Hazard.new()
	shot.position = game.player.position - Vector2(100, 0)
	shot.direction = Vector2.RIGHT
	shot.damage = 7
	root.add_child(shot)
	shot.set_physics_process(false)
	game.player.is_invincible = false
	game.player.health = 100
	shot._physics_process(1.0)
	check(game.player.health == 93, "Swept enemy projectile collision deals damage")
	var blast = Hazard.new()
	blast.position = game.player.position
	blast.damage = 10
	blast.blast_radius = 90
	blast.warning_time = 1.4
	root.add_child(blast)
	blast.set_physics_process(false)
	blast._physics_process(1.0)
	check(game.player.health == 93, "Mortar warning deals no early damage")
	blast._physics_process(0.41)
	check(game.player.health == 83, "Mortar deals damage after warning")
	blast._physics_process(0.01)
	check(game.player.health == 83, "Mortar deals damage only once")
	blast.queue_free()
	var deaths: Array = []
	game.player.player_died.connect(func(): deaths.append(true))
	game.player.take_damage(1000)
	game.player.take_damage(1000)
	check(deaths.size() == 1, "Simultaneous enemy attacks emit death only once")
	check(game.game_over_screen.visible, "Death opens the game-over screen")
	paused = false
	game.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.15, true, false, true).timeout
	print("ENCOUNTER_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
