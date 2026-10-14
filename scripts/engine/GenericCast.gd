extends Node2D
## One cast of a generic spell: caster-level keywords, arrangement, release, and the parts it spawns
## (doc 18 §4.6–4.8). Steps its parts itself; tests set `manual` and call step().

const SpellPart = preload("res://scripts/engine/SpellPart.gd")
const MAX_LINK_DEPTH = 3
const MAX_SPAWNS = 48

var plan: Dictionary = {}
var caster: Node2D = null
var world: Node = null
var source: Dictionary = {}
var manual := false
var rng := RandomNumberGenerator.new()
var clock := 0.0
var pending: Array = []        # {at, power, size, first}
var spawns: Array = []         # queued root spawns {at, ...}
var parts: Array = []
var spawned := 0
var hits_log: Array = []       # {part, enemy_id} for tests/telemetry
var finished := false
var release_acc := 0.0
var aim_dir := Vector2.RIGHT
var shared_hits: Dictionary = {} # enemy id -> cast clock of the last hit (limits.rehit_shared)
var once: Dictionary = {}      # payload items marked once_per_cast: "item@enemy" already applied
var had_caster := false        # a cast whose caster is freed ends (run teardown, old effect nodes)
var forced_dir := Vector2.ZERO  # aim set by the caller
var forced_target = null       # ported spells keep their old targeting: the caller picks the target
var target_picker: Callable    # or picks it when each copy is released (release.retarget)
var point_picker: Callable     # arrangement "points": the caller picks the ground points (old Meteor Shower)

func setup(p_plan: Dictionary, p_caster: Node2D, p_world: Node, p_source: Dictionary, p_manual: bool = false, seed_value: int = -1) -> void:
	plan = p_plan
	caster = p_caster
	had_caster = p_caster != null
	world = p_world
	source = p_source
	manual = p_manual
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	heal_left = float(plan.get("heal_budget", 0.0))
	for i in plan.get("casts", []).size():
		var c: Dictionary = plan.casts[i]
		pending.append({"at": float(c.delay), "power": float(c.power), "size": float(c.size), "first": i == 0})
	# VFX: anticipation for delayed / charged casts (docs/VFX_EVENTS.md); read-only.
	var vfx = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Vfx") if Engine.get_main_loop() is SceneTree else null
	if vfx:
		vfx.cast_queued(self)

func _ready() -> void:
	add_to_group("generic_casts")

## Live parts the cast spawned itself (not event children), oldest first.
func root_parts() -> Array:
	return parts.filter(func(p): return is_instance_valid(p) and not p.done and p.depth == 0)

func _physics_process(delta: float) -> void:
	if not manual:
		step(delta)
		if finished and get_child_count() == 0:
			queue_free()

func step(delta: float) -> void:
	if finished:
		return
	if had_caster and not is_instance_valid(caster):
		for p in parts:
			if is_instance_valid(p) and not p.done:
				p.finish(false)
		parts.clear()
		pending.clear()
		spawns.clear()
		finished = true
		return
	clock += delta
	for c in pending.duplicate():
		if clock + 0.00001 >= float(c.at):
			pending.erase(c)
			_start_cast(c)
	for s in spawns.duplicate():
		if clock + 0.00001 >= float(s.at):
			spawns.erase(s)
			_spawn_root(s)
	_release_step(delta)
	for p in parts.duplicate():
		if is_instance_valid(p) and not p.done:
			p.step(delta)
	parts = parts.filter(func(p): return is_instance_valid(p) and not p.done)
	if pending.is_empty() and spawns.is_empty() and parts.is_empty():
		finished = true

## Same as run(): lets tests drive ported spells like the old effect nodes.
func advance(seconds: float) -> void:
	manual = true
	run(seconds)

## Run until finished or out of time (tests).
## on_step lets a test tick other systems (statuses) on the same clock.
func run(seconds: float, dt: float = 1.0 / 60.0, on_step: Callable = Callable()) -> void:
	# Whole steps, then the remainder: exactly `seconds` of game time (no float drift).
	var whole = int(floor(seconds / dt + 0.000001))
	for i in whole:
		if finished:
			return
		step(dt)
		if on_step.is_valid():
			on_step.call(dt)
	var rest = seconds - whole * dt
	if rest > 0.000001 and not finished:
		step(rest)
		if on_step.is_valid():
			on_step.call(rest)

