extends SceneTree

var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 1000.0
	var dying = false
	var slow = 0.0
	func take_damage(amount, _source = Vector2.ZERO):
		if not dying:
			current_health = maxf(0.0, current_health - amount)
	func apply_slow(amount, _duration):
		slow = amount

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func make_target(game, position):
	var target = Target.new()
	target.position = position
	game.add_child(target)
	target.add_to_group("enemies")
	return target

func effect_for(game, id):
	for effect in get_nodes_in_group("build_spell_effects"):
		if effect.info.id == id and not effect.is_queued_for_deletion():
			effect.set_physics_process(false)
			return effect
	return null

func run():
	root.get_node("CharacterManager").reset_progression()
	for recipe_id in preload("res://scripts/SynergyCatalog.gd").RECIPES:
		if not preload("res://scripts/SynergyCatalog.gd").RECIPES[recipe_id].get("enabled", true):
			continue
		var game = load("res://scenes/Game.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		game.get_node("MonsterManager").spawn_timer.stop()
		game.get_node("MonsterManager").set_process(false)
		game.set_process(false)
		game.player.set_physics_process(false)
		var manager = game.spell_manager
		manager.set_process(false)
		check(manager.spell_catalog.size() == 16, "Sixteen implemented base spell choices")
		check(game.spell_slots.size() == 6, "HUD has six active slots")
		var before = manager.spells.duplicate(true)
		check(not manager.learn_spell(recipe_id) and manager.spells == before, "Ineligible evolution is atomic")
		var recipe = manager.Synergies.RECIPES[recipe_id]
		for ingredient in recipe.ingredients:
			if ingredient != "bolt":
				check(manager.learn_spell(ingredient), "Ingredient acquired")
		var primary = recipe.ingredients[0]
		manager.upgrade_spell(primary)
		manager.upgrade_spell(primary)
		var slot = manager.find_spell_slot(primary)
		for id in manager.BASE_SPELL_IDS:
			if manager.spells.size() < 6:
				manager.learn_spell(id)
		check(manager.spells.size() == 6, "Loadout reaches six")
		check(manager.get_learnable_spell_cards().all(func(card): return card.effect.spell in manager.Synergies.RECIPES), "Full kit only offers evolutions, never seventh primary spell")
		manager.queue_spell(slot)
		manager.start_typing()
		manager.typing_slowdown_remaining = 1.0
		check(manager.learn_spell(recipe_id), "Full kit can evolve")
		check(manager.is_typing, "Additive learning preserves an ingredient cast")
		check(manager.typing_slowdown_remaining == 1.0, "Learning does not reset current cast allowance")
		check(manager.spells.size() == 6 and manager.spells[slot].id == primary, "Bonus preserves occupied primary slot")
		check(manager.get_spell_rank(recipe_id) == 1, "Bonus starts at rank one")
		check(manager.get_spell_rank(primary) == 3, "Ingredient rank preserved")
		check(not manager.learn_spell(primary), "Duplicate ingredient rejected")
		check(manager.find_cast_spell_slot(manager.spells[slot].display_name) == slot, "Ingredient remains castable")
		check(manager.get_spell_rank(recipe.ingredients[1]) > 0, "Both ingredients retained")
		manager.upgrade_spell(recipe_id)
		check(manager.get_spell_rank(recipe_id) == 2, "Bonus ranks independently")
		game.level_up_screen.generate_upgrade_options({}, 5)
		check(game.level_up_screen.current_upgrade_pool.any(func(card): return card.key == "rank:" + recipe_id), "Bonus rank available in real pool")
		manager.cancel_typing()
		game.update_spell_slot_lock_status()
		game.update_spell_slot_lock_status()
		check(game.spell_slots[slot - 1].get_node("VBox/SpellName").text == manager.spells[slot].name, "HUD retains ingredient name")
		check(not game.spell_slots[slot - 1].get_node("LevelLabel").visible, "Normal HUD omits rank detail")
		for i in range(6):
			await process_frame
		for card in game.spell_slots:
			var name_rect = card.get_node("VBox/SpellName").get_global_rect()
			var rank_rect = card.get_node("LevelLabel").get_global_rect()
			check(not card.get_node("LevelLabel").visible or name_rect.end.y <= rank_rect.position.y, "Visible rank reserves space below spell name")
			check(card.get_global_rect().encloses(name_rect), "Wrapped equipped name stays inside its card")
			check(game.get_node("UI/HUD/SpellSlotsPanel").get_global_rect().encloses(card.get_global_rect()), "HUD panel contains all equipped cards")
		check(game.spell_slots[slot - 1].find_children("SlotBackground", "Panel", false, false).size() == 1, "HUD refresh reuses background")
		var target = make_target(game, game.player.global_position + Vector2(70, 0))
		check(manager.cast_freeform_spell(recipe.incantation), "Space route dispatches evolved effect")
		manager.queue_spell(slot)
		manager.cast_spell()
		check(game.spells_cast == 2, "Numbered route dispatches evolved effect")
		check(recipe_id in root.get_node("CharacterManager").discovered_synergies, "Each selected recipe recorded")
		game.queue_free()
		await process_frame
		await process_frame
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	var manager = game.spell_manager
	var start = game.player.global_position
	var a = make_target(game, start + Vector2(70, 0))
	var b = make_target(game, start + Vector2(140, 0))
	var c = make_target(game, start + Vector2(70, 65))
	manager.learn_spell("ember_lance")
	manager.cast_freeform_spell("ember lance")
	var effect = effect_for(game, "ember_lance")
	effect.advance(0.3)
	check(a.current_health == 955 and b.current_health == 955, "Swept lance pierces two enemies")
	check(c.current_health == 1000, "Lance does not damage outside its line")
	effect.advance(0.5)
	check(a.current_health == 955, "Piercing target cannot be hit twice")
	manager.learn_spell("meteor_shower")
	manager.learn_spell("meteor_lance")
	manager.cast_freeform_spell("meteor lance")
	effect = effect_for(game, "meteor_lance")
	effect.advance(0.3)
	check(c.current_health < 1000, "Meteor Lance splash reaches off-line enemy")
	manager.learn_spell("plague_seed")
	manager.learn_spell("regeneration")
	manager.learn_spell("soul_bloom")
	game.player.health = 20.0
	manager.cast_freeform_spell("soul bloom")
	effect = effect_for(game, "soul_bloom")
	effect.advance(1.25)
	check(game.player.health > 20.0 and game.player.health <= 22.0, "Soul Bloom heals only from actual damage")
	check(effect.infections.size() > 1, "Infection spreads to neighbor")
	for i in range(15):
		make_target(game, start + Vector2(70 + i, 0))
	for i in range(8):
		effect.advance(0.5)
	check(effect.infections.size() == 8, "Spreading bounded to eight enemies per cast")
	var multi_health = game.player.health
	effect.tick_infections()
	check(is_equal_approx(game.player.health - multi_health, 2.0), "Eight infected enemies share a two-HP total healing budget per tick")
	a.current_health = 0.0
	var hp = game.player.health
	effect.deal_damage(a, 100.0)
	check(game.player.health == hp, "Dead targets cannot heal")
	a.current_health = 1.0
	effect.healing_remaining = 2.0
	effect.deal_damage(a, 100.0)
	check(is_equal_approx(game.player.health - hp, 0.1), "Overkill healing uses actual health lost")
	game.queue_free()
	await process_frame
	await process_frame
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	manager = game.spell_manager
	start = game.player.global_position
	a = make_target(game, start + Vector2(65, 0))
	b = make_target(game, start + Vector2(500, 0))
	manager.learn_spell("cinder_field")
	manager.cast_freeform_spell("cinder field")
	effect = effect_for(game, "cinder_field")
	effect.advance(0.5)
	effect.advance(0.5)
	check(a.current_health < 980 and b.current_health == 1000, "Field ticks repeatedly only inside radius")
	var position = effect.global_position
	game.player.position += Vector2(400, 0)
	effect.advance(0.5)
	check(effect.global_position == position, "Field remains anchored when player moves")
	manager.learn_spell("ice_blast")
	manager.learn_spell("steam_field")
	manager.cast_freeform_spell("steam field")
	effect = effect_for(game, "steam_field")
	effect.advance(0.5)
	check(is_equal_approx(b.slow, 0.6), "Steam Field slows damaged nearby target")
	manager.learn_spell("arcane_orbit")
	manager.cast_freeform_spell("arcane orbit")
	effect = effect_for(game, "arcane_orbit")
	b.position = game.player.position + Vector2.from_angle(2.0) * float(effect.info.orbit_radius)
	var old_health = b.current_health
	effect.advance(0.5)
	check(is_equal_approx(effect.angle, 2.0), "Orbit naturally rotates four radians per second")
	check(b.current_health < old_health, "Orbit damages target at its naturally advanced spark position")
	b.position = game.player.position + Vector2.from_angle(4.0) * float(effect.info.orbit_radius)
	old_health = b.current_health
	effect.advance(0.5)
	check(b.current_health < old_health, "Orbit continues hitting at the next rotated position")
	game.player.position += Vector2(10, 0)
	effect.advance(0.1)
	check(effect.global_position == game.player.global_position, "Orbit follows player")
	effect.advance(5.0)
	check(effect.is_queued_for_deletion(), "Persistent spells expire")
	for candidate in get_nodes_in_group("build_spell_effects"):
		candidate.queue_free()
	a.current_health = 1000.0
	a.position = game.player.position
	b.position = game.player.position + Vector2(1000, 0)
	var fixture_info = manager.spell_catalog.cinder_field
	var bulk = preload("res://scripts/BuildSpellEffect.gd").new()
	bulk.configure(fixture_info, 12.0, game.player, a)
	game.add_child(bulk)
	bulk.set_physics_process(false)
	bulk.advance(5.0)
	check(a.current_health == 880.0, "Five seconds produces exactly ten half-second ticks")
	a.current_health = 1000.0
	var sliced = preload("res://scripts/BuildSpellEffect.gd").new()
	sliced.configure(fixture_info, 12.0, game.player, a)
	game.add_child(sliced)
	sliced.set_physics_process(false)
	for i in range(10):
		sliced.advance(0.5)
	check(a.current_health == 880.0, "Tick totals independent of frame partition")
	for i in range(5):
		manager.cast_freeform_spell("arcane orbit")
	var active = get_nodes_in_group("build_spell_effects").filter(func(item): return item.info.id == "arcane_orbit" and not item.is_queued_for_deletion())
	check(active.size() == 3, "Repeated casts retain at most three active effects")
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	manager.evolved_ingredients.clear()
	manager.learn_spell("bolt")
	manager.unlock_all_spells()
	check(manager.spells.size() == 6, "Public unlock helper fills available slots")
	check(manager.get_unlocked_spell_names() == ["mana_bolt", "bolt", "life", "regeneration", "ice_blast", "earth_shield", "lightning_arc"], "Public unlock helper fills in deterministic catalog order")
	manager.learn_spell("life_bolt")
	manager.unlock_all_spells()
	check(manager.spells.size() == 6 and manager.spells[1].id == "bolt" and manager.bonus_spells.size() == 1, "Repeated unlock respects cap and preserves bonus")
	manager.last_spell_cast_time = manager.casting_clock
	var space = InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	manager.handle_key_input(space)
	check(not manager.is_typing, "Cooldown blocks immediate recast")
	manager._process(0.11)
	manager.handle_key_input(space)
	check(manager.is_typing, "Cooldown expires through simulated unscaled time")
	manager.cancel_typing()
	game.queue_free()
	await process_frame
	await process_frame
	check(get_nodes_in_group("build_spell_effects").is_empty(), "Run teardown removes all spell effects")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.5).timeout
	print("SPELL_BUILD_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
