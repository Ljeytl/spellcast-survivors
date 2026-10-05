extends Node
## Every status on one entity, ticked in one loop (doc 18 §5.3).
## Burn: each application is its own short burn; all tick together.
## Bleed: adds damage and duration, fills a meter that bursts into a hemorrhage.
## Poison: ramps every tick, weakens, refresh keeps the ramp.
## Chilled: frostbite + stacks of slow; at the cap the entity becomes Frozen.
## Reactions (doc 18 §6.4) fire only between different casts; one cast fuses with itself.

const DATA_PATH = "res://data/statuses.json"
static var _defs: Dictionary = {}

var entity: Node = null
var clock := 0.0
var burns: Array = []        # {per_tick, ticks_left, acc, tick, source, cast}
var bleed: Dictionary = {}   # {per_tick, remaining, acc, source, cast}
var bleed_meter := 0.0
var bleed_since_hit := 999.0
var poison: Dictionary = {}  # {base, remaining, acc, ticks, source, cast}
var chill: Dictionary = {}   # {stacks, remaining, source, cast}
var timed: Dictionary = {}   # id -> {remaining, strength, source, cast}
var freeze_immunity := 0.0
var entangle_times: Array = []
var last_hard_cc := -999.0
var reaction_ready_at := 0.0
var reactions_fired: Array = []   # names, for tests/telemetry
var _weaken_base = null
var _applied_dealt := 1.0

static func definitions() -> Dictionary:
	if _defs.is_empty():
		var file = FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_defs = parsed
	return _defs

static func def(id: String) -> Dictionary:
	return definitions().get(id, {})

static func rule(key: String, fallback):
	return definitions().get("_rules", {}).get(key, fallback)

func _ready():
	entity = get_parent()

func _owner() -> Node:
	if entity == null:
		entity = get_parent()
	return entity

func is_boss() -> bool:
	var e = _owner()
	return e != null and e.is_in_group("bosses")

func is_elite() -> bool:
	var e = _owner()
	return e != null and bool(e.get("is_elite")) if e != null and e.get("is_elite") != null else false

# ---------------------------------------------------------------- applying

func apply(id: String, params: Dictionary = {}, source: Dictionary = {}) -> void:
	var d = def(id)
	if d.is_empty():
		return
	var hit = float(params.get("hit", 0.0))
	var cast = source.get("cast_id", null)
	var duration = float(params.get("duration", d.get("duration", 1.0)))
	match id:
		"burn":
			var tick = float(d.tick)
			var ticks = maxi(1, int(round(duration / tick)))
			var total = float(params.get("total", float(d.share) * hit * float(params.get("strength", 1.0))))
			if total > 0.0:
				burns.append({"per_tick": total / ticks, "ticks_left": ticks, "acc": 0.0, "tick": tick, "source": source, "cast": cast})
		"bleed":
			var per_tick = float(params.get("per_tick", float(d.share_per_tick) * hit * float(params.get("strength", 1.0))))
			if bleed.is_empty():
				bleed = {"per_tick": 0.0, "remaining": 0.0, "acc": 0.0, "source": source, "cast": cast, "last_add": 0.0}
			bleed.per_tick += per_tick
			bleed.remaining += duration
			bleed.source = source
			bleed.cast = cast
			bleed.last_add = per_tick
			bleed_since_hit = 0.0
			var fill = float(d.meter_per_hit) * float(params.get("meter", 1.0))
			if is_boss():
				fill /= float(d.boss_meter_multiplier)
			bleed_meter += fill
			if bleed_meter >= 1.0 - 0.0001:
				_hemorrhage(per_tick, source)
		"poison":
			var add = float(params.get("base", float(d.share_per_tick) * hit * float(params.get("strength", 1.0))))
			if poison.is_empty():
				poison = {"base": 0.0, "remaining": 0.0, "acc": 0.0, "ticks": 0, "source": source, "cast": cast}
			poison.base += add
			poison.remaining = maxf(float(poison.remaining), duration)
			poison.source = source
			poison.cast = cast
		"chilled":
			var stacks = int(params.get("stacks", 1))
			if hit > 0.0 and not bool(params.get("no_frostbite", false)):
				_deal(float(d.frostbite_share) * hit * stacks, "water", source, false)
			if chill.is_empty():
				chill = {"stacks": 0, "remaining": 0.0, "source": source, "cast": cast}
			var cap = int(d.cap)
			var can_freeze = not bool(params.get("no_freeze", false))
			chill.stacks = mini(cap if can_freeze else cap - 1, int(chill.stacks) + stacks)
			chill.remaining = duration
			chill.cast = cast
			if can_freeze and int(chill.stacks) >= cap and freeze_immunity <= 0.0:
				chill = {}
				apply("frozen", {}, source)
				freeze_immunity = remaining_of("frozen") + float(d.refreeze_immunity)
		"entangled":
			_set_timed(id, duration, float(params.get("strength", d.get("slow", 0.25))), source)
			entangle_times.append(clock)
			entangle_times = entangle_times.filter(func(t): return clock - t <= float(d.root_window) + 0.0001)
			if entangle_times.size() >= int(d.root_after):
				entangle_times.clear()
				apply("rooted", {"duration": float(d.root_duration)}, source)
		"shocked":
			_set_timed(id, duration, 1.0, source)
			if hit > 0.0 and not bool(params.get("no_arc", false)):
				_arc(hit * float(d.arc_share), float(d.arc_range), source)
		_:
			if str(d.get("kind", "")) == "hard":
				if (is_boss() or is_elite()) and clock - last_hard_cc < float(rule("hard_cc_window", 4.0)):
					duration *= float(rule("hard_cc_repeat_multiplier", 0.5))
				last_hard_cc = clock
			var strength = float(params.get("strength", d.get("slow", 1.0)))
			_set_timed(id, duration, strength, source)
	_refresh_modifiers()

