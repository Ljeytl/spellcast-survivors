extends SceneTree

const CATALOG = preload("res://scripts/SynergyCatalog.gd")
var game
var manager
var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 10000.0
	var dying = false
	var slow = 1.0
	var hits = 0
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health = maxf(0, current_health - amount)
		hits += 1
	func apply_slow(amount, _duration):
		slow = amount

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func fresh(recipe: String, evolved: bool):
	if is_instance_valid(game):
		game.free()
	paused = false
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	game.set_process(false)
	manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.spell_damage_multiplier = 1.7
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	for ingredient in CATALOG.RECIPES[recipe].ingredients:
		if ingredient != "bolt":
			manager.learn_spell(ingredient)
	var primary = CATALOG.RECIPES[recipe].ingredients[0]
	manager.upgrade_spell(primary)
	manager.upgrade_spell(primary)
	if evolved:
		manager.learn_spell(recipe)
		manager.upgrade_spell(recipe)
		manager.upgrade_spell(recipe)
	var info = manager.resolve_cast_info(manager.find_spell_slot(recipe if evolved else primary))
	if evolved and "--known-bad-combination-penalty" in OS.get_cmdline_user_args():
		info.damage *= 0.5
	return info

func target(offset: Vector2):
	var enemy = Target.new()
	game.add_child(enemy)
	enemy.global_position = game.player.global_position + offset
	enemy.add_to_group("enemies")
	return enemy

func effect(info: Dictionary, aim):
	var node = load("res://scripts/TacticalSpellEffect.gd").new() if info.type in ["beam", "trap", "spirit"] else load("res://scripts/BuildSpellEffect.gd").new()
	node.configure(info, manager.calculate_spell_damage(info), game.player, aim)
	game.add_child(node)
	node.set_physics_process(false)
	return node

func run():
	root.size = Vector2i(1280, 720)
	for id in CATALOG.RECIPES:
		if not CATALOG.RECIPES[id].get("enabled", true):
			continue
		var base = fresh(id, false).duplicate(true)
		var primary = CATALOG.RECIPES[id].ingredients[0]
		var ingredients = CATALOG.RECIPES[id].ingredients
		check(not manager.get_learnable_spell_cards().any(func(card): return card.effect.spell == id), "Evolution withheld below rank 8: " + id)
		for ingredient in ingredients:
			manager.get_spell_info(manager.find_spell_slot(ingredient)).level = manager.COMBINATION_RANK
		var offers = manager.get_learnable_spell_cards()
		check(offers.any(func(card): return card.effect.spell == id), "Eligible optional evolution offered: " + id)
		for ingredient in ingredients:
			manager.get_spell_info(manager.find_spell_slot(ingredient)).level = 1
		game.level_up_screen.generate_upgrade_options({}, 8)
		check(game.level_up_screen.current_upgrade_pool.any(func(card): return card.key == "rank:" + primary), "Basic rank investment remains available beside evolution: " + id)
		var base_damage = manager.calculate_spell_damage(base)
		var evolved = fresh(id, true)
		check(manager.calculate_spell_damage(evolved) >= base_damage - 0.000001, "Combination keeps ingredient impact investment: " + id)
		check(evolved.level == 3 and evolved.get("combination_scaled", false), "Bonus resolves explicit component ranks: " + id)
		check(not evolved.has("rank_steps") and not evolved.has("damage_multiplier"), "Combination avoids copied reward trees and penalties: " + id)
		check(manager.find_spell_slot(primary) > 0 and manager.find_spell_slot(CATALOG.RECIPES[id].ingredients[1]) > 0, "Both ingredients retained: " + id)
		check(not "Cost:" in CATALOG.RECIPES[id].card_description, "Offer no longer advertises removed penalties: " + id)
		var previous_damage = manager.calculate_spell_damage(evolved)
		manager.upgrade_spell(id)
		var upgraded = manager.resolve_cast_info(manager.find_spell_slot(id))
		check(manager.calculate_spell_damage(upgraded) >= previous_damage - 0.000001, "Own rank does not reduce damage: " + id)
		check(not manager.get_rank_upgrade_description(id).is_empty(), "Own rank has an upgrade description: " + id)

	compare_optional_offers()
	await compare_life()
	compare_meteor()
	compare_soul()
	compare_fields()
	compare_prism()
	compare_traps()
	check(not manager.learn_spell("reaping_spirit"), "Deferred Reaping Spirit cannot enter acquisition")
	print("Evolution tradeoffs: ", checks, " assertions, ", failures, " failures")
	game.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.2).timeout
	quit(1 if failures else 0)

