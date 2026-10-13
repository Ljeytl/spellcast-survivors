extends SceneTree
## Every shipping spell is drawn by the VFX layer in the real game (docs/VFX_EVENTS.md): each part
## a cast spawns is presented (no placeholder art), and the spell objects outside the engine
## (healing seeds, Earth Shield charges) are drawn there too.

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run():
	root.get_node("AudioManager").quitting = true
	var vfx = root.get_node("Vfx")
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	var manager = game.spell_manager
	manager.set_process(false)
	await process_frame
	check(vfx._active, "VFX layer is up in the game scene")
	var ids: Array = manager.BASE_SPELL_IDS.duplicate()   # the shipping spells
	var recipes = preload("res://scripts/SynergyCatalog.gd").RECIPES
	for id in recipes:
		if recipes[id].get("enabled", true):
			ids.append(id)
	var seen: Dictionary = {}
	var ported_types = preload("res://scripts/engine/LegacyBridge.gd").PORTED
	for id in ids + ["mana_bolt"]:
		for e in get_nodes_in_group("enemies"):
			e.free()
		for c in get_nodes_in_group("generic_casts"):
			c.free()
		for i in 6:
			var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
			enemy.global_position = game.player.global_position + Vector2(120 + 40 * i, -40 + 20 * (i % 3))
			enemy.set_physics_process(false)
			enemy.current_health = 1
			enemy.max_health = 1
		var ok := true
		if id == "mana_bolt":
			manager.fire_mana_bolt()
		else:
			manager.spells.clear()
			manager.bonus_spells.clear()
			manager.acquired_spells.clear()
			if recipes.has(id):
				for ingredient in recipes[id].ingredients:
					manager.learn_spell(ingredient)
					manager.get_spell_info(manager.find_spell_slot(ingredient)).level = manager.COMBINATION_RANK
			manager.learn_spell(id)
			var slot = manager.find_spell_slot(id)
			if slot < 0:
				check(false, "Learn " + id)
				continue
			check(ported_types.has(str(manager.resolve_cast_info(slot).get("type", ""))), id + " runs on the generic engine")
			ok = manager.cast_spell_by_type(slot)
			check(ok, "Cast " + id + ": " + manager.last_cast_failure)
		var placeholders: Array = []
		var count := 0
		for frame in 90:
			await physics_frame
			if id == "earth_shield" and frame == 5:
				game.player.earth_shield.block({"source_position": game.player.global_position + Vector2(100, 0)})
			for c in get_nodes_in_group("generic_casts"):
				for p in c.parts:
					if is_instance_valid(p) and not p.done:
						count += 1
						var family = str(p.def.get("vfx", {}).get("family", ""))
						if not vfx.presents(p) and family != "emitter":
							placeholders.append(p.part_name)
		seen[id] = count
		check(placeholders.is_empty(), id + " parts all drawn by the VFX layer (placeholders: %s)" % str(placeholders.slice(0, 4)))
		if id == "earth_shield":
			check(is_instance_valid(game.player.earth_shield) and vfx.presents_prop(game.player.earth_shield), "Earth Shield charges drawn by the VFX layer")
	check(seen.get("mana_bolt", 0) > 0, "Magic Missile spawns generic parts")
	# Healing seeds (Life Bolt, Soul Bloom) are props the layer draws.
	var seed = preload("res://scripts/HealingSeed.gd").new()
	seed.player_ref = weakref(game.player)
	game.add_child(seed)
	seed.global_position = game.player.global_position + Vector2(200, 0)
	await process_frame
	check(vfx.presents_prop(seed), "Healing seeds drawn by the VFX layer")
	check(vfx.prop_burst("heal", game.player.global_position), "Heals show through the VFX layer")
	print("VFX shipping coverage: %d checks, %d failures, parts %s" % [checks, failures, str(seen)])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
