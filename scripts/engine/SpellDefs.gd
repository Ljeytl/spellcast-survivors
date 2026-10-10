extends RefCounted
## Loads and validates generic spell definitions (data/generic_spells.json, doc 18 §4).

const DATA_PATH = "res://data/generic_spells.json"
const DELIVERIES = ["projectile", "volume", "field", "aura", "trap", "self"]
const GEOMETRIES = ["body", "disk", "ring", "cone", "line", "rect"]
const MOTIONS = ["straight", "guided", "spiral", "orbit", "none"]
const PAYLOADS = ["damage", "status", "impulse", "heal"]
const EVENTS = ["on_hit", "on_first_hit", "on_kill", "on_expire", "on_tick", "on_travel", "on_trigger"]
const ORIGINS = ["caster", "target", "parent", "behind_caster"]
const PROPAGATIONS = ["instant", "expanding", "travelling"]
const ELEMENTS = ["", "arcane", "fire", "water", "storm", "earth", "plague", "life"]

static var _spells: Dictionary = {}
static var _extra: Dictionary = {}

static func all() -> Dictionary:
	if _spells.is_empty():
		var file = FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for id in parsed.get("spells", {}):
					var d: Dictionary = parsed.spells[id]
					d["id"] = id
					_spells[id] = d
	var merged = _spells.duplicate()
	merged.merge(_extra, true)
	return merged

static func get_def(id: String) -> Dictionary:
	return all().get(id, {})

## Tests and future content can add definitions at runtime.
static func register(def: Dictionary) -> Array:
	var errors = validate(def)
	if errors.is_empty():
		_extra[str(def.id)] = def
	return errors

static func unregister(id: String) -> void:
	_extra.erase(id)

static func by_incantation() -> Dictionary:
	var out := {}
	var spells = all()
	for id in spells:
		out[str(spells[id].get("incantation", id)).to_lower()] = id
	return out

static func bare_incantations() -> Array:
	var out := []
	var spells = all()
	for id in spells:
		if str(spells[id].get("acquire", "")) == "bare":
			out.append(str(spells[id].get("incantation", id)).to_lower())
	return out

static func validate(def: Dictionary) -> Array:
	var errors := []
	var id = str(def.get("id", "?"))
	for key in ["id", "name", "incantation", "parts", "root"]:
		if not def.has(key):
			errors.append(id + ": missing " + key)
	if not errors.is_empty():
		return errors
	if not str(def.get("element", "")) in ELEMENTS:
		errors.append(id + ": unknown element " + str(def.element))
	var parts: Dictionary = def.parts
	if not parts.has(def.root):
		errors.append(id + ": root part " + str(def.root) + " missing")
	for name in parts:
		var p: Dictionary = parts[name]
		var where = id + "." + str(name)
		if not str(p.get("delivery", "")) in DELIVERIES:
			errors.append(where + ": unknown delivery " + str(p.get("delivery", "")))
		if p.has("origin") and not str(p.origin) in ORIGINS:
			errors.append(where + ": unknown origin " + str(p.origin))
		if p.has("geometry") and not str(p.geometry.get("type", "")) in GEOMETRIES:
			errors.append(where + ": unknown geometry " + str(p.geometry.get("type", "")))
		if str(p.get("delivery", "")) in ["projectile"] and not p.has("motion"):
			errors.append(where + ": projectile needs motion")
		for phase in p.get("motion", []):
			if not str(phase.get("type", "")) in MOTIONS:
				errors.append(where + ": unknown motion " + str(phase.get("type", "")))
		if p.has("propagation") and not str(p.propagation.get("type", "")) in PROPAGATIONS:
			errors.append(where + ": unknown propagation " + str(p.propagation.get("type", "")))
		for item in p.get("payload", []):
			if not str(item.get("type", "")) in PAYLOADS:
				errors.append(where + ": unknown payload " + str(item.get("type", "")))
			if str(item.get("type", "")) == "status" and not preload("res://scripts/engine/StatusComponent.gd").definitions().has(str(item.get("status", ""))):
				errors.append(where + ": unknown status " + str(item.get("status", "")))
		for ev in p.get("events", {}):
			if not str(ev) in EVENTS:
				errors.append(where + ": unknown event " + str(ev))
			elif not parts.has(str(p.events[ev].get("part", ""))):
				errors.append(where + ": event " + str(ev) + " points to missing part " + str(p.events[ev].get("part", "")))
	return errors
