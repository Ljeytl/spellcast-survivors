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
var bleed: Dictionary = {}   # {stacks: [{per_tick, remaining, spell}], acc, source, cast, by_spell}
var bleed_meter := 0.0
var bleed_since_hit := 999.0
var poison: Dictionary = {}  # {stacks: [{base, remaining, ticks, spell}], acc, source, cast, by_spell}
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

## A monster with an element shrugs off that element's own status (a FIERY elite cannot burn); the
## element's direct damage still lands, through the type chart. statuses.json _rules.own_element_immune.
func immune_to(id: String) -> bool:
	var e = _owner()
	if e == null or not bool(rule("own_element_immune", false)):
		return false
	var own = str(e.get("element")) if e.get("element") != null else ""
	return own != "" and own == str(def(id).get("element", ""))

# ---------------------------------------------------------------- applying

func apply(id: String, params: Dictionary = {}, source: Dictionary = {}) -> void:
	var d = def(id)
	if d.is_empty() or immune_to(id):
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
				bleed = {"stacks": [], "acc": 0.0, "source": source, "cast": cast, "last_add": 0.0, "by_spell": {}}
			# Each application is its own stack with its own timer: bleed stacks without a cap, but its
			# strength follows how fast you hit, not how long the fight has lasted.
			bleed.stacks.append({"per_tick": per_tick, "remaining": duration, "spell": str(source.get("spell", ""))})
			_refresh_bleed_split()
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
				poison = {"stacks": [], "acc": 0.0, "source": source, "cast": cast, "by_spell": {}}
			# Each application is its own stack with its own clock and its own ramp (like bleed), so
			# refreshing poison forever cannot compound; each stack's ramp stops at ramp_max.
			poison.stacks.append({"base": add, "remaining": duration, "ticks": 0, "spell": str(source.get("spell", ""))})
			_refresh_poison_split()
			poison.source = source
			poison.cast = cast
		"chilled":
			var stacks = int(params.get("stacks", 1))
			if hit > 0.0 and not bool(params.get("no_frostbite", false)):
				_deal(float(d.frostbite_share) * hit * stacks, "water", source, "frostbite")
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
		"vulnerable":
			# Stacks (doc 21 §2.1): each adds damage taken, up to a cap; a new application refreshes them.
			# One stack per application unless a spell says otherwise (Focus Ray: half a stack per tick).
			var add = float(params.get("stacks", 1.0))
			var now = float(timed.get("vulnerable", {}).get("strength", 0.0))
			timed["vulnerable"] = {"remaining": duration, "strength": minf(float(d.max_stacks), now + add), "source": source, "cast": cast}
		"shocked":
			# A mark: the next Lightning hit chains it, Water/Ice conducts it, Earth grounds it (doc 18 §6.1b).
			_set_timed(id, duration, 1.0, source)
			# The jolt is a real stun (doc 21 §5.3); Prism Ray's shock is the mark alone.
			if not bool(params.get("no_stun", false)):
				apply("stunned", {"duration": float(d.get("stun", 0.2))}, source)
		_:
			if str(d.get("kind", "")) == "hard":
				if (is_boss() or is_elite()) and clock - last_hard_cc < float(rule("hard_cc_window", 4.0)):
					duration *= float(rule("hard_cc_repeat_multiplier", 0.5))
				last_hard_cc = clock
			var strength = float(params.get("strength", d.get("slow", 1.0)))
			_set_timed(id, duration, strength, source)
	_refresh_modifiers()
	if id != "frozen" or has("frozen"):
		_announce("applied", {"status": id, "stacks": _stacks_of(id)})

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
	_announce("reaction", {"name": "hemorrhage"})
	_deal(max_health * pct + float(d.bleed_multiplier) * per_tick_added, "bleed", source, "hemorrhage")

