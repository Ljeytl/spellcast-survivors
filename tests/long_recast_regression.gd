extends SceneTree
## A spell kept alive by recasts (Fire Walk extended for minutes) keeps working: every recast adds
## a fresh spawn budget, so it never silently stops laying patches (found by the 0.3 solo bot matrix:
## Fire Walk stopped killing after minute six).

var checks = 0
var failures = 0

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

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var mm = game.get_node("MonsterManager")
	mm.set_process(false)
	mm.spawn_timer.stop()
	game.player.is_invincible = true
	game.player.set_physics_process(false)
	var sm = game.spell_manager
	sm.set_process(false)
	sm.learn_spell("firewalk")
	var slot = sm.find_spell_slot("firewalk")
	check(sm.cast_spell_by_type(slot), "Fire Walk casts")
	var cast = sm.last_generic_cast
	var budget = int(cast.plan.get("max_spawns", 48))
	cast.spawned = budget - 1   # as if it had been extended for minutes
	var start = game.player.global_position
	for f in 30:
		game.player.global_position = start + Vector2(f * 6.0, 0)
		await physics_frame
	var before = cast.spawned
	check(before >= budget, "Budget is spent (%d of %d)" % [before, budget])
	sm.last_spell_cast_time = -1e9
	check(sm.cast_spell_by_type(slot), "Recast extends")
	check(sm.last_generic_cast == cast, "Recast extended the same cast")
	check(int(cast.plan.max_spawns) >= budget * 2, "The recast added a fresh spawn budget")
	for f in 60:
		game.player.global_position = start + Vector2(180 + f * 6.0, 0)
		await physics_frame
	check(cast.spawned > before + 5, "Patches keep coming after the recast (%d -> %d)" % [before, cast.spawned])
	print("long_recast_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
