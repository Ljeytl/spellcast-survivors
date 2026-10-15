extends SceneTree
## The spell lists that were code constants in 0.3.0 now come from data/spells.json
## ("preparable", "opens_kit", "preparation"). They must equal the 0.3.0 values exactly.


var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	run.call_deferred()

func run():
	var SpellManagerScript = load("res://scripts/SpellManager.gd")
	var Preparation = load("res://scripts/Preparation.gd")
	check(SpellManagerScript.BASE_SPELL_IDS == ["bolt", "life", "regeneration", "ice_blast", "earth_shield", "lightning", "meteor_shower", "ember_spear", "infestation", "cinder_field", "arcane_orbit", "focus_ray", "rune_trap", "seeker", "firewalk", "cross_blade"], "preparable spells in 0.3.0 order: %s" % [SpellManagerScript.BASE_SPELL_IDS])
	check(Preparation.SLOTS == 6 and typeof(Preparation.SLOTS) == TYPE_INT, "six slots")
	check(Preparation.ACTIVATION_LEVELS == [1, 2, 4, 7, 11, 16] and Preparation.ACTIVATION_LEVELS.all(func(l): return typeof(l) == TYPE_INT), "activation levels")
	check(Preparation.NON_ATTACK == ["life", "regeneration", "earth_shield"], "spells that cannot open the kit: %s" % [Preparation.NON_ATTACK])
	check(Preparation.DEFAULT_SLOTS == ["bolt", "ice_blast", "lightning", "life", "meteor_shower", "ember_spear"], "default kit")
	check(Preparation.can_start("bolt") and not Preparation.can_start("life"), "slot 1 rule reads the data")
	print("spell_lists_data: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
