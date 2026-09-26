extends SceneTree

var checks = 0
var failures = 0
var restart_count = 0

class Contact extends Node2D:
	var base_damage = 6.0
	var current_health = 30.0
	var dying = false

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

func settle():
	for i in range(12):
		await process_frame

func key(code: int, character: int = 0, echo: bool = false):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = character
	event.pressed = true
	event.echo = echo
	root.push_input(event, true)
	var release = event.duplicate()
	release.pressed = false
	release.echo = false
	root.push_input(release, true)

func click(control: Control, button: int = MOUSE_BUTTON_LEFT):
	var event = InputEventMouseButton.new()
	event.position = control.get_global_rect().get_center()
	event.global_position = event.position
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	event.pressed = false
	root.push_input(event, true)

func wait_for_state(condition: Callable):
	var deadline = Time.get_ticks_msec() + 2000
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame

func run():
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var manager = game.spell_manager
	var player = game.player
	var interface = game.get_node("GameplayReadability")
	check("WASD" in interface.guidance.text and "automatically" in interface.guidance.text, "Fresh run explains movement and automatic attack")
	key(KEY_1)
	key(KEY_B, 98)
	key(KEY_O, 111)
	var budget = manager.typing_slowdown_remaining
	key(KEY_ENTER)
	check(manager.is_typing and manager.current_typing_text == "bo", "Incomplete numbered Enter keeps editable input")
	check(manager.typing_slowdown_remaining <= budget, "Rejected numbered Enter never refills slowdown")
	check("Keep typing" in game.typing_label.text, "Incomplete submission receives truthful feedback")
	key(KEY_X, 120)
	key(KEY_ENTER)
	check(manager.current_typing_text == "box" and "Mismatch" in game.typing_label.text, "Mistyped numbered Enter keeps input and mismatch feedback")
	key(KEY_BACKSPACE, 0, true)
	check(manager.current_typing_text == "bo", "Repeated Backspace still edits")
	Input.action_press("move_up")
	player.handle_movement()
	check(player.velocity == Vector2.ZERO, "Typing blocks held movement")
	key(KEY_W, 119, true)
	check(manager.current_typing_text == "bo", "Held movement key echo cannot type into incantation")
	key(KEY_L, 108)
	key(KEY_T, 116)
	check(not manager.is_typing and game.spells_cast == 1, "Correction completes exactly one cast")
	player.handle_movement()
	check(player.velocity.y < 0, "Held movement resumes after completed cast")
	Input.action_release("move_up")
	player.handle_movement()
	manager.casting_clock += 1
	key(KEY_1, 0, true)
	check(not manager.is_typing, "Repeated activation key cannot reopen typing")
	click(game.spell_slots[0])
	check(manager.is_typing and manager.target_spell == "bolt", "Actual owned-slot mouse click starts guarded numbered casting")
	manager.cancel_typing()
	click(game.spell_slots[1])
	check(not manager.is_typing and manager.spells.size() == 1, "Actual empty-slot click never grants or casts spell")
	check("Learn a spell" in interface.feedback_copy, "Empty-slot click explains acquisition")
	manager.last_spell_cast_time = manager.casting_clock
	click(game.spell_slots[0])
	check(not manager.is_typing and "recovering" in interface.feedback_copy, "Mouse respects same cooldown gate")
	manager.casting_clock += 1
	manager.space_casting = true
	manager.start_freeform_typing()
	key(KEY_W, 119, true)
	check(manager.current_typing_text.is_empty(), "Space casting also ignores held printable echo")
	key(KEY_ESCAPE)
	check(not manager.is_typing and not paused, "Escape cancels typing without pausing")
	root.size = Vector2i(960, 540)
	interface.layout()
	await settle()
	game._on_player_level_up(2, {})
	game._on_player_level_up(3, {})
	await settle()
	var choices = game.level_up_screen
	check(root.gui_get_focus_owner() == choices.upgrade_buttons[0], "Actual level-up gives first visible card keyboard focus")
	var choice_scroll = choices.get_node("Panel/VBoxContainer/UpgradeScroll")
	var first_copy = choices.upgrade_buttons[0].get_node("CardText")
	check(choice_scroll.scroll_vertical == 0, "Initial short-window offer starts at top after layout settles")
	check(first_copy.get_global_rect().position.y >= choice_scroll.get_global_rect().position.y, "Initially focused card title remains visible at 540px")
	var last_copy = choices.upgrade_buttons[2].get_node("CardText")
	var original_copy = last_copy.text
	last_copy.text = original_copy.repeat(8)
	await settle()
	choice_scroll.scroll_vertical = 50
	await settle()
	check(first_copy.get_global_rect().position.y < choice_scroll.get_global_rect().position.y, "Known-bad stale scroll hides the first offer title")
	last_copy.text = original_copy
	choices.focus_first_choice()
	await settle()
	check(choice_scroll.scroll_vertical == 0, "Refocusing first choice restores its title without arrow workaround")
	for code in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		key(code, 0, true)
		check(not choices.selecting_upgrade and game.pending_level_ups.size() == 1, "Held activation echo never accepts focused offer")
	key(KEY_DOWN)
	check(root.gui_get_focus_owner() == choices.upgrade_buttons[1], "Arrow navigation moves to next offer")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == choices.upgrade_buttons[2], "Tab follows same deterministic offer order")
	choices.locks_remaining = 0
	var offered_before = choices.available_upgrades.duplicate(true)
	var banishes_before = choices.banishes_remaining
	click(choices.upgrade_buttons[0], MOUSE_BUTTON_RIGHT)
	check(choices.available_upgrades == offered_before and choices.banishes_remaining == banishes_before, "Right-click with zero locks cannot silently banish")
	choices.locks_remaining = 1
	click(choices.upgrade_buttons[0], MOUSE_BUTTON_RIGHT)
	check(0 in choices.locked_upgrades, "Right-click consistently locks")
	click(choices.upgrade_buttons[0], MOUSE_BUTTON_RIGHT)
	check(0 not in choices.locked_upgrades and choices.locks_remaining == 1, "Right-click consistently unlocks and refunds")
	choices.upgrade_buttons[0].grab_focus()
	var selected_name = choices.available_upgrades[0].name
	key(KEY_ENTER)
	await wait_for_state(func(): return choices.visible and choices.level_label.text == "Level 3" and not choices.selecting_upgrade)
	check(choices.level_label.text == "Level 3" and game.pending_level_ups.is_empty(), "One keyboard choice advances exactly one queued offer")
	check(not interface.guidance.visible, "Acknowledgement stays hidden beneath next queued offer")
	check(root.gui_get_focus_owner() == choices.upgrade_buttons[0], "Next queued offer restores first-card focus")
	key(KEY_SPACE)
	await wait_for_state(func(): return game.current_state == game.GameState.PLAYING and not paused)
	await settle()
	check(not manager.is_typing, "Offer selection does not leak Space into casting")
	check(interface.guidance.visible and not interface.feedback_copy.is_empty(), "Applied choice gets nonmodal acknowledgement")
	game._on_upgrade_selected({"name": "Empowered Spells", "description": "+10% spell damage (Currently: +0%)", "effect": {"type": "spell_damage", "value": 0.1}})
	check("+10% spell damage" in interface.feedback_copy and not "Currently" in interface.feedback_copy, "Acknowledgement shows applied change without stale pre-upgrade total")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 900), Vector2i(960, 540)]:
		root.size = geometry
		interface.layout()
		await settle()
		check(game.get_node("UI/HUD").get_global_rect().encloses(interface.guidance.get_global_rect()), "Guidance stays in viewport")
		check(not interface.guidance.get_global_rect().intersects(game.get_node("UI/HUD/SpellSlotsPanel").get_global_rect()), "Guidance stays above spell slots")
	root.size = Vector2i(1280, 720)
	interface.layout()
	player.health = 20
	player.overheal = 5
	player.take_damage(7, {"kind": "projectile", "source": "Marksman"})
	check(player.last_damage_context.health_loss == 2 and player.last_damage_context.overheal_loss == 5, "Damage context separates actual health and bonus health loss")
	var context = player.last_damage_context.duplicate(true)
	player.is_invincible = true
	player.take_damage(99, {"kind": "blast"})
	check(player.last_damage_context == context, "Invincibility never overwrites damage cause")
	player.is_invincible = false
	player.take_damage(0)
	check(player.last_damage_context == context, "Zero damage never overwrites damage cause")
	player.health = 0
	player.take_damage(99)
	check(player.last_damage_context == context, "Already-dead damage never overwrites cause")
	player.health = 18
	var shot = load("res://scripts/EnemyProjectile.gd").new()
	shot.position = player.position
	shot.damage_source = "Marksman"
	shot.damage = 2
	game.add_child(shot)
	shot.set_physics_process(false)
	shot._physics_process(0)
	check(player.last_damage_context.kind == "projectile" and player.last_damage_context.source == "Marksman", "Actual projectile path records source")
	var blast = load("res://scripts/EnemyProjectile.gd").new()
	blast.position = player.position
	blast.blast_radius = 90
	blast.warning_time = 0
	blast.damage_source = "Mortar"
	blast.damage = 3
	game.add_child(blast)
	blast.set_physics_process(false)
	blast._physics_process(0)
	check(player.last_damage_context.kind == "blast" and player.last_damage_context.source == "Mortar", "Actual area blast path records source")
	var first = Contact.new()
	var second = Contact.new()
	second.base_damage = 8
	game.add_child(first)
	game.add_child(second)
	player.health = 9
	player.overheal = 4
	player.touching_enemies = [first, second]
	player.damage_timer = 0
	player.process_enemy_contact_damage(0)
	check(player.health == 0 and player.last_damage_context.kind == "contact" and player.last_damage_context.count == 2, "Actual contact aggregator records all contributing enemies")
	check(player.last_damage_context.damage == 13, "Lethal overkill reports only actual damage taken")
	var result = game.game_over_screen
	await settle()
	result.keyboard_armed_at = Time.get_ticks_msec() + 350
	check("2 enemies" in result.defeat_label.text and "9.0 health + 4.0 bonus health" in result.defeat_label.text, "Defeat explains aggregate contact and actual loss")
	check("not recorded" in result.describe_final_hit({}), "Unknown source is explicit rather than fabricated")
	result.restart_game.disconnect(game._on_restart_game)
	result.restart_game.connect(func(): restart_count += 1)
	for code in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		key(code)
		check(restart_count == 0, "Death transition swallows immediate activation")
	result.keyboard_armed_at = 0
	key(KEY_SPACE, 0, true)
	check(restart_count == 0, "Held activation stays ignored after arming")
	key(KEY_KP_ENTER)
	check(restart_count == 1, "Fresh deliberate keypad Enter restarts after arming")
	result.action_started = false
	result.keyboard_armed_at = Time.get_ticks_msec() + 350
	click(result.play_again_button)
	check(restart_count == 2, "Explicit mouse restart remains immediate")
	result.action_started = false
	result.keyboard_armed_at = 0
	key(KEY_ENTER)
	check(restart_count == 3, "Known-bad removed arming gate permits premature restart")
	paused = false
	manager.is_typing = true
	manager.current_typing_text = "bo"
	manager.cancel_typing()
	check(not (manager.is_typing and manager.current_typing_text == "bo"), "Known-bad old cancellation violates input-preservation invariant")
	print("Gameplay UX: ", checks, " assertions, ", failures, " failures")
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	game.queue_free()
	await create_timer(0.2).timeout
	quit(1 if failures else 0)
