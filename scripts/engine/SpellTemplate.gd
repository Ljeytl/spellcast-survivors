extends RefCounted
## Spell shapes as data (doc 19 §4.1, P1): data/spell_shapes.json holds, per spell id, the parts a
## cast is made of. A template is the generic definition CastPlanner reads, with these additions:
##
##   "=<expression>"            a value computed when the spell is cast (Godot Expression syntax).
##                              Inputs: damage, speed (projectile speed stat), level, and the helpers
##                              v(key, default) (resolved spell info), c(key, default) (cast context),
##                              has(key), is_id(id), mix(part), stacks(part, status), pick(cond, a, b).
##   {"$damage": "part"}        inside an array: the part's damage item and status items from
##                              data/spell_damage.json ("" = the spell's own profile). Optional
##                              "amount": an expression for the hit (default: damage).
##   {"$statuses": "part"}      inside an array: only the part's status items.
##   "$when": "<expression>"    on any object: dropped (from its array or parent object) when false.
##   {"$choose": [ ... ]}       the first option whose "$when" holds (or that has none); an option
##                              {"value": x} gives a plain value. No match: the key is left out.
##   "$extends": "<spell id>"   at the top of a template: deep-merges this template over that one.
##   "by_type" (file level)     the shape for an info whose id has no entry, by its old spell type
##                              (ad-hoc infos in tests and tools; goes away with spell types).
##   "cast_rules"               how the spell is cast rather than what it is made of: "targeting"
##                              {rule, ...settings}, "context" (values computed from the caster's
##                              stats: power, duration_stat, size_stat), "points", "lanes", "picker",
##                              "cast" (a custom cast handler). Read with rules(); not part of the shape.
##   "$recast": true            at the top: the recast rule from the spell info (recast_behavior,
##                              active_limit, extend_at_cap, max_banked_casts).
##
## Number literals become int for the keys in INT_KEYS (JSON has one number type).

const SpellDamage = preload("res://scripts/engine/SpellDamage.gd")
const SpellGeometry = preload("res://scripts/SpellGeometry.gd")
const DATA_PATH = "res://data/spell_shapes.json"
const INT_KEYS = ["pierce", "cap", "count", "max_depth", "max_spawns", "hops", "targets", "status_repeat"]
const INPUTS = ["damage", "speed", "level", "BOLT_RADIUS", "SPEAR_RADIUS", "BEAM_RADIUS", "SPIRIT_RADIUS"]

static var _shapes: Dictionary = {}
static var _by_type: Dictionary = {}
const SKIP = "\u0000skip"
static var _loaded := false
static var _parsed: Dictionary = {}

static func shapes() -> Dictionary:
	if not _loaded:
		_loaded = true
		var doc = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_shapes = doc.get("shapes", {}) if doc is Dictionary else {}
		_by_type = doc.get("by_type", {}) if doc is Dictionary else {}
	return _shapes

static func has_shape(id: String) -> bool:
	return shapes().has(id)

## The shape entry an info builds from: its own id, else its old spell type's.
static func shape_id(info: Dictionary) -> String:
	var id = str(info.get("id", ""))
	if shapes().has(id):
		return id
	return str(_by_type.get(str(info.get("type", "")), ""))

## The template for a spell id with "$extends" resolved.
static func template(id: String) -> Dictionary:
	var t: Dictionary = shapes().get(id, {})
	if t.has("$extends"):
		var merged = _deep_merge(template(str(t["$extends"])), t)
		merged.erase("$extends")
		return merged
	return t.duplicate(true)

## info: resolved and size-scaled spell data. damage: the per-hit damage. ctx: {speed_mult, heal, ...}.
## Returns a generic definition for CastPlanner ({} when the spell has no shape).
static func build(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.get("id", ""))
	var shape = shape_id(info)
	if shape == "":
		return {}
	var env = Env.new(info, ctx, id)
	var inputs = [damage, float(ctx.get("speed_mult", 1.0)), int(info.get("level", 1)),
		SpellGeometry.BOLT_RADIUS, SpellGeometry.SPEAR_RADIUS, SpellGeometry.BEAM_RADIUS, SpellGeometry.SPIRIT_RADIUS]
	env.inputs = inputs
	env.damage = damage
	env.cache = _parsed
	var t = template(shape)
	var recast = bool(t.get("$recast", false))
	t.erase("$recast")
	t.erase("cast_rules")
	var def: Dictionary = _eval(t, env, "")
	var shell := {"id": id, "name": str(info.get("name", id)), "incantation": str(info.get("incantation", id)),
		"element": SpellDamage.profile(id).element, "legacy": true, "max_spawns": 400}
	shell.merge(def, true)
	if recast:
		shell.recast = recast_rule(info)
	return shell

