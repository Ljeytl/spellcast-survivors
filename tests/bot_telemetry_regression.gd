extends "res://tools/bot_player.gd"

var checks = 0
var test_failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run_checks.call_deferred()

func _process(_delta):
	return false

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		test_failures += 1
		printerr("FAIL: ", message)

func run_checks():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	previous_health = game.player.health
	previous_overheal = game.player.overheal
	game.player.health_changed.connect(observe_health)
	game.player.player_damaged.connect(observe_damage)
	game.player.take_damage(6, {"kind": "contact", "count": 1})
	check(damage_by_kind.get("contact", 0) == 6, "Actual contact damage recorded")
	game.player.take_damage(0, {"kind": "projectile"})
	check(damage_by_kind.size() == 1 and damage_by_kind.contact == 6 and damage_events.size() == 1, "Zero damage does not repeat stale context")
	game.player.add_overheal(20)
	game.spell_manager.is_typing = true
	game.player.take_damage(8, {"kind": "projectile", "source": "Marksman"})
	check(damage_by_kind.get("projectile", 0) == 8 and damage_while_typing == 8, "Shield absorption is attributed while typing")
	check(damage_taken == 6, "Shield absorption is not health loss")
	game.player.handle_overheal_expiration(100)
	check(damage_by_kind.projectile == 8 and damage_events.size() == 2, "Shield expiration alone is not combat damage")
	game.player.take_damage(0)
	check(damage_by_kind.projectile == 8 and damage_events.size() == 2, "Zero hit after shield expiration remains ignored")
	game.player.is_invincible = true
	game.player.take_damage(10, {"kind": "blast"})
	check(not damage_by_kind.has("blast"), "Invincible hit contributes no damage")
	game.player.is_invincible = false
	game.spell_manager.is_typing = false
	game.player.heal(6)
	for i in range(15):
		game.player.take_damage(1, {"kind": "contact", "count": 1})
	check(damage_events.size() == 12, "Recent history stays bounded")
	check(damage_by_kind.contact == 21 and damage_taken == 21, "Healing does not erase accumulated actual loss")
	check(damage_while_typing == 8, "Non-typing damage does not inflate typing total")
	game.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.25).timeout
	print("BOT_TELEMETRY_CHECKS=", checks, " FAILURES=", test_failures)
	quit(1 if test_failures else 0)
