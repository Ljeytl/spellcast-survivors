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
const PORTED = ["heal_over_time", "piercing", "projectile", "aoe", "heal", "direct_strike", "chain", "trap", "field", "orbit", "multi_aoe", "bouncing_projectile", "life_bolt", "beam", "spirit", "trail", "returning", "plague", "shield"]

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
		"bouncing_projectile":
			return _lightning_bolt(info, damage, ctx)
		"life_bolt":
			return _life_bolt(info, damage, ctx)
		"beam":
			return _beam(info, damage, ctx)
		"spirit":
			return _seeker(info, damage, ctx)
		"trail":
			return _firewalk(info, damage, ctx)
		"returning":
			return _cross_blade(info, damage, ctx)
		"plague":
			return _infestation(info, damage, ctx)
		"shield":
			return _earth_eruption(info, ctx)
		"mana_bolt":
			return _mana_bolt(info, damage, ctx)
	return {}

## Magic Missile (the auto-attack): one missile per count, 0.05 s apart, each homing on the enemy
## worth hitting when it leaves (overkill-aware) and retargeting if that one dies; a contact hits
## everything the missile overlaps, then it is spent. Lives three seconds.
static func _mana_bolt(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.get("id", "mana_bolt"))
	var speed = 450.0 * float(ctx.get("speed_mult", 1.0))
	var missile := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": SpellGeometry.BOLT_RADIUS * float(info.get("projectile_size_multiplier", 1.0)), "pad": "hurtbox"},
		"motion": [{"type": "guided", "speed": speed, "lerp": 6.0, "range": speed * 3.0}],  # old homing_strength 6
		"payload": _damage(id, damage),
		"limits": {"pierce": 0, "contact_all": true},
		"vfx": {"family": "dart"},
	}
	var def = _shell(info, "missile", {"missile": missile})
	def.arrangement = {"type": "single", "count": maxi(1, int(info.get("projectile_count", 1)))}
	def.release = {"type": "staggered", "interval": 0.05, "retarget": true}
	def.needs_target = true
	return def

## How a recast meets the casts already out (the old recast_behavior / active_limit / extend_at_cap).
static func _recast(info: Dictionary) -> Dictionary:
	var r := {"behavior": str(info.get("recast_behavior", "stack")), "cap": int(info.get("active_limit", 3)),
		"extend_at_cap": bool(info.get("extend_at_cap", false))}
	if info.has("max_banked_casts"):
		r.max_banked = float(info.max_banked_casts)
	return r

## A part's damage and statuses from data/spell_damage.json. `amount` is the spell's base hit; the
## part's mix carries its share of it (doc 21 §5: Lightning Bolt's strike is 1.5x the base, in storm).
static func _damage(spell_id: String, amount: float, part: String = "") -> Array:
	var p = SpellDamage.profile(spell_id, part)
	var out: Array = [{"type": "damage", "amount": amount, "mix": p.damage}]
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
		"payload": _damage(id, damage, "spear"),
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
			"payload": _damage(id, damage, "trail"),   # doc 21 §5.2: 20% of the spear hit as fire, + burn
			"limits": {"cap": 3},
			"vfx": {"style": "smoulder"},
		}
	if bool(info.get("explosive", false)):
		# Meteor Spear (doc 21 §5.6): a small meteor drops on every enemy the spear pierces.
		var small = 48.0 * float(info.get("spell_size_multiplier", 1.0))   # was 70: too wide early (playtest)
		spear.events = {"on_hit": {"part": "drop"}}
		parts.drop = {
			"delivery": "field", "origin": "parent", "anchor": "hit_target",
			"geometry": {"type": "disk", "radius": small, "pad": 0.0},
			# the mark shows at the pierced enemy, a beat, then the rock falls (0.65 s) and lands:
			# the meteor clearly follows the hit (playtest: 0.25 s read as summoned at once)
			"timing": {"duration": 1.0, "interval": 999.0},
			"events": {"on_expire": {"part": "meteor"}},
			"payload": [],
			"vfx": {"family": "meteor"},
		}
		parts.meteor = {
			"delivery": "volume", "origin": "parent",
			"geometry": {"type": "disk", "radius": small, "pad": 0.0},
			"propagation": {"type": "instant", "linger": 0.1},
			"payload": _damage(id, damage, "meteor"),
			"vfx": {"heavy": 0.6},   # a landing with weight: flash, ring, rocks, shake (playtest)
		}
	var def = _shell(info, "spear", parts)
	if bool(info.get("explosive", false)):
		def.max_depth = 3
	return def

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
	# Chill (1 stack per shard that hits) is Ice Blast's slow now (doc 21 §5.3); no separate slow.
	var shard := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": 12.0 * size, "pad": "hurtbox"},
		"motion": [{"type": "straight", "speed": speed, "range": float(info.get("radius", 400.0))}],
		"payload": payload,
		"limits": {"pierce": int(info.get("shard_pierce", 0))},
		"vfx": {"family": "shard", "look": "ice"},
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
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": float(info.get("radius", 160.0)), "pad": 0.0},
		"propagation": {"type": "instant", "linger": float(info.get("active_duration", 0.2 * float(info.get("spell_duration_multiplier", 1.0))))},
		"payload": _damage(id, damage),
		"vfx": {"heavy": 1.0},
	}
	var mark := _warn(float(info.get("radius", 160.0)), "strike", "target")
	var def = _shell(info, "mark", {"mark": mark, "strike": strike})
	def.max_depth = 2
	def.needs_target = true
	return def

