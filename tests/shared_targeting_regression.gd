extends SceneTree

const Targeting = preload("res://scripts/SpellTargeting.gd")
var checks = 0
var failures = 0

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

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	for node in get_nodes_in_group("enemies") + get_nodes_in_group("spell_projectiles"):
		node.free()
	var enemies = []
	for point in [Vector2(200, 0), Vector2(300, 100), Vector2(320, 100)]:
		var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
		enemy.position = game.player.position + point
		enemy.set_physics_process(false)
		enemy.current_health = 10
		enemies.append(enemy)
	var sm = game.spell_manager
	check(sm.cast_freeform_spell("bolt"), "Owned Bolt cast accepted")
	# Bolt runs on the generic engine (doc 18 phase 2); its parts reserve their target's damage.
	var first_cast = sm.last_generic_cast
	first_cast.manual = true
	var first = first_cast.parts.back()
	check(first.assigned == enemies[0], "First Bolt picks nearest real enemy")
	check(sm.cast_freeform_spell("bolt"), "Rapid owned Bolt accepted")
	var second_cast = sm.last_generic_cast
	second_cast.manual = true
	var second = second_cast.parts.back()
	check(second.assigned == enemies[1], "Rapid cast avoids lethally reserved enemy")
	check(str(first.def.motion[0].type) == "straight" and str(second.def.motion[0].type) == "straight", "Bolt remains straight")
	check(Targeting.select_area(self, game.player.position, 50) == enemies[1], "Area selection favors useful clustered coverage")
	var distant = []
	for offset in [Vector2(5000, 0), Vector2(5010, 0), Vector2(5020, 0), Vector2(5030, 0)]:
		var far = manager.spawn_monster(manager.get_available_variants(0)[0])
		far.position = game.player.position + offset
		far.set_physics_process(false)
		distant.append(far)
	var view = game.get_viewport().get_visible_rect()
	check(Targeting.select_area(self, game.player.position, 50) in distant, "Known-bad control: unrestricted area selection prefers the larger off-screen cluster")
	check(Targeting.select_area(self, game.player.position, 50, INF, {}, view) == enemies[1], "Visible-only area selection ignores the off-screen cluster")
	for far in distant:
		far.free()
	var keep_until = first.reserve_until
	first.reserve_until = -1.0
	check(Targeting.select(self, game.player.position) == enemies[0], "Expired estimate releases target")
	first.reserve_until = keep_until
	first.direction = Vector2.LEFT
	check(first.reserved_damage(enemies[0]) == 0, "Missed straight shot releases reservation")
	first.finish(false)
	check(first.reserved_damage(enemies[0]) == 0 and second.reserved_damage(enemies[1]) > 0, "A finished shot releases its target; a live one keeps it")
	second.finish(false)
	for p in get_nodes_in_group("spell_projectiles"):
		p.despawn()
	enemies[0].current_health = 10000
	# Magic Missile runs on the generic engine: homing missiles reserve their target's damage.
	var missile_info = {"id": "mana_bolt", "type": "mana_bolt", "projectile_count": 2}
	var missiles = sm.spawn_ported(missile_info, 15, {}, enemies[0])
	missiles.manual = true
	missiles.run(0.06)
	var shots = missiles.parts.filter(func(p): return p.depth == 0 and not p.done)
	check(shots.size() == 2 and shots[0].assigned == enemies[0] and shots[1].assigned == enemies[0], "Healthy target receives multiple useful projectiles")
	enemies[0].take_damage(20000, game.player.position)
	missiles.step(1.0 / 60.0)
	check(shots[0].assigned == enemies[1] and shots[1].assigned == enemies[2], "Host death retargets homing shots and distributes lethal damage")
	check(Targeting.select(self, game.player.position) != null, "All targets reserved still permits sensible fallback")
	shots[0].finish(false)
	check(shots[0].reserved_damage(enemies[1]) == 0, "Despawn releases committed damage")
	shots[1].reserve_until = shots[1].age - 1.0
	check(shots[1].reserved_damage(enemies[2]) == 0, "Expired estimate releases committed damage")
	missiles.free()
	var weak = sm.spawn_ported(missile_info, 15)
	weak.manual = true
	weak.run(0.06)
	var weak_shots = weak.parts.filter(func(p): return p.depth == 0 and not p.done)
	check(weak_shots.size() == 2 and weak_shots[0].assigned != weak_shots[1].assigned, "Weak enemies receive distinct passive projectiles at launch")
	var aimed = weak_shots[0].assigned
	weak.run(1.0)
	check(not is_instance_valid(weak_shots[0]) or weak_shots[0].done, "Real enemy impact consumes the projectile")
	check(not Targeting.alive(aimed) or Targeting.incoming(self, aimed) == 0, "Impact releases its reservation")
	weak.free()
	for enemy in enemies:
		if Targeting.alive(enemy):
			enemy.current_health = 0
	check(Targeting.select(self, game.player.position) == null, "No live target gives no stale selection")
	print("SHARED_TARGETING checks=", checks, " failures=", failures)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
