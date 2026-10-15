extends SceneTree
## Rank-up card lines, rank caps and Magic Missile's count moved from per-spell code to data
## (spells.json rank_card_*, projectile_ranks; recipes.json max_rank). They must match 0.3.0 exactly
## for every shipped spell and combination at ranks 1-11 (tools/rank_card_fixtures.gd).

const FIXTURE = "res://tests/fixtures/rank_cards_0_3_0.bin"
const Tool = preload("res://tools/rank_card_fixtures.gd")
## Deliberate changes since 0.3.0. 0.3.2: Bolt's card said "+1 projectile" at ranks 3 and 6, but Bolt
## fires one bolt per rank up to five; the card now says it on ranks 2-5, matching what it does.
const CHANGED = {"bolt 1": "+1 projectile, +damage", "bolt 3": "+1 projectile, +damage", "bolt 4": "+1 projectile, +damage", "bolt 5": "+damage"}

var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var file = FileAccess.open(FIXTURE, FileAccess.READ)
	var expected: Array = file.get_var()
	file.close()
	var got: Array = await Tool.collect(root)
	check(got.size() == expected.size(), "same cases (%d vs %d)" % [got.size(), expected.size()])
	for i in mini(got.size(), expected.size()):
		var key = "%s %d" % [expected[i].id, expected[i].rank]
		if CHANGED.has(key):
			expected[i].summary = CHANGED[key]
		check(got[i] == expected[i], "%s rank %s: %s vs %s" % [expected[i].id, expected[i].rank, expected[i], got[i]])
	# Magic Missile fires one more missile at each of its projectile_ranks (0.3.0: 3, 6, 10).
	var ranks: Array = root.get_node("DataManager").get_all_spells().mana_bolt.projectile_ranks
	for level in range(1, 13):
		var old = 1 + int(level >= 3) + int(level >= 6) + int(level >= 10)
		check(1 + ranks.filter(func(r): return level >= int(r)).size() == old, "Magic Missile count at rank %d" % level)
	# Bolt's card promises a bolt exactly when its shape fires one more (count = rank, up to five).
	for case in got:
		if case.id == "bolt" and case.rank < 8:
			var more = mini(5, case.rank + 1) > mini(5, case.rank)
			check(case.summary.begins_with("+1 projectile") == more, "Bolt rank %d card matches its bolt count (%s)" % [case.rank, case.summary])
	print("rank_cards_data: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
