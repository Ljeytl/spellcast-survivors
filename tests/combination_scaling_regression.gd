extends SceneTree

const Scaling = preload("res://scripts/CombinationScaling.gd")
var checks = 0
var failures = 0

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func recipe(id: String, own: int = 1, ranks: Dictionary = {}) -> Dictionary:
	return Scaling.resolve({"id": id, "level": own, "damage": 40, "rank_steps": [{"projectile_count": 99}]}, ranks)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	var life = recipe("life_bolt", 1, {"bolt": 5, "life": 3})
	check(is_equal_approx(life.damage, Scaling.ingredient_damage("bolt", 5, 0.0)) and life.damage > Scaling.ingredient_damage("bolt", 1, 0.0), "Bolt rank increases only impact potency")
	check(life.projectile_count == 1, "Ingredient count upgrades are not inherited")
	check(is_equal_approx(life.healing_seed_amount, 7.8), "Life rank improves healing budget")
	check(not life.has("rank_steps"), "Combination has no copied ingredient upgrade tree")
	check(recipe("life_bolt", 2).projectile_count == 2, "Life Bolt rank two adds bolt")
	check(recipe("life_bolt", 3).projectile_count == 2, "Rank three keeps count")
	check(recipe("life_bolt", 3).healing_seed_radius > recipe("life_bolt", 2).healing_seed_radius, "Rank three increases healing radius")
	var lightning = recipe("lightning_bolt", 4, {"bolt": 2, "lightning_arc": 3})
	check(is_equal_approx(lightning.damage, Scaling.ingredient_damage("bolt", 2, 0.0)), "Bolt controls Lightning Bolt direct hit")
	check(is_equal_approx(lightning.splash_damage, Scaling.ingredient_damage("lightning_arc", 3, 0.0)) and lightning.splash_damage > Scaling.ingredient_damage("lightning_arc", 1, 0.0), "Lightning controls splash damage")
	check(is_equal_approx(lightning.splash_radius, 88.0), "Lightning controls splash radius")
	check(lightning.bounce_count == 7, "Own Lightning Bolt level controls bounces")
	check(recipe("lightning_bolt", 8).damage == recipe("lightning_bolt").damage, "Bounce ranks do not secretly multiply damage")
	var meteor = recipe("meteor_lance", 2, {"ember_lance": 3, "meteor_shower": 4})
	check(is_equal_approx(meteor.damage, Scaling.ingredient_damage("ember_lance", 3, 0.0) * 1.1), "Ember and own ranks scale lance")
	check(is_equal_approx(meteor.explosion_damage, Scaling.ingredient_damage("meteor_shower", 4, 0.0) * 0.8 * 1.1), "Meteor and own ranks scale explosion")
	var soul = recipe("soul_bloom", 3, {"plague_seed": 3, "regeneration": 5})
	check(is_equal_approx(soul.damage, Scaling.ingredient_damage("plague_seed", 3, 9.0)) and soul.damage > Scaling.ingredient_damage("plague_seed", 1, 9.0), "Plague controls infection damage through its own rank curve")
	check(is_equal_approx(soul.healing_bloom_amount, 9.6), "Regeneration controls healing budget")
	check(is_equal_approx(soul.orphan_lifetime, 6.0), "Own Soul rank improves lingering spore")
	var steam = recipe("steam_field", 2, {"cinder_field": 3, "ice_blast": 5})
	check(is_equal_approx(steam.damage, Scaling.ingredient_damage("cinder_field", 3, 12.0)) and steam.damage > 12.0, "Cinder controls field damage through its own rank curve")
	check(is_equal_approx(steam.slow, 0.5), "Ice controls Steam slow")
	check(steam.duration > 5.0, "Steam no duration penalty")
	var prism = recipe("prism_ray", 3, {"focus_ray": 3, "ember_lance": 3})
	check(is_equal_approx(prism.damage, Scaling.ingredient_damage("focus_ray", 3, 0.0) * 1.4 * (1.0 + 0.05 * 2 + 0.1 * 2)), "Prism rank contributions additive")
	check(prism.beam_turn_speed == 0.25, "Prism tracks at a very slow rate")
	check(prism.beam_radius == 32.0, "Prism broad footprint")
	var frost = recipe("frost_sigil", 5, {"rune_trap": 3, "ice_blast": 3})
	check(is_equal_approx(frost.damage, Scaling.ingredient_damage("rune_trap", 3, 0.0) * 1.25), "Rune controls Frost damage")
	check(is_equal_approx(frost.trap_radius, 204.0), "Frost ingredient radii add")
	check(is_equal_approx(frost.arm_delay, 0.8), "Own Frost levels shorten arming")
	check(recipe("frost_sigil", 99).arm_delay == 0.4, "Arming floor preserved")
	for id in ["life_bolt", "lightning_bolt", "meteor_lance", "soul_bloom", "steam_field", "prism_ray", "frost_sigil"]:
		var info = recipe(id)
		check(info.combination_scaled and not info.has("damage_multiplier"), id + " has explicit resolved damage")
	print("COMBINATION SCALING: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
