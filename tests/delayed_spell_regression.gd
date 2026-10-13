extends SceneTree

var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 1000.0
	var dying = false
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health = maxf(0, current_health - amount)

func _initialize():
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func target_for(game, position):
	var target = Target.new()
	game.add_child(target)
	target.position = position
	target.add_to_group("enemies")
	return target

func settle(seconds):
	var deadline = Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		await process_frame

func projectile_count(game):
	return game.get_children().filter(func(child): return child is Area2D and child.get("projectile_type") in ["mana_bolt", "bolt"]).size()

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var spells = game.spell_manager
	spells.set_process(false)
	spells.mana_bolt_level = 3
	var target = target_for(game, game.player.position + Vector2(1000, 0))
	spells.fire_mana_bolt()
	var before = projectile_count(game)
	var before_ids = game.get_children().filter(func(child): return child is Area2D and child.get("projectile_type") in ["mana_bolt", "bolt"]).map(func(child): return child.get_instance_id())
	check(before == 1, "First mana projectile fires immediately")
	target.free()
	await settle(0.08)
	var after_ids = game.get_children().filter(func(child): return child is Area2D and child.get("projectile_type") in ["mana_bolt", "bolt"]).map(func(child): return child.get_instance_id())
	check(after_ids.all(func(id): return before_ids.has(id)), "Delayed mana projectile skips freed target while existing projectiles may expire")
	target = target_for(game, game.player.position + Vector2(1000, 0))
	spells.spells[1].level = 3
	spells.cast_spell_by_type(1)
	var bolt_cast = spells.last_generic_cast
	var thrown = bolt_cast.spawned
	target.free()
	await settle(0.3)
	check(not is_instance_valid(bolt_cast) or bolt_cast.spawned == thrown, "Delayed spread projectiles skip freed target")
	# The old chain_lightning helper is gone: Lightning Bolt bounces on the generic engine (tests/legacy_port_regression.gd).
	target = target_for(game, game.player.position + Vector2(1000, 0))
	spells.fire_mana_bolt()
	spells.cast_spell_by_type(1)
	target_for(game, target.position + Vector2(50, 0))
	game.queue_free()
	await process_frame
	await settle(0.4)
	check(not is_instance_valid(game), "Receiver teardown safely disconnects pending callbacks")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await settle(0.2)
	print("DELAYED_SPELL_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