# --- caster ----------------------------------------------------------------------------
func caster_position() -> Vector2:
	return caster.global_position if is_instance_valid(caster) else global_position

## Healing words: what is left of this cast's healing budget (doc 21 §4.3). Takes up to `amount`.
var heal_left := 0.0
func spend_heal(amount: float) -> float:
	var took = clampf(amount, 0.0, heal_left)
	heal_left -= took
	return took

## LEECHING: heal a share of the damage this cast deals, up to a cap per cast (a share of max health,
## kept below SANGUINE's cost so blood magic always costs something).
var leech_taken := 0.0
func leech(dealt: float) -> void:
	var flags: Dictionary = plan.get("flags", {})
	if not flags.has("leeching") or dealt <= 0.0 or not is_instance_valid(caster) or caster.get("max_health") == null:
		return
	var cap = float(caster.max_health) * float(flags.leeching.get("cap", 0.08))
	var amount = minf(dealt * float(flags.leeching.get("share", 0.15)), cap - leech_taken)
	if amount > 0.0:
		leech_taken += amount
		heal_caster(amount)

## A healing circle where an area impact landed: heals the caster while they stand in it.
func spawn_heal_zone(at: Vector2, radius: float, amount: float, duration: float) -> void:
	if world == null or amount <= 0.0:
		return
	var zone = preload("res://scripts/HealingZone.gd").new()
	zone.player_ref = weakref(caster)
	zone.radius = radius
	zone.total = amount
	zone.duration = duration
	world.add_child(zone)
	zone.global_position = at

func heal_caster(amount: float, visual_size: float = 1.0) -> void:
	if is_instance_valid(caster) and caster.has_method("heal"):
		var heal: Callable = caster.heal
		if heal.get_argument_count() >= 2:
			heal.call(amount, visual_size)   # the player shows bigger heals bigger (MEGA)
		else:
			heal.call(amount)

