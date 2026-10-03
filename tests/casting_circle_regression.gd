extends SceneTree

var checks = 0
var failures = 0
const STATE = preload("res://scripts/CastingCircleState.gd")
const SPELLS = [
	{"incantation": "bolt", "element": "arcane"}, {"incantation": "life", "element": "holy"},
	{"incantation": "lightning", "element": "storm"}, {"incantation": "ice blast", "element": "ice"},
	{"incantation": "infection", "element": "plague"}, {"incantation": "meteor shower", "element": "fire"},
	{"incantation": "ember lance", "element": "fire"}, {"incantation": "cinder field", "element": "fire"},
	{"incantation": "cross blade", "element": "steel"}, {"incantation": "fire walk", "element": "fire"},
	{"incantation": "focus ray", "element": "arcane"},
]
const POWER = ["mega"]

func _initialize():
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func a(text: String) -> Dictionary:
	return STATE.analyze(text, SPELLS, POWER)

func run():
	var s = a("")
	check(s.valid and s.rune_count == 0 and s.element == "" and s.spell == "", "Empty text is valid and neutral")
	s = a("bol")
	check(s.full_rings == 1 and s.partial == 0 and s.spell == "bolt" and s.element == "arcane", "Three runes close the first ring; bolt locks")
	check(s.ring_count == 2 and s.total_runes == 4, "Bolt needs a second ring for its fourth rune")
	check(a("bolt").complete, "Typing the whole incantation completes")
	s = a("li")
	check(s.spell == "" and s.element == "" and s.candidates.size() == 2, "li is ambiguous between life and lightning")
	s = a("c")
	check(s.element == "" , "c could be fire (cinder) or steel (cross blade): neutral")
	s = a("ci")
	check(s.element == "fire" and s.spell == "cinder field", "ci locks fire and cinder field")
	s = a("ice ")
	check(s.rune_count == 3 and s.runes == "ice", "Trailing space is not a rune yet")
	s = a("ice b")
	check(s.rune_count == 5, "Inner space takes a rune slot")
	s = a("   bolt")
	check(s.rune_count == 4 and s.complete, "Leading spaces are ignored")
	s = a("me")
	check(s.element == "" and s.spell == "" and s.valid, "me could be mega or meteor: neutral")
	s = a("meg")
	check(s.forming_power_word and s.rune_count == 3, "meg can only be the power word")
	s = a("mega ")
	check(s.power_words == ["mega"] and s.rune_count == 0, "mega + space becomes a satellite")
	s = a("mega mega met")
	check(s.power_words == ["mega", "mega"] and s.spell == "meteor shower" and s.element == "fire", "Stacked power words, then the spell locks")
	s = a("mega meteor shower")
	check(s.complete and s.ring_count == 5, "Meteor shower: 13 runes over 5 rings")
	check(not a("bx").valid, "A letter that fits nothing is invalid")
	check(STATE.ring_of(0) == 0 and STATE.ring_of(2) == 0 and STATE.ring_of(3) == 1 and STATE.ring_of(8) == 2, "3-6-9 ring indexing")
	print("casting_circle_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