## Chain: storm damage arcs to the nearest few enemies and shocks them. They carry this hit's cast,
## so the same cast cannot chain them again; the next cast can.
func _chain(amount: float, count: int, reach: float, source: Dictionary) -> Array:
	var e = _owner()
	var targets: Array = []
	if e == null or not e.is_inside_tree():
		return targets
	var near: Array = []
	for other in e.get_tree().get_nodes_in_group("enemies"):
		if other == e or not is_instance_valid(other) or bool(other.get("dying")):
			continue
		var dist = (other.global_position - e.global_position).length()
		if dist <= reach:
			near.append([dist, other])
	near.sort_custom(func(a, b): return a[0] < b[0])
	var effects = preload("res://scripts/engine/Effects.gd")
	for pair in near.slice(0, count):
		var other = pair[1]
		targets.append(other.global_position)
		effects.apply(other, {"type": "damage", "entries": [{"amount": amount, "damage_type": "storm"}], "element": "storm", "dot": true}, tag(source, "chain"), e.global_position)
		if is_instance_valid(other) and not bool(other.get("dying")):
			effects.apply(other, {"type": "status", "status": "shocked"}, source, e.global_position)
	return targets

# ---------------------------------------------------------------- reactions

## Called by the effects pipeline for every direct (non-DoT) damage hit. Returns extra damage for this entity.
func on_hit(effect: Dictionary, source: Dictionary, origin: Vector2) -> float:
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
	# Grounded: Earth removes shock with no bonus, even during the reaction cooldown.
	if elements.has("earth") and timed.has("shocked"):
		timed.erase("shocked")
		_announce("reaction", {"name": "grounded"})
	if clock < reaction_ready_at:
		return 0.0
	var extra := 0.0
	var fired := ""
	var chained_to: Array = []
	var shock_def = def("shocked")
	if elements.has("storm") and _other(timed.get("shocked", {}), cast):
		fired = "chain"
		timed.erase("shocked")
		chained_to = _chain(total * float(shock_def.chain_share), int(shock_def.chain_targets), float(shock_def.chain_range), source)
	elif elements.has("water") and _other(timed.get("shocked", {}), cast):
		fired = "conduct"
		timed.erase("shocked")
		_burst(total * float(shock_def.conduct_share), "storm", float(shock_def.conduct_radius), source, "conduct")
	elif elements.has("fire") and (_other(chill, cast) or _other(timed.get("frozen", {}), cast)):
		fired = "thaw"
		chill = {}
		timed.erase("frozen")
		_burst(total * 0.3, "water", 90.0, source, "thaw")
	elif elements.has("earth") and _other(timed.get("frozen", {}), cast):
		fired = "shatter"
		timed.erase("frozen")
		extra += total * 0.5
	elif elements.has("fire") and _other(poison, cast):
		fired = "toxic_flare"
		var remaining = _poison_remaining()
		var poisoners = _shared(poison)
		poison = {}
		_burst(remaining * 0.6, "plague", 100.0, poisoners, "toxic flare")
	elif elements.has("life") and (_other(poison, cast) or _other(timed.get("weakened", {}), cast)):
		fired = "cleanse"
		extra += _poison_remaining() + (10.0 if timed.has("weakened") else 0.0)
		poison = {}
		timed.erase("weakened")
	if fired != "":
		reactions_fired.append(fired)
		reaction_ready_at = clock + float(rule("reaction_cooldown", 1.0))
		_refresh_modifiers()
		_announce("reaction", {"name": fired, "targets": chained_to})
	return extra

func _other(instance: Dictionary, cast) -> bool:
	if instance.is_empty():
		return false
	var mine = instance.get("cast", null)
	return mine == null or cast == null or mine != cast

func _burst(amount: float, kind: String, reach: float, source: Dictionary, via: String) -> void:
	source = tag(source, via)
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
	for stack in poison.stacks:
		var ticks_left = int(ceil(float(stack.remaining) / float(d.tick) - 0.0001))
		for i in ticks_left:
			total += _poison_tick(stack, int(stack.ticks) + i)
	return total

## One poison tick of a stack: base × (1 + ramp)^ticks, capped at base × ramp_max (data/statuses.json).
func _poison_tick(stack: Dictionary, ticks: int) -> float:
	var d = def("poison")
	return float(stack.base) * minf(pow(1.0 + float(d.ramp), ticks), float(d.get("ramp_max", INF)))