func _set_timed(id: String, duration: float, strength: float, source: Dictionary) -> void:
	var current = timed.get(id, {})
	timed[id] = {"remaining": maxf(duration, float(current.get("remaining", 0.0))), "strength": maxf(strength, float(current.get("strength", 0.0))), "source": source, "cast": source.get("cast_id", null)}

func _hemorrhage(per_tick_added: float, source: Dictionary) -> void:
	var d = def("bleed").hemorrhage
	var e = _owner()
	var max_health = float(e.get("max_health")) if e and e.get("max_health") != null else 0.0
	var pct = float(d.boss_max_health) if is_boss() else (float(d.elite_max_health) if is_elite() else float(d.max_health))
	bleed_meter = 0.0
	reactions_fired.append("hemorrhage")
	_deal(max_health * pct + float(d.bleed_multiplier) * per_tick_added, "raw", source, true)

func _arc(amount: float, reach: float, source: Dictionary) -> void:
	var e = _owner()
	if e == null or not e.is_inside_tree():
		return
	var best = null
	var best_d = reach
	for other in e.get_tree().get_nodes_in_group("enemies"):
		if other == e or not is_instance_valid(other) or bool(other.get("dying")):
			continue
		var dist = (other.global_position - e.global_position).length()
		if dist <= best_d:
			best = other
			best_d = dist
	if best:
		preload("res://scripts/engine/Effects.gd").apply(best, {"type": "damage", "entries": [{"amount": amount, "damage_type": "storm"}], "element": "storm", "dot": true}, source, e.global_position)
		if best.has_method("apply_effect"):
			best.apply_effect({"type": "status", "status": "shocked", "no_arc": true}, source, e.global_position)

# ---------------------------------------------------------------- reactions