## A warning before a landing (playtest: "a blue ring, a beat, then BAM"): a payload-less mark
## over the true area for `wait` seconds that drops `then` when it expires.
const WARN_SECONDS := 0.32
static func _warn(radius: float, then: String, origin: String = "parent", wait: float = WARN_SECONDS) -> Dictionary:
	return {
		"delivery": "field", "origin": origin,
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		"timing": {"duration": wait, "interval": 999.0},
		"events": {"on_expire": {"part": then}},
		"payload": [],
		"vfx": {"warn": true},
	}

## Rune Trap (and Frost Sigil), doc 21 §5.1: a rune laid toward the nearest enemy (at most 160 away)
## arms, waits, and when an enemy steps in it ACTIVATES (roots everyone inside briefly and marks them
## vulnerable, 0 stacks at rank 1 up to 5 at rank 6+), then EXPLODES on the rooted, softened crowd.
static func _trap(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var radius = float(info.get("trap_radius", 130.0))
	var rune := {
		"delivery": "trap", "origin": "toward_target", "reach": 160.0,
		"geometry": {"type": "disk", "radius": float(info.get("trigger_radius", 70.0)), "pad": 0.0},
		"timing": {"arming": float(info.get("arm_delay", 0.8)), "duration": 1.0e9},
		"events": {"on_trigger": {"part": "activate"}},
	}
	var cap = int(info.get("active_limit", 999))
	if cap < 999:
		rune.limits = {"cap": cap}
	var marks: Array = []
	for rule in SpellDamage.statuses_for(id, "activate"):
		marks.append(status_item(rule))
	var stacks = clampi(int(info.get("level", 1)) - 1, 0, 5)
	if stacks > 0:
		marks.append({"type": "status", "status": "vulnerable", "stacks": float(stacks)})
	var activate := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		# live for the fuse: anyone stepping in before it blows is rooted and marked too
		"propagation": {"type": "instant", "linger": 0.4},
		"payload": marks,
		"events": {"on_expire": {"part": "burst"}},
		"vfx": {"warn": true},   # the 0.4 s fuse reads as the closing ring before the blast
	}
	var burst := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		# old rune: the burst stays live 0.25 s (× Duration) and catches late entrants once
		"propagation": {"type": "instant", "linger": float(info.get("active_duration", 0.25 * float(info.get("spell_duration_multiplier", 1.0))))},
		"payload": _damage(id, damage, "burst"),
		"vfx": {"heavy": 0.8},
	}
	var def = _shell(info, "rune", {"rune": rune, "activate": activate, "burst": burst})
	def.max_depth = 3
	return def