## Credit for the next poison tick goes to the spells whose stacks are still active, by what they deal.
func _refresh_poison_split() -> void:
	var by_spell := {}
	for stack in poison.get("stacks", []):
		var spell = str(stack.spell)
		if not spell.is_empty():
			by_spell[spell] = float(by_spell.get(spell, 0.0)) + _poison_tick(stack, int(stack.ticks))
	poison.by_spell = by_spell

func _bleed_remaining() -> float:
	if bleed.is_empty():
		return 0.0
	var tick_len = float(def("bleed").tick)
	var total = 0.0
	for stack in bleed.stacks:
		total += float(stack.per_tick) * ceil(float(stack.remaining) / tick_len - 0.0001)
	return total

## Credit for the next bleed tick goes to the spells whose stacks are still active.
func _refresh_bleed_split() -> void:
	var by_spell := {}
	for stack in bleed.get("stacks", []):
		var spell = str(stack.spell)
		if not spell.is_empty():
			by_spell[spell] = float(by_spell.get(spell, 0.0)) + float(stack.per_tick)
	bleed.by_spell = by_spell

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
		_announce("expired", {"status": id})
	if not chill.is_empty():
		chill.remaining = float(chill.remaining) - delta
		if float(chill.remaining) <= 0.0:
			chill = {}
			_announce("expired", {"status": "chilled"})
	# Burns
	for b in burns:
		b.acc = float(b.acc) + delta
		while float(b.acc) >= float(b.tick) - 0.00001 and int(b.ticks_left) > 0:
			b.acc = float(b.acc) - float(b.tick)
			b.ticks_left = int(b.ticks_left) - 1
			_deal(float(b.per_tick), "fire", b.source, "burn")
	var was_burning = not burns.is_empty()
	burns = burns.filter(func(b): return int(b.ticks_left) > 0)
	if was_burning and burns.is_empty():
		_announce("expired", {"status": "burn"})
	# Bleed
	bleed_since_hit += delta
	if bleed_since_hit > float(def("bleed").get("meter_decay_delay", 2.0)):
		bleed_meter = maxf(0.0, bleed_meter - float(def("bleed").get("meter_decay", 0.1)) * delta)
	if not bleed.is_empty():
		var tick_len = float(def("bleed").tick)
		bleed.acc = float(bleed.acc) + delta
		while float(bleed.acc) >= tick_len - 0.00001 and not bleed.stacks.is_empty():
			bleed.acc = float(bleed.acc) - tick_len
			var amount = 0.0
			for stack in bleed.stacks:
				amount += float(stack.per_tick)
				stack.remaining = float(stack.remaining) - tick_len
			_refresh_bleed_split()
			_deal(amount, "bleed", _shared(bleed), "bleed")
			if bleed.is_empty():
				break  # the tick killed the enemy and cleared its statuses
			bleed.stacks = bleed.stacks.filter(func(stack): return float(stack.remaining) > 0.00001)
		if not bleed.is_empty() and bleed.stacks.is_empty():
			bleed = {}
			_announce("expired", {"status": "bleed"})
	# Poison
	if not poison.is_empty():
		var d = def("poison")
		poison.acc = float(poison.acc) + delta
		while float(poison.acc) >= float(d.tick) - 0.00001 and not poison.stacks.is_empty():
			poison.acc = float(poison.acc) - float(d.tick)
			var amount = 0.0
			_refresh_poison_split()
			for stack in poison.stacks:
				amount += _poison_tick(stack, int(stack.ticks))
				stack.ticks = int(stack.ticks) + 1
				stack.remaining = float(stack.remaining) - float(d.tick)
			_deal(amount, "plague", _shared(poison), "poison")
			if poison.is_empty():
				break  # the tick killed the enemy and cleared its statuses
			poison.stacks = poison.stacks.filter(func(stack): return float(stack.remaining) > 0.00001)
		if not poison.is_empty() and poison.stacks.is_empty():
			poison = {}
			_announce("expired", {"status": "poison"})
	_refresh_modifiers()

