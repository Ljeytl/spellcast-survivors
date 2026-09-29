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
	var first = get_nodes_in_group("spell_projectiles").filter(func(p): return p.projectile_type == "bolt").back()
	first.set_process(false)
	check(first.target == enemies[0], "First Bolt picks nearest real enemy")
	check(sm.cast_freeform_spell("bolt"), "Rapid owned Bolt accepted")
	var second = get_nodes_in_group("spell_projectiles").filter(func(p): return p.projectile_type == "bolt").back()
	second.set_process(false)
	check(second.target == enemies[1], "Rapid cast avoids lethally reserved enemy")
	check(not first.is_homing and not second.is_homing, "Bolt remains straight")
	check(Targeting.select_area(self, game.player.position, 50) == enemies[1], "Area selection favors useful clustered coverage")
	first.reservation_remaining = 0
	check(Targeting.select(self, game.player.position) == enemies[0], "Expired estimate releases target")
	first.assign_target(enemies[0])
	first.direction = Vector2.LEFT
	first._process(0.01)
	check(first.reserved_damage(enemies[0]) == 0, "Missed straight shot releases reservation")
	first.reset_for_pool()
	check(first.target == null and first.reservation_remaining == 0, "Pool reuse clears target and estimate")
	for p in get_nodes_in_group("spell_projectiles"):
		p.despawn()
	enemies[0].current_health = 10000
	sm.create_mana_bolt_projectile(enemies[0], 15, 0)
	sm.create_mana_bolt_projectile(enemies[0], 15, 1)
	var bolts = get_nodes_in_group("spell_projectiles").filter(func(p): return not p.despawning and p.projectile_type == "mana_bolt")
	check(bolts.size() == 2 and bolts[0].target == enemies[0] and bolts[1].target == enemies[0], "Healthy target receives multiple useful projectiles")
	for p in bolts:
		p.set_process(false)
	enemies[0].take_damage(20000, game.player.position)
	bolts[0]._process(0.01)
	bolts[1]._process(0.01)
	check(bolts[0].target == enemies[1] and bolts[1].target == enemies[2], "Host death retargets homing shots and distributes lethal damage")
	check(Targeting.select(self, game.player.position) != null, "All targets reserved still permits sensible fallback")
	bolts[0].despawn()
	check(bolts[0].reserved_damage(enemies[1]) == 0, "Despawn releases committed damage")
	bolts[1].lifetime_timer = 0.001
	bolts[1]._process(0.01)
	check(bolts[1].despawning and bolts[1].reserved_damage(enemies[2]) == 0, "Lifetime expiry releases committed damage")
	sm.create_mana_bolt_projectile(enemies[1], 15, 0)
	sm.create_mana_bolt_projectile(enemies[1], 15, 1)
	var weak_bolts = get_nodes_in_group("spell_projectiles").filter(func(p): return not p.despawning and p.projectile_type == "mana_bolt")
	check(weak_bolts.size() == 2 and weak_bolts[0].target != weak_bolts[1].target, "Weak enemies receive distinct passive projectiles at launch")
	for p in weak_bolts:
		p.set_process(false)
	weak_bolts[0]._on_area_entered(weak_bolts[0].target.get_node("HurtBox"))
	weak_bolts[0].resolve_impact()
	check(weak_bolts[0].despawning and weak_bolts[0].reservation_remaining == 0, "Real enemy impact consumes projectile reservation")
	weak_bolts[1].reset_for_pool()
	weak_bolts[1].setup_homing(game.player.position, enemies[2], 4, Color.WHITE, "mana_bolt")
	check(weak_bolts[1].reserved_damage(enemies[2]) == 4, "Reused projectile reserves only its new damage")
	var pooled = game.object_pool.get_object("SpellProjectile")
	game.add_child(pooled)
	pooled.setup_homing(game.player.position, enemies[2], 7, Color.WHITE, "mana_bolt")
	pooled.set_process(false)
	check(pooled.reserved_damage(enemies[2]) == 7, "Checked-out pooled projectile commits its impact")
	pooled.despawn()
	await process_frame
	await process_frame
	check(pooled.get_parent() == null and pooled.reservation_remaining == 0, "Deferred pool return detaches and clears reservation")
	var reused = game.object_pool.get_object("SpellProjectile")
	check(reused == pooled and reused.target == null, "Actual pool checkout reuses clean object")
	game.add_child(reused)
	reused.setup_homing(game.player.position, enemies[2], 3, Color.WHITE, "mana_bolt")
	reused.set_process(false)
	check(reused.reserved_damage(enemies[2]) == 3, "Reattached pool object contributes only current shot")
	for enemy in enemies:
		if Targeting.alive(enemy):
			enemy.current_health = 0
	check(Targeting.select(self, game.player.position) == null, "No live target gives no stale selection")
	print("SHARED_TARGETING checks=", checks, " failures=", failures)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
