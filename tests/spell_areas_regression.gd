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
	for group in ["enemies", "spell_projectiles", "generic_casts"]:
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

## Ported spells run on the generic engine (doc 18 phase 2): spawn from catalog data, driven by hand.
func spell(id: String, target = null, overrides: Dictionary = {}):
	var info = game.spell_manager.spell_catalog[id].duplicate(true)
	info.merge(overrides, true)
	var cast = game.spell_manager.spawn_ported(info, float(info.damage), {}, target)
	cast.manual = true
	return cast

func root_of(cast):
	var roots = cast.root_parts()
	return roots[0] if not roots.is_empty() else null

func burning(cast, point: Vector2) -> bool:
	for p in cast.parts:
		if is_instance_valid(p) and not p.done and p.part_name.begins_with("patch") and p.contains(point, 0.0):
			return true
	return false

## Lightning centred on the origin (an anchor enemy stands there to aim it).
func lightning(step: float):
	var anchor = enemy(Vector2.ZERO)
	var cast = game.spell_manager.spawn_ported({"id": "lightning", "type": "direct_strike", "radius": 160, "active_duration": 0.2}, 80, {}, anchor)
	cast.manual = true
	cast.run(0.2, step)
	return cast

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
		check(area.finished, "Lightning expires at 0.2 seconds")
		clear_combat()
	var close = enemy(Vector2(120, 0))
	var cluster = [enemy(Vector2(300, 0)), enemy(Vector2(310, 60)), enemy(Vector2(300, -60))]
	game.spell_manager.learn_spell("lightning")
	check(game.spell_manager.cast_freeform_spell("lightning"), "Owned typed Lightning casts")
	check(close.current_health == 10000 and cluster.all(func(node): return node.current_health == 9940), "Lightning favors useful group coverage over isolated nearest enemy")
	var strike = game.spell_manager.last_generic_cast
	check(strike != null and strike.plan.id == "lightning" and str(strike.plan.parts[strike.plan.root].geometry.type) == "disk", "Lightning uses circular burst, not bouncing projectile")
	clear_combat()
	var weak_a = enemy(Vector2(-350, 0))
	var weak_b = enemy(Vector2(350, 0))
	weak_a.current_health = 15
	weak_b.current_health = 15
	game.spell_manager.learn_spell("meteor_shower")
	check(game.spell_manager.cast_freeform_spell("meteor shower"), "Owned Meteor Shower casts")
	# Meteor Shower runs on the generic engine (doc 18 phase 2): each mark is a root part.
	var warnings = game.spell_manager.last_generic_cast.root_parts()
	check(warnings.size() == 3, "Meteor creates one telegraph per scheduled impact")
	check(warnings.all(func(node): return node.global_position in [weak_a.global_position, weak_b.global_position]), "Meteor targets visible enemy positions")
	check(warnings.all(func(node): return node.total_life() >= 0.65 and is_equal_approx(node.geo("radius"), float(game.spell_manager.spell_catalog["meteor_shower"].radius))), "Every meteor retains full warning and data impact geometry")
	check(weak_a.current_health == 15 and weak_b.current_health == 15, "Warnings deal no damage before impact")
	clear_combat()
	var durable = enemy(Vector2(200, 0), true)
	game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("meteor_shower"))
	warnings = game.spell_manager.last_generic_cast.root_parts()
	check(warnings.all(func(node): return node.global_position == durable.global_position), "Lone healthy boss can receive all meteor impacts")
	clear_combat()
	var orbit_target = enemy(Vector2(145, 0))
	var orbit_outside = enemy(Vector2(174, 0))
	var orbit = spell("arcane_orbit", null, {"orbit_radius": 130})  # full-rank geometry
	orbit.advance(1)
	check(orbit_target.current_health < 10000, "Larger orbit protects at 145 units")
	check(orbit_outside.current_health == 10000, "Orbit cannot hit outside radius plus body")
	check(10000 - orbit_target.current_health <= 56, "Orbit damage bounded by per-target half-second cooldown")
	clear_combat()
	var pass_target = enemy(Vector2(150, 18))
	var outside_blade = enemy(Vector2(150, 26))
	var linger_target = enemy(Vector2(350, 0))
	var blade = spell("cross_blade", pass_target, {"blade_count": 1})
	var thrown = root_of(blade)
	thrown.direction = Vector2.RIGHT
	var blade_damage = float(game.spell_manager.spell_catalog.cross_blade.damage)
	blade.advance(0.7)
	check(is_equal_approx(pass_target.current_health, 10000 - blade_damage), "Cross Blade sweeps a target inside the reduced body once")
	blade.advance(0.9)
	# Doc 21 §5.4: the blade holds and pulses at 100% each (50 physical / 50 earth).
	check(linger_target.current_health >= 10000 - blade_damage * 4.0 - 2.0 and linger_target.current_health <= 10000 - blade_damage * 3.0 + 0.001, "Holding provides two or three full-damage pulses plus outbound (%s)" % (10000 - linger_target.current_health))
	blade.advance(0.8)
	check(is_equal_approx(pass_target.current_health, 10000 - blade_damage * 3.0), "Return adds one double-strength enemy hit")
	check(outside_blade.current_health == 10000, "Reduced blade misses a target inside its former width")
	# Hits, not health: blade statuses (spell_damage.json) add their own procs on top.
	var linger_hits = blade.hits_log.filter(func(h): return h.enemy == linger_target.get_instance_id()).size()
	check(linger_hits <= 5, "Linger and return cannot multiply per-frame damage (%d hits: outbound, three pulses, return)" % linger_hits)
	blade.advance(5)
	check(blade.finished, "Cross Blade returns and expires")
	clear_combat()
	for speed in [1.0, 2.0]:
		game.player.projectile_speed_multiplier = speed
		blade = spell("cross_blade", null, {"blade_count": 1})
		blade.advance(0.7 / speed)
		check(is_equal_approx(root_of(blade).global_position.distance_to(origin), 350), "Projectile speed retains Cross Blade travel distance (%s)" % root_of(blade).global_position.distance_to(origin))
		blade.free()
	game.player.projectile_speed_multiplier = 1.0
	var boss = enemy(Vector2(-300, 0), true)
	var trail = spell("firewalk")
	for index in range(100):
		game.player.position = origin + Vector2((index + 1) * 10, 0)
		boss.position += Vector2(4.5, 0)
		trail.advance(0.05)
	check(boss.current_health <= 10000 - 24, "Actual pursuing boss reaches live flames before they expire (%s, boss at %s, patches %d)" % [10000 - boss.current_health, boss.position - origin, trail.parts.filter(func(p): return is_instance_valid(p) and not p.done).size()])
	clear_combat()
	var walk_radius = float(game.spell_manager.spell_catalog.firewalk.get("trail_radius", 65.0))
	for step in [0.01, 0.05, 0.5]:
		var victim = enemy(Vector2(80, 0))
		trail = spell("firewalk")
		game.player.position += Vector2(160, 0)
		trail.advance(0.1)
		check(burning(trail, origin + Vector2(80, walk_radius * 0.8)) and not burning(trail, origin + Vector2(80, walk_radius + 2)), "Connected trail covers its strip and nothing beyond")
		for index in range(roundi(1.5 / step)):
			trail.advance(step)
		var total = 10000 - victim.current_health
		check(is_equal_approx(total, 3.0 * float(game.spell_manager.spell_catalog.firewalk.damage)), "Overlapping samples deal one damage tick, independent of step " + str(step) + " (%s)" % total)
		trail.advance(30)
		check(trail.finished, "Firewalk and patches expire")
		clear_combat()
	game.player.position = origin + Vector2(-120, -120)
	trail = spell("firewalk", null, {"trail_radius": 35})
	for point in [Vector2(120, -120), Vector2(120, 120), Vector2(-120, 120), Vector2(-120, -120)]:
		game.player.position = origin + point
		trail.advance(0.1)
	check(not burning(trail, origin), "Closed Firewalk path preserves unburned center")
	check(burning(trail, origin + Vector2(120, 0)), "Closed Firewalk retains traversed edge coverage")
	clear_combat()
	var trigger = enemy(Vector2(300, 0))
	var trap = spell("rune_trap", trigger, {"trap_radius": 130, "trigger_radius": 70})  # full-rank geometry
	var rune = root_of(trap)
	trap.advance(10)
	check(not rune.done and rune.armed and not trap.finished, "Visible armed trap persists without an enemy in trigger circle")
	trigger.position = rune.global_position + Vector2(70, 0)
	trap.advance(0.5)   # activate, then the explosion 0.4 s later
	var trap_damage = float(game.spell_manager.spell_catalog.rune_trap.damage)
	check(is_equal_approx(trigger.current_health, 10000 - trap_damage), "Real enemy at visible trigger boundary detonates trap once (%s)" % trigger.current_health)
	trap.advance(1)
	check(is_equal_approx(trigger.current_health, 10000 - trap_damage) and trap.finished, "Trap burst is once-only and expires")
	clear_combat()
	print("Spell areas: ", checks, " assertions, ", failures, " failures")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
