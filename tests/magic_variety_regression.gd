extends SceneTree

const NEW_IDS = ["focus_ray", "rune_trap", "seeker", "firewalk", "cross_blade"]
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

## Ported spells (doc 18 phase 2): the generic cast, driven by hand.
func effect(id: String, aim = null, overrides: Dictionary = {}):
	var data = manager.spell_catalog[id].duplicate(true)
	data.merge(overrides, true)
	var cast = manager.spawn_ported(data, float(data.damage), {}, aim)
	cast.manual = true
	for part in cast.root_parts():
		if part.delivery == "beam":
			part.beam_offset = Vector2.ZERO  # fixtures measure from the wizard, not a side lane
			part.step(0.0)
	return cast

func root_of(cast):
	var roots = cast.root_parts()
	return roots[0] if not roots.is_empty() else null

## Cross Blade throws a ring; the aimed blade is the one heading along +x in these fixtures.
func aimed_blade(cast):
	var best = null
	for p in cast.root_parts():
		if best == null or p.direction.x > best.direction.x:
			best = p
	return best

func live_patches(cast) -> int:
	return cast.parts.filter(func(p): return is_instance_valid(p) and not p.done and p.part_name.begins_with("patch")).size()

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
		if id == "cross_blade":
			check(is_equal_approx(manager.calculate_spell_damage(manager.spells[slot]), original_damage + float(manager.spells[slot].rank_growth.damage.per_rank)), "Blade count upgrade also adds its per-rank damage")
			check("blade" in manager.get_rank_upgrade_description(id), "Next blade rank describes the volley")
		else:
			var growth = manager.spells[slot].get("rank_growth", {}).get("damage", {})
			if growth.is_empty():
				check(is_equal_approx(manager.calculate_spell_damage(manager.spells[slot]), original_damage * 1.15), "New spell rank increases actual damage: " + id)
				check("+15% of base damage" in manager.get_rank_upgrade_description(id), "Rank copy matches damage rule")
			else:
				check(is_equal_approx(manager.calculate_spell_damage(manager.spells[slot]), original_damage + float(growth.per_rank)), "New spell rank adds its per-rank damage: " + id)
				check("+damage" in manager.get_rank_upgrade_description(id), "Rank copy matches damage rule")
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
		var active = manager.ported_casts(id)
		var capped = active.size()
		# Extend-recast spells (Fire Walk) lengthen one instance instead of stacking up to active_limit.
		var expected_cap = 1 if manager.spells[slot].get("recast_behavior", "stack") == "extend" else mini(int(manager.spells[slot].active_limit), 7)
		check(capped == expected_cap, "Per-spell concurrent cap: " + id)
		enemy.free()
		for node in active:
			# A trap waits, everything else runs out.
			var root = node.root_parts()[0] if not node.root_parts().is_empty() else null
			var is_trap = root != null and root.delivery == "trap"
			node.advance(120.0)   # stops early once finished (extended recasts accumulate duration)
			if is_trap:
				check(not node.finished and not root.done, "Untriggered trap remains prepared in empty arena")
			else:
				check(node.finished, "Nonpersistent empty-arena effect expires after large delta")
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
		var family_nodes = []
		for owned in [recipe.ingredients[0], recipe_id]:
			family_nodes.append_array(manager.ported_casts(owned))
		check(family_nodes.size() == mini(int(manager.get_spell_info(bonus_slot).active_limit), 5) + 1, "Bonus keeps its own active limit without replacing ingredient: " + recipe_id)
	for id in ["rune_trap"]:
		fresh()
		manager.learn_spell(id)
		var corpse = target(Vector2(20, 0))
		corpse.dying = true
		var live = target(Vector2(0, 120))
		manager.cast_spell_by_type(manager.find_spell_slot(id))
		var rune = manager.last_generic_cast.root_parts()[0]
		check(game.player.global_position.direction_to(rune.global_position).dot(Vector2.DOWN) > 0.99, "Initial tactical aim ignores nearest dying enemy: " + id)
	fresh()
	var near = target(Vector2(100, 0))
	var far = target(Vector2(200, 0))
	var off_axis = target(Vector2(100, 90))
	var beam = effect("focus_ray", near)
	beam.advance(0.24)
	check(near.hits == 0, "Beam has no early extra tick")
	check(root_of(beam).beam_end.length() < 120, "Base beam visual stops at first blocking target")
	beam.advance(0.01)
	check(near.hits == 1 and far.hits == 0 and off_axis.hits == 0, "Focused beam hits one aligned target")
	beam.advance(1.75)
	check(near.hits == 8 and far.hits == 0, "Beam deals exactly eight ticks over two seconds (%d)" % near.hits)
	check(near.hits != 9, "Known-bad immediate-plus-lifetime ninth tick rejected")
	fresh()
	var line = [target(Vector2(100, 0)), target(Vector2(200, 0)), target(Vector2(300, 0)), target(Vector2(400, 0))]
	beam = effect("focus_ray", line[0], {"beam_targets": 3})
	beam.advance(0.25)
	check(line[0].hits == 1 and line[1].hits == 1 and line[2].hits == 1 and line[3].hits == 0, "Prism pierces three, never fourth")
	check(root_of(beam).beam_end.length() > 300 and root_of(beam).beam_end.length() < 320, "Prism visual matches third blocking enemy (%s)" % root_of(beam).beam_end.length())
	line[0].free()
	game.player.position += Vector2(0, 30)
	beam.advance(0.25)
	check(root_of(beam).global_position.distance_to(game.player.global_position) < 0.01 and root_of(beam).target_ref.get_ref() == line[1], "Beam follows caster and retargets freed target")
	fresh()
	near = target(Vector2(160, 0))
	far = target(Vector2(310, 0))
	var trap = effect("rune_trap", near, {"trap_radius": 170, "frost": true})
	trap.advance(0.79)
	check(near.hits == 0 and far.hits == 0, "Trap cannot hit before arming")
	trap.advance(0.01)
	check(near.hits == 0 and far.hits == 0, "Stepping in activates the rune; the explosion waits for its fuse (doc 21 §5.1)")
	trap.advance(0.45)
	check(near.hits == 1 and far.hits == 1, "Frost burst reaches enlarged radius after arming")
	trap.advance(3)
	check(near.hits == 1 and far.hits == 1 and trap.finished, "Trap bursts exactly once")
	fresh()
	trap = effect("rune_trap")
	trap.advance(5.9)
	check(not trap.finished and root_of(trap) != null and root_of(trap).armed, "Empty trap does not detonate on a timer")
	near = target(Vector2(160, 0))
	trap.advance(0.5)
	check(near.hits == 1, "Armed trap triggers on later proximity")
	fresh()
	await process_frame  # Seeker only targets on-screen enemies; let the new camera settle first
	near = target(Vector2(100, 0))
	var spirit = effect("seeker", near, {"move_speed": 320, "hit_interval": 0.5})  # pursuit timing fixture
	spirit.advance(0.2)
	check(root_of(spirit).global_position.x > game.player.position.x and near.hits == 0, "Spirit travels instead of remote damage")
	near.position += Vector2(60, 0)
	spirit.advance(0.6)
	check(near.hits > 0, "Spirit pursues moving target and strikes")
	far = target(Vector2(250, 0))
	near.free()
	spirit.advance(0.1)
	check(root_of(spirit).target_ref != null and root_of(spirit).target_ref.get_ref() == far, "Spirit reacquires after target freed")
	fresh()
	await process_frame
	near = target(Vector2(30, 0))
	far = target(Vector2(80, 0))
	var reaper_damage = float(manager.spell_catalog.seeker.damage)
	spirit = effect("seeker", near, {"reaping": true, "hit_interval": 0.5})  # pre-1.0s-interval fixture timing
	spirit.advance(0.05)
	check(near.hits == 1 and far.hits == 0, "Reaping spirit survivor hit does not burst")
	near.current_health = 1
	spirit.advance(0.6)  # past the 0.5s re-hit boundary without relying on exact float accumulation
	check(near.hits == 2 and far.hits == 1 and is_equal_approx(far.current_health, 10000 - reaper_damage * 0.5), "Actual spirit kill bursts half damage once, excluding primary (%s)" % far.current_health)
	fresh()
	near = target(Vector2.ZERO)
	var trail = effect("firewalk", null, {"patch_duration": 2.0})
	trail.advance(2.1)
	var stationary_hits = near.hits
	trail.advance(2)
	check(live_patches(trail) == 0 and near.hits == stationary_hits, "Standing still cannot keep regenerating a stationary field")
	game.player.position += Vector2(40, 0)
	trail.advance(0.4)
	check(live_patches(trail) == maxi(1, ceili(40.0 / float(manager.spell_catalog.firewalk.trail_radius))), "Movement creates a new spaced patch (%d)" % live_patches(trail))
	game.player.position += Vector2(40, 0)
	trail.advance(0.2)
	near.position = game.player.position - Vector2(20, 0)
	var prior_hits = near.hits
	trail.advance(0.5)
	check(near.hits - prior_hits <= 1, "Overlapping patches never multiply one trail tick")
	trail.advance(10)
	check(trail.finished, "Trail has finite total lifetime")
	fresh()
	near = target(Vector2(150, 0))
	far = target(Vector2(280, 0))
	var blade = effect("cross_blade", near)
	var thrown = aimed_blade(blade)
	blade.advance(0.7)
	check(near.hits == 1 and far.hits == 1 and thrown.phase >= 1, "Outbound sweep hits each crossed enemy once (%d, %d, phase %d)" % [near.hits, far.hits, thrown.phase])
	blade.advance(1.6)
	check(near.hits == 2 and far.hits == 2, "Return leg can hit each enemy once again (%d, %d)" % [near.hits, far.hits])
	check(near.hits != 3, "Known-bad per-frame blade hit would fail deduplication")
	fresh()
	near = target(Vector2(150, 0))
	blade = effect("cross_blade", near)
	thrown = aimed_blade(blade)
	blade.advance(0.7)
	game.player.position += Vector2(0, 100)
	blade.advance(1.1)
	check(not is_instance_valid(thrown) or thrown.done or thrown.global_position.y > game.player.position.y - 100, "Returning blade tracks moving caster")
	blade.advance(20)
	check(blade.finished, "Moving-caster blade remains finite")
	fresh()
	for id in NEW_IDS:
		var temporary_caster = Node2D.new()
		game.add_child(temporary_caster)
		var data = manager.spell_catalog[id]
		var def = load("res://scripts/engine/LegacyBridge.gd").build(load("res://scripts/SpellGeometry.gd").scaled_data(data, game.player), 1.0, {})
		var cast = load("res://scripts/engine/GenericCast.gd").new()
		cast.setup(load("res://scripts/engine/CastPlanner.gd").plan(def, {}, {}), temporary_caster, game, {"spell": id}, true)
		game.add_child(cast)
		cast.step(0.0)
		temporary_caster.free()
		cast.advance(0.1)
		check(cast.finished, "Freed caster safely ends effect: " + id)
	var paused_effect = effect("focus_ray")
	paused_effect.manual = false
	var lifetime = root_of(paused_effect).remaining_life()
	paused = true
	await create_timer(0.1, true).timeout
	check(root_of(paused_effect).remaining_life() == lifetime, "Effects do not advance during pause")
	paused = false
	game.free()
	game = null
	check(get_nodes_in_group("generic_casts").is_empty(), "Run teardown removes all effect nodes")
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
			# Combinations unlock only at ingredient rank 8, so recipe goals need a longer ordinary run.
			for level in range(2, 62 if goal in NEW_RECIPES else 32):
				last_level = level
				var options = game.level_up_screen.generate_upgrade_options({}, level)
				var choice = {}
				for card in options:
					if card.effect.type == "learn_spell":
						offered[card.effect.spell] = true
						if card.effect.spell in desired:
							choice = card
				if choice.is_empty():
					# Combinations unlock at ingredient rank 8, so a goal-seeking player ranks its ingredients up.
					for card in options:
						if card.effect.type == "spell_upgrade" and card.effect.get("spell", "") in desired and card.effect.spell != goal:
							choice = card
							break
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
