extends SceneTree
## Per-spell presentation moved from code tables to spell data (presentation.*). For every shipped
## spell and combination it must match 0.3.1 exactly: description, cast sound, whether the cast plays
## it, inventory icon, spellbook preview and projectile scale (tools/presentation_fixtures.gd). A spell
## with no presentation data gets element/shape defaults.

const FIXTURE = "res://tests/fixtures/presentation_0_3_1.bin"

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
	var Catalog = load("res://scripts/engine/SpellCatalog.gd")
	var copy = load("res://scripts/UpgradeCopy.gd")
	var audio = root.get_node("AudioManager")
	var file = FileAccess.open(FIXTURE, FileAccess.READ)
	var cases: Dictionary = file.get_var()
	file.close()
	check(cases.size() == 25, "all 25 spells recorded")
	for id in cases:
		var want: Dictionary = cases[id]
		check(copy.summary(id) == want.summary, "%s description: %s vs %s" % [id, want.summary, copy.summary(id)])
		check(int(audio.spell_sound_type(id)) == want.sound, "%s cast sound" % id)
		check(Catalog.sound_on_cast(id) == want.sound_on_cast, "%s plays its sound on cast" % id)
		check(Catalog.icon(id) == want.icon, "%s icon: %s vs %s" % [id, want.icon, Catalog.icon(id)])
		check(Catalog.preview(id) == want.preview, "%s preview: %s vs %s" % [id, want.preview, Catalog.preview(id)])
		check(Catalog.projectile_scale(id) == want.projectile_scale, "%s projectile scale" % id)
	# A spell with no presentation data: defaults from its element (fire) and its shape.
	check(Catalog.sound("no_such_spell") == "SPELL_BOLT" and Catalog.icon("no_such_spell") == "rune", "unknown spell falls back")
	print("presentation_data: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
