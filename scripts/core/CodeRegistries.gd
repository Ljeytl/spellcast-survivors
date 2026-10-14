extends RefCounted
## Ids that are still defined in code rather than data, so data files may reference them.
## Every entry here is a migration debt: doc 19 step 3 moves combinations into spell data,
## and this file shrinks to nothing.

const Synergies = preload("res://scripts/SynergyCatalog.gd")

static func all() -> Dictionary:
	var spells: Array = Synergies.RECIPES.keys()
	spells.append("atomic")  # style ability (StyleSession); a damage source with a damage profile
	return {"spell": spells}