## Called by the effects pipeline for every direct (non-DoT) damage hit. Returns extra damage for this entity.
func on_hit(effect: Dictionary, source: Dictionary, origin: Vector2) -> float:
	if clock < reaction_ready_at:
		return 0.0
	var elements := {}
	var total := 0.0
	for entry in effect.get("entries", []):
		var amount = float(entry.get("amount", 0.0))
		total += amount
		var kind = preload("res://scripts/engine/TypeChart.gd").normalize(str(entry.get("chart_element", entry.get("damage_type", "raw"))))
		if amount > 0.0:
			elements[kind] = true
	var spell_element = preload("res://scripts/engine/TypeChart.gd").normalize(str(effect.get("element", "")))
	if spell_element != "":
		elements[spell_element] = true
	var cast = source.get("cast_id", null)
	var extra := 0.0
	var fired := ""
	if elements.has("fire") and (_other(chill, cast) or _other(timed.get("frozen", {}), cast)):
		fired = "thaw"
		chill = {}
		timed.erase("frozen")
		_burst(total * 0.3, "water", 90.0, source)
	elif elements.has("earth") and _other(timed.get("frozen", {}), cast):
		fired = "shatter"
		timed.erase("frozen")
		extra += total * 0.5
	elif elements.has("fire") and _other(poison, cast):
		fired = "toxic_flare"
		var remaining = _poison_remaining()
		poison = {}
		_burst(remaining * 0.6, "plague", 100.0, source)
	elif elements.has("arcane") and (_other(bleed, cast) or _other(poison, cast) or burns.any(func(b): return b.cast == null or b.cast != cast)):
		fired = "overload"
		extra += _bleed_remaining() + _poison_remaining() + _burns_remaining()
		bleed = {}
		poison = {}
		burns.clear()
	elif elements.has("life") and (_other(poison, cast) or _other(timed.get("weakened", {}), cast)):
		fired = "cleanse"
		extra += _poison_remaining() + (10.0 if timed.has("weakened") else 0.0)
		poison = {}
		timed.erase("weakened")
	if fired != "":
		reactions_fired.append(fired)
		reaction_ready_at = clock + float(rule("reaction_cooldown", 1.0))
		_refresh_modifiers()
	return extra

func _other(instance: Dictionary, cast) -> bool:
	if instance.is_empty():
		return false
	var mine = instance.get("cast", null)
	return mine == null or cast == null or mine != cast

func _burst(amount: float, kind: String, reach: float, source: Dictionary) -> void:
	var e = _owner()
	if amount <= 0.0 or e == null or not e.is_inside_tree():
		return
	var effects = preload("res://scripts/engine/Effects.gd")
	for other in e.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(other) or bool(other.get("dying")):
			continue
		if (other.global_position - e.global_position).length() <= reach:
			effects.apply(other, {"type": "damage", "entries": [{"amount": amount, "damage_type": kind}], "element": kind, "dot": true}, source, e.global_position)

func _poison_remaining() -> float:
	if poison.is_empty():
		return 0.0
	var d = def("poison")
	var total = 0.0
	var ticks_left = int(ceil(float(poison.remaining) / float(d.tick)))
	for i in ticks_left:
		total += float(poison.base) * pow(1.0 + float(d.ramp), int(poison.ticks) + i)
	return total

func _bleed_remaining() -> float:
	if bleed.is_empty():
		return 0.0
	return float(bleed.per_tick) * ceil(float(bleed.remaining) / float(def("bleed").tick))

func _burns_remaining() -> float:
	var total = 0.0
	for b in burns:
		total += float(b.per_tick) * int(b.ticks_left)
	return total

# ---------------------------------------------------------------- ticking

func _physics_process(delta: float) -> void:
	# Enemies tick from process_status_effects; a component on anything else ticks itself.
	var e = _owner()
	if e == null or not e.has_method("process_status_effects"):
		tick(delta)