func _start_cast(c: Dictionary) -> void:
	var flags: Dictionary = plan.get("flags", {})
	if c.first:
		if flags.has("sanguine") and is_instance_valid(caster) and caster.get("health") != null:
			var cost = float(caster.get("max_health")) * float(flags.sanguine.get("health_cost", 0.1))
			caster.set("health", maxf(1.0, float(caster.get("health")) - cost))
			# Blood price: not damage (no hurt, ignores invulnerability) but the health bar and telemetry must see it.
			if caster.get("last_damage_context") != null:
				caster.set("last_damage_context", {"kind": "sanguine", "damage": cost})
			if caster.has_signal("health_changed"):
				caster.health_changed.emit(float(caster.get("health")), float(caster.get("max_health")), float(caster.get("overheal")) if caster.get("overheal") != null else 0.0)
		if flags.has("warding") and is_instance_valid(caster) and caster.has_method("add_ward"):
			caster.add_ward(float(flags.warding.get("absorb", 30.0)), float(flags.warding.get("duration", 6.0)))
		if flags.has("blinking") and is_instance_valid(caster):
			var near = nearest_enemy(caster.global_position, INF, {})
			var away = near.global_position.direction_to(caster.global_position) if near else Vector2.LEFT
			caster.global_position += away * float(flags.blinking.get("distance", 140.0))
	var target = _pick_target()
	if forced_dir != Vector2.ZERO:
		target = null   # aimed by the caller (Earth Shield erupts toward the attacker)
	if target == null and bool(plan.get("needs_target", false)):
		return   # old area spells with nothing worth striking cast nothing
	aim_dir = caster_position().direction_to(target.global_position) if target else (forced_dir.normalized() if forced_dir != Vector2.ZERO else _facing())
	var vfx = get_node_or_null("/root/Vfx")
	if vfx:
		vfx.cast_started(self)
	var root_name = str(plan.root)
	var root: Dictionary = plan.parts[root_name]
	var arrangement: Dictionary = plan.get("arrangement", {"type": "single", "count": 1})
	var release: Dictionary = plan.get("release", {"type": "together"})
	var count = maxi(1, int(arrangement.get("count", 1)))
	var points: Array = []
	if str(arrangement.get("type", "")) == "points":
		points = point_picker.call(count) if point_picker.is_valid() else []
		if points.is_empty():
			return   # nothing worth bombarding
		count = points.size()
	var spread = deg_to_rad(float(arrangement.get("spread", 14.0)))
	var radius = float(arrangement.get("radius", 80.0))
	for i in count:
		var t = target
		if plan.flags.has("scattered"):
			var pool = enemies()
			t = pool[rng.randi() % pool.size()] if not pool.is_empty() else null
		var dir = caster_position().direction_to(t.global_position) if t else aim_dir
		var base = _origin_for(root, t, dir)
		var pos = base
		var orbit_angle = 0.0
		match str(arrangement.get("type", "single")):
			"points":
				pos = points[i]
				dir = caster_position().direction_to(pos) if caster_position() != pos else aim_dir
			"fan":
				if not (plan.flags.has("scattered") and t != null):
					dir = dir.rotated(spread * (i - (count - 1) * 0.5))
			"ring":
				var ang = TAU * i / count
				orbit_angle = ang
				if not _orbits(root):
					pos = base + Vector2.RIGHT.rotated(ang) * radius
					if str(root.delivery) == "projectile":
						dir = Vector2.RIGHT.rotated(ang)
						if bool(arrangement.get("aimed", false)):
							# Old Cross Blade: the ring is turned so one blade flies at the target.
							var aim_angle = aim_dir.angle() if target != null else float(arrangement.get("default_angle", -PI / 2.0))
							dir = Vector2.from_angle(aim_angle + float(arrangement.get("offset", 0.0)) + ang)
			"line":
				var step_len = maxf(40.0, radius)
				pos = base + dir.orthogonal() * step_len * (i - (count - 1) * 0.5)
		var at = clock
		if str(release.get("type", "together")) == "staggered":
			at += float(release.get("interval", 0.15)) * i
		var spawn = {"at": at, "index": i, "pos": pos, "dir": dir, "power": c.power, "size": c.size, "orbit": orbit_angle, "target": t,
			"held": str(release.get("type", "together")) == "triggered"}
		if at <= clock + 0.00001:
			_spawn_root(spawn)
		else:
			spawns.append(spawn)

func _orbits(part: Dictionary) -> bool:
	var motion: Array = part.get("motion", [])
	return not motion.is_empty() and str(motion[0].type) == "orbit"

func _origin_for(part: Dictionary, target, dir: Vector2) -> Vector2:
	match str(part.get("origin", "caster")):
		"target":
			return target.global_position if target else caster_position() + dir * 220.0
		"behind_caster":
			return caster_position() - dir * 120.0
		"target_or_caster":
			return target.global_position if target else caster_position()
		"toward_target":
			# Old Rune Trap: laid toward the target, at most `reach` from the caster.
			var reach = float(part.get("reach", 160.0))
			var d = caster_position().distance_to(target.global_position) if target else reach
			return caster_position() + dir * minf(reach, d)
	return caster_position()

func _facing() -> Vector2:
	if is_instance_valid(caster):
		for key in ["last_direction", "facing", "last_move_direction"]:
			var v = caster.get(key)
			if v is Vector2 and v.length() > 0.0:
				return v.normalized()
	return Vector2.RIGHT

func _pick_target():
	if target_picker.is_valid():
		var picked = target_picker.call()
		if picked != null and is_instance_valid(picked):
			return picked
	if forced_target != null and is_instance_valid(forced_target) and forced_target in enemies():
		return forced_target
	var pool = enemies()
	if pool.is_empty():
		return null
	if plan.flags.has("hunting"):
		var best = null
		var hp = -1.0
		for e in pool:
			var h = float(e.get("current_health")) if e.get("current_health") != null else 0.0
			if h > hp:
				hp = h
				best = e
		return best
	return nearest_enemy(caster_position(), INF, {})

