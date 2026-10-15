extends SceneTree
## 0.3.2: one file per spell (data/spells/<id>.json). SpellLibrary must reassemble the five old spell
## documents exactly as they read before the split (spells added since are allowed) (tests/fixtures/spell_documents_0_3_2.bin): every
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
	# Spells added since the split (new files) are allowed; everything that existed must read back the
	# same, in the same relative order.
	var item_key = {"spells": "spells", "recipes": "recipes", "spell_shapes": "shapes", "spell_damage": "spells", "generic_spells": "spells"}
	for name in library.names():
		var now: Dictionary = library.document(name)
		check(now.keys() == old[name].keys(), "%s top-level order" % name)
		var k = item_key[name]
		for top in old[name]:
			if top != k:
				check(now[top] == old[name][top], "%s.%s unchanged" % [name, top])
		for id in old[name][k]:
			check(now[k].has(id) and now[k][id] == old[name][k][id], "%s: %s reads back exactly" % [name, id])
		if name in ["spells", "recipes", "generic_spells"]:   # catalog order matters; shapes and damage are looked up by id
			check(now[k].keys().filter(func(id): return old[name][k].has(id)) == old[name][k].keys(), "%s keeps its order" % name)
	for e in library.entries():
		check(FileAccess.file_exists("res://data/spells/%s.json" % e.id), "one file per spell: " + str(e.id))
	# Completeness: every spell a player can prepare, and every combination, carries what it needs to
	# be cast and shown (a shape with a known targeting rule, a damage entry, a description).
	var Template = load("res://scripts/engine/SpellTemplate.gd")
	var known = ["line", "select", "area", "visible_host", "free_beam", "none", "nearest", "spread"]
	for e in library.entries():
		var playable = bool(e.get("spell", {}).get("preparable", false)) or (e.has("recipe") and e.recipe.get("enabled", true)) or str(e.id) == "mana_bolt"
		if not playable:
			continue
		check(e.has("shape"), "%s has a shape" % e.id)
		check(e.has("damage") or e.get("spell", {}).has("heal_amount") or str(e.id) == "regeneration", "%s has damage types" % e.id)
		var p: Dictionary = e.get("spell", e.get("recipe", {})).get("presentation", {})
		check(p.has("summary"), "%s has a description" % e.id)
		check(str(Template.rules({"id": e.id}).get("targeting", {}).get("rule", "")) in known, "%s has a known targeting rule" % e.id)
	print("spell_library: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