func tick(delta: float) -> void:
	clock += delta
	freeze_immunity = maxf(0.0, freeze_immunity - delta)
	var expired := []
	for id in timed:
		timed[id].remaining = float(timed[id].remaining) - delta
		if float(timed[id].remaining) <= 0.0:
			expired.append(id)
	for id in expired:
		timed.erase(id)
	if not chill.is_empty():
		chill.remaining = float(chill.remaining) - delta
		if float(chill.remaining) <= 0.0:
			chill = {}
	# Burns
	for b in burns:
		b.acc = float(b.acc) + delta
		while float(b.acc) >= float(b.tick) - 0.00001 and int(b.ticks_left) > 0:
			b.acc = float(b.acc) - float(b.tick)
			b.ticks_left = int(b.ticks_left) - 1
			_deal(float(b.per_tick), "fire", b.source, false)
	burns = burns.filter(func(b): return int(b.ticks_left) > 0)
	# Bleed
	bleed_since_hit += delta
	if bleed_since_hit > float(def("bleed").get("meter_decay_delay", 2.0)):
		bleed_meter = maxf(0.0, bleed_meter - float(def("bleed").get("meter_decay", 0.1)) * delta)
	if not bleed.is_empty():
		var tick_len = float(def("bleed").tick)
		bleed.acc = float(bleed.acc) + delta
		while float(bleed.acc) >= tick_len - 0.00001 and float(bleed.remaining) > 0.0:
			bleed.acc = float(bleed.acc) - tick_len
			bleed.remaining = float(bleed.remaining) - tick_len
			_deal(float(bleed.per_tick), "raw", bleed.source, true)
		if float(bleed.remaining) <= 0.00001:
			bleed = {}
	# Poison
	if not poison.is_empty():
		var d = def("poison")
		poison.acc = float(poison.acc) + delta
		while float(poison.acc) >= float(d.tick) - 0.00001 and float(poison.remaining) > 0.0:
			poison.acc = float(poison.acc) - float(d.tick)
			poison.remaining = float(poison.remaining) - float(d.tick)
			_deal(float(poison.base) * pow(1.0 + float(d.ramp), int(poison.ticks)), "plague", poison.source, false)
			poison.ticks = int(poison.ticks) + 1
		if float(poison.remaining) <= 0.00001:
			poison = {}
	_refresh_modifiers()

func _deal(amount: float, kind: String, source: Dictionary, ignores_armour: bool) -> void:
	var e = _owner()
	if amount <= 0.0 or e == null or bool(e.get("dying")):
		return
	preload("res://scripts/engine/Effects.gd").apply(e, {"type": "damage", "entries": [{"amount": amount, "damage_type": kind, "ignores_armour": ignores_armour}], "element": kind, "dot": true}, source)

# ---------------------------------------------------------------- queries

func has(id: String) -> bool:
	match id:
		"burn": return not burns.is_empty()
		"bleed": return not bleed.is_empty()
		"poison": return not poison.is_empty()
		"chilled": return not chill.is_empty()
	return timed.has(id)

func remaining_of(id: String) -> float:
	return float(timed.get(id, {}).get("remaining", 0.0))

func chill_stacks() -> int:
	return int(chill.get("stacks", 0))

func locked(kind: String) -> bool:
	for id in timed:
		if kind in def(id).get("locks", []):
			return true
	return false

func slow_amount() -> float:
	var slows: Array = []
	if not chill.is_empty():
		slows.append(float(def("chilled").slow_per_stack) * int(chill.stacks))
	for id in ["slowed", "entangled"]:
		if timed.has(id):
			slows.append(float(timed[id].strength))
	if slows.is_empty():
		return 0.0
	slows.sort()
	slows.reverse()
	var total = float(slows[0])
	for i in range(1, slows.size()):
		total += float(slows[i]) * float(rule("secondary_slow_share", 0.1))
	return minf(total, float(rule("slow_cap", 0.7)))

func move_multiplier() -> float:
	if locked("move"):
		return 0.0
	return 1.0 - slow_amount()

func damage_taken_multiplier() -> float:
	return float(def("vulnerable").damage_taken) if timed.has("vulnerable") else 1.0

func damage_dealt_multiplier() -> float:
	if timed.has("weakened"):
		return float(def("weakened").damage_dealt)
	if not poison.is_empty():
		return 1.0 - float(def("poison").weaken)
	return 1.0

## Weaken lowers the entity's own outgoing damage value while it lasts.
func _refresh_modifiers() -> void:
	var e = _owner()
	if e == null or e.get("damage") == null:
		return
	var wanted = damage_dealt_multiplier()
	if is_equal_approx(wanted, _applied_dealt):
		return
	if _weaken_base == null:
		_weaken_base = float(e.get("damage")) / _applied_dealt
	e.set("damage", float(_weaken_base) * wanted)
	_applied_dealt = wanted
	if is_equal_approx(wanted, 1.0):
		_weaken_base = null
