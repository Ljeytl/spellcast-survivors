extends RefCounted
## Old internal spell ids -> new ones (doc 18 §11.3). Saves written before the rename load through here.

const RENAMED = {
	"ember_lance": "ember_spear",
	"meteor_lance": "meteor_spear",
	"lightning_arc": "lightning",
	"seeking_spirit": "seeker",
	"ember_trail": "firewalk",
	"returning_blade": "cross_blade",
	"plague_seed": "infestation",
}

static func id(value) -> String:
	return str(RENAMED.get(str(value), str(value)))

## Renames and de-duplicates, keeping order.
static func ids(values) -> Array:
	var out: Array = []
	if not values is Array:
		return out
	for v in values:
		var renamed = id(v)
		if not out.has(renamed):
			out.append(renamed)
	return out
