extends SceneTree
## Doc 19 step 1b: stats as base + modifiers with sources; the wizard's passives are modifiers
## and give the same numbers as the old += fields.

const StatBlock = preload("res://scripts/engine/stats/StatBlock.gd")

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001

func run():
	# Arithmetic: (base + Σadd) × Π(1 + mul); override wins; sources remove exactly their modifiers.
	var s = StatBlock.new({"power": 1.0, "speed": 300.0})
	check(near(s.value("power"), 1.0) and near(s.value("speed"), 300.0), "Bases read back")
	s.add_modifier("power", "add", 0.1, "passive:a")
	s.add_modifier("power", "add", 0.1, "passive:a")
	s.add_modifier("power", "mul", 0.2, "ley")
	check(near(s.value("power"), 1.2 * 1.2), "(1 + 0.2) × 1.2 = %s" % s.value("power"))
	check(s.remove_source("ley") == 1 and near(s.value("power"), 1.2), "Removing a source removes its modifiers only")
	s.add_modifier("speed", "mul", -0.5, "status:slowed")
	s.add_modifier("speed", "mul", -0.5, "status:chilled")
	check(near(s.value("speed"), 75.0), "Multipliers compound: 300 × 0.5 × 0.5")
	s.add_modifier("speed", "override", 0.0, "status:frozen")
	check(near(s.value("speed"), 0.0), "Override wins")
	s.remove_source("status:frozen")
	check(near(s.value("speed"), 75.0), "Removing the override restores the computed value")
	s.set_value("power", 2.0)
	check(near(s.value("power"), 2.0) and s.has_source("passive:a"), "set_value hits the target and keeps modifiers")
	s.remove_source("passive:a")
	check(near(s.value("power"), 1.8), "Base was adjusted under the modifiers (2.0 − 0.2)")
	check(near(s.value("unknown"), 0.0), "Unknown stats read as 0")
	var changed: Array = []
	s.changed.connect(func(stat): changed.append(stat))
	s.add_modifier("power", "add", 1.0, "x")
	check(changed == ["power"], "changed fires per stat")
	check(s.snapshot().has("power") and s.snapshot().has("speed"), "Snapshot lists every stat")

	# The wizard: passive picks are modifiers with the same numbers as before.
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var player = game.player
	check(near(player.spell_damage_multiplier, 1.0) and near(player.max_health, 100.0), "Starting stats unchanged")
	var picks = [["spell_damage", 0.15], ["spell_damage", 0.15], ["spell_area", 0.2], ["spell_duration", 0.25],
		["movement_speed", 0.1], ["xp_range", 0.5], ["projectile_speed", 0.2], ["slowdown_duration", 0.5], ["max_health", 20.0]]
	var expected = {"spell_damage_multiplier": 1.3, "spell_size_multiplier": 1.2, "spell_duration_multiplier": 1.25,
		"movement_speed_multiplier": 1.1, "xp_range_multiplier": 1.5, "projectile_speed_multiplier": 1.2, "typing_duration_bonus": 0.5, "max_health": 120.0}
	var health_before = player.health
	for i in picks.size():
		if i == 6:
			player.passive_ranks = {}  # the six-family cap is not what this test is about
		var pick = picks[i]
		check(player.apply_upgrade({"effect": {"type": pick[0], "value": pick[1]}}), "Pick %s accepted" % pick[0])
	for stat in expected:
		check(near(float(player.get(stat)), expected[stat]), "%s = %s after picks (got %s)" % [stat, expected[stat], player.get(stat)])
	check(near(player.health, health_before + 20.0), "A max-health pick also heals by the same amount")
	check(player.stats.modifiers("spell_damage_multiplier").size() == 2 and player.stats.modifiers("spell_damage_multiplier")[0].source == "passive:spell_damage", "Each pick is a modifier with a passive source")
	player.passive_ranks = {}
	player.apply_upgrade({"effect": {"type": "mana_bolt_mastery"}})
	check(near(player.cast_speed_multiplier, 1.1), "Mana bolt mastery adds 0.1 cast speed")
	player.spell_damage_multiplier = 2.0
	check(near(player.spell_damage_multiplier, 2.0), "Direct assignment still sets the value (console, tests)")
	check(near(float(player.get("spell_size_multiplier")), 1.2), "Object.get reads through the stat block")

	print("stat_block_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
