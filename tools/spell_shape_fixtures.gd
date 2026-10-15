extends SceneTree
## Records what the 0.3.0 code-built spell shapes (LegacyBridge) produce for every shipped spell
## and combination over a grid of ranks, sizes, durations, speeds and damage, so the data shapes in
## data/spell_shapes.json can be proved identical (tests/spell_shape_equivalence_regression.gd).
## Ran once against the 0.3.0 code builders (since deleted); kept as the record of how the fixture was made.

const OUT = "res://tests/fixtures/spell_shapes_0_3_0.bin"   # binary: exact floats
const Bridge = preload("res://scripts/engine/SpellTemplate.gd")
const Progression = preload("res://scripts/SpellProgression.gd")
const CombinationScaling = preload("res://scripts/CombinationScaling.gd")
const Geometry = preload("res://scripts/SpellGeometry.gd")
const Synergies = preload("res://scripts/SynergyCatalog.gd")
const SpellManagerScript = preload("res://scripts/SpellManager.gd")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var manager = game.spell_manager
	var player = game.player
	var bases: Dictionary = {}
	# Magic Missile's cast info is built in SpellManager.fire_mana_bolt (count by level).
	bases.mana_bolt = {"id": "mana_bolt", "type": "mana_bolt", "name": "Magic Missile", "projectile_count": 1}
	for id in SpellManagerScript.BASE_SPELL_IDS:
		bases[id] = manager.spell_catalog[id].duplicate(true) if manager.spell_catalog.has(id) else null
	for id in Synergies.RECIPES:
		var recipe = Synergies.RECIPES[id]
		var bonus = manager.spell_catalog[recipe.ingredients[0]].duplicate(true)
		bonus.merge(recipe.overrides, true)
		bonus.erase("rank_steps")
		var growth = bonus.get("rank_growth", {})
		for key in growth:
			if growth[key].has("max"):
				bonus[key] = growth[key].max
		bonus.erase("rank_growth")
		bonus.id = id
		bonus.name = recipe.name
		bonus.display_name = recipe.incantation
		bases[id] = bonus
	var cases: Array = []
	var variants = [[1.0, 1.0, 1.0, 1.0], [1.42, 1.5, 0.8, 1.0], [0.7, 2.0, 1.3, 1.42], [1.0, 1.0, 1.0, 1.81]]
	for id in bases:
		if bases[id] == null:
			printerr("missing base ", id)
			continue
		for level in range(1, 13):
			for v in variants:
				var info = bases[id].duplicate(true)
				info.level = level
				if id == "mana_bolt":
					info.projectile_count = 1 + int(level >= 3) + int(level >= 6) + int(level >= 10)
				info = Progression.resolve(info)
				if id in Synergies.RECIPES:
					var ranks := {}
					for ing in Synergies.RECIPES[id].ingredients:
						ranks[ing] = level
					info = CombinationScaling.resolve(info, ranks)
				info.keyword_size_multiplier = v[3]
				info.keyword_stats = {"spell_size_multiplier": v[0], "spell_duration_multiplier": v[1]}
				var pre = info.duplicate(true)
				var scaled = Geometry.scaled_data(info, player)
				var damage = 37.5 * level * v[0]
				var ctx = {"speed_mult": v[2]}
				var t = str(scaled.get("type", ""))
				if t == "heal":
					ctx.heal = 10.0 + level
				if t == "heal_over_time":
					ctx.heal_rate = 2.0 + level
					ctx.duration = 5.0 * v[1]
				if t == "shield":
					ctx = {"damage": 60.0 * level, "reach": 160.0 * v[0], "half_angle": deg_to_rad(50.0 * v[3]), "knockback": 500.0, "travel_time": 0.22 * v[1]}
					damage = 0.0
				if not Bridge.has_shape(id):
					printerr("not ported: ", id, " ", t)
					continue
				cases.append({"id": id, "pre": pre, "info": scaled, "damage": damage, "ctx": ctx, "expected": Bridge.build(scaled, damage, ctx)})
	var f = FileAccess.open(OUT, FileAccess.WRITE)
	f.store_var(cases)
	f.close()
	print("wrote %d cases for %d spells" % [cases.size(), bases.size()])
	quit(0)
