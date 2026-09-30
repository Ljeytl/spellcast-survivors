extends SceneTree

const NEW_IDS = ["focus_ray", "rune_trap", "seeking_spirit", "ember_trail", "returning_blade"]
const NEW_RECIPES = ["prism_ray", "frost_sigil"]
var checks = 0
var failures = 0
var game
var manager

class Target extends Node2D:
	var current_health = 10000.0
	var dying = false
	var slow = 0.0
	var hits = 0
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		if not dying:
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

func fresh():
	paused = false
	if is_instance_valid(game):
		game.free()
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	manager.set_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)

func target(offset: Vector2):
	var enemy = Target.new()
	enemy.position = game.player.position + offset
	game.add_child(enemy)
	enemy.add_to_group("enemies")
	return enemy

func effect(id: String, aim = null, overrides: Dictionary = {}):
	var data = manager.spell_catalog[id].duplicate(true)
	data.merge(overrides, true)
	var spell = load("res://scripts/TacticalSpellEffect.gd").new()
	spell.configure(data, float(data.damage), game.player, aim)
	game.add_child(spell)
	spell.set_physics_process(false)
	return spell

func key(code: int, character: int = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.unicode = character
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func type_name(text: String):
	for character in text:
		key(character.to_upper().unicode_at(0), character.unicode_at(0))

func run():
	root.size = Vector2i(1280, 720)
	fresh()
	check(manager.spell_catalog.size() == 16, "Sixteen implemented base spells")
	for id in NEW_IDS:
		check(not manager.cast_freeform_spell(manager.spell_catalog[id].display_name), "Unowned new spell is rejected: " + id)
	check(not manager.learn_spell("reaping_spirit") and not manager.get_learnable_spell_cards().any(func(card): return card.effect.spell == "reaping_spirit"), "Deferred Reaping Spirit is not available")
	for id in NEW_IDS:
		fresh()
		check(manager.learn_spell(id), "New spell acquired: " + id)
		var slot = manager.find_spell_slot(id)
		var original_damage = manager.calculate_spell_damage(manager.spells[slot])
		manager.upgrade_spell(id)
		if id == "returning_blade":
			check(is_equal_approx(manager.calculate_spell_damage(manager.spells[slot]), original_damage), "Blade count upgrade does not also increase damage")
			check("radius" in manager.get_rank_upgrade_description(id), "Next blade rank describes size")
		else:
			check(is_equal_approx(manager.calculate_spell_damage(manager.spells[slot]), original_damage * 1.15), "New spell rank increases actual damage: " + id)
			check("+15% of base damage" in manager.get_rank_upgrade_description(id), "Rank copy matches damage rule")
		var enemy = target(Vector2(130, 0))
		key(KEY_SPACE)
		type_name(manager.spells[slot].display_name)
		key(KEY_ENTER)
		check(game.spells_cast == 1 and not manager.is_typing, "Actual Space/type/Enter casts owned new incantation")
		manager.casting_clock += 1
		key(KEY_0 + slot)
		type_name(manager.spells[slot].display_name)
		check(game.spells_cast == 2 and not manager.is_typing, "Actual numbered typing casts new incantation")
		for i in range(5):
			manager.cast_spell_by_type(slot)
		var active = get_nodes_in_group("build_spell_effects").filter(func(node): return node.info.id == id and not node.is_queued_for_deletion() and not node.get_parent().is_queued_for_deletion())
		var capped = get_nodes_in_group("cross_blade_volleys").filter(func(node): return not node.is_queued_for_deletion()).size() if id == "returning_blade" else active.size()
		check(capped == manager.spells[slot].active_limit, "Per-spell concurrent cap: " + id)
		enemy.free()
		for node in active:
			node.set_physics_process(false)
			node.advance(20)
			if node.info.type == "trap":
				check(not node.is_queued_for_deletion() and not node.triggered, "Untriggered trap remains prepared in empty arena")
			else:
				check(node.is_queued_for_deletion(), "Nonpersistent empty-arena effect expires after large delta")
	for recipe_id in NEW_RECIPES:
		fresh()
		var recipe = load("res://scripts/SynergyCatalog.gd").RECIPES[recipe_id]
		for ingredient in recipe.ingredients:
			manager.learn_spell(ingredient)
		var primary_slot = manager.find_spell_slot(recipe.ingredients[0])
		manager.cast_spell_by_type(primary_slot)
		check(manager.learn_spell(recipe_id), "Learn additive tactical bonus: " + recipe_id)
		var bonus_slot = manager.find_spell_slot(recipe_id)
		check(bonus_slot > 6 and manager.find_spell_slot(recipe.ingredients[0]) == primary_slot, "Tactical bonus preserves primary slot")
		for i in range(5):
			manager.cast_spell_by_type(bonus_slot)
		var family = manager.spells[primary_slot].type
		var family_nodes = get_nodes_in_group("build_spell_effects").filter(func(node): return node.info.type == family and not node.is_queued_for_deletion())
		check(family_nodes.size() == int(manager.get_spell_info(bonus_slot).active_limit) + 1, "Bonus keeps its own active limit without replacing ingredient: " + recipe_id)
	for id in ["rune_trap"]:
		fresh()
		manager.learn_spell(id)
		var corpse = target(Vector2(20, 0))
		corpse.dying = true
		var live = target(Vector2(0, 120))
		manager.cast_spell_by_type(manager.find_spell_slot(id))
		var spawned = get_nodes_in_group("build_spell_effects").back()
		check(spawned.target_ref.get_ref() == live, "Initial tactical aim ignores nearest dying enemy: " + id)
	fresh()
	var near = target(Vector2(100, 0))
	var far = target(Vector2(200, 0))
	var off_axis = target(Vector2(100, 90))
	var beam = effect("focus_ray", near)
	if "--known-bad-extra-beam-tick" in OS.get_cmdline_user_args():
		beam.tick_remaining = 0
	beam.advance(0.24)
	check(near.hits == 0, "Beam has no early extra tick")
	check(beam.beam_end.length() < 120, "Base beam visual stops at first blocking target")
	beam.advance(0.01)
	check(near.hits == 1 and far.hits == 0 and off_axis.hits == 0, "Focused beam hits one aligned target")
	beam.advance(1.75)
	check(near.hits == 8 and far.hits == 0, "Beam deals exactly eight ticks over two seconds")
	check(near.hits != 9, "Known-bad immediate-plus-lifetime ninth tick rejected")
	fresh()
	var line = [target(Vector2(100, 0)), target(Vector2(200, 0)), target(Vector2(300, 0)), target(Vector2(400, 0))]
	beam = effect("focus_ray", line[0], {"beam_targets": 3})
	beam.advance(0.25)
	check(line[0].hits == 1 and line[1].hits == 1 and line[2].hits == 1 and line[3].hits == 0, "Prism pierces three, never fourth")
	check(beam.beam_end.length() > 300 and beam.beam_end.length() < 320, "Prism visual matches third blocking enemy")
	line[0].free()
	game.player.position += Vector2(0, 30)
	beam.advance(0.25)
	check(beam.global_position == game.player.global_position and beam.target_ref.get_ref() == line[1], "Beam follows caster and retargets freed target")
	fresh()
	near = target(Vector2(160, 0))
	far = target(Vector2(310, 0))
	var trap = effect("rune_trap", near, {"trap_radius": 170, "frost": true})
	trap.advance(0.79)
	check(near.hits == 0 and far.hits == 0, "Trap cannot hit before arming")
	trap.advance(0.01)
	check(near.hits == 1 and far.hits == 1, "Frost burst reaches enlarged radius after arming")
	check(near.slow == 0.6 and far.slow == 0.6, "Frost uses 60% remaining speed for 40% slow")
	trap.advance(3)
	check(near.hits == 1 and far.hits == 1 and trap.is_queued_for_deletion(), "Trap bursts exactly once")
	fresh()
	trap = effect("rune_trap")
	trap.advance(5.9)
	check(not trap.triggered, "Empty trap does not detonate on a timer")
	near = target(Vector2(160, 0))
	trap.advance(0.05)
	check(trap.triggered and near.hits == 1, "Armed trap triggers on later proximity")
	fresh()
	near = target(Vector2(100, 0))
	var spirit = effect("seeking_spirit", near)
	spirit.advance(0.2)
	check(spirit.global_position.x > game.player.position.x and near.hits == 0, "Spirit travels instead of remote damage")
	near.position += Vector2(60, 0)
	spirit.advance(0.6)
	check(near.hits > 0, "Spirit pursues moving target and strikes")
	far = target(Vector2(250, 0))
	near.free()
	spirit.advance(0.1)
	check(spirit.target_ref.get_ref() == far, "Spirit reacquires after target freed")
	fresh()
	near = target(Vector2(30, 0))
	far = target(Vector2(80, 0))
	spirit = effect("seeking_spirit", near, {"reaping": true})
	spirit.advance(0.05)
	check(near.hits == 1 and far.hits == 0 and spirit.burst_remaining == 0, "Reaping spirit survivor hit does not burst or flash")
	near.current_health = 1
	spirit.advance(0.5)
	check(near.hits == 2 and far.hits == 1 and far.current_health == 10000 - 9, "Actual spirit kill bursts half damage once, excluding primary")
	check(spirit.burst_remaining > 0 and spirit.burst_position == near.global_position, "Only actual kill creates a flash at the damage center")
	spirit.advance(0.3)
	check(spirit.burst_remaining == 0, "Burst flash expires within the owning spirit without extra nodes")
	fresh()
	near = target(Vector2.ZERO)
	var trail = effect("ember_trail", null, {"patch_duration": 2.0})
	trail.advance(2.1)
	var stationary_hits = near.hits
	trail.advance(2)
	check(trail.trail_points.is_empty() and near.hits == stationary_hits, "Standing still cannot keep regenerating a stationary field")
	game.player.position += Vector2(40, 0)
	trail.advance(0.4)
	check(trail.trail_points.size() == 1, "Movement creates a new spaced patch")
	game.player.position += Vector2(40, 0)
	trail.advance(0.2)
	near.position = game.player.position - Vector2(20, 0)
	var prior_hits = near.hits
	trail.advance(0.5)
	check(near.hits - prior_hits <= 1, "Overlapping patches never multiply one trail tick")
	trail.advance(10)
	check(trail.is_queued_for_deletion(), "Trail has finite total lifetime")
	fresh()
	near = target(Vector2(150, 0))
	far = target(Vector2(280, 0))
	var blade = effect("returning_blade", near)
	blade.advance(0.7)
	check(near.hits == 1 and far.hits == 1 and blade.leg == 1, "Outbound sweep hits each crossed enemy once")
	blade.advance(1.6)
	check(near.hits == 2 and far.hits == 2, "Return leg can hit each enemy once again")
	check(near.hits != 3, "Known-bad per-frame blade hit would fail deduplication")
	fresh()
	near = target(Vector2(150, 0))
	blade = effect("returning_blade", near)
	blade.advance(0.7)
	game.player.position += Vector2(0, 100)
	blade.advance(1.1)
	check(blade.global_position.y > game.player.position.y - 100, "Returning blade tracks moving caster")
	blade.advance(20)
	check(blade.is_queued_for_deletion(), "Moving-caster blade remains finite")
	fresh()
	for id in NEW_IDS:
		var temporary_caster = Node2D.new()
		game.add_child(temporary_caster)
		var spell = load("res://scripts/TacticalSpellEffect.gd").new()
		spell.configure(manager.spell_catalog[id], 1, temporary_caster, null)
		game.add_child(spell)
		spell.set_physics_process(false)
		temporary_caster.free()
		spell.advance(0.1)
		check(spell.is_queued_for_deletion(), "Freed caster safely ends effect: " + id)
	var paused_effect = effect("focus_ray")
	paused_effect.set_physics_process(true)
	var lifetime = paused_effect.remaining
	paused = true
	await create_timer(0.1, true).timeout
	check(paused_effect.remaining == lifetime, "Effects do not advance during pause")
	paused = false
	game.free()
	game = null
	check(get_nodes_in_group("build_spell_effects").is_empty(), "Run teardown removes all effect nodes")
	await test_ordinary_offers()
	print("Magic variety: ", checks, " assertions, ", failures, " failures")
	if is_instance_valid(game):
		game.queue_free()
	paused = false
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.2).timeout
	quit(1 if failures else 0)