## Status moments for the VFX layer (docs/VFX_EVENTS.md): calls /root/Vfx.status_event(enemy, event, data)
## when it exists. Read-only for VFX; one call per moment; never waits on it.
## event: "applied" {status, stacks}, "reaction" {name, targets}, "expired" {status}; data always has position.
func _announce(event: String, data: Dictionary) -> void:
	var e = _owner()
	if e == null or not e.is_inside_tree():
		return
	var vfx = e.get_node_or_null("/root/Vfx")
	if vfx == null or not vfx.has_method("status_event"):
		return
	data["position"] = e.global_position
	vfx.status_event(e, event, data)

## Current stack count of a status, for VFX intensity: chill stacks, bleed stacks, burn instances, else 1.
func _stacks_of(id: String) -> int:
	match id:
		"chilled": return int(chill.get("stacks", 0))
		"bleed": return bleed.get("stacks", []).size()
		"burn": return burns.size()
		"vulnerable": return ceili(float(timed.get("vulnerable", {}).get("strength", 0.0)))
	return 1 if has(id) else 0

## DoT and status damage. Bleed is its own damage type, so only a bleed resistance reduces it.
func _deal(amount: float, kind: String, source: Dictionary, via: String) -> void:
	var e = _owner()
	if amount <= 0.0 or e == null or bool(e.get("dying")):
		return
	preload("res://scripts/engine/Effects.gd").apply(e, {"type": "damage", "entries": [{"amount": amount, "damage_type": kind}], "element": kind, "dot": true}, tag(source, via))

## The pool's latest source plus "split": {spell: fraction} for damage credit (kills still go to the latest).
static func _shared(pool: Dictionary) -> Dictionary:
	var shared: Dictionary = pool.get("source", {}).duplicate()
	var by_spell: Dictionary = pool.get("by_spell", {})
	var total = 0.0
	for spell in by_spell:
		total += float(by_spell[spell])
	if by_spell.size() > 1 and total > 0.0:
		var split := {}
		for spell in by_spell:
			split[spell] = float(by_spell[spell]) / total
		shared["split"] = split
	return shared

## The casting spell's source plus how this damage was dealt (bleed, burn, thaw…), so the end screen
## can credit DoTs and reactions to the spell that caused them.
static func tag(source: Dictionary, via: String) -> Dictionary:
	var tagged = source.duplicate()
	tagged["via"] = via
	return tagged

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
	var chill_slow := 0.0
	if not chill.is_empty():
		chill_slow = float(def("chilled").slow_per_stack) * int(chill.stacks)
		slows.append(chill_slow)
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
	# Chill alone may pass the cap: it climbs 20% a stack toward freeze (doc 21 §2).
	return minf(total, maxf(float(rule("slow_cap", 0.7)), chill_slow))

func move_multiplier() -> float:
	if locked("move"):
		return 0.0
	return 1.0 - slow_amount()

func damage_taken_multiplier() -> float:
	if not timed.has("vulnerable"):
		return 1.0
	return 1.0 + float(def("vulnerable").per_stack) * float(timed.vulnerable.strength)

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

## Overload (doc 21 §3): an elementless payoff word. Every damage over time pending on this entity
## (bleed, poison, burn: what has built up, not ramp still to come) lands now at `multiplier`, credited
## to the spells that applied it, and is cleared. Nothing pending: nothing happens. Returns the damage.
func overload(multiplier: float, source: Dictionary) -> float:
	var pending: Array = []
	if not bleed.is_empty():
		pending.append([_bleed_remaining(), "bleed", _shared(bleed)])
	if not poison.is_empty():
		pending.append([_poison_remaining(), "plague", _shared(poison)])
	for b in burns:
		pending.append([float(b.per_tick) * int(b.ticks_left), "fire", b.source])
	if pending.is_empty():
		return 0.0
	bleed = {}
	poison = {}
	burns.clear()
	var total := 0.0
	for p in pending:
		total += float(p[0]) * multiplier
		_deal(float(p[0]) * multiplier, str(p[1]), p[2], "overload")
	reactions_fired.append("overload")
	_announce("reaction", {"name": "overload"})
	_refresh_modifiers()
	return total
