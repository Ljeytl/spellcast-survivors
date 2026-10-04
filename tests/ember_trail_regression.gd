extends SceneTree
## Ember Spear leaves a short burning line: enemies that walk into it after the throw burn.

var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 100000.0
	var dying = false
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health = maxf(0.0, current_health - amount)

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

func lance_effects() -> Array:
	return get_nodes_in_group("build_spell_effects").filter(func(e): return e.info.id == "ember_lance" and not e.is_queued_for_deletion())

func trails() -> Array:
	return get_nodes_in_group("ember_trails").filter(func(t): return not t.is_queued_for_deletion())

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	var start = game.player.global_position
	var front = Target.new()
	front.position = start + Vector2(200, 0)
	game.add_child(front)
	front.add_to_group("enemies")
	manager.learn_spell("ember_lance")
	manager.cast_freeform_spell("ember spear")
	var spear = lance_effects().back()
	spear.set_physics_process(false)
	spear.advance(0.5)
	check(front.current_health < 100000.0, "The throw hits the enemy in its line")
	check(trails().size() == 1, "The throw leaves one burning line")
	var trail = trails().back()
	trail.set_physics_process(false)
	# An enemy walks into the line after the spear has passed.
	var late = Target.new()
	late.position = start + Vector2(120, 4)
	game.add_child(late)
	late.add_to_group("enemies")
	trail.advance(0.1)
	var after_one = late.current_health
	check(after_one < 100000.0, "An enemy stepping into the line after the throw burns")
	trail.advance(0.1)
	check(late.current_health == after_one, "Burn ticks are spaced, not every frame")
	trail.advance(0.5)
	check(late.current_health < after_one, "It keeps burning while the enemy stands in the line")
	var off = Target.new()
	off.position = start + Vector2(120, 200)
	game.add_child(off)
	off.add_to_group("enemies")
	trail.advance(0.5)
	check(off.current_health == 100000.0, "Enemies beside the line do not burn")
	trail.advance(5.0)
	await process_frame
	check(trails().is_empty(), "The line burns out")
	for i in 5:
		manager.cast_freeform_spell("ember spear")
		lance_effects().back().advance(0.1)
	await process_frame
	check(trails().size() <= 3, "At most three burning lines at once")
	print("ember_trail_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
