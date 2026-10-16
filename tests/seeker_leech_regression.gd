extends SceneTree

var checks := 0
var failures := 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	monsters.monsters_alive = 0
	var enemies: Array = []
	for offset in [Vector2(100, 0), Vector2(220, 60), Vector2(280, -60)]:
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
		enemy.set_physics_process(false)
		enemy.global_position = game.player.global_position + offset
		enemy.current_health = 10000
		enemies.append(enemy)
	var spells = game.spell_manager
	check(spells.learn_spell("seeker"), "Seeker learned through real inventory")
	var slot = spells.find_spell_slot("seeker")
	var player = game.player
	var enemy = enemies[0]
	player.health = 50.0
	var spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	var before = enemy.current_health
	spirit.step(0.001)
	check(enemy.current_health < before, "Outbound contact deals damage")
	check(spirit.returning_life and not spirit.done, "Successful drain starts return")
	check(player.health == 50.0, "Contact never heals immediately")
	check(is_equal_approx(spirit.stolen_life, 2.0), "Strong hit respects two-health cap")
	check(spirit.target_ref == null, "Returning spirit releases target reservation")
	var after = enemy.current_health
	spirit.step(0.01)
	check(enemy.current_health == after, "Return does not damage enemies")
	spirit.global_position = player.global_position
	spirit.step(0.01)
	check(player.health == 52.0 and spirit.done, "Arrival delivers health and consumes spirit")
	spirit.step(0.1)
	check(player.health == 52.0, "Arrival cannot pay twice")
	player.health = player.max_health
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	before = enemy.current_health
	spirit.step(0.001)
	check(spirit.done and enemy.current_health < before, "Full-health contact damages and consumes spirit")
	player.health = 50.0
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	player.health = player.max_health
	spirit.step(0.01)
	check(not spirit.returning_life and spirit.stolen_life == 0.0, "Full health during return redirects and discards cargo")
	spirit.hit(enemy)
	check(spirit.done, "Redirected spirit bursts on its next victim")
	player.health = 50.0
	spirit = launch(spells, slot)
	enemy.current_health = 1.0
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	check(is_equal_approx(spirit.stolen_life, 0.15), "Overkill only steals the victim's remaining health")
	spirit.finish(false)
	enemy.dying = false
	enemy.current_health = 10000.0
	spirit = launch(spells, slot)
	spirit.cast.spirit_heal_reserved = 1.8
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	check(is_equal_approx(spirit.stolen_life, 0.2), "Copies share remaining cast healing budget")
	spirit.finish(false)
	spirit = launch(spells, slot)
	enemy.resistances = {"plague": 1.0}
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	check(spirit.stolen_life == 0.0 and spirit.done, "Immune target yields no stolen health")
	enemy.resistances = {}
	spirit = launch(spells, slot)
	spirit.age = spirit.total_life() - 0.01
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	spirit.step(0.02)
	check(not spirit.done and spirit.returning_life, "Late hit gets a bounded return window")
	spirit.step(4.0)
	check(spirit.done and player.health == 50.0, "Expired return grants no healing")
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	player.health = 0.0
	spirit.step(0.01)
	check(spirit.done and player.health == 0.0, "Returning spirit cannot revive dead caster")
	player.health = 50.0
	for word in ["splitting", "chaining"]:
		enemy.dying = false
		enemy.current_health = 1.0
		var modified = keyword_launch(word + " seeker", player, game)
		var first = modified.parts[0]
		first.global_position = enemy.global_position
		first.hit(enemy)
		var children = modified.parts.filter(func(p): return p.depth > 0)
		check(not children.is_empty(), word + " creates real keyword children")
		var child = children[0]
		child.global_position = enemies[1].global_position
		child.step(0.001)
		check(child.returning_life and not child.done, word + " contact survives pierce limit to return")
		check(player.health == 50.0, word + " does not heal at contact")
		child.global_position = player.global_position
		child.step(0.001)
		check(child.done and player.health > 50.0 and player.health <= 52.0, word + " child delivers capped healing")
		modified.free()
		player.health = 50.0
	enemy.dying = false
	enemy.current_health = 10000.0
	var exploding = keyword_launch("leeching exploding seeker", player, game)
	exploding.parts[0].global_position = enemy.global_position
	exploding.parts[0].hit(enemy)
	check(player.health == 50.0, "Leeching explosion cannot bypass return delivery")
	check(exploding.spirit_heal_reserved <= 2.0, "Leeching modifier respects shared spirit cap")
	exploding.free()
	game.queue_free()
	await process_frame
	print("Seeker leech: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func launch(spells, slot):
	spells.cast_spell_by_type(slot)
	var cast = spells.last_generic_cast
	cast.manual = true
	return cast.parts[0]

func keyword_launch(words, player, game):
	var defs = preload("res://scripts/engine/SpellDefs.gd")
	var info: Dictionary = preload("res://scripts/core/GameData.gd").file("spells").spells.seeker.duplicate(true)
	info.incantation = "seeker"
	defs.register(preload("res://scripts/engine/SpellTemplate.gd").build(info, 15.0, {}))
	var parsed = preload("res://scripts/engine/KeywordParser.gd").parse(words, defs.by_incantation().keys())
	var plan = preload("res://scripts/engine/CastPlanner.gd").plan(defs.get_def(defs.by_incantation()[parsed.spell]), parsed.bundle, {})
	var cast = preload("res://scripts/engine/GenericCast.gd").new()
	game.add_child(cast)
	cast.setup(plan, player, game, {"spell": "seeker"}, true, 1)
	cast.step(0.001)
	return cast
