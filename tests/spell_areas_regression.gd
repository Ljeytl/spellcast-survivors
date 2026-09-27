extends SceneTree

var checks = 0
var failures = 0
var game
var manager
var origin: Vector2

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func clear_combat():
	for group in ["enemies", "build_spell_effects", "lightning_areas", "spell_projectiles"]:
		for node in get_nodes_in_group(group):
			node.free()
	game.player.position = origin
	manager.monsters_alive = 0

func enemy(offset: Vector2, boss = false):
	var result = manager.spawn_monster(manager.get_available_variants(0)[0], boss)
	result.position = origin + offset
	result.set_physics_process(false)
	result.current_health = 10000
	return result

func spell(id: String, target = null, overrides: Dictionary = {}):
	var info = game.spell_manager.spell_catalog[id].duplicate(true)
	info.merge(overrides, true)
	var node = load("res://scripts/TacticalSpellEffect.gd" if info.type in ["trail", "returning", "trap"] else "res://scripts/BuildSpellEffect.gd").new()
	node.configure(info, float(info.damage), game.player, target)
	game.add_child(node)
	node.set_physics_process(false)
	return node

func lightning(step: float):
	var node = load("res://scripts/LightningArea.gd").new()
	node.configure(origin, {"radius": 160, "active_duration": 0.2}, 80, game.player)
	game.add_child(node)
	node.set_physics_process(false)
	for index in range(ceili(0.2 / step)):
		node.advance(step)
	return node

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	origin = game.player.position
	clear_combat()
	for step in [0.01, 0.05, 0.2]:
		var inside = enemy(Vector2(60, 0))
		var edge = enemy(Vector2(160, 0))
		var outside = enemy(Vector2(160.1, 0))
		var area = lightning(step)
		check(inside.current_health == 9920 and edge.current_health == 9920, "Lightning hits inside and exact boundary once at step " + str(step))
		check(outside.current_health == 10000, "Lightning never damages beyond visible radius")
		check(area.is_queued_for_deletion(), "Lightning expires at 0.2 seconds")
		clear_combat()
	var close = enemy(Vector2(120, 0))
	var cluster = [enemy(Vector2(300, 0)), enemy(Vector2(310, 60)), enemy(Vector2(300, -60))]
	game.spell_manager.learn_spell("lightning_arc")
	check(game.spell_manager.cast_freeform_spell("lightning"), "Owned typed Lightning casts")
	check(close.current_health == 10000 and cluster.all(func(node): return node.current_health == 9920), "Lightning favors useful group coverage over isolated nearest enemy")
	check(get_nodes_in_group("lightning_areas").size() == 1, "Lightning uses circular burst, not bouncing projectile")
	clear_combat()
	var orbit_target = enemy(Vector2(145, 0))
	var orbit_outside = enemy(Vector2(174, 0))
	var orbit = spell("arcane_orbit")
	if "--known-bad-small-orbit" in OS.get_cmdline_user_args():
		orbit.info.orbit_radius = 65
		orbit.info.body_radius = 24
	orbit.advance(1)
	check(orbit_target.current_health < 10000, "Larger orbit protects at 145 units")
	check(orbit_outside.current_health == 10000, "Orbit cannot hit outside radius plus body")
	check(10000 - orbit_target.current_health <= 56, "Orbit damage bounded by per-target half-second cooldown")
	clear_combat()
	var pass_target = enemy(Vector2(150, 35))
	var linger_target = enemy(Vector2(350, 0))
	var blade = spell("returning_blade", pass_target)
	blade.direction = Vector2.RIGHT
	blade.advance(0.7)
	check(pass_target.current_health == 9940, "Wider Cross Blade sweeps real enemy on outbound once")
	blade.advance(0.9)
	check(linger_target.current_health >= 9850 and linger_target.current_health <= 9880, "Linger provides two or three controlled half-damage ticks plus outbound")
	blade.advance(0.8)
	check(pass_target.current_health == 9880, "Return adds one real enemy hit")
	check(linger_target.current_health >= 9790, "Linger and return cannot multiply per-frame damage")
	check(blade.is_queued_for_deletion(), "Cross Blade returns and expires")
	clear_combat()
	for speed in [1.0, 2.0]:
		blade = spell("returning_blade", null, {"projectile_speed_multiplier": speed})
		blade.advance(0.7 / speed)
		check(is_equal_approx(blade.global_position.distance_to(origin), 350), "Projectile speed retains Cross Blade travel distance")
		blade.free()
	var boss = enemy(Vector2(-300, 0), true)
	var trail = spell("ember_trail")
	if "--known-bad-short-fire" in OS.get_cmdline_user_args():
		trail.info.patch_duration = 2
	for index in range(100):
		game.player.position = origin + Vector2((index + 1) * 10, 0)
		boss.position += Vector2(4.5, 0)
		trail.advance(0.05)
	check(boss.current_health <= 10000 - 24, "Actual pursuing boss reaches live flames before they expire")
	clear_combat()
	var first_total = 0.0
	for step in [0.01, 0.05, 0.5]:
		var victim = enemy(Vector2(80, 0))
		trail = spell("ember_trail")
		game.player.position += Vector2(160, 0)
		trail.advance(0.1)
		check(trail.trail_contains(origin + Vector2(80, 64)) and not trail.trail_contains(origin + Vector2(80, 66)), "Connected trail has authoritative capsule boundary")
		for index in range(roundi(1.5 / step)):
			trail.advance(step)
		var total = 10000 - victim.current_health
		check(total == 72, "Overlapping samples deal one damage tick, independent of step " + str(step))
		first_total = total
		trail.advance(20)
		check(trail.is_queued_for_deletion(), "Firewalk and patches expire")
		clear_combat()
	var trigger = enemy(Vector2(300, 0))
	var trap = spell("rune_trap", trigger)
	trap.advance(10)
	check(not trap.triggered and not trap.is_queued_for_deletion(), "Visible armed trap persists without an enemy in trigger circle")
	trigger.position = trap.position + Vector2(70, 0)
	trap.advance(0.05)
	check(trap.triggered and trigger.current_health == 9940, "Real enemy at visible trigger boundary detonates trap once")
	trap.advance(1)
	check(trigger.current_health == 9940 and trap.is_queued_for_deletion(), "Trap burst is once-only and expires")
	clear_combat()
	print("Spell areas: ", checks, " assertions, ", failures, " failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
