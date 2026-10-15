extends SceneTree
## Co-op-ready rules (doc 19 §6.1), enforced as a ratchet.
##   Rule 2: no global player/game lookups (group lookups or absolute /root/Game paths).
##   Rule 5: no unseeded randomness in gameplay code (use scripts/core/Rng.gd). Global rand*(),
##   shuffle/pick_random (global generator) and rng.randomize() all count.
## tests/coop_rules_allowlist.json records today's violations per file. A new violation fails.
## Removing one also fails until the allowance is lowered, so the list only ever shrinks.
## Presentation-only scripts are exempt from rule 5 (doc 19 P5).

const ALLOWLIST = "res://tests/coop_rules_allowlist.json"
const PRESENTATION = ["res://scripts/vfx/", "res://scripts/CastingCircle.gd", "res://scripts/Background.gd",
	"res://scripts/CameraShake.gd", "res://scripts/AudioManager.gd",
	"res://scripts/core/Rng.gd"]  # the seeded source itself picks a random seed when a run has none
const RULES = {
	"no_global_player_lookup": "get_(first_node|nodes)_in_group\\(\"(player|game)\"\\)|\"/root/Game[^\"]*\"|get_node\\(\"\\.\\./Player\"\\)",
	"no_unseeded_random": "(?<![\\w.])(randf|randi|randf_range|randi_range|randfn|randomize)\\(|\\.(shuffle|pick_random|randomize)\\(",
}

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func scripts_in(dir: String, out: Array) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		scripts_in(dir.path_join(sub), out)

func is_presentation(path: String) -> bool:
	for prefix in PRESENTATION:
		if path.begins_with(prefix):
			return true
	return false

## Counts matches outside comments.
func count(path: String, regex: RegEx) -> int:
	var n := 0
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var code = line.split("#")[0] if not "\"#" in line else line
		n += regex.search_all(code).size()
	return n

func run():
	var allow: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ALLOWLIST))
	var files: Array = []
	scripts_in("res://scripts", files)
	var report := {}
	for rule in RULES:
		var regex = RegEx.create_from_string(RULES[rule])
		var allowed: Dictionary = allow.get(rule, {})
		report[rule] = {}
		for path in files:
			if rule == "no_unseeded_random" and is_presentation(path):
				continue
			var n = count(path, regex)
			var key = path.trim_prefix("res://")
			if n > 0:
				report[rule][key] = n
			var limit = int(allowed.get(key, 0))
			check(n <= limit, "%s: %s has %d (allowed %d). Use the caster interface / actor registry (rule 2) or Rng streams (rule 5)." % [rule, key, n, limit])
			check(n >= limit, "%s: %s is down to %d, lower its allowance in %s from %d (the list only shrinks)" % [rule, key, n, ALLOWLIST, limit])
		for key in allowed:
			check(FileAccess.file_exists("res://" + key), "%s: allow-listed file %s no longer exists; remove it from the list" % [rule, key])
	if failures > 0:
		print("Current counts: ", JSON.stringify(report))
	print("coop_rules_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
