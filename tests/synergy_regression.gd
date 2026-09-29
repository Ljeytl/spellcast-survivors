extends SceneTree

var checks = 0
var failures = 0

class HitTarget extends Node2D:
	var current_health = 20.0
	var dying = false
	func take_damage(amount, _position):
		if not dying:
			current_health = maxf(0.0, current_health - amount)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Refusing nonisolated synergy regression")
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func key(code, character = 0):
	var event = InputEventKey.new()
	event.keycode = code
	event.unicode = character
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func type_text(value):
	for character in value:
		key(character.unicode_at(0), character.unicode_at(0))

func run():
	var profile = root.get_node("CharacterManager")
	profile.reset_progression()
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var spells = game.spell_manager
	spells.set_process(false)
	check(not spells.learn_spell("life_bolt"), "Recipe cannot be learned without ingredients")
	check(not spells.cast_freeform_spell("life bolt"), "Discovery cannot bypass run ownership")
	key(KEY_SPACE)
	check(spells.is_typing and spells.space_casting, "Space opens casting")
	Input.action_press("move_right")
	game.player.handle_movement()
	check(game.player.velocity == Vector2.ZERO, "Movement stops while typing")
	Input.action_release("move_right")
	type_text("bolt")
	check(game.spells_cast == 0, "Exact match waits for Enter")
	key(KEY_BACKSPACE)
	check(spells.current_typing_text == "bol", "Backspace corrects input")
	type_text("t")
	key(KEY_ENTER)
	check(game.spells_cast == 1 and not spells.is_typing, "Enter casts exactly once and closes")
	spells.casting_clock += 0.12
	key(KEY_SPACE)
	type_text("life bolt")
	key(KEY_ENTER)
	check(game.spells_cast == 1 and spells.is_typing, "Unavailable spell stays editable without casting")
	key(KEY_ESCAPE)
	check(not spells.is_typing and not paused, "Escape cancels without pause")
	check(spells.learn_spell("life"), "Learn second ingredient")
	var cards = spells.get_learnable_spell_cards()
	check(cards.any(func(card): return card.key == "learn:life_bolt"), "Ingredients reveal recipe as level-up option")
	check(profile.discovered_synergies.is_empty(), "Eligibility alone does not persist discovery")
	game.change_state(game.GameState.LEVEL_UP)
	game.level_up_screen.available_upgrades = cards.filter(func(card): return card.key == "learn:life_bolt")
	game.level_up_screen.update_ui(2)
	game.level_up_screen.upgrade_buttons[0].pressed.emit()
	var selection_deadline = Time.get_ticks_msec() + 1000
	while not spells.acquired_spells.has("life_bolt") and Time.get_ticks_msec() < selection_deadline:
		await process_frame
	check(spells.acquired_spells.has("life_bolt") and not paused, "Selecting recipe card grants spell and resumes")
	check(not spells.learn_spell("life_bolt"), "Duplicate acquisition rejected")
	check(spells.spells[1].id == "bolt" and spells.spells[2].id == "life" and spells.bonus_spells.size() == 1, "Bonus preserves both ingredients")
	check(spells.cast_freeform_spell("bolt"), "Ingredient remains castable")
	check("life bolt" in spells.get_owned_incantations(), "Owned synergy appears in casting names")
	check("life_bolt" in profile.discovered_synergies, "Selection persists discovery")
	profile.discovered_synergies.clear()
	profile.load_progression_data()
	check("life_bolt" in profile.discovered_synergies, "Discovery survives disk reload")
	profile.load_progression_data(987)
	check(profile.discovered_synergies.is_empty(), "Missing slot cannot inherit discovery")
	var corrupt = FileAccess.open("user://spellcast_save_slot_988.save", FileAccess.WRITE)
	corrupt.store_string("[]")
	corrupt.close()
	profile.load_progression_data(988)
	check(profile.discovered_synergies.is_empty(), "Malformed slot cannot inherit discovery")
	profile.load_progression_data()
	var target = HitTarget.new()
	target.add_to_group("enemies")
	target.position = Vector2(5000, 5000)
	var hurt = Area2D.new()
	hurt.name = "HurtBox"
	target.add_child(hurt)
	game.add_child(target)
	game.player.health = 50.0
	check(spells.cast_freeform_spell("life bolt"), "Owned synergy casts")
	check(game.player.health == 50.0, "Casting alone cannot heal")
	var projectile
	for child in game.get_children():
		if child is Area2D and child.has_meta("healing_seed_amount"):
			projectile = child
	check(projectile != null, "Life Bolt creates seed-bearing projectile")
	projectile.global_position = target.global_position
	projectile._on_area_entered(hurt)
	projectile.resolve_impact()
	check(game.player.health == 50.0, "Damaging hit does not remotely heal")
	var seeds = get_nodes_in_group("healing_seeds")
	check(seeds.size() == 1 and seeds[0].global_position == target.global_position, "Actual impact plants one seed at the enemy")
	projectile._on_area_entered(hurt)
	projectile.resolve_impact()
	check(get_nodes_in_group("healing_seeds").size() == 1, "Same projectile cannot plant twice")
	var seed = seeds[0]
	seed.set_physics_process(false)
	game.player.global_position = seed.global_position
	game.player.health = game.player.max_health
	seed._physics_process(0.1)
	check(not seed.collected, "Full health preserves the seed")
	game.player.health = 50
	seed._physics_process(0.1)
	check(seed.collected and game.player.health == 50, "Physical collection starts healing without an instant return")
	spells.process_healing_effects(1)
	check(game.player.health == 53, "Collected seed heals three HP in one second")
	spells.process_healing_effects(10)
	check(game.player.health == 56, "Seed HoT cannot exceed six total HP")
	var pooled = load("res://scenes/SpellProjectile.tscn").instantiate()
	game.add_child(pooled)
	pooled.set_meta("healing_seed_amount", 6.0)
	pooled.set_meta("healing_seed_owner", weakref(game.player))
	pooled.reset_for_pool()
	check(not pooled.has_meta("healing_seed_amount") and not pooled.has_meta("healing_seed_owner"), "Pool reset removes seed ownership")
	game.queue_free()
	await process_frame
	await process_frame
	var fresh = load("res://scenes/Game.tscn").instantiate()
	root.add_child(fresh)
	current_scene = fresh
	await process_frame
	check(not fresh.spell_manager.acquired_spells.has("life_bolt"), "New run does not inherit synergy ownership")
	check("life_bolt" in profile.discovered_synergies, "New run keeps discovery")
	fresh.queue_free()
	await process_frame
	await process_frame
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.get_node("MenuPanel/VBoxContainer/CollectionButton").pressed.emit()
	check(not menu.get_node("MenuPanel").visible, "Collection blocks main-menu interaction")
	var labels = menu.find_children("*", "Label", true, false)
	check(labels.any(func(label): return "Life Bolt" in label.text), "Discovered recipe appears in collection")
	key(KEY_ESCAPE)
	await process_frame
	check(menu.get_node("MenuPanel").visible, "Escape closes collection")
	profile.reset_progression()
	check(profile.discovered_synergies.is_empty(), "Profile reset clears discovery")
	menu.get_node("MenuPanel/VBoxContainer/CollectionButton").pressed.emit()
	labels = menu.find_children("*", "Label", true, false)
	check(labels.any(func(label): return "Life Bolt" in label.text), "Necronomicon lists undiscovered recipes")
	check(labels.any(func(label): return "Undiscovered" in label.text), "Necronomicon marks undiscovered recipes without granting them")
	menu.queue_free()
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.25).timeout
	print("SYNERGY_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
