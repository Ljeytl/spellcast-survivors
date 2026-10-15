extends RefCounted
## Shipped spells on the generic engine. Their shapes are data now (data/spell_shapes.json, built by
## scripts/engine/SpellTemplate.gd); this file only keeps the old entry points until the remaining
## type-based rules (targeting, cast context, spell list) move to data as well.

const SpellTemplate = preload("res://scripts/engine/SpellTemplate.gd")

## Old spell types that run on the generic engine.
const PORTED = ["heal_over_time", "piercing", "projectile", "aoe", "heal", "direct_strike", "chain", "trap", "field", "orbit", "multi_aoe", "bouncing_projectile", "life_bolt", "beam", "spirit", "trail", "returning", "plague", "shield"]

static func handles(info: Dictionary) -> bool:
	return str(info.get("type", "")) in PORTED

## info: resolved and size-scaled spell data. damage: the per-hit damage. ctx: {speed_mult, ...}.
static func build(info: Dictionary, damage: float, ctx: Dictionary) -> Dictionary:
	return SpellTemplate.build(info, damage, ctx)

static func status_item(rule: Dictionary) -> Dictionary:
	return SpellTemplate.status_item(rule)