func _spawn_root(s: Dictionary) -> void:
	var root_name = str(plan.root)
	if bool(plan.get("release", {}).get("retarget", false)) and int(s.get("index", 0)) > 0:
		# Staggered copies aim when they leave the caster, at the target worth hitting then.
		var t = _pick_target()
		if t == null:
			return   # nothing left worth hitting: the later copies are not thrown
		s.dir = caster_position().direction_to(t.global_position)
		s.target = t
		s.pos = _origin_for(plan.parts[root_name], t, s.dir)
	var part = _make_part(root_name, s.pos, s.dir, 0, float(s.power), float(s.size))
	if part == null:
		return
	part.orbit_angle = float(s.orbit)
	if part.delivery == "beam" and s.target != null and is_instance_valid(s.target):
		part.target_ref = weakref(s.target)
	if part.delivery == "infection" and part.infection != null:
		part.infection.start(s.target if s.target != null and is_instance_valid(s.target) else null, caster_position())
	if plan.get("arrangement", {}).has("stagger_life"):
		# Old Meteor Shower: every mark shows at once; each lands one interval after the last.
		part.life_total = part.total_life() + float(plan.arrangement.stagger_life) * int(s.get("index", 0))
	if _orbits(plan.parts[root_name]):
		part.global_position = caster_position() + Vector2.RIGHT.rotated(part.orbit_angle) * float(plan.parts[root_name].motion[0].get("radius", 80.0))
	if s.held:
		part.released = false
	if s.target and str(plan.parts[root_name].delivery) == "projectile" and (plan.flags.has("scattered") or bool(plan.get("release", {}).get("retarget", false))):
		part.assigned = s.target
		var speed = 600.0
		for ph in part.def.get("motion", []):
			if ph.has("speed"):
				speed = float(ph.speed)
				break
		part.reserve_until = part.global_position.distance_to(s.target.global_position) / maxf(speed, 1.0) + 0.25

func _make_part(name: String, pos: Vector2, dir: Vector2, depth: int, power: float, size: float):
	if spawned >= int(plan.get("max_spawns", MAX_SPAWNS)) or not plan.parts.has(name):
		return null
	spawned += 1
	var part = SpellPart.new()
	part.power_scale = power
	part.size_scale = size
	part.depth = depth
	part.name = "Part_" + name
	add_child(part)
	part.setup(self, name, plan.parts[name], pos, dir)
	parts.append(part)
	return part

# --- release (meteor ring) --------------------------------------------------------------
func _release_step(delta: float) -> void:
	var release: Dictionary = plan.get("release", {})
	if str(release.get("type", "")) != "triggered":
		return
	release_acc += delta
	var held = parts.filter(func(p): return is_instance_valid(p) and not p.done and not p.released and p.depth == 0)
	if held.is_empty():
		return
	if nearest_enemy(caster_position(), float(release.get("range", 450.0)), {}) == null:
		return
	if bool(release.get("one_at_a_time", true)):
		if release_acc >= float(release.get("interval", 0.15)):
			release_acc = 0.0
			held[0].released = true
	else:
		for p in held:
			p.released = true

# --- events -----------------------------------------------------------------------------
func spawn_event(parent, ev: Dictionary, at: Vector2, victim) -> void:
	var child_name = str(ev.get("part", ""))
	if not plan.parts.has(child_name):
		return
	var is_chain = bool(ev.get("chain", false))
	var remaining := 0
	if is_chain:
		remaining = int(ev.hops) if ev.has("hops") else parent.hops
		if remaining <= 0:
			_chain_end(parent, ev, at, victim)
			return
	elif parent.depth + 1 > int(plan.get("max_depth", MAX_LINK_DEPTH)):
		return
	var exclude: Dictionary = parent.exclude.duplicate() if is_chain else {}
	if victim != null and is_instance_valid(victim) and bool(ev.get("exclude_hit", false)):
		exclude[victim.get_instance_id()] = true
	var copies = maxi(1, int(ev.get("copies", 1)))
	var spread = deg_to_rad(float(ev.get("spread", 30.0)))
	var target = null
	var dir = parent.direction
	if is_chain:
		var reach = float(ev.get("range", parent.chain_range))
		target = nearest_enemy(at, reach, exclude)
		if target == null:
			_chain_end(parent, ev, at, victim)
			return
		dir = at.direction_to(target.global_position)
	if ev.has("turn"):
		dir = dir.rotated(deg_to_rad(float(ev.turn)))   # a fixed angle off the parent (Prism Ray's refraction)
	for i in copies:
		var d = dir.rotated(spread * (i - (copies - 1) * 0.5)) if copies > 1 else dir
		var child = _make_part(child_name, at, d, parent.depth + 1, parent.power_scale, parent.size_scale)
		if child == null:
			return
		child.exclude = exclude.duplicate()
		child.parent_hit = victim
		if is_chain:
			child.hops = remaining - 1
			child.chain_range = float(ev.get("range", parent.chain_range))
			child.assigned = target
		if str(child.delivery) == "volume":
			child.step(0.0)   # a burst lands the moment its event fires, not a frame later

