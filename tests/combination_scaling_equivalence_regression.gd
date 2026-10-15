extends SceneTree
## Combination growth moved from code to data/recipes.json ("scaling", "rank_note") must give
## exactly what 0.3.0 gave: every field, value and type, for every combination over its own rank
## and four ingredient ranks each, and every level-up line (tools/combination_scaling_fixtures.gd).

const CombinationScaling = preload("res://scripts/CombinationScaling.gd")
const FIXTURE = "res://tests/fixtures/combination_scaling_0_3_0.bin"

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	var file = FileAccess.open(FIXTURE, FileAccess.READ)
	var cases = file.get_var()
	file.close()
	check(cases is Array and cases.size() > 1000, "fixture loads")
	var failed := {}
	for case in cases:
		if case.has("note"):
			check(CombinationScaling.next_description(case.id, case.rank) == case.note, "%s rank %d note: %s vs %s" % [case.id, case.rank, case.note, CombinationScaling.next_description(case.id, case.rank)])
			continue
		var got = CombinationScaling.resolve(case.data, case.ranks)
		var d = diff(case.expected, got)
		if d != "" and not failed.has(case.id):
			failed[case.id] = true
			check(false, "%s own %s ranks %s: %s" % [case.id, case.data.level if case.data.has("level") else "?", case.ranks, d])
		else:
			checks += 1
	print("combination_scaling_equivalence: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func diff(a, b, at: String = "$") -> String:
	if typeof(a) != typeof(b):
		return "%s: %s (%s) vs %s (%s)" % [at, a, type_string(typeof(a)), b, type_string(typeof(b))]
	if a is Dictionary:
		for k in a:
			if not b.has(k):
				return "%s.%s missing" % [at, k]
		for k in b:
			if not a.has(k):
				return "%s.%s extra" % [at, k]
			var d = diff(a[k], b[k], "%s.%s" % [at, k])
			if d != "":
				return d
		return ""
	if a is Array:
		if a.size() != b.size():
			return "%s: size %d vs %d" % [at, a.size(), b.size()]
		for i in a.size():
			var d = diff(a[i], b[i], "%s[%d]" % [at, i])
			if d != "":
				return d
		return ""
	return "" if a == b else "%s: %s vs %s (diff %s)" % [at, a, b, a - b] if a is float else "%s: %s vs %s" % [at, a, b]
