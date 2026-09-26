extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func press(code: int, character: int = 0):
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

func wait_real(seconds: float):
	var started = Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < seconds * 1000:
		await process_frame

func run():
	Engine.max_fps = 60
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	var player = game.player
	var spells = game.spell_manager
	player.set_physics_process(false)
	player.is_invincible = true
	var definition = manager.encounter_config.variants.pursuer.duplicate(true)
	definition.id = "pursuer"
	var enemy = manager.spawn_monster(definition)
	enemy.current_health = 10000
	enemy.max_health = 10000
	var casts: Array = []
	spells.spell_cast.connect(func(name): casts.append(name))
	await wait_real(0.5)
	var movements: Array = []
	for multiplier in [1.0, 1.1, 1.5]:
		player.cast_speed_multiplier = multiplier
		enemy.position = player.position + Vector2(300, 0)
		enemy.velocity = Vector2.ZERO
		spells.typing_slowdown_remaining = spells.typing_slowdown_capacity
		spells.mana_bolt_timer = 99999
		await wait_real(0.1)
		press(KEY_SPACE)
		check(is_equal_approx(Engine.time_scale, 0.2), "Attack-rate upgrades preserve typing protection at %.1f" % multiplier)
		var before = enemy.position
		for letter in "bolt":
			await wait_real(0.25)
			press(letter.unicode_at(0), letter.unicode_at(0))
		movements.append(enemy.position.distance_to(before))
		press(KEY_ENTER)
		check(not spells.is_typing and casts.size() == movements.size(), "Same input still completes an owned manual cast")
		check(spells.typing_slowdown_remaining > 1.8 and spells.typing_slowdown_remaining < 2.1, "One real second consumes the same bounded typing budget")
		spells.mana_bolt_timer = 0
		spells.handle_auto_attack(0)
		check(is_equal_approx(spells.mana_bolt_timer, 1.5 / multiplier), "Automatic attack cadence retains rate upgrade")
		await wait_real(0.6)
		spells.typing_slowdown_remaining = spells.typing_slowdown_capacity
		press(KEY_SPACE)
		spells.advance_typing_slowdown(3.0)
		check(spells.is_typing and is_equal_approx(Engine.time_scale, 1.0), "Rate upgrades never extend typing protection past its budget")
		press(KEY_ESCAPE)
		await wait_real(0.4)
	print("ENEMY_TRAVEL_DURING_IDENTICAL_INPUT=", movements)
	check(absf(movements[1] - movements[0]) < 2.0, "One rate upgrade does not speed enemies up during typing")
	check(absf(movements[2] - movements[0]) < 2.0, "Stacked rate upgrades do not speed enemies up during typing")
	spells.set_process(false)
	enemy.set_physics_process(false)
	player.is_invincible = false
	player.health = 100
	player.damage_timer = 0
	enemy.position = player.position + Vector2(10, 0)
	var overlap_deadline = Time.get_ticks_msec() + 1000
	while not player.touching_enemies.has(enemy) and Time.get_ticks_msec() < overlap_deadline:
		await process_frame
	check(player.touching_enemies.has(enemy), "Actual HitBox overlap registers the live enemy")
	player.process_enemy_contact_damage(0)
	check(is_equal_approx(player.health, 96), "Live contact remains damaging")
	enemy.take_damage(100000)
	check(enemy.dying and is_instance_valid(enemy), "Control reaches deferred-death window")
	player.damage_timer = 0
	player.process_enemy_contact_damage(0)
	check(is_equal_approx(player.health, 96), "Lethally hit enemy cannot deal a postmortem contact tick")
	check(player.touching_enemies.is_empty(), "Dead contact is removed before aggregate damage")
	var living = manager.spawn_monster(definition)
	living.set_physics_process(false)
	player._on_hit_box_body_entered(living)
	var queued = manager.spawn_monster(definition)
	queued.set_physics_process(false)
	player._on_hit_box_body_entered(queued)
	queued.queue_free()
	player.damage_timer = 0
	player.process_enemy_contact_damage(0)
	check(is_equal_approx(player.health, 92), "Queued removal is excluded while live contact still counts")
	check(player.last_damage_context.count == 1, "Contact explanation counts only living attackers")
	var rate_upgrade = root.get_node("DataManager").get_generic_upgrades().get("cast_speed", {})
	check(rate_upgrade.get("description", "").contains("Mana Bolt"), "Upgrade explains its actual automatic attack benefit")
	game.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await wait_real(0.25)
	print("CAST_BALANCE_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)
