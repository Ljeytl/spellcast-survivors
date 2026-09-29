extends SceneTree

var checks = 0
var failures = 0

func check(value, label):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var pickup_script = load("res://scripts/StylePickup.gd")
	var health_script = load("res://scripts/HealthPotion.gd")
	var position = game.player.position + Vector2(500, 0)
	for script in [pickup_script, health_script]:
		check(script.DROP_CHANCE == 0.01, "drop chance exactly one percent")
		for roll in [0.01, 0.5, 1.0]:
			check(script.try_drop(game, position, roll) == null, "failed boundary roll %s" % roll)
		for roll in [0.0, 0.009999]:
			var drop = script.try_drop(game, position, roll)
			check(drop != null, "successful boundary roll %s" % roll)
			drop.free()
	var score = game.style_session.score
	score.combo = 750
	score.grace_remaining = 1.25
	score.freshness = {"bolt": 0.5}
	score.receipts = {12: true}
	var updates = [0]
	var promotions = [false]
	game.style_session.updated.connect(func(): updates[0] += 1)
	game.style_session.feedback.connect(func(_text, promoted): promotions[0] = promoted)
	var pickup = pickup_script.try_drop(game, position, 0.0)
	game.current_state = game.GameState.PAUSED
	check(not pickup.collect(), "paused game cannot collect")
	game.current_state = game.GameState.PLAYING
	game.player.health = 0
	check(not pickup.collect(), "dead player cannot collect")
	game.player.health = game.player.max_health
	var reentrant = [true]
	game.style_session.updated.connect(func(): reentrant[0] = pickup.collect(), CONNECT_ONE_SHOT)
	check(pickup.collect(), "full health player can collect style")
	check(not reentrant[0], "signal callbacks cannot collect the same pickup twice")
	check(score.combo == 950, "two hundred raw combo across rank boundary")
	check(score.run_score == 200, "pre-promotion multiplier used")
	check(score.rank_index() == 1 and score.peak_rank == 1 and score.peak_combo == 950, "rank and peak refreshed")
	check(updates[0] == 1 and promotions[0], "one UI update with promotion feedback")
	check(not pickup.collect() and score.run_score == 200, "pickup awards exactly once")
	check(score.manual_casts == 0 and score.clean_casts == 0, "pickup is not a cast")
	check(score.freshness == {"bolt": 0.5} and score.receipts == {12: true}, "cast history unchanged")
	check(score.grace_remaining == 1.25, "pickup does not fake active casting")
	await process_frame
	score.combo = 11950
	var award = score.award_pickup()
	check(score.combo == score.CAP and score.peak_combo == score.CAP, "raw combo cap enforced")
	check(award.banked == 1200 and score.run_score == 1400, "high rank multiplier applies to score only")
	var capped = pickup_script.try_drop(game, position, 0.0)
	check(capped.collect(), "capped combo still collects for run score")
	check(score.combo == score.CAP and score.run_score == 2600, "cap does not discard score award")
	await process_frame
	game.style_session.finalized = true
	var final_drop = pickup_script.try_drop(game, position, 0.0)
	check(not final_drop.collect() and score.run_score == 2600, "finished run cannot gain score")
	final_drop.free()
	for i in range(pickup_script.MAX_DROPS):
		pickup_script.try_drop(game, position, 0.0)
	check(pickup_script.try_drop(game, position, 0.0) == null, "bounded outstanding pickups")
	for drop in get_nodes_in_group("style_pickups"):
		drop.position += Vector2(10000, 10000)
	check(pickup_script.try_drop(game, position, 0.0) != null, "distant pickups can be replaced")
	check(get_nodes_in_group("style_pickups").size() == pickup_script.MAX_DROPS, "replacement preserves cap")
	print("style_pickup_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
