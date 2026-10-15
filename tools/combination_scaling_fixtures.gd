extends SceneTree
## Records what the 0.3.0 code combination scaling (CombinationScaling.resolve / next_description)
## produced for every combination over its own rank and its ingredients' ranks, so the data rules in
## data/recipes.json ("scaling", "rank_note") can be proved identical
## (tests/combination_scaling_equivalence_regression.gd). Ran once against the code rules.

const OUT = "res://tests/fixtures/combination_scaling_0_3_0.bin"   # binary: exact floats
const CombinationScaling = preload("res://scripts/CombinationScaling.gd")
const Synergies = preload("res://scripts/SynergyCatalog.gd")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	var spells = preload("res://scripts/core/GameData.gd").file("spells").spells
	var cases: Array = []
	for id in Synergies.RECIPES:
		var recipe = Synergies.RECIPES[id]
		var bonus = spells[recipe.ingredients[0]].duplicate(true)
		bonus.merge(recipe.overrides, true)
		bonus.id = id
		for own in range(1, 13):
			for a in [1, 3, 8, 12]:
				for b in [1, 4, 8, 12]:
					var info = bonus.duplicate(true)
					info.level = own
					var ranks = {recipe.ingredients[0]: a, recipe.ingredients[1]: b}
					cases.append({"id": id, "data": info, "ranks": ranks, "expected": CombinationScaling.resolve(info, ranks)})
		for rank in range(1, 13):
			cases.append({"id": id, "rank": rank, "note": CombinationScaling.next_description(id, rank)})
	# an id with no combination rules passes through untouched
	cases.append({"id": "bolt", "data": spells.bolt.duplicate(true), "ranks": {}, "expected": CombinationScaling.resolve(spells.bolt, {})})
	var f = FileAccess.open(OUT, FileAccess.WRITE)
	f.store_var(cases)
	f.close()
	print("wrote %d cases" % cases.size())
	quit(0)