func test_ordinary_offers():
	var acquired: Dictionary = {}
	var offered: Dictionary = {}
	var seed_results: Array = []
	var goals = NEW_IDS + NEW_RECIPES
	for index in range(goals.size()):
		var goal = goals[index]
		var achieved = false
		for attempt in range(16):
			fresh()
			var run_seed = 901 + index * 32 + attempt
			seed(run_seed)
			var desired = manager.Synergies.RECIPES[goal].ingredients + [goal] if goal in NEW_RECIPES else [goal]
			var last_level = 1
			for level in range(2, 32):
				last_level = level
				var options = game.level_up_screen.generate_upgrade_options({}, level)
				var choice = {}
				for card in options:
					if card.effect.type == "learn_spell":
						offered[card.effect.spell] = true
						if card.effect.spell in desired:
							choice = card
				if choice.is_empty():
					for card in options:
						if card.effect.type != "learn_spell":
							choice = card
							break
				if choice.is_empty():
					choice = options[0]
				game._on_upgrade_selected(choice)
				if choice.effect.type == "learn_spell":
					acquired[choice.effect.spell] = true
				if manager.find_spell_slot(goal) != 0:
					achieved = true
					break
				if manager.spells.size() == 6 and desired.any(func(id): return id != goal and manager.find_spell_slot(id) == 0):
					break
			seed_results.append({"seed": run_seed, "goal": goal, "level": last_level, "achieved": achieved})
			if achieved:
				break
		check(achieved and offered.has(goal) and acquired.has(goal), "Seeded ordinary offers acquire build component: " + goal)
		check(manager.spells.size() <= 6, "Ordinary seeded progression respects kit cap")
		if goal in NEW_RECIPES and achieved:
			var primary = manager.Synergies.RECIPES[goal].ingredients[0]
			var catalyst = manager.Synergies.RECIPES[goal].ingredients[1]
			check(manager.find_spell_slot(primary) != 0 and manager.find_spell_slot(catalyst) != 0 and manager.find_spell_slot(goal) > 6, "Ordinary bonus preserves both ingredients outside active slots")
	print("MAGIC_SEEDED_OFFERED=", JSON.stringify(offered.keys()), " ACQUIRED=", JSON.stringify(acquired.keys()), " RUNS=", JSON.stringify(seed_results))
