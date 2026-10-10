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

func setup(p_plan: Dictionary, p_caster: Node2D, p_world: Node, p_source: Dictionary, p_manual: bool = false, seed_value: int = -1) -> void:
	plan = p_plan
	caster = p_caster
	world = p_world
	source = p_source
	manual = p_manual
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for i in plan.get("casts", []).size():
		var c: Dictionary = plan.casts[i]
		pending.append({"at": float(c.delay), "power": float(c.power), "size": float(c.size), "first": i == 0})

func _physics_process(delta: float) -> void:
	if not manual:
		step(delta)
		if finished and get_child_count() == 0:
			queue_free()

func step(delta: float) -> void:
	if finished:
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

## Run until finished or out of time (tests).
## on_step lets a test tick other systems (statuses) on the same clock.
func run(seconds: float, dt: float = 1.0 / 60.0, on_step: Callable = Callable()) -> void:
	var t = 0.0
	while t < seconds and not finished:
		step(dt)
		if on_step.is_valid():
			on_step.call(dt)
		t += dt

# --- caster ----------------------------------------------------------------------------
func caster_position() -> Vector2:
	return caster.global_position if is_instance_valid(caster) else global_position

func heal_caster(amount: float) -> void:
	if is_instance_valid(caster) and caster.has_method("heal"):
		caster.heal(amount)

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
		if flags.has("blinking") and is_instance_valid(caster):
			var near = nearest_enemy(caster.global_position, INF, {})
			var away = near.global_position.direction_to(caster.global_position) if near else Vector2.LEFT
			caster.global_position += away * float(flags.blinking.get("distance", 140.0))
	var target = _pick_target()
	aim_dir = caster_position().direction_to(target.global_position) if target else _facing()
	var root_name = str(plan.root)
	var root: Dictionary = plan.parts[root_name]
	var arrangement: Dictionary = plan.get("arrangement", {"type": "single", "count": 1})
	var release: Dictionary = plan.get("release", {"type": "together"})
	var count = maxi(1, int(arrangement.get("count", 1)))
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
			"line":
				var step_len = maxf(40.0, radius)
				pos = base + dir.orthogonal() * step_len * (i - (count - 1) * 0.5)
		var at = clock
		if str(release.get("type", "together")) == "staggered":
			at += float(release.get("interval", 0.15)) * i
		var spawn = {"at": at, "pos": pos, "dir": dir, "power": c.power, "size": c.size, "orbit": orbit_angle, "target": t,
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
	return caster_position()

func _facing() -> Vector2:
	if is_instance_valid(caster):
		for key in ["last_direction", "facing", "last_move_direction"]:
			var v = caster.get(key)
			if v is Vector2 and v.length() > 0.0:
				return v.normalized()
	return Vector2.RIGHT

func _pick_target():
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
	var part = _make_part(root_name, s.pos, s.dir, 0, float(s.power), float(s.size))
	if part == null:
		return
	part.orbit_angle = float(s.orbit)
	if _orbits(plan.parts[root_name]):
		part.global_position = caster_position() + Vector2.RIGHT.rotated(part.orbit_angle) * float(plan.parts[root_name].motion[0].get("radius", 80.0))
	if s.held:
		part.released = false
	if s.target and str(plan.parts[root_name].delivery) == "projectile" and plan.flags.has("scattered"):
		part.assigned = s.target

func _make_part(name: String, pos: Vector2, dir: Vector2, depth: int, power: float, size: float):
	if spawned >= MAX_SPAWNS or not plan.parts.has(name):
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
			return
	elif parent.depth + 1 > MAX_LINK_DEPTH:
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
			return
		dir = at.direction_to(target.global_position)
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
