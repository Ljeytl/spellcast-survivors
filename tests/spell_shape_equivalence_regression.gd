extends SceneTree
## Spell shapes moved from code (0.3.0 LegacyBridge builders) to data/spell_shapes.json must build
## exactly the same generic definitions: same keys, same values, same types. The fixture holds the
## 0.3.0 builders' output for every shipped spell and combination over ranks 1-12 and four size /
## duration / speed / keyword-size variants (tools/spell_shape_fixtures.gd).

const SpellTemplate = preload("res://scripts/engine/SpellTemplate.gd")
const FIXTURE = "res://tests/fixtures/spell_shapes_0_3_0.txt"

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

## First difference between two values, "" when identical (types included).
func diff(a, b, at: String = "$") -> String:
	if typeof(a) != typeof(b):
		return "%s: %s (%s) vs %s (%s)" % [at, a, type_string(typeof(a)), b, type_string(typeof(b))]
	if a is Dictionary:
		for k in a:
			if not b.has(k):
				return "%s.%s missing in data shape" % [at, k]
		for k in b:
			if not a.has(k):
				return "%s.%s extra in data shape" % [at, k]
			var d = diff(a[k], b[k], "%s.%s" % [at, k])
			if d != "":
				return d
		return ""
	if a is Array:
		if a.size() != b.size():
			return "%s: %d items vs %d" % [at, a.size(), b.size()]
		for i in a.size():
			var d = diff(a[i], b[i], "%s[%d]" % [at, i])
			if d != "":
				return d
		return ""
	if a is float:
		return "" if a == b or is_equal_approx(a, b) else "%s: %s vs %s" % [at, a, b]
	return "" if a == b else "%s: %s vs %s" % [at, a, b]

func run():
	var cases = str_to_var(FileAccess.get_file_as_string(FIXTURE))
	check(cases is Array and cases.size() >= 1200, "fixture loads (%s cases)" % (cases.size() if cases is Array else -1))
	var ids := {}
	var failed_ids := {}
	for case in cases:
		ids[case.id] = true
		check(SpellTemplate.has_shape(case.id), "%s has a data shape" % case.id)
		var built = SpellTemplate.build(case.info, case.damage, case.ctx)
		var d = diff(case.expected, built)
		if d != "" and not failed_ids.has(case.id):
			failed_ids[case.id] = true
			check(false, "%s rank %s: %s" % [case.id, case.info.get("level", "?"), d])
		else:
			checks += 1
	check(ids.size() == 25, "all 25 shipped spells and combinations covered (%d)" % ids.size())
	# Every shipped spell names a targeting rule SpellManager.pick_target knows (cast_rules, data).
	var known = ["line", "select", "area", "visible_host", "free_beam", "none", "nearest", "spread"]
	for id in ids:
		var rule = str(SpellTemplate.rules({"id": id}).get("targeting", {}).get("rule", ""))
		check(rule in known, "%s has a known targeting rule (%s)" % [id, rule])
	print("spell_shape_equivalence: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