## Cinder Field (and Steam Field): a burning circle on the group worth hitting (where the caster
## stands if there is none). First pulse after one interval, then every interval.
static func _field(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var payload = _damage(id, damage)   # Steam Field's slow is its chill now (data/spell_damage.json)
	var field := {
		"delivery": "field", "origin": "target_or_caster",
		"geometry": {"type": "disk", "radius": float(info.get("radius", 150.0)), "pad": 0.0},
		"timing": {"interval": float(info.get("tick_interval", 0.5)), "duration": float(info.get("duration", 5.0)), "delay_first": true},
		"payload": payload,
	}
	if id == "steam_field":
		field.vfx = {"style": "steam"}   # its own look: billowing steam over hot water, not Cinder Field's fire
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
		"vfx": {"family": "sphere"},   # a glowing orb, not a bolt (playtest)
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
		"vfx": {"family": "none"},   # no ring: the heal sparkles are the look
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
		"events": {"on_expire": {"part": "impact"}, "on_expire#crater": {"part": "crater"}},
		"payload": [],
		"vfx": {"family": "meteor"},
	}
	var impact := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		# old meteor strike: a 0.2 s (× Duration) blast that still catches late entrants
		"propagation": {"type": "instant", "linger": 0.2 * float(info.get("spell_duration_multiplier", 1.0))},
		"payload": _damage(id, damage, "impact"),
		"vfx": {"heavy": 1.2},
	}
	# Doc 21 §5.2: a short burning crater of hot rubble (25% of the impact a tick, no burn); Duration extends it.
	var crater := {
		"delivery": "field", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius * 0.6, "pad": 0.0},
		"timing": {"interval": 0.5, "duration": 1.0 * float(info.get("spell_duration_multiplier", 1.0)), "delay_first": true},
		"payload": _damage(id, damage, "crater"),
		"vfx": {"style": "rubble"},
	}
	var def = _shell(info, "mark", {"mark": mark, "impact": impact, "crater": crater})
	def.arrangement = {"type": "points", "count": int(info.get("meteor_count", 3)), "stagger_life": float(info.get("delay_interval", 0.3))}
	return def

## Lightning Bolt: a homing bolt that bounces to the next enemy (never the same one twice),
## striking a small lightning area at every hit.
static func _lightning_bolt(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var speed = 550.0 * float(ctx.get("speed_mult", 1.0))
	var hop_speed = 260.0 * float(ctx.get("speed_mult", 1.0))   # bounces travel slowly so each hop reads (playtest)
	var hops = int(info.get("bounce_count", 4))
	var reach = float(info.get("bounce_range", 240.0))
	# Doc 21 §5.6: the bolt bounces through up to `hops` more enemies, then ONE strike lands on the last.
	var events = {"on_hit#bounce": {"part": "bounce", "chain": true, "hops": hops, "range": reach, "exclude_hit": true, "end": {"part": "splash_warn"}}}
	var bolt := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": SpellGeometry.BOLT_RADIUS * float(info.get("projectile_size_multiplier", 1.0)), "pad": "hurtbox"},
		"motion": [{"type": "guided", "speed": speed, "lerp": 5.0, "range": maxf(3.0 * speed, (hops + 1) * reach + speed)}],  # old homing_strength 5
		"payload": _damage(id, damage, "bolt"),
		"limits": {"pierce": 0},
		"events": events,
		"vfx": {"family": "bolt"},
	}
	var bounce = bolt.duplicate(true)
	bounce.origin = "parent"
	bounce.motion = [{"type": "guided", "speed": hop_speed, "lerp": 5.0, "range": reach * 1.5}]
	bounce.payload = _damage(id, damage, "bounce")
	bounce.events = {"on_hit#bounce": {"part": "bounce", "chain": true, "range": reach, "exclude_hit": true, "end": {"part": "splash_warn"}}}
	var splash := {
		"delivery": "volume", "origin": "parent",
		"geometry": {"type": "disk", "radius": float(info.get("splash_radius", 80.0)) * float(info.get("spell_size_multiplier", 1.0)), "pad": 0.0},
		"propagation": {"type": "instant", "linger": 0.2},   # old splash: 0.2 s, late entrants still hit once
		"payload": _damage(id, damage, "splash"),   # 1.5x the base hit in storm (data/spell_damage.json)
		"vfx": {"heavy": 0.8},
	}
	var splash_warn := _warn(float(info.get("splash_radius", 80.0)) * float(info.get("spell_size_multiplier", 1.0)), "splash")
	var def = _shell(info, "bolt", {"bolt": bolt, "bounce": bounce, "splash_warn": splash_warn, "splash": splash})
	def.release = {"type": "together", "retarget": true}
	def.max_spawns = 64
	def.max_depth = hops + 3       # the warning and the strike still land after the last bounce
	def.needs_target = true        # no enemy, no bolt (old behaviour)
	return def

