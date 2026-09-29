extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func shield_effect():
	for effect in get_nodes_in_group("effect_bursts"):
		if effect.kind == "stone" and effect.followed and not effect.is_queued_for_deletion():
			return effect
	return null

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	var info = game.spell_manager.spell_catalog.earth_shield.duplicate(true)
	game.spell_manager.spells[2] = info
	game.spell_manager.cast_earthshield_spell(2)
	var effect = shield_effect()
	check(is_equal_approx(game.player.overheal_timer, 16), "Actual protection starts at sixteen seconds")
	check(effect != null and is_equal_approx(effect.duration, 16), "Visible stones use the same sixteen seconds")
	if effect == null:
		print("Shield duration: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	effect.set_process(false)
	game.player.handle_overheal_expiration(15.9)
	effect._process(15.9)
	check(game.player.overheal > 0 and not effect.is_queued_for_deletion(), "Shield and stones survive beyond the old five/eight-second durations")
	game.player.handle_overheal_expiration(0.11)
	effect._process(0.11)
	check(game.player.overheal == 0 and effect.is_queued_for_deletion(), "Protection and stones expire together at sixteen seconds")
	game.spell_manager.cast_earthshield_spell(2)
	effect = shield_effect()
	effect.set_process(false)
	game.player.handle_overheal_expiration(10)
	game.spell_manager.cast_earthshield_spell(2)
	var refreshed = shield_effect()
	refreshed.set_process(false)
	check(effect.is_queued_for_deletion() and refreshed != effect, "Recast replaces old stones")
	check(is_equal_approx(game.player.overheal_timer, 22) and is_equal_approx(refreshed.duration, 22), "Recast adds full duration to six remaining seconds")
	game.player.take_damage(game.player.overheal)
	refreshed._process(0.01)
	check(game.player.overheal == 0 and refreshed.is_queued_for_deletion(), "Depleted shield removes stones immediately")
	game.spell_manager.spells[2].duration = 21.0
	game.spell_manager.cast_earthshield_spell(2)
	check(is_equal_approx(game.player.overheal_timer, 21) and is_equal_approx(shield_effect().duration, 21), "Runtime and visuals follow authored duration, not a hardcoded value")
	game.queue_free()
	await process_frame
	print("Shield duration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
