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
	var effect = game.particle_manager.get_pooled_particle("spell_cast")
	effect.emitting = true
	game.particle_manager.auto_cleanup_particle(effect, 0.5)
	var cleanups: Array = []
	effect.get_node("EmissionTimeout").timeout.connect(func(): cleanups.append(true))
	await create_timer(0.1).timeout
	game.particle_manager.auto_cleanup_particle(effect, 1.0)
	await create_timer(0.6).timeout
	check(cleanups.is_empty(), "Reused particles are not stopped by an earlier timeout")
	paused = true
	await create_timer(1.2).timeout
	check(cleanups.is_empty(), "Particle cleanup pauses with the effect")
	paused = false
	await create_timer(1.2).timeout
	check(cleanups.size() == 1 and not effect.emitting, "Particle emission stops once after its current lifetime")
	manager.game_time = 0.0
	check(manager.get_available_variants(0).size() == 1, "Opening begins with consistent pursuers")
	check(manager.encounter_config.variants.size() == 13, "Thirteen distinct variants exist")
	for family in ["grunt", "runner", "brute", "shooter"]:
		var count = 0
		for data in manager.encounter_config.variants.values():
			if data.family == family:
				count += 1
		check(count == (4 if family == "grunt" else 3), "%s has its variants (grunts include the Imp)" % family)
	for second in range(600):
		for data in manager.get_available_variants(second):
			check(data.family != "shooter", "No ranged enemy before ten minutes")
	check(manager.get_available_variants(600).any(func(data): return data.id == "marksman"), "Marksman unlocks at ten minutes")
	check(manager.get_available_variants(720).size() == manager.encounter_config.variants.size(), "All variants become available by twelve minutes")
	var grunt = manager.calculate_monster_stats(definition(manager, "pursuer"))
	var runner = manager.calculate_monster_stats(definition(manager, "sprinter"))
	check(ceil(grunt.health / 15.0) in [2.0, 3.0], "Grunts require two to three starting passive hits")
	check(runner.health <= 15 and runner.speed >= grunt.speed * 2.0 and runner.speed <= grunt.speed * 3.0, "Sprinter trades durability for 2–3x speed")
	manager.game_time = 900.0
	check(manager.calculate_monster_stats(definition(manager, "pursuer")).health > grunt.health, "Health grows when passive attack is not upgraded")
	for boundary in [300, 600, 900]:
		manager.game_time = boundary - 0.01
		manager.check_boss_milestones()
		check(manager.spawned_bosses.size() == boundary / 300 - 1, "Boss never arrives early")
		manager.game_time = boundary
		manager.check_boss_milestones()
		manager.check_boss_milestones()
		check(manager.spawned_bosses.size() == boundary / 300, "Boss milestone dispatches once")
	check(get_nodes_in_group("bosses").size() == 3, "Bosses coexist when earlier ones are alive")
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
	var front = shield.global_position + Vector2(100, 0)
	var spec = shield.spawn_data.shield
	check(is_equal_approx(shield.shield_max, shield.max_health * float(spec.health_share)), "the shield has its own health, a share of the body's")
	shield.take_damage(10, front)
	check(is_equal_approx(health - shield.current_health, 10.0 * float(spec.bleed_through)), "a front hit mostly lands on the shield; bleed_through reaches the body")
	check(is_equal_approx(shield.shield_hp, shield.shield_max - 10.0 * (1.0 - float(spec.bleed_through))), "the shield takes the rest")
	health = shield.current_health
	shield.take_damage(10, shield.global_position - Vector2(100, 0))
	check(is_equal_approx(health - shield.current_health, 10.0), "Flanking bypasses shield")
	health = shield.current_health
	shield.take_damage(10)
	check(is_equal_approx(health - shield.current_health, 10.0), "damage with no origin (burn, bleed, poison ticks) skips the shield")
	health = shield.current_health
	var left = shield.shield_hp
	var big = left / (1.0 - float(spec.bleed_through)) + 20.0
	shield.take_damage(big, front)
	check(shield.shield_hp == 0.0 and shield.stagger_remaining > 0.0, "breaking the shield staggers the Shieldbearer")
	check(is_equal_approx(health - shield.current_health, big - left), "what the shield could not hold goes through")
	health = shield.current_health
	shield.take_damage(10, front)
	check(is_equal_approx(health - shield.current_health, 10.0), "a broken shield stays broken: front hits land in full")
	for id in ["pursuer", "flanker", "skirmisher", "imp", "sprinter", "charger", "swarmer", "juggernaut", "slammer", "marksman", "fan_caster", "mortar"]:
		var enemy = manager.spawn_monster(definition(manager, id))
		check(enemy != null and enemy.variant == id, "Instantiated behavior %s" % id)
		enemy.set_physics_process(false)
		enemy.position = game.player.position + Vector2(300, 0)
		enemy.action_time = 0
		enemy._physics_process(0.016)
		check(enemy.velocity.is_finite(), "Movement remains finite for %s" % id)
		if id == "flanker":
			check(absf(enemy.velocity.y) > 0.1, "Flanker approaches at an angle")
			var mate = manager.spawn_monster(definition(manager, id))
			mate.set_physics_process(false)
			mate.position = game.player.position + Vector2(320, 60)
			enemy.partner_search = 0.0
			enemy._physics_process(0.016)
			check(enemy.get_partner() == mate and mate.get_partner() == enemy, "Flankers pair up")
			mate._physics_process(0.016)
			var p0 = game.player.global_position
			var a = (enemy.velocity.normalized().dot((p0 - enemy.global_position).normalized()))
			check(enemy.velocity.normalized().dot(mate.velocity.normalized()) < 0.5, "the pair splits to opposite sides of you")
			enemy.pincer_wait = 10.0
			enemy._physics_process(0.016)
			check(enemy.pincer_closing > 0.0 and mate.pincer_closing > 0.0, "the pair closes in together")
			mate._physics_process(0.016)
			check(mate.velocity.length() > mate.speed * 1.5, "closing is a burst")
			mate.queue_free()
		if id == "skirmisher":
			var l = enemy.spawn_data.lunge
			enemy.position = game.player.position + Vector2(100, 0)
			enemy.action_time = 1.0
			enemy._physics_process(0.016)
			check(enemy.velocity.x > 0, "Spear goblin backs off when you are closer than its standoff")
			enemy.position = game.player.position + Vector2(220, 0)
			enemy.action_time = 0.0
			enemy._physics_process(0.016)
			check(enemy.warning > 0.0 and enemy.velocity == Vector2.ZERO, "Spear goblin stops and telegraphs its lunge at mid range")
			enemy.update_lunge(enemy.warning + 0.01, Vector2.LEFT, 220.0)
			enemy.update_lunge(0.016, Vector2.LEFT, 220.0)
			check(enemy.velocity.x < -float(l.speed) * 0.5, "the lunge drives at you along the telegraphed line")
			enemy.update_lunge(float(l.duration), Vector2.LEFT, 220.0)
			enemy.update_lunge(0.016, Vector2.LEFT, 220.0)
			check(enemy.retreat_remaining > 0.0 and enemy.velocity.x > 0, "after the lunge it backs off")
		if id == "imp":
			var look = enemy.get_node("Sprite2D").material
			check(look is ShaderMaterial and is_equal_approx(float(look.get_shader_parameter("hue_shift")), float(enemy.spawn_data.recolor.hue)), "the Imp's placeholder recolour applies (doc 22 §9)")
			var o = enemy.spawn_data.orb
			check(enemy.warning > 0.0, "Special attack has a readable wind-up for imp (at 300 px)")
			enemy.warning = 0.0
			enemy.position = game.player.position + Vector2(100, 0)
			enemy.action_time = 0.0
			enemy._physics_process(0.016)
			check(enemy.warning == 0.0 and enemy.velocity.x < 0, "Imp chases you up close instead of throwing")
			enemy.position = game.player.position + Vector2(400, 0)
			enemy._physics_process(0.016)
			check(enemy.warning > 0.0 and enemy.velocity == Vector2.ZERO, "Imp winds up its orb when you get distance on it")
			var before_orbs = get_nodes_in_group("enemy_projectiles").size()
			enemy.update_imp(enemy.warning + 0.01, Vector2.LEFT, 400.0)
			await process_frame
			var orbs = get_nodes_in_group("enemy_projectiles")
			check(orbs.size() == before_orbs + 1 and orbs[-1].orb_radius == float(o.radius) and orbs[-1].speed == float(o.speed), "the orb is slow and round (dodgeable)")
			check(enemy.action_time > 0.0, "the orb has a cooldown")
		if id == "juggernaut":
			check(enemy.current_health > grunt.health * 3 and enemy.speed < grunt.speed, "Juggernaut trades speed for durability")
			enemy.position = game.player.position + Vector2(300, 0)
			enemy._physics_process(0.016)
			var calm = enemy.velocity.length()
			enemy.current_health = enemy.max_health * 0.1
			enemy._physics_process(0.016)
			check(enemy.velocity.length() > calm * 1.8, "Juggernaut enrages: hurt, it comes much faster (%.0f -> %.0f)" % [calm, enemy.velocity.length()])
			var jstatus = preload("res://scripts/engine/Effects.gd").ensure_status(enemy)
			jstatus.apply("chilled", {})
			enemy.apply_knockback(Vector2.RIGHT, 500.0)
			enemy._physics_process(0.016)
			check(enemy.slow_multiplier < 1.0 and enemy.velocity.length() > calm * 1.8 and enemy.knockback_velocity == Vector2.ZERO, "chill and knockback do not hold an enraged Juggernaut")
			jstatus.apply("frozen", {})
			enemy._physics_process(0.016)
			check(enemy.velocity == Vector2.ZERO, "a full freeze still stops it (slow %.2f)" % enemy.slow_multiplier)
			check(enemy.get_node("Sprite2D").self_modulate.r > 1.1, "an enraged Juggernaut glows hot")
		if id == "slammer":
			enemy.position = game.player.position + Vector2(100, 0)
			var before = get_nodes_in_group("enemy_projectiles").size()
			enemy._physics_process(0.016)
			check(enemy.velocity == Vector2.ZERO and get_nodes_in_group("enemy_projectiles").size() == before + 1, "Slammer stops and warns before an area strike")

		if id in ["charger", "marksman", "fan_caster", "mortar"]:
			check(enemy.warning > 0, "Special attack has a readable wind-up for %s" % id)
		if id == "mortar":
			check(enemy.get_node("Sprite2D").self_modulate.is_equal_approx(Color(1.0, 0.62, 0.38)), "the Mortar's placeholder tint sets it apart from the Shieldbearer's identical sprite")
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
	await process_frame
	print("ENCOUNTER_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
