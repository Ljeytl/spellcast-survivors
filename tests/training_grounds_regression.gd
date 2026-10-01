extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		printerr("Use the isolated Synergy Test profile")
		quit(2)
		return
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run():
	root.size = Vector2i(1280, 720)
	var RunMode = load("res://scripts/RunMode.gd")
	var character = root.get_node("CharacterManager")
	var discoveries = character.discovered_synergies.duplicate()
	RunMode.training = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 5:
		await process_frame
	var training = game.get_node_or_null("TrainingGrounds")
	check(training != null, "Training flag starts Training Grounds")
	var manager = game.spell_manager
	check(not game.style_session.eligible, "Training never reaches the leaderboard")
	check(manager.spells.size() == 16 and manager.bonus_spells.size() == training.available_ids().size() - 16, "Every spell and combination is equipped")
	check(manager.cast_freeform_spell("cross blade") and manager.cast_freeform_spell("soul bloom"), "Spells past slot six and combinations cast by name")
	var dummies = get_nodes_in_group("training_dummies")
	check(dummies.size() == 4 + training.CLUSTER_SIZE, "Static dummies and moving cluster spawn")
	var target = training.static_dummies[0]
	target.take_damage(1.0e6, game.player.global_position, {"spell": "bolt", "cast_clock": 0.0})
	await process_frame
	check(is_instance_valid(target) and not target.dying, "Dummy survives any hit")
	check(game.style_session.damage_by_spell.get("bolt", 0.0) >= 1.0e6, "Dummy damage feeds the readout")
	var start = training.cluster[0].global_position
	training._process(1.0)
	for i in 10:
		await physics_frame
	check(training.cluster[0].global_position.distance_to(start) > 1.0, "Cluster moves")
	# Knockback shoves a dummy off its spot and it walks back.
	var pushed = training.static_dummies[1]
	var home = pushed.training_anchor
	pushed.apply_knockback(Vector2.UP, 600.0)
	for i in 4:
		await physics_frame
	check(pushed.global_position.distance_to(home) > 20.0, "Knockback moves a dummy")
	for i in 90:
		await physics_frame
	check(pushed.global_position.distance_to(home) < 3.0, "Dummy returns home after knockback")
	# A slowed dummy covers less ground than an unslowed one chasing the same offset.
	var slowed = training.static_dummies[2]
	var normal_dummy = training.static_dummies[3]
	slowed.apply_slow(0.25, 2.0)
	var slowed_start = slowed.global_position
	var normal_start = normal_dummy.global_position
	slowed.training_anchor += Vector2(300, 0)
	normal_dummy.training_anchor += Vector2(300, 0)
	for i in 30:
		await physics_frame
	var slowed_moved = slowed.global_position.distance_to(slowed_start)
	var normal_moved = normal_dummy.global_position.distance_to(normal_start)
	check(slowed_moved > 1.0 and slowed_moved < normal_moved * 0.5, "Slow cuts a dummy's speed (%.0f vs %.0f)" % [slowed_moved, normal_moved])
	check(slowed.slow_multiplier < 1.0 and slowed.slow_timer < 2.0, "Slow timer runs down on dummies")
	training.toggle("lightning_arc")
	check(not manager.acquired_spells.has("lightning_arc") and not manager.acquired_spells.has("lightning_bolt"), "Switching off an ingredient removes its combination")
	training.toggle("lightning_arc")
	training.toggle("lightning_bolt")
	check(manager.acquired_spells.has("lightning_bolt"), "Combination switches back on with both ingredients")
	check(character.discovered_synergies == discoveries, "Training combinations are not recorded as discoveries")
	training.change_rank("bolt", 20)
	check(manager.get_spell_rank("bolt") == training.MAX_RANK, "Rank control clamps at the training maximum")
	training.reset_damage()
	check(training.total_damage() == 0.0, "Reset clears the readout")
	game.free()
	RunMode.training = false
	await process_frame
	var normal = load("res://scenes/Game.tscn").instantiate()
	root.add_child(normal)
	await process_frame
	check(normal.get_node_or_null("TrainingGrounds") == null and normal.spell_manager.slot_limit == 6, "Normal runs keep the bench out and six slots")
	normal.free()
	await process_frame
	print("Training grounds: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