func compare_life():
	var totals: Array = []
	for evolved in [false, true]:
		fresh("life_bolt", evolved)
		var enemy = target(Vector2(5000, 0))
		var hurt = Area2D.new()
		hurt.name = "HurtBox"
		enemy.add_child(hurt)
		game.player.health = 50
		manager.cast_spell_by_type(manager.find_spell_slot("life_bolt" if evolved else "bolt"))
		await create_timer(0.4).timeout
		var projectiles = game.get_children().filter(func(node): return node is Area2D and node.get("projectile_type") in ["bolt", "life_bolt"])
		check(projectiles.size() == (2 if evolved else 3), "Rank-three Life Bolt has two shots; Bolt has three")
		for projectile in projectiles:
			projectile._on_area_entered(hurt)
			projectile.resolve_impact()
		totals.append(10000 - enemy.current_health)
		check(game.player.health == 50, "Life Bolt requires seed pickup instead of remote healing")
	check(totals[0] > totals[1], "Ranked Bolt wins damage against healthy durable enemy")
	var rank_five_damage: Array = []
	for evolved in [false, true]:
		fresh("life_bolt", evolved)
		var id = "life_bolt" if evolved else "bolt"
		manager.upgrade_spell(id)
		manager.upgrade_spell(id)
		var durable = target(Vector2(5000, 0))
		var hitbox = Area2D.new()
		hitbox.name = "HurtBox"
		durable.add_child(hitbox)
		manager.cast_spell_by_type(manager.find_spell_slot("life_bolt" if evolved else "bolt"))
		await create_timer(0.6).timeout
		var volley = game.get_children().filter(func(node): return node is Area2D and node.get("projectile_type") in ["bolt", "life_bolt"])
		check(volley.size() == (3 if evolved else 5), "Rank-five Life Bolt has three shots; Bolt has five")
		for shot in volley:
			shot._on_area_entered(hitbox)
			shot.resolve_impact()
		rank_five_damage.append(10000 - durable.current_health)
	check(rank_five_damage[0] > rank_five_damage[1], "Rank-five basic volley retains damage advantage")
	fresh("life_bolt", true)
	var enemy = target(Vector2(5000, 0))
	var hurt = Area2D.new()
	hurt.name = "HurtBox"
	enemy.add_child(hurt)
	manager.cast_spell_by_type(manager.find_spell_slot("life_bolt"))
	var projectile = game.get_children().filter(func(node): return node is Area2D and node.get("projectile_type") == "life_bolt")[0]
	projectile._on_area_entered(hurt)
	projectile.resolve_impact()
	check(game.player.health == game.player.max_health, "Life Bolt provides no overheal at full health")

func compare_meteor():
	var solo: Array = []
	var crowds: Array = []
	for evolved in [false, true]:
		var info = fresh("meteor_lance", evolved)
		var enemy = target(Vector2(70, 0))
		var spell = effect(info, enemy)
		spell.advance(0.1)
		solo.append(10000 - enemy.current_health)
		info = fresh("meteor_lance", evolved)
		var enemies = [target(Vector2(70, 0)), target(Vector2(70, 60)), target(Vector2(70, -60)), target(Vector2(70, 85))]
		spell = effect(info, enemies[0])
		spell.advance(0.1)
		crowds.append(enemies.reduce(func(total, node): return total + 10000 - node.current_health, 0.0))
	check(solo[1] >= solo[0], "Meteor Spear preserves direct-hit investment")
	check(crowds[1] > crowds[0], "Meteor Spear wins damage against a compact off-axis crowd")

func compare_soul():
	var damage: Array = []
	for evolved in [false, true]:
		var info = fresh("soul_bloom", evolved)
		var enemy = target(Vector2(100, 0))
		game.player.health = 50
		var spell = effect(info, enemy)
		spell.advance(1.0)
		damage.append(10000 - enemy.current_health)
		check(game.player.health == 50, "Infection never heals remotely")
		check(not info.has("lifesteal"), "Soul Bloom uses ground healing instead of leech")
		if evolved:
			enemy.current_health = 1
			spell.advance(0.5)
			var blooms = get_nodes_in_group("healing_seeds")
			check(blooms.size() == 1, "Infected death creates one healing bloom")
			check(spell.resting_spores.size() == 1, "Infected death preserves separate infectious spore")
			check(game.player.health == 50, "Death bloom still requires physical collection")
	check(is_equal_approx(damage[0], damage[1]), "Soul Bloom preserves Plague Seed infection damage")

func compare_fields():
	var totals: Array = []
	var displacement: Array = []
	for evolved in [false, true]:
		var info = fresh("steam_field", evolved)
		var enemy = target(Vector2(100, 0))
		var spell = effect(info, enemy)
		spell.advance(float(info.duration))
		totals.append(10000 - enemy.current_health)
		check(enemy.hits == (12 if evolved else 10), "Rank-three Steam adds field lifetime and ticks")
		check(spell.is_queued_for_deletion(), "Field expires at its own duration")
		info = fresh("steam_field", evolved)
		enemy = target(Vector2(100, 0))
		spell = effect(info, enemy)
		spell.advance(0.5)
		var start = enemy.position
		for i in range(10):
			enemy.position.x += 100 * enemy.slow * 0.1
			spell.advance(0.1)
		displacement.append(enemy.position.distance_to(start))
	check(totals[1] >= totals[0], "Steam preserves damage and extends field lifetime")
	check(displacement[1] < displacement[0], "Steam Field adds control to its damaging field")

