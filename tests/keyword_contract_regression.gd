extends SceneTree
## Keyword contract (doc 18 §8, doc 19 step 5): every keyword on every shipping spell either changes
## the cast or is rejected with a reason (its rune cracks). Nothing silently does nothing, nothing
## fails to cast. Casts go through the real typed path (SpellManager.cast_keyword_spell).
## Also: one keyword per category per spell is drawn by the VFX layer with no placeholder parts.

const KP = preload("res://scripts/engine/KeywordParser.gd")
## The VFX half runs as its own test (keyword_vfx_regression.gd extends this one) to stay under the time limit.
var VFX_PASS := false

var checks = 0
var failures = 0
var game
var manager
var monsters

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

func norm(plan: Dictionary) -> String:
	var p = plan.duplicate(true)
	p.erase("rejected")
	return var_to_str(p)

func reset_field() -> void:
	for c in get_nodes_in_group("generic_casts"):
		c.free()
	for e in get_nodes_in_group("enemies"):
		e.free()
	monsters.monsters_alive = 0
	for i in 6:
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0], false, true)
		if enemy == null:
			continue
		enemy.global_position = game.player.global_position + Vector2(120 + 40 * i, -40 + 20 * (i % 3))
		enemy.set_physics_process(false)
		enemy.max_health = 100000
		enemy.current_health = 100000

## Casts text and returns [ok, plan, cracked words, failure]. MEGA-tier charges are stepped to release.
func cast(text: String) -> Array:
	var before = manager.last_generic_cast
	manager.last_spell_cast_time = -1e9
	manager.last_cracked = []
	var shield_before = game.player.earth_shield.charges.size() if is_instance_valid(game.player.get("earth_shield")) else 0
	var ok = manager.cast_keyword_spell(text)
	var made = manager.last_generic_cast
	if ok and text.ends_with("earth shield"):
		var steps = 0
		while steps < 90 and (not is_instance_valid(game.player.get("earth_shield")) or game.player.earth_shield.charges.size() <= shield_before):
			manager._process(1.0 / 60.0)
			await physics_frame
			steps += 1
		var charges = game.player.earth_shield.charges if is_instance_valid(game.player.get("earth_shield")) else []
		var charge: Dictionary = charges[-1].duplicate() if not charges.is_empty() else {}
		charge.erase("remaining")
		charge.erase("damage_source")
		return [ok, charge, manager.last_cracked.map(func(r): return str(r.word)), manager.last_cast_failure]
	var waited = 0
	while ok and (made == before or not is_instance_valid(made)) and waited < 90:
		manager.mana_bolt_timer = 1e9
		manager._process(1.0 / 60.0)
		await physics_frame
		waited += 1
		made = manager.last_generic_cast
	var plan = made.plan if ok and made != before and is_instance_valid(made) else {}
	return [ok, plan, manager.last_cracked.map(func(r): return str(r.word)), manager.last_cast_failure]

func learn_only(id: String, recipes: Dictionary) -> String:
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	if recipes.has(id):
		for ingredient in recipes[id].ingredients:
			manager.learn_spell(ingredient)
			manager.get_spell_info(manager.find_spell_slot(ingredient)).level = manager.COMBINATION_RANK
	manager.learn_spell(id)
	var slot = manager.find_spell_slot(id)
	return str(manager.get_spell_info(slot).display_name).to_lower() if slot > 0 else ""

func run():
	root.get_node("AudioManager").quitting = true
	var vfx = root.get_node("Vfx")
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	monsters = game.get_node("MonsterManager")
	monsters.set_process(false)
	monsters.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	manager = game.spell_manager
	manager.set_process(false)
	await process_frame
	var words: Dictionary = KP.data().words
	var live: Array = words.keys().filter(func(w): return not bool(words[w].get("planned", false)))
	var ids: Array = manager.BASE_SPELL_IDS.duplicate()
	var recipes = preload("res://scripts/SynergyCatalog.gd").RECIPES
	for id in recipes:
		if recipes[id].get("enabled", true):
			ids.append(id)
	var accepted_somewhere := {}
	for id in ids:
		var inc = learn_only(id, recipes)
		if inc == "":
			check(false, "Learn " + id)
			continue
		reset_field()
		await process_frame
		var bare = await cast(inc)
		check(bare[0] and not bare[1].is_empty(), "%s casts bare (%s)" % [id, bare[3]])
		if not bare[0] or bare[1].is_empty():
			continue
		var bare_plan = norm(bare[1])
		var by_category := {}
		for word in live:
			reset_field()
			await process_frame
			var r = await cast(word + " " + inc)
			if not r[0]:
				check(false, "%s %s casts (%s)" % [word, id, r[3]])
			elif word in r[2]:
				pass  # rejected with a reason: the rune cracks and the spell casts without it
			elif r[1].is_empty():
				check(false, "%s %s makes a cast" % [word, id])
			else:
				check(norm(r[1]) != bare_plan, "%s changes %s or is rejected" % [word.to_upper(), id])
				accepted_somewhere[word] = true
				var cat = str(words[word].category)
				if not by_category.has(cat):
					by_category[cat] = word
		# VFX: one accepted word per category, drawn without placeholders (tests/keyword_vfx_regression.gd).
		if not VFX_PASS:
			continue
		for cat in by_category:
			reset_field()
			await process_frame
			var word = by_category[cat]
			var r = await cast(word + " " + inc)
			if id == "earth_shield":
				game.player.earth_shield.block({"source_position": game.player.global_position + Vector2(100, 0)})
			var placeholders: Array = []
			for frame in 6:
				await physics_frame
				for c in get_nodes_in_group("generic_casts"):
					for p in c.parts:
						if is_instance_valid(p) and not p.done and str(p.def.get("vfx", {}).get("family", "")) != "emitter" and not vfx.presents(p):
							placeholders.append(p.part_name)
			check(placeholders.is_empty(), "%s %s drawn by the VFX layer (placeholders: %s)" % [word, id, str(placeholders.slice(0, 3))])
	for word in live:
		check(accepted_somewhere.has(word), "%s works on at least one shipping spell (else mark it planned)" % word.to_upper())
	# Planned words crack with their reason and stay out of the Necronomicon.
	for word in words:
		if bool(words[word].get("planned", false)):
			learn_only("bolt", recipes)
			reset_field()
			var r = await cast(word + " bolt")
			check(r[0] and word in r[2], "Planned %s cracks and the spell still casts" % word.to_upper())
	print("%s: %d checks, %d failures" % ["keyword_vfx_regression" if VFX_PASS else "keyword_contract_regression", checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
