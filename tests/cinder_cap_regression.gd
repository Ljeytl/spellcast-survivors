extends SceneTree
## Cinder Field at its 3-field cap: a recast extends the field already covering the horde,
## otherwise moves the emptiest field to the horde. Fields never sit extended on empty ground.

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

func fields() -> Array:
	return get_nodes_in_group("build_spell_effects").filter(func(e): return e.info.id == "cinder_field" and not e.is_queued_for_deletion())

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
	var horde: Array = []
	for i in 3:
		var t = Target.new()
		t.position = start + Vector2(120, i * 10)
		game.add_child(t)
		t.add_to_group("enemies")
		horde.append(t)
	manager.learn_spell("cinder_field")
	for i in 3:
		manager.cast_freeform_spell("cinder field")
	await process_frame
	check(fields().size() == 3, "Three fields at the cap")
	manager.cast_freeform_spell("cinder field")
	await process_frame
	check(fields().size() == 3, "Recast on a covered horde does not add a fourth field")
	# The horde walks away; the old fields now sit on empty ground.
	var away = start + Vector2(-300, 0)
	for i in horde.size():
		horde[i].position = away + Vector2(0, i * 10)
	manager.cast_freeform_spell("cinder field")
	await process_frame
	var covered = false
	for f in fields():
		if f.global_position.distance_to(away) <= float(f.info.get("radius", 150.0)):
			covered = true
	check(fields().size() == 3, "Still three fields after moving one")
	check(covered, "Recast moves an empty field onto the horde instead of extending it in place")
	print("cinder_cap_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
