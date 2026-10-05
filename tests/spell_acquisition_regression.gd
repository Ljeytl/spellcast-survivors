extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func validate_cards(screen):
	var keys: Array = []
	for card in screen.available_upgrades:
		check(card.has("effect") and card.has("name"), "Every card has an applicable effect and title")
		check(card.key not in keys, "Offer has unique cards")
		check(card.key not in screen.banished_upgrades, "Offer respects banishes")
		keys.append(card.key)

func run():
	seed(17)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	var spells = game.spell_manager
	spells.set_process(false)
	var screen = game.level_up_screen
	spells.queue_spell(1)
	spells.start_typing()
	check(spells.player_sprite.modulate.a == 1.0, "Player stays visible while typing")
	var escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	check(not spells.is_typing and not paused, "Escape cancels casting without pausing")
	Input.parse_input_event(escape)
	await process_frame
	check(paused, "Escape pauses when no spell is being typed")
	Input.parse_input_event(escape)
	await process_frame
	check(not paused, "Escape resumes a paused run")
	check(spells.get_unlocked_spell_names() == ["mana_bolt", "bolt"], "Run starts with Bolt and the passive only")
	var y_key = InputEventKey.new()
	y_key.keycode = KEY_Y
	y_key.unicode = 121
	y_key.pressed = true
	spells.handle_key_input(y_key)
	spells.freeform_mode = true
	spells.handle_key_input(y_key)
	check(spells.get_unlocked_spell_names().size() == 2, "Typing Y cannot unlock spells in either mode")
	spells.cancel_typing()
	spells.freeform_mode = false
	game.player.level = 50
	check(not spells.is_spell_unlocked(6), "Player level does not bypass acquisition")
	spells.queue_spell(2)
	check(spells.spell_queue.is_empty(), "Numbered slot rejects unlearned regeneration")
	spells.cast_freeform_spell("regeneration")
	check(spells.active_healing_effects.is_empty(), "Freeform rejects unlearned regeneration")
	game.player.level = 1
	for i in range(40):
		screen.show_level_up(2)
		validate_cards(screen)
		check(screen.available_upgrades.any(func(card): return card.effect.type == "learn_spell"), "Each offer includes an eligible new spell")
		for card in screen.available_upgrades:
			check(card.effect.type in ["learn_spell", "spell_upgrade"] or card.effect.type in game.player.SUPPORTED_PASSIVES, "Offer only includes implemented effects")
			if card.effect.type == "spell_upgrade":
				check(card.effect.spell in spells.get_unlocked_spell_names(), "Only owned spells can be upgraded")
	for i in range(3):
		screen.show_level_up(2)
		var learned_card = screen.available_upgrades[0]
		screen.banish_upgrade(0)
		check(screen.available_upgrades.any(func(card): return card.effect.type == "learn_spell"), "Banishing a learning card preserves another eligible learning choice")
		check(learned_card.key in screen.banished_upgrades, "Learning bans are retained")
	screen.banished_upgrades.clear()
	screen.banishes_remaining = 5
	screen.show_level_up(2)
	var held_key = screen.available_upgrades[0].key
	screen.lock_upgrade(0)
	screen._on_reroll_pressed()
	check(screen.available_upgrades[0].key == held_key, "Reroll preserves a locked card")
	validate_cards(screen)
	var banned_key = screen.available_upgrades[1].key
	screen._on_banish_mode_toggled()
	screen._on_upgrade_button_pressed(1)
	check(screen.upgrade_buttons[1].get_node("KeyTitle").text == screen.available_upgrades[1].name and screen.upgrade_buttons[1].get_node("CardText").text.contains(preload("res://scripts/UpgradeCopy.gd").description(screen.available_upgrades[1], spells)), "Replacement updates visible card copy")
	check(banned_key in screen.banished_upgrades and not screen.selecting_upgrade, "Banish mode removes a card without selecting it")
	validate_cards(screen)
	screen.show_level_up(3)
	check(screen.locked_upgrades.is_empty(), "Locks do not attach to unrelated choices next level")
	validate_cards(screen)
	spells.learn_spell("life")
	game.update_spell_slot_lock_status()
	check(spells.get_spell_rank("life") == 1 and not game.spell_slots[1].get_node("LevelLabel").visible, "Learned rank exists without cluttering the normal HUD")
	check(spells.learn_spell("regeneration"), "Regeneration is separate from quick Life")
	spells.upgrade_spell("life")
	check(spells.get_spell_rank("regeneration") == 1 and spells.get_spell_rank("life") == 2, "Life and Regeneration ranks are independent")
	game.player.health = 40
	spells.cast_freeform_spell("life")
	check(is_equal_approx(game.player.health, 44.6) and spells.active_healing_effects.is_empty(), "Ranked Life heals immediately without adding regeneration")
	spells.upgrade_spell("regeneration")
	spells.cast_freeform_spell("regeneration")
	check(spells.active_healing_effects.size() == 1, "Learned freeform regeneration casts")
	check(is_equal_approx(spells.active_healing_effects[0].heal_per_second, 3.45), "Freeform casting uses the acquired spell's rank")
	spells.active_healing_effects.clear()
	spells.queue_spell(spells.find_spell_slot("regeneration"))
	spells.cast_spell()
	check(is_equal_approx(spells.active_healing_effects[0].heal_per_second, 3.45), "Numbered and freeform healing match")
	for id in ["ice_blast", "earth_shield", "lightning"]:
		check(spells.learn_spell(id), "Each remaining spell can be acquired")
		spells.upgrade_spell(id)
		check(spells.get_spell_rank(id) == 2, "Each canonical spell ID upgrades")
	check(not spells.learn_spell("meteor_shower"), "Seventh equipped spell is rejected")
	check(spells.learn_spell("life_bolt"), "Full base kit can learn a slot-free bonus")
	check(not spells.learn_spell("bolt"), "Already owned primary cannot be duplicated")
	check(spells.get_learnable_spell_cards().all(func(card): return card.effect.spell in spells.Synergies.RECIPES), "Full loadout still offers eligible bonuses but no new primary")
	check(spells.learn_spell("lightning_bolt"), "Full loadout can learn its other eligible bonus")
	check(spells.spells.size() == 6 and spells.bonus_spells.size() == 2 and spells.find_spell_slot("bolt") == 1, "Both bonuses preserve the six primary slots")
	check(spells.get_learnable_spell_cards().is_empty(), "Owned eligible bonuses are not reoffered")
	screen.show_level_up(4)
	validate_cards(screen)
	check(screen.available_upgrades.all(func(card): return card.effect.type != "learn_spell"), "Full loadout offers only upgrades")
	var before_rank = spells.get_spell_rank("life_bolt")
	screen.available_upgrades = [{"key":"rank:life_bolt", "name":"Life Bolt+", "effect":{"type":"spell_upgrade", "spell":"life_bolt"}}]
	screen.selecting_upgrade = false
	game.change_state(game.GameState.LEVEL_UP)
	screen._on_upgrade_button_pressed(0)
	screen._on_upgrade_button_pressed(0)
	var rerolls = screen.rerolls_remaining
	screen._on_reroll_pressed()
	check(screen.rerolls_remaining == rerolls, "Reroll cannot mutate a resolving choice")
	await create_timer(0.4).timeout
	check(spells.get_spell_rank("life_bolt") == before_rank + 1, "Selecting an upgrade applies exactly once")
	check(not paused, "Selection resumes the run")
	var fresh = load("res://scenes/Game.tscn").instantiate()
	game.queue_free()
	await process_frame
	await process_frame
	root.add_child(fresh)
	current_scene = fresh
	await process_frame
	check(fresh.spell_manager.get_unlocked_spell_names() == ["mana_bolt", "bolt"], "New run resets acquisition")
	check(fresh.spell_manager.get_spell_rank("bolt") == 1, "New run resets ranks")
	fresh.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.25).timeout
	await process_frame
	print("ACQUISITION_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