## Life Bolt: bolts spread over different enemies (on screen first); a hit that deals damage
## plants a healing seed the caster can walk over.
static func _life_bolt(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var speed = 400.0 * float(ctx.get("speed_mult", 1.0))
	var payload = _damage(id, damage)
	# Doc 21 §5.6: the seed heals 15% of the damage the hit dealt.
	payload.append({"type": "seed", "share_of_dealt": 0.15, "amount": float(info.get("healing_seed_amount", 6.0)), "duration": float(info.get("healing_seed_duration", 2.0)),
		"lifetime": float(info.get("healing_seed_lifetime", 10.0)) * float(info.get("spell_duration_multiplier", 1.0)),
		"radius": float(info.get("healing_seed_radius", 28.0)) * float(info.get("spell_size_multiplier", 1.0)), "cap": 6})
	var bolt := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": SpellGeometry.BOLT_RADIUS * float(info.get("projectile_size_multiplier", 1.0)), "pad": "hurtbox"},
		"motion": [{"type": "straight", "speed": speed, "range": speed * 3.0}],
		"payload": payload,
		"limits": {"pierce": 0, "contact_all": true},
		"vfx": {"family": "bolt"},
	}
	var def = _shell(info, "bolt", {"bolt": bolt})
	def.arrangement = {"type": "single", "count": maxi(1, int(info.get("projectile_count", 1)))}
	def.release = {"type": "together", "retarget": true}
	return def

