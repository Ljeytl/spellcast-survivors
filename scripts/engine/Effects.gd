extends RefCounted
## One entry point for everything a spell does to a target (doc 18 §5).
##
## effect = {"type": "damage", "entries": [{"amount": 74, "damage_type": "raw"}, {"amount": 22, "damage_type": "fire"}],
##           "element": "fire"}                      # spell element, used by the type chart
##        | {"type": "impulse", "direction": Vector2, "force": 400}
##        | {"type": "status", "status": "chilled", "hit": 30.0}
##        | {"type": "heal", "amount": 10}
##
## Targets with apply_effect() get the full pipeline. Anything else (old spells' test dummies,
## the player, props) falls back to its legacy methods, so nothing that worked before breaks.

const TypeChart = preload("res://scripts/engine/TypeChart.gd")
const StatusComponent = preload("res://scripts/engine/StatusComponent.gd")

static var _cast_counter := 0

static func next_cast_id() -> int:
	_cast_counter += 1
	return _cast_counter

static func apply(target: Object, effect: Dictionary, source: Dictionary = {}, origin: Vector2 = Vector2.INF) -> float:
	if not is_instance_valid(target):
		return 0.0
	if target.has_method("apply_effect"):
		return float(target.apply_effect(effect, source, origin))
	return _legacy_apply(target, effect, source, origin)

static func _legacy_apply(target: Object, effect: Dictionary, source: Dictionary, origin: Vector2) -> float:
	match str(effect.get("type", "")):
		"damage":
			var total = 0.0
			for entry in effect.get("entries", []):
				total += float(entry.get("amount", 0.0))
			if effect.has("amount"):
				total += float(effect.amount)
			if total > 0.0 and target.has_method("take_damage"):
				target.take_damage(total, origin, source)
				return total
		"impulse":
			if target.has_method("apply_knockback"):
				target.apply_knockback(effect.get("direction", Vector2.ZERO), float(effect.get("force", 0.0)))
		"status":
			var id = str(effect.get("status", ""))
			if id in ["chilled", "slowed", "entangled"] and target.has_method("apply_slow"):
				var defs = StatusComponent.definitions()
				var slow = float(effect.get("slow", defs.get(id, {}).get("slow", defs.get(id, {}).get("slow_per_stack", 0.3))))
				target.apply_slow(1.0 - slow, float(effect.get("duration", defs.get(id, {}).get("duration", 2.0))))
		"heal":
			if target.has_method("heal"):
				target.heal(float(effect.get("amount", 0.0)))
	return 0.0

## Final damage of each entry against an entity with element / resistances / armour / statuses.
## Returns [total, per_type Dictionary].
static func resolve_damage(entity: Object, effect: Dictionary) -> Array:
	var entries: Array = effect.get("entries", [])
	if entries.is_empty() and effect.has("amount"):
		entries = [{"amount": float(effect.amount), "damage_type": str(effect.get("damage_type", "raw"))}]
	var enemy_element = str(entity.get("element")) if entity.get("element") != null else ""
	var resistances: Dictionary = entity.get("resistances") if entity.get("resistances") is Dictionary else {}
	var armour = float(entity.call("armour_value")) if entity.has_method("armour_value") else 0.0
	var taken = 1.0
	var status = entity.get("status")
	if status != null and is_instance_valid(status):
		taken = status.damage_taken_multiplier()
	var total = 0.0
	var by_type := {}
	for entry in entries:
		var amount = float(entry.get("amount", 0.0))
		if amount <= 0.0:
			continue
		var kind = TypeChart.normalize(str(entry.get("damage_type", "raw")))
		# The type chart reads the element of the source of this share: the spell's element for its own
		# damage, the element word's element for damage an element word added.
		var chart_element = TypeChart.normalize(str(entry.get("chart_element", effect.get("element", kind))))
		amount *= TypeChart.multiplier(chart_element, enemy_element)
		if kind == "raw":
			if not bool(entry.get("ignores_armour", false)):
				amount *= clampf(1.0 - armour, 0.0, 1.0)
		else:
			amount *= clampf(1.0 - float(resistances.get(kind, 0.0)), 0.0, 2.0)
		amount *= taken
		total += amount
		by_type[kind] = float(by_type.get(kind, 0.0)) + amount
	return [total, by_type]

## Full pipeline for an enemy-like entity that has a status component and receive_damage().
static func apply_to_entity(entity: Object, effect: Dictionary, source: Dictionary, origin: Vector2) -> float:
	var kind = str(effect.get("type", ""))
	var component = ensure_status(entity) if kind in ["damage", "status"] else entity.get("status")
	match kind:
		"damage":
			var resolved = resolve_damage(entity, effect)
			var total: float = resolved[0]
			if not bool(effect.get("dot", false)) and component:
				total += component.on_hit(effect, source, origin)
			if total > 0.0:
				entity.receive_damage(total, origin, source)
			return total
		"impulse":
			if entity.has_method("apply_knockback"):
				entity.apply_knockback(effect.get("direction", Vector2.ZERO), float(effect.get("force", 0.0)))
		"status":
			if component:
				component.apply(str(effect.get("status", "")), effect, source)
		"heal":
			if entity.has_method("heal"):
				entity.heal(float(effect.get("amount", 0.0)))
	return 0.0

static func ensure_status(entity: Object):
	var component = entity.get("status")
	if component != null and is_instance_valid(component):
		return component
	if not (entity is Node):
		return null
	component = StatusComponent.new()
	component.name = "StatusComponent"
	entity.add_child(component)
	entity.set("status", component)
	return component
