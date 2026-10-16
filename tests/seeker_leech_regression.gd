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
	check(is_equal_approx(spirit.total_life(), 12.0), "Base Seeker retains twelve-second hunt")
	spirit.global_position = enemy.global_position
	var before = enemy.current_health
	spirit.step(0.001)
	check(enemy.current_health < before, "Hunt contact deals damage")
	check(not spirit.returning_life and not spirit.done, "First hit continues hunting")
	check(player.health == 50.0, "Hunt never heals immediately")
	check(is_equal_approx(spirit.stolen_life, 2.0), "Hunt collects capped healing")
	var after = enemy.current_health
	spirit.step(0.1)
	check(enemy.current_health == after, "Hunt respects hit interval")
	spirit.global_position = enemy.global_position
	spirit.step(1.0)
	check(enemy.current_health < after and not spirit.spirit_ending, "Hunt repeats contact damage before duration ends")
	check(spirit.stolen_life == 2.0, "Repeated hits do not increase healing beyond cap")
	spirit.age = spirit.total_life()
	spirit.step(0.001)
	check(spirit.returning_life and spirit.target_ref == null, "Duration ends hunt and releases target for return")
	after = enemy.current_health
	var return_start = spirit.global_position
	spirit.step(0.01)
	check(absf(return_start.distance_to(spirit.global_position) - float(spirit.def.motion[0].speed) * 0.8 * 0.01) < 0.01, "Healing return travels twenty percent slower than outbound")
	check(enemy.current_health == after, "Return does no contact damage")
	spirit.global_position = player.global_position
	spirit.step(0.01)
	check(player.health == 52.0 and spirit.done, "Arrival delivers healing once")
	spirit.step(0.1)
	check(player.health == 52.0, "Arrival cannot pay twice")
	player.health = player.max_health
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	spirit.hit(enemies[1])
	check(not spirit.done and not spirit.spirit_ending, "Full-health Seeker still completes its hunt")
	spirit.age = spirit.total_life()
	spirit.step(0.001)
	check(spirit.finishing_hunt and spirit.target_ref.get_ref() == enemies[2], "Red ending selects an enemy never hunted")
	before = enemy.current_health
	spirit.hit(enemy)
	check(enemy.current_health == before and not spirit.done, "Finisher cannot hit a previous victim even directly")
	spirit.global_position = enemies[2].global_position
	before = enemies[2].current_health
	spirit.step(0.001)
	check(spirit.done and enemies[2].current_health < before, "Fresh-target finishing dive damages and disappears")
	player.health = 50.0
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	spirit.hit(enemy)
	spirit.age = spirit.total_life()
	spirit.step(0.001)
	player.health = player.max_health
	spirit.step(0.001)
	check(spirit.finishing_hunt and not spirit.returning_life and spirit.target_ref.get_ref() != enemy, "Filling up on return redirects to fresh victim")
	spirit.finish(false)
	spirit = launch(spells, slot)
	for foe in enemies:
		spirit.hunted_targets[foe.get_instance_id()] = true
	spirit.age = spirit.total_life()
	spirit.step(0.01)
	check(spirit.finishing_hunt and spirit.target_ref == null and not spirit.done, "No fresh enemy waits without recycling hunted targets")
	spirit.step(4.0)
	check(spirit.done, "Fresh-target search has a bounded timeout")
	player.health = 50.0
	spirit = launch(spells, slot)
	enemy.current_health = 1.0
	spirit.hit(enemy)
	check(is_equal_approx(spirit.stolen_life, 0.15), "Overkill only steals remaining health")
	spirit.finish(false)
	enemy.dying = false
	enemy.current_health = 10000.0
	spirit = launch(spells, slot)
	spirit.global_position = enemy.global_position
	enemy.resistances = {"plague": 1.0}
	spirit.hit(enemy)
	check(spirit.stolen_life == 0.0 and not spirit.done, "Immune target grants no cargo but does not end hunt")
	enemy.resistances = {}
	spirit.hit(enemy)
	spirit.age = spirit.total_life()
	spirit.step(0.001)
	spirit.step(4.0)
	check(spirit.done and player.health == 50.0, "Return expiry grants no healing")
	spirit = launch(spells, slot)
	spirit.hit(enemy)
	player.health = 0.0
	spirit.step(0.01)
	check(spirit.done and player.health == 0.0, "Spirits cannot revive dead caster")
	player.health = 50.0
	spells.get_spell_info(slot).level = 8
	spirit = launch(spells, slot)
	check(is_equal_approx(spirit.total_life(), 24.0), "Rank eight preserves twenty-four-second hunting duration")
	spirit.age = 12.1
	spirit.step(0.01)
	check(not spirit.spirit_ending, "High-rank spirit continues hunting beyond base duration")
	spirit.finish(false)
	spells.get_spell_info(slot).level = 1
	player.health = player.max_health
	spirit = launch(spells, slot)
	var pursued = spirit._spirit_target(600.0)
	check(pursued != null and spirit.hit_count == 0, "Pursuit-only fixture has not hit its selected prey")
	spirit.age = spirit.total_life()
	spirit.step(0.001)
	var fresh = spirit.target_ref.get_ref()
	check(fresh != pursued, "Finisher excludes prey pursued but never hit")
	var spare = enemies.filter(func(e): return e != pursued and e != fresh)[0]
	var spare_position = spare.global_position
	spare.global_position = spirit.global_position + Vector2(2, 0)
	spirit.step(0.001)
	check(spirit.target_ref.get_ref() == fresh, "Final dive stays committed when another enemy moves closer")
	fresh.dying = true
	spare.global_position = spare_position
	spirit.step(0.001)
	check(spirit.target_ref.get_ref() == spare, "Dead finishing target retargets another fresh enemy")
	fresh.dying = false
	spirit.finish(false)
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