## Focus Ray (and Prism Ray): a beam from the caster that turns toward the enemy it tracks and hits
## the first enemy along it four times a second. Prism Ray (doc 21 §5.6) tracks the same way, and every
## tick that hits refracts at the target into six piercing lasers fanning out behind it, one per element.
const PRISM_RAYS = ["ray_fire", "ray_water", "ray_storm", "ray_earth", "ray_plague", "ray_life"]
const PRISM_LOOKS = {"ray_fire": "fire", "ray_water": "ice", "ray_storm": "lightning", "ray_earth": "earth", "ray_plague": "plague", "ray_life": "life"}
static func _beam(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var piercing = bool(info.get("beam_piercing", false))
	var turn = float(info.get("beam_turn_speed", info.get("turn_speed", 4.0)))
	if not piercing:
		turn *= float(ctx.get("speed_mult", 1.0))
	var beam := {
		"delivery": "beam", "origin": "caster",
		"geometry": {"type": "line", "length": 450.0, "width": float(info.get("beam_radius", SpellGeometry.BEAM_RADIUS)) * float(info.get("spell_size_multiplier", 1.0)) * 2.0, "pad": "hurtbox"},
		"aim": {"turn": turn},
		"timing": {"interval": 0.25, "duration": float(info.get("duration", 2.0))},
		"payload": _damage(id, damage, "beam"),
		"limits": {"targets": int(info.get("beam_targets", 1)), "beam_piercing": piercing},
	}
	var parts := {"beam": beam}
	if bool(info.get("refract", false)):
		var fan = 150.0   # wide: one enemy takes one or two rays, not all six (playtest)
		beam.events = {}
		for i in PRISM_RAYS.size():
			var ray = PRISM_RAYS[i]
			beam.events["on_hit#" + ray] = {"part": ray, "turn": -fan * 0.5 + fan * i / (PRISM_RAYS.size() - 1), "exclude_hit": true,
				"sway": 14.0, "sway_speed": 0.35, "sway_phase": float(i)}
			parts[ray] = {
				"delivery": "volume", "origin": "parent",
				"geometry": {"type": "line", "length": 420.0 * float(info.get("spell_size_multiplier", 1.0)), "width": 28.0 * float(info.get("spell_size_multiplier", 1.0)), "pad": "hurtbox"},
				"propagation": {"type": "instant", "linger": 0.05},
				"payload": _damage(id, damage, ray),
				"vfx": {"family": "ray", "look": PRISM_LOOKS[ray]},
			}
	var def = _shell(info, "beam", parts)
	if bool(info.get("refract", false)):
		def.max_spawns = 4000
		def.max_depth = 2
	def.recast = _recast(info)
	return def

## Seeker: a slow spirit hunts the nearest on-screen enemy no other spirit is on, striking each
## enemy at most once per hit_interval, for its duration.
static func _seeker(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var spirit := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": SpellGeometry.SPIRIT_RADIUS * float(info.get("spell_size_multiplier", 1.0)), "pad": 0.0},
		"motion": [{"type": "chase", "speed": float(info.get("move_speed", 320.0)) * float(ctx.get("speed_mult", 1.0)), "range": 600.0}],
		"payload": _damage(id, damage),
		"limits": {"pierce": -1, "rehit": float(info.get("hit_interval", 0.5)), "lifetime": float(info.get("duration", 5.0)), "visible_only": true},
		"vfx": {"family": "ghost"},
	}
	var parts := {"spirit": spirit}
	if bool(info.get("reaping", false)):
		# Reaping Spirit (disabled combination): a kill bursts for half damage around the victim.
		spirit.events = {"on_kill": {"part": "reap", "exclude_hit": true}}
		parts.reap = {
			"delivery": "volume", "origin": "parent",
			"geometry": {"type": "disk", "radius": 100.0 * float(info.get("spell_size_multiplier", 1.0)), "pad": 0.0},
			"payload": _damage(id, damage * 0.5),
		}
	var def = _shell(info, "spirit", parts)
	def.recast = _recast(info)
	return def

## Fire Walk: while it lasts, the caster leaves burning patches along their path. An enemy in the
## trail burns once per tick however many patches it stands in.
static func _firewalk(info: Dictionary, damage: float, _ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var radius = float(info.get("trail_radius", 65.0))
	var emitter := {
		"delivery": "aura", "origin": "caster", "anchor": "caster",
		"geometry": {"type": "disk", "radius": 1.0},
		"timing": {"duration": float(info.get("emission_duration", 5.0)), "interval": 999.0},
		"emit": {"part": "patch", "every": 0.1, "min_step": 24.0, "spacing": radius},
		"payload": [],
		"vfx": {"family": "emitter"},
	}
	var interval = float(info.get("tick_interval", 0.5))
	var patch := {
		"delivery": "field", "origin": "parent",
		"geometry": {"type": "disk", "radius": radius, "pad": 0.0},
		"timing": {"interval": interval, "duration": float(info.get("patch_duration", 6.0)), "shared_clock": true},
		"payload": _damage(id, damage),
		"limits": {"rehit": interval - 0.001, "rehit_shared": true},
		"vfx": {"family": "firewalk"},
	}
	var def = _shell(info, "emitter", {"emitter": emitter, "patch": patch})
	def.recast = _recast(info)
	def.max_spawns = 4000
	def.max_depth = 2
	return def

## Cross Blade (doc 21 §5.4): blades fly out (100%, 75 physical / 25 earth), hold where they stop and
## pulse every interval (100% each, 50 / 50), then fly back hitting every enemy again (200%: 75 / 125)
## with a double bleed. Duration makes the blade hold longer; nothing is left behind.
static func _cross_blade(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var speed = float(info.get("speed", 500.0)) * float(ctx.get("speed_mult", 1.0))
	var linger = float(info.get("linger_duration", 0.9)) * float(info.get("spell_duration_multiplier", 1.0))
	var interval = float(info.get("linger_interval", 0.3))
	var radius = float(info.get("blade_radius", 33.6))
	var hold_mix = SpellDamage.profile(id, "hold").damage
	var back_part = SpellDamage.profile(id, "return")
	var back_bleed = 1
	for rule in back_part.statuses:
		if str(rule.status) == "bleed":
			back_bleed = maxi(1, int(rule.get("stacks", 1)))
	var back := {"type": "return", "speed": speed, "catch": 18.0, "mult": 1.0, "mix": back_part.damage, "status_repeat": back_bleed, "fresh_hits": true}
	var blade := {
		"delivery": "projectile", "origin": "caster",
		"geometry": {"type": "body", "radius": radius, "pad": 0.0},
		"motion": [
			{"type": "straight", "speed": speed, "range": float(info.get("travel_distance", 350.0))},
			{"type": "hold", "time": linger, "pulse": {"interval": interval, "mult": 1.0, "mix": hold_mix}},
			back,
		],
		"payload": _damage(id, damage, "blade"),
		"limits": {"pierce": -1},
		"vfx": {"family": "blade"},
	}
	var def = _shell(info, "blade", {"blade": blade})
	var count = maxi(1, int(info.get("blade_count", 3)))
	def.arrangement = {"type": "ring", "count": count, "radius": 0.0, "aimed": true, "offset": PI / 4.0 if count == 4 else 0.0}
	def.recast = _recast(info)
	return def

## Infestation (and Soul Bloom): a spore flies to the target and the plague jumps from host to
## host (scripts/engine/Infection.gd); Soul Bloom's dead hosts drop healing blooms.
static func _infestation(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var size = float(info.get("spell_size_multiplier", 1.0))
	var cfg := {
		"duration": float(info.get("duration", 3.0)),
		"interval": float(info.get("tick_interval", 0.5)),
		"spread_radius": float(info.get("spread_radius", 130.0)) * size,
		"resting_multiplier": float(info.get("resting_spread_multiplier", 1.3)),
		"spread_speed": float(info.get("spread_speed", 460.0)) * float(ctx.get("speed_mult", 1.0)),
		"spore_life": float(info.get("orphan_lifetime", float(info.get("spore_linger", 1.5)) * float(info.get("spell_duration_multiplier", 1.0)))),
		"cast_range": float(info.get("cast_range", 600.0)),
	}
	if float(info.get("healing_bloom_amount", 0.0)) > 0.0:
		cfg.bloom = {"amount": float(info.healing_bloom_amount), "duration": 2.0, "lifetime": float(info.get("healing_bloom_lifetime", 10.0)),
			"radius": float(info.get("healing_bloom_radius", 48.0)), "cap": 6}
	var plague := {
		"delivery": "infection", "origin": "caster",
		"geometry": {"type": "disk", "radius": 1.0},
		"infection": cfg,
		"payload": _damage(id, damage),
		"vfx": {"family": "infection"},
	}
	var def = _shell(info, "plague", {"plague": plague})
	def.recast = _recast(info)
	def.needs_target = true
	return def

## Earth Shield: each cast stores a block charge on the caster (Player.add_earth_shield_charge);
## a blocked hit erupts a cone of stone toward the attacker. This is that eruption: a cone that
## grows over travel_time, hitting each enemy once and pushing it away.
static func _earth_eruption(info: Dictionary, ctx: Dictionary) -> Dictionary:
	var id = str(info.id)
	var reach = float(ctx.get("reach", 160.0))
	var travel = maxf(0.01, float(ctx.get("travel_time", 0.22)))
	var payload = _damage(id, float(ctx.get("damage", 60.0)))
	payload.append({"type": "impulse", "direction": "away", "force": float(ctx.get("knockback", 500.0))})
	var cone := {
		"delivery": "volume", "origin": "caster",
		"geometry": {"type": "cone", "radius": reach, "angle": rad_to_deg(float(ctx.get("half_angle", deg_to_rad(50.0)))) * 2.0, "pad": 0.0},
		"propagation": {"type": "expanding", "speed": reach / travel},
		"payload": payload,
	}
	return _shell(info, "eruption", {"eruption": cone})
