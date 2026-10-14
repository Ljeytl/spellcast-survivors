extends RefCounted
## Stats as base values plus modifiers with sources (doc 19 §5.3).
##
##   value = override if any modifier overrides (the latest wins)
##         else (base + Σ add) × Π (1 + mul)
##
## Every change has a source ("passive:spell_damage", "ley:attuned", "elite:armored", "status:slowed"),
## so removing a source removes exactly what it added, and the debug overlay can say why a number
## is what it is. Unknown stats read as 0 unless a base was set.

signal changed(stat: String)

const OPS = ["add", "mul", "override"]

var _base: Dictionary = {}
var _mods: Array = []          # {stat, op, value, source}
var _cache: Dictionary = {}

func _init(bases: Dictionary = {}) -> void:
	for stat in bases:
		_base[str(stat)] = float(bases[stat])

func set_base(stat: String, value: float) -> void:
	_base[stat] = value
	_invalidate(stat)

func base(stat: String) -> float:
	return float(_base.get(stat, 0.0))

func has_stat(stat: String) -> bool:
	return _base.has(stat) or _mods.any(func(m): return m.stat == stat)

func value(stat: String) -> float:
	if _cache.has(stat):
		return _cache[stat]
	var add := 0.0
	var mul := 1.0
	var override = null
	for m in _mods:
		if m.stat != stat:
			continue
		match m.op:
			"add": add += m.value
			"mul": mul *= 1.0 + m.value
			"override": override = m.value
	var result: float = float(override) if override != null else (base(stat) + add) * mul
	_cache[stat] = result
	return result

## Adds one modifier. Several modifiers may share a source (three picks of the same passive).
func add_modifier(stat: String, op: String, amount: float, source: String) -> void:
	assert(op in OPS, "StatBlock: unknown op '%s'" % op)
	_mods.append({"stat": stat, "op": op, "value": amount, "source": source})
	_invalidate(stat)

## Removes every modifier from source; returns how many were removed.
func remove_source(source: String) -> int:
	var touched := {}
	var kept: Array = []
	for m in _mods:
		if m.source == source:
			touched[m.stat] = true
		else:
			kept.append(m)
	var removed := _mods.size() - kept.size()
	_mods = kept
	for stat in touched:
		_invalidate(stat)
	return removed

func has_source(source: String) -> bool:
	return _mods.any(func(m): return m.source == source)

## Sets the base so the current value becomes target, keeping every modifier.
## For code and tests that assign a stat directly (player.spell_damage_multiplier = 2.0).
func set_value(stat: String, target: float) -> void:
	var add := 0.0
	var mul := 1.0
	for m in _mods:
		if m.stat == stat:
			match m.op:
				"add": add += m.value
				"mul": mul *= 1.0 + m.value
				"override": push_warning("StatBlock: %s is overridden; set_value changes only its base" % stat)
	_base[stat] = (target / mul if not is_zero_approx(mul) else target) - add
	_invalidate(stat)

func modifiers(stat: String = "") -> Array:
	return _mods.filter(func(m): return stat == "" or m.stat == stat).map(func(m): return m.duplicate())

## {stat: value} for every stat with a base or a modifier (cast messages, debug overlay).
func snapshot() -> Dictionary:
	var out := {}
	for stat in _base:
		out[stat] = value(stat)
	for m in _mods:
		out[m.stat] = value(m.stat)
	return out

func _invalidate(stat: String) -> void:
	_cache.erase(stat)
	changed.emit(stat)
