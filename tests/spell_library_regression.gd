extends SceneTree
## 0.3.2: one file per spell (data/spells/<id>.json). SpellLibrary must reassemble the five old spell
## documents exactly as they read before the split (tests/fixtures/spell_documents_0_3_2.bin): every
## value, and the key order of spells, recipes and generic spells (catalog order matters).

var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	var library = load("res://scripts/core/SpellLibrary.gd")
	var f = FileAccess.open("res://tests/fixtures/spell_documents_0_3_2.bin", FileAccess.READ)
	var old: Dictionary = f.get_var()
	f.close()
	for name in library.names():
		var now: Dictionary = library.document(name)
		check(now == old[name], "%s reassembles exactly" % name)
		check(now.keys() == old[name].keys(), "%s top-level order" % name)
	check(library.document("spells").spells.keys() == old.spells.spells.keys(), "spell catalog order")
	check(library.document("recipes").recipes.keys() == old.recipes.recipes.keys(), "recipe order")
	check(library.document("generic_spells").spells.keys() == old.generic_spells.spells.keys(), "generic spell order")
	for e in library.entries():
		check(FileAccess.file_exists("res://data/spells/%s.json" % e.id), "one file per spell: " + str(e.id))
	print("spell_library: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
