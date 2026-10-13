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
const PORTED = ["piercing", "projectile", "aoe", "heal", "direct_strike", "chain", "trap", "field", "orbit", "multi_aoe"]

static func handles(info: Dictionary) -> bool:
	return str(info.get("type", "")) in PORTED

## info: resolved and size-scaled spell data. damage: the old per-hit damage.
## ctx: {speed_mult}. Returns a generic definition for CastPlanner.
static func build(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	match str(info.get("type", "")):
		"piercing":
			return _spear(info, damage, ctx)
		"projectile":
			return _bolt(info, damage, ctx)
		"aoe":
			return _ice_blast(info, damage, ctx)
		"heal":
			return _life(info, ctx)
		"direct_strike", "chain":
			return _lightning(info, damage, ctx)
		"trap":
			return _trap(info, damage, ctx)
		"field":
			return _field(info, damage, ctx)
		"orbit":
			return _orbit(info, damage, ctx)
		"heal_over_time":
			return _regeneration(info, ctx)
		"multi_aoe":
			return _meteor_shower(info, damage, ctx)
	return {}

## How a recast meets the casts already out (the old recast_behavior / active_limit / extend_at_cap).
static func _recast(info: Dictionary) -> Dictionary:
	var r := {"behavior": str(info.get("recast_behavior", "stack")), "cap": int(info.get("active_limit", 3)),
		"extend_at_cap": bool(info.get("extend_at_cap", false))}
	if info.has("max_banked_casts"):
		r.max_banked = float(info.max_banked_casts)
	return r

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

## Bolt: one bolt per rank up to five, 0.12 s apart, each aimed when it leaves at the enemy
## worth hitting (overkill-aware); a contact hits everything the bolt overlaps, then it is spent.
static func _bolt(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var count = mini(5, maxi(1, int(info.get("level", 1))))
	var speed = 500.0 * float(ctx.get("speed_mult", 1.0))
	var bolt := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": SpellGeometry.BOLT_RADIUS * float(info.get("projectile_size_multiplier", 1.0)), "pad": "hurtbox"},
		"motion": [{"type": "straight", "speed": speed, "range": speed * 3.0}],
		"payload": _damage(id, damage),
		"limits": {"pierce": 0, "contact_all": true},
		"vfx": {"family": "bolt"},
	}
	var def = _shell(info, "bolt", {"bolt": bolt})
	def.arrangement = {"type": "single", "count": count}
	def.release = {"type": "staggered", "interval": 0.12, "retarget": true}
	return def

## Ice Blast: a fan of shards (a full ring by rank 8) toward the nearest enemy. Every shard deals
## full damage; the push (stronger up close) and the slow land once per enemy per cast.
static func _ice_blast(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var size = float(info.get("spell_size_multiplier", 1.0))   # scaled_data: passive size x keyword size
	var cone = float(info.get("cone_degrees", 90.0))
	var count = maxi(1, int(round(cone / float(info.degrees_per_shard))) if info.has("degrees_per_shard") else int(info.get("shard_count", 13)))
	var speed = 620.0 * float(ctx.get("speed_mult", 1.0))
	var knockback = float(info.get("knockback", 400)) + (int(info.get("level", 1)) - 1) * 50.0
	var payload = _damage(id, damage)
	payload.append({"type": "impulse", "direction": "travel", "force": knockback, "falloff": [2.0, 1.2], "once_per_cast": true})
	payload.append({"type": "slow", "factor": float(info.get("slow_effect", 0.3)), "duration": float(info.get("slow_duration", 2.0)), "once_per_cast": true})
	var shard := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": 12.0 * size, "pad": "hurtbox"},
		"motion": [{"type": "straight", "speed": speed, "range": float(info.get("radius", 400.0))}],
		"payload": payload,
		"limits": {"pierce": int(info.get("shard_pierce", 0))},
		"vfx": {"family": "bolt", "look": "ice"},
	}
	var def = _shell(info, "shard", {"shard": shard})
	if cone >= 359.0:
		def.arrangement = {"type": "ring", "count": count, "radius": 0.0}
	else:
		def.arrangement = {"type": "fan", "count": count, "spread": cone / maxf(1.0, count - 1.0)}
	return def

## Life: heal the caster at once.
static func _life(info: Dictionary, ctx: Dictionary) -> Dictionary:
	var self_part := {"delivery": "self", "origin": "caster", "payload": [{"type": "heal", "amount": float(ctx.get("heal", 0.0)), "visual_size": float(info.get("keyword_size_multiplier", 1.0))}]}
	var def = _shell(info, "self", {"self": self_part})
	def.element = "life"
	return def

## Lightning: a brief storm circle on the group worth striking; nothing if there is none.
static func _lightning(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var strike := {
		"delivery": "volume", "origin": "target",
		"geometry": {"type": "disk", "radius": float(info.get("radius", 160.0)), "pad": 0.0},
		"propagation": {"type": "instant"},
		"payload": _damage(id, damage),
	}
	var def = _shell(info, "strike", {"strike": strike})
	def.needs_target = true
	return def

## Rune Trap (and Frost Sigil): a rune laid toward the nearest enemy (at most 160 away). It arms,
## waits for as long as it takes, and bursts when an enemy steps inside its trigger.
static func _trap(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var blast_payload = _damage(id, damage)
	if bool(info.get("frost", false)):
		blast_payload.append({"type": "slow", "factor": 1.0 - float(info.get("slow", 0.4)), "duration": float(info.get("slow_duration", 2.0))})
	var rune := {
		"delivery": "trap", "origin": "toward_target", "reach": 160.0,
		"geometry": {"type": "disk", "radius": float(info.get("trigger_radius", 70.0)), "pad": 0.0},
		"timing": {"arming": float(info.get("arm_delay", 0.8)), "duration": 1.0e9},
		"events": {"on_trigger": {"part": "burst"}},
	}
	var cap = int(info.get("active_limit", 999))
	if cap < 999:
		rune.limits = {"cap": cap}
	var burst := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": float(info.get("trap_radius", 130.0)), "pad": 0.0},
		"propagation": {"type": "instant"},
		"payload": blast_payload,
	}
	return _shell(info, "rune", {"rune": rune, "burst": burst})

## Cinder Field (and Steam Field): a burning circle on the group worth hitting (where the caster
## stands if there is none). First pulse after one interval, then every interval.
static func _field(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var payload = _damage(id, damage)
	if float(info.get("slow", 0.0)) > 0.0:
		payload.append({"type": "slow", "factor": 1.0 - float(info.slow), "duration": 0.7})
	var field := {
		"delivery": "field", "origin": "target_or_caster",
		"geometry": {"type": "disk", "radius": float(info.get("radius", 150.0)), "pad": 0.0},
		"timing": {"interval": float(info.get("tick_interval", 0.5)), "duration": float(info.get("duration", 5.0)), "delay_first": true},
		"payload": payload,
	}
	var def = _shell(info, "field", {"field": field})
	def.recast = _recast(info)
	return def

## Arcane Orbit: sparks circle the caster; one hit cooldown per enemy across all sparks.
static func _orbit(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var orb := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": float(info.get("body_radius", 42.0)), "pad": 0.0},
		"motion": [{"type": "orbit", "speed": float(info.get("angular_speed", 4.0)) * float(ctx.get("speed_mult", 1.0)), "radius": float(info.get("orbit_radius", 130.0))}],
		"payload": _damage(id, damage),
		"limits": {"pierce": -1, "rehit": float(info.get("tick_interval", 0.5)), "rehit_shared": true, "lifetime": float(info.get("duration", 6.0))},
	}
	var def = _shell(info, "orb", {"orb": orb})
	def.arrangement = {"type": "ring", "count": maxi(1, int(info.get("orb_count", 3))), "radius": float(info.get("orbit_radius", 130.0))}
	def.recast = _recast(info)
	return def

## Regeneration: healing flows for the duration; a recast adds a full duration (not a faster rate).
static func _regeneration(info: Dictionary, ctx: Dictionary) -> Dictionary:
	var aura := {
		"delivery": "aura", "origin": "caster", "anchor": "caster",
		"geometry": {"type": "disk", "radius": 34.0 * float(info.get("keyword_size_multiplier", 1.0))},
		"timing": {"duration": float(ctx.get("duration", info.get("duration", 5.0)))},
		"heal_rate": float(ctx.get("heal_rate", 0.0)),
		"visual_size": float(info.get("keyword_size_multiplier", 1.0)),
		"payload": [],
	}
	var def = _shell(info, "aura", {"aura": aura})
	def.element = "life"
	def.recast = _recast(info)
	return def

## Meteor Shower: meteors on ground points picked at cast time (the old weighted pick that
## spreads them over the horde). Every mark shows at once; the first lands after
## warning_duration, each next one delay_interval later.
static func _meteor_shower(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var radius = float(info.get("radius", 220.0))
	var mark := {
		"delivery": "field", "origin": "caster",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		"timing": {"duration": float(info.get("warning_duration", 0.65)), "interval": 999.0},
		"events": {"on_expire": {"part": "impact"}},
		"payload": [],
		"vfx": {"family": "meteor"},
	}
	var impact := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		"propagation": {"type": "instant"},
		"payload": _damage(id, damage),
	}
	var def = _shell(info, "mark", {"mark": mark, "impact": impact})
	def.arrangement = {"type": "points", "count": int(info.get("meteor_count", 3)), "stagger_life": float(info.get("delay_interval", 0.3))}
	return def
