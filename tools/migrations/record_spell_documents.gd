extends SceneTree
## Records the five per-concern spell documents as parsed before the 0.3.2 split (one-time).
func _initialize():
	var docs := {}
	for name in ["spells", "recipes", "spell_shapes", "spell_damage", "generic_spells"]:
		docs[name] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))
	var f = FileAccess.open("res://tests/fixtures/spell_documents_0_3_2.bin", FileAccess.WRITE)
	f.store_var(docs)
	f.close()
	print("recorded ", docs.keys())
	quit(0)