## The spell's cast rules (targeting, context, pickers), evaluated for this info and context.
static func rules(info: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var shape = shape_id(info)
	if shape == "":
		return {}
	var r = template(shape).get("cast_rules", {})
	if r.is_empty():
		return {}
	var env = Env.new(info, ctx, str(info.get("id", "")))
	env.inputs = [0.0, float(ctx.get("speed_mult", 1.0)), int(info.get("level", 1)),
		SpellGeometry.BOLT_RADIUS, SpellGeometry.SPEAR_RADIUS, SpellGeometry.BEAM_RADIUS, SpellGeometry.SPIRIT_RADIUS]
	env.cache = _parsed
	return _eval(r, env, "")

## How a recast meets the casts already out (recast_behavior / active_limit / extend_at_cap).
static func recast_rule(info: Dictionary) -> Dictionary:
	var r := {"behavior": str(info.get("recast_behavior", "stack")), "cap": int(info.get("active_limit", 3)),
		"extend_at_cap": bool(info.get("extend_at_cap", false))}
	if info.has("max_banked_casts"):
		r.max_banked = float(info.max_banked_casts)
	return r

## A part's damage and statuses from data/spell_damage.json.
static func damage_items(spell_id: String, amount: float, part: String = "") -> Array:
	var p = SpellDamage.profile(spell_id, part)
	var out: Array = [{"type": "damage", "amount": amount, "mix": p.damage}]
	out.append_array(status_items(spell_id, part))
	return out

static func status_items(spell_id: String, part: String = "") -> Array:
	var out: Array = []
	for rule in SpellDamage.statuses_for(spell_id, part):
		out.append(status_item(rule))
	return out

## One status rule as a payload item: strength, stacks, duration and flags pass through.
static func status_item(rule: Dictionary) -> Dictionary:
	var item := {"type": "status", "status": str(rule.status), "strength": float(rule.get("strength", 1.0))}
	for k in ["stacks", "duration", "no_freeze", "no_stun"]:
		if rule.has(k):
			item[k] = rule[k]
	return item

# --- evaluation -------------------------------------------------------------------------------

static func _eval(value, env, key: String):
	if value is String:
		if value.begins_with("="):
			return env.run(value.substr(1))
		return value
	if value is float:
		return int(value) if key in INT_KEYS and is_equal_approx(value, roundf(value)) else value
	if value is Array:
		var out: Array = []
		for item in value:
			if item is Dictionary and item.has("$damage"):
				if _holds(item, env):
					var amount = env.run(str(item.amount).substr(1)) if item.has("amount") else env.damage
					out.append_array(damage_items(env.id, float(amount), str(item["$damage"])))
			elif item is Dictionary and item.has("$statuses"):
				if _holds(item, env):
					out.append_array(status_items(env.id, str(item["$statuses"])))
			elif item is Dictionary and not _holds(item, env):
				continue
			else:
				out.append(_eval(item, env, key))
		return out
	if value is Dictionary:
		if value.has("$choose"):
			for option in value["$choose"]:
				if _holds(option, env):
					return _eval(option.value, env, key) if option.has("value") else _eval(option, env, key)
			return SKIP
		var out := {}
		for k in value:
			if k == "$when":
				continue
			var child = value[k]
			if child is Dictionary and not _holds(child, env):
				continue
			var result = _eval(child, env, str(k))
			if result is String and result == SKIP:
				continue
			out[k] = result
		return out
	return value

static func _holds(d: Dictionary, env) -> bool:
	return not d.has("$when") or bool(env.run(str(d["$when"])))

static func _deep_merge(base: Dictionary, over: Dictionary) -> Dictionary:
	var out = base.duplicate(true)
	for k in over:
		if out.get(k) is Dictionary and over[k] is Dictionary:
			out[k] = _deep_merge(out[k], over[k])
		else:
			out[k] = over[k] if not (over[k] is Dictionary or over[k] is Array) else over[k].duplicate(true)
	return out

## Expression helpers. Each expression string is parsed once.
class Env:
	var info: Dictionary
	var ctx: Dictionary
	var id: String
	var inputs: Array
	var damage: float
	var cache: Dictionary
	func _init(i: Dictionary, c: Dictionary, spell_id: String):
		info = i
		ctx = c
		id = spell_id
	func v(key: String, default = null):
		return info.get(key, default)
	func c(key: String, default = null):
		return ctx.get(key, default)
	func has(key: String) -> bool:
		return info.has(key)
	func is_id(spell_id: String) -> bool:
		return id == spell_id
	func pick(cond, a, b):
		return a if cond else b
	func mix(part: String) -> Dictionary:
		return SpellDamage.profile(id, part).damage
	func stacks(part: String, status: String) -> int:
		var n = 1
		for rule in SpellDamage.profile(id, part).statuses:
			if str(rule.status) == status:
				n = maxi(1, int(rule.get("stacks", 1)))
		return n
	func run(source: String):
		var e: Expression = cache.get(source)
		if e == null:
			e = Expression.new()
			if e.parse(source, INPUTS) != OK:
				push_error("spell_shapes.json %s: cannot parse '%s': %s" % [id, source, e.get_error_text()])
				return null
			cache[source] = e
		var result = e.execute(inputs, self)
		if e.has_execute_failed():
			push_error("spell_shapes.json %s: '%s' failed: %s" % [id, source, e.get_error_text()])
			return null
		return result