## A chain that cannot go on fires its `end` event where it stopped (Lightning Bolt: one strike at
## the last enemy, doc 21 §5.6).
func _chain_end(parent, ev: Dictionary, at: Vector2, victim) -> void:
	if ev.has("end"):
		var end: Dictionary = ev.end.duplicate()
		end.erase("chain")
		spawn_event(parent, end, at, victim)

## A projectile's trail: a line field that grows from the throw point to the projectile.
func spawn_trail(parent, ev: Dictionary) -> void:
	var child = _make_part(str(ev.get("part", "")), parent.global_position, parent.direction.orthogonal(), parent.depth + 1, parent.power_scale, parent.size_scale)
	if child == null:
		return
	child.trail_parent = weakref(parent)
	child.trail_from = parent.global_position
	child.geo_override.length = 0.0

## Soul Bloom's ghost: heals the caster if hurt, else hunts the nearest enemy for the same amount.
func spawn_ghost(at: Vector2, amount: float) -> void:
	if not is_instance_valid(caster) or world == null or amount <= 0.0:
		return
	var ghost = preload("res://scripts/SoulGhost.gd").new()
	ghost.cast_ref = weakref(self)
	ghost.player_ref = weakref(caster)
	ghost.amount = amount
	ghost.source = preload("res://scripts/engine/StatusComponent.gd").tag(source, "ghost")
	world.add_child(ghost)
	ghost.global_position = at

## A collectible healing seed for the caster (Life Bolt).
func spawn_seed(at: Vector2, item: Dictionary) -> void:
	if not is_instance_valid(caster) or world == null:
		return
	var seed = preload("res://scripts/HealingSeed.gd").new()
	seed.player_ref = weakref(caster)
	seed.healing_amount = float(item.get("amount", 6.0))
	seed.healing_duration = float(item.get("duration", 2.0))
	seed.remaining = float(item.get("lifetime", 10.0))
	seed.cap = maxi(1, int(item.get("cap", 6)))
	seed.radius = float(item.get("radius", 28.0))
	world.add_child(seed)
	seed.global_position = at

func part_finished(_part) -> void:
	pass

func record_hit(part, enemy) -> void:
	hits_log.append({"part": part.part_name, "enemy": enemy.get_instance_id(), "depth": part.depth, "t": clock})

# --- queries ------------------------------------------------------------------------------
func enemies() -> Array:
	if not is_inside_tree():
		return []
	return get_tree().get_nodes_in_group("enemies").filter(func(e):
		return is_instance_valid(e) and e is Node2D and e.is_inside_tree() and e.get("dying") != true \
			and (e.get("current_health") == null or float(e.get("current_health")) > 0.0))

func nearest_enemy(from: Vector2, max_range: float, exclude: Dictionary):
	var best = null
	var best_d = max_range
	for e in enemies():
		if exclude.has(e.get_instance_id()):
			continue
		var d = from.distance_to(e.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best

func densest_enemy(from: Vector2):
	var pool = enemies().filter(func(e): return e.global_position.distance_to(from) <= 900.0)
	var best = null
	var best_n = -1
	for e in pool:
		var n = 0
		for o in pool:
			if o.global_position.distance_to(e.global_position) <= 120.0:
				n += 1
		if n > best_n:
			best_n = n
			best = e
	return best