func compare_prism():
	var solos: Array = []
	var totals: Array = []
	for evolved in [false, true]:
		var info = fresh("prism_ray", evolved)
		var enemies = [target(Vector2(100, 0)), target(Vector2(200, 0)), target(Vector2(300, 0))]
		var spell = effect(info, enemies[0])
		if evolved:
			check(spell.beam_radius() >= 32, "Prism has wide laser footprint")
			check(is_equal_approx(float(info.get("beam_turn_speed", -1)), 0.25), "Prism slow-tracking contract")
		spell.advance(2)
		solos.append(10000 - enemies[0].current_health)
		totals.append(enemies.reduce(func(total, node): return total + 10000 - node.current_health, 0.0))
	check(solos[1] >= solos[0], "Prism preserves concentrated damage on first target")
	check(totals[1] > totals[0], "Prism Ray wins aggregate damage on three aligned targets")

func compare_traps():
	for evolved in [false, true]:
		var info = fresh("frost_sigil", evolved)
		if evolved:
			check(is_equal_approx(float(info.arm_delay), 1.0), "Rank-three Frost arms after one second")
		var enemy = target(Vector2(160, 0))
		var spell = effect(info, enemy)
		spell.advance(0.8)
		check(enemy.hits == (0 if evolved else 1), "Rune Trap catches an early crossing while Frost is still arming")
		enemy.position += Vector2(300, 0)
		spell.advance(0.6)
		check(enemy.hits == (0 if evolved else 1), "Frost does not retroactively hit a departed target")
		info = fresh("frost_sigil", evolved)
		enemy = target(Vector2(160, 0))
		var outside = target(Vector2(310, 0))
		spell = effect(info, enemy)
		spell.advance(1.4)
		check(outside.hits == (1 if evolved else 0), "Prepared Frost Sigil reaches the larger-radius target")
		check(enemy.slow == (0.6 if evolved else 1.0), "Frost adds slow after its longer preparation")

func compare_optional_offers():
	fresh("life_bolt", false)
	for id in ["plague_seed", "cinder_field", "ice_blast", "regeneration"]:
		manager.learn_spell(id)
	# Combination cards need both ingredients at rank 8.
	for info in manager.spells.values():
		while manager.get_spell_rank(info.id) < manager.COMBINATION_RANK:
			manager.upgrade_spell(info.id)
	var screen = game.level_up_screen
	for i in range(100):
		seed(5000 + i)
		var cards = screen.generate_upgrade_options({}, 10)
		check(not cards.all(screen.is_evolution_card), "Ordinary multi-recipe offers preserve a nonevolution choice")
	var evolutions = screen.current_upgrade_pool.filter(screen.is_evolution_card)
	check(evolutions.size() == 3, "Controlled kit has three simultaneous eligible recipes")
	var forced = evolutions.duplicate(true)
	if "--known-bad-forced-evolution" not in OS.get_cmdline_user_args():
		screen.ensure_optional_evolutions(forced)
	check(not forced.all(screen.is_evolution_card), "All-evolution composition must be repaired")
	check(forced.any(func(card): return ["rank:bolt", "rank:plague_seed", "rank:cinder_field"].any(func(key): return screen.get_upgrade_key(card) == key or screen.get_upgrade_key(card).begins_with(key + ":"))), "Repair prefers a primary rank alternative")
	var locked = evolutions.duplicate(true)
	screen.ensure_optional_evolutions(locked, [0, 1, 2])
	check(locked == evolutions, "Explicitly locking all three choices preserves user choices")
	for i in range(50):
		screen.available_upgrades = evolutions.duplicate(true)
		screen.locked_upgrades = [0, 1]
		screen.reroll_upgrades()
		check(screen.available_upgrades[0] == evolutions[0] and screen.available_upgrades[1] == evolutions[1], "Reroll preserves both locked evolutions")
		check(not screen.available_upgrades.all(screen.is_evolution_card), "Reroll keeps a basic alternative in unlocked slot")
		screen.banishes_remaining = 100
		screen.banish_upgrade(2)
		check(not screen.available_upgrades.all(screen.is_evolution_card), "Banishing last basic alternative replaces it with another basic choice")
		check(screen.available_upgrades.map(screen.get_upgrade_key).all(func(key): return key not in screen.banished_upgrades), "Repaired choices respect banishes")
		check(screen.available_upgrades.map(screen.get_upgrade_key).size() == 3 and screen.available_upgrades[0] != screen.available_upgrades[1] and screen.available_upgrades[1] != screen.available_upgrades[2] and screen.available_upgrades[0] != screen.available_upgrades[2], "Repaired cards remain three unique choices")
		screen.banished_upgrades.clear()
