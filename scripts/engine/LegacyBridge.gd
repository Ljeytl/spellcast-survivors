extends RefCounted
## Doc 18 §14 phase 2: the shipping spells, rebuilt as generic definitions one at a time.
##
## A ported spell keeps every number it had: SpellManager resolves rank, combination scaling,
## passives and MEGA exactly as before (resolve_cast_info, SpellGeometry.scaled_data,
## calculate_spell_damage) and hands the results here. This file only says what shape the spell
## is. Damage mixes and statuses come from data/spell_damage.json, as they did for the old hits.
## Hitboxes keep their old reach (geometry.pad 0: the old spells did not add an enemy radius).

const SpellDamage = preload("res://scripts/engine/SpellDamage.gd")
const SpellGeometry = preload("res://scripts/SpellGeometry.gd")

## Old spell types that now run on the generic engine.
const PORTED = ["piercing"]

static func handles(info: Dictionary) -> bool:
	return str(info.get("type", "")) in PORTED

## info: resolved and size-scaled spell data. damage: the old per-hit damage.
## ctx: {speed_mult}. Returns a generic definition for CastPlanner.
static func build(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	match str(info.get("type", "")):
		"piercing":
			return _spear(info, damage, ctx)
	return {}

static func _damage(spell_id: String, amount: float, part: String = "") -> Array:
	var p = SpellDamage.profile(spell_id)
	var out: Array = [{"type": "damage", "amount": amount, "mix": p.damage}]
	for rule in SpellDamage.statuses_for(spell_id, part):
		out.append({"type": "status", "status": str(rule.status), "strength": float(rule.get("strength", 1.0))})
	return out

static func _shell(info: Dictionary, root: String, parts: Dictionary) -> Dictionary:
	var id = str(info.id)
	return {"id": id, "name": str(info.get("name", id)), "incantation": str(info.get("incantation", id)),
		"element": SpellDamage.profile(id).element, "root": root, "parts": parts, "legacy": true,
		"max_spawns": 400}

## Ember Spear (and Meteor Spear): a fast piercing spear that leaves a burning line (doc 18 §11.1).
static func _spear(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var radius = float(info.get("spear_radius", SpellGeometry.SPEAR_RADIUS)) * float(info.get("projectile_size_multiplier", 1.0))
	var speed = 700.0 * float(ctx.get("speed_mult", 1.0))
	var flight = 1.5
	var spear := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": radius, "pad": 0.0},
		"motion": [{"type": "straight", "speed": speed, "range": speed * flight}],
		"payload": _damage(id, damage),
		"limits": {"pierce": -1},
		"vfx": {"family": "spear"},
	}
	var parts := {"spear": spear}
	if bool(info.get("burn_trail", false)):
		spear.trail = {"part": "trail"}
		parts.trail = {
			"delivery": "field", "origin": "parent",
			"geometry": {"type": "line", "length": 0.0, "width": radius * 2.0, "pad": 0.0},
			"timing": {"duration": flight + float(info.get("burn_duration", 1.5)), "interval": float(info.get("burn_tick", 0.5)), "per_target": true},
			"payload": _damage(id, damage * float(info.get("burn_tick_ratio", 0.12)), "trail"),
			"limits": {"cap": 3},
			"vfx": {"style": "smoulder"},
		}
	if bool(info.get("explosive", false)):
		spear.events = {"on_hit": {"part": "blast", "exclude_hit": true}}
		parts.blast = {
			"delivery": "volume", "origin": "parent",
			"geometry": {"type": "disk", "radius": float(info.get("explosion_radius", 90.0 * float(info.get("spell_size_multiplier", 1.0)))), "pad": 0.0},
			"payload": _damage(id, float(info.get("explosion_damage", damage * 0.5))),
		}
	return _shell(info, "spear", parts)
