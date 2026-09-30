class_name DamageSource
extends RefCounted
## Tags enemy damage with the spell and cast that caused it.
## SpellManager sets `current` while a cast resolves; effect nodes created then copy it,
## and delayed callbacks are wrapped so meteors, chains and delayed bolts keep their cast.

static var current: Dictionary = {}

## Kills from these give score but never combo.
const SCORE_ONLY = ["mana_bolt", "atomic", ""]
const FULL_VALUE_SECONDS = 5.0
const HALF_LIFE_SECONDS = 5.0

static func stamp(node: Object, source: Dictionary = current) -> void:
	if node and not source.is_empty():
		node.set_meta("damage_source", source)

static func of(node: Object) -> Dictionary:
	return node.get_meta("damage_source", {}) if node and node.has_meta("damage_source") else {}

static func make(spell: String, cast_clock: float) -> Dictionary:
	return {"spell": spell, "cast_clock": cast_clock}

## Returns a callable that restores the cast source captured now when it later runs.
static func wrap(callable: Callable) -> Callable:
	var captured = current
	return func():
		var previous = DamageSource.current
		if not callable.is_valid():
			return
		DamageSource.current = captured
		callable.call()
		DamageSource.current = previous

## Combo value of a kill: full for five seconds after the cast, then halving every five.
static func combo_factor(source: Dictionary, now: float) -> float:
	var spell = str(source.get("spell", ""))
	if spell in SCORE_ONLY:
		return 0.0
	var age = maxf(0.0, now - float(source.get("cast_clock", now)))
	if age <= FULL_VALUE_SECONDS:
		return 1.0
	return pow(0.5, (age - FULL_VALUE_SECONDS) / HALF_LIFE_SECONDS)
