extends SceneTree
## Records the 0.3.1 per-spell presentation tables that lived in code (UpgradeCopy text, AudioManager
## cast sounds, InventoryIcon kinds, SpellBookPreview glyphs/colours, VisualDefaults projectile scales)
## so moving them to spell data can be proved identical (tests/presentation_data_regression.gd).
## The icon and preview rules below are verbatim copies of the 0.3.1 code. Ran once.

const OUT = "res://tests/fixtures/presentation_0_3_1.bin"

func _initialize():
	run.call_deferred()

func run():
	var copy = load("res://scripts/UpgradeCopy.gd")
	var audio = root.get_node("AudioManager")
	var ids: Array = ["mana_bolt"] + load("res://scripts/SpellManager.gd").BASE_SPELL_IDS + preload("res://scripts/SynergyCatalog.gd").RECIPES.keys()
	var cases := {}
	for id in ids:
		cases[id] = {
			"summary": copy.EVOLUTIONS.get(id, copy.SPELLS.get(id, "")),
			"in_spells": copy.SPELLS.has(id), "in_evolutions": copy.EVOLUTIONS.has(id),
			"sound": int(audio.spell_sound_type(id)),
			"sound_on_cast": id.to_lower().replace(" ", "_") != "lightning",
			"icon": old_icon(id),
			"preview": old_preview(id),
			"projectile_scale": float(load("res://scripts/VisualDefaults.gd").PROJECTILE_SCALES.get(id, 1.0)),
		}
	var f = FileAccess.open(OUT, FileAccess.WRITE)
	f.store_var(cases)
	f.close()
	print("wrote %d spells" % cases.size())
	quit(0)

static func old_icon(item_id: String) -> String:
	if item_id == "focus_ray":
		return "beam"
	var kind = "rune"
	for entry in [["cinder", "flame"], ["soul", "heal"], ["meteor", "meteor"], ["lightning", "lightning"], ["prism", "prism"], ["focus", "mana"], ["blade", "blade"], ["bolt", "bolt"], ["life", "heal"], ["regeneration", "heal"], ["health", "heal"], ["ice", "ice"], ["frost", "ice"], ["fire", "flame"], ["ember", "spear"], ["plague", "plague"], ["spirit", "spirit"], ["seeker", "spirit"], ["shield", "stone"], ["orbit", "orbit"], ["steam", "steam"]]:
		if entry[0] in item_id:
			kind = entry[1]
			break
	return {"bolt": "mana", "firewalk": "ember", "life_bolt": "heal", "lightning_bolt": "lightning", "meteor_spear": "spear"}.get(item_id, kind)

static func old_preview(spell_id: String) -> Dictionary:
	var color = "bc8fff"
	if spell_id in ["life", "regeneration", "life_bolt", "infestation", "soul_bloom"]:
		color = "91de83"
	elif spell_id in ["ice_blast", "frost_sigil", "steam_field"]:
		color = "8ce6ee"
	elif spell_id in ["ember_spear", "cinder_field", "meteor_shower", "meteor_spear", "firewalk"]:
		color = "ffa66b"
	elif spell_id in ["lightning", "lightning_bolt"]:
		color = "f4ed96"
	var glyph = "bolt"
	match spell_id:
		"life", "regeneration": glyph = "cross"
		"ice_blast": glyph = "cone"
		"lightning", "lightning_bolt": glyph = "zigzag"
		"cinder_field", "steam_field", "rune_trap", "frost_sigil", "arcane_orbit": glyph = "ring"
		"earth_shield": glyph = "rocks"
		"focus_ray", "prism_ray", "ember_spear", "meteor_spear": glyph = "beam"
		"meteor_shower", "firewalk": glyph = "meteors"
		"cross_blade": glyph = "arc"
	return {"glyph": glyph, "color": color}
