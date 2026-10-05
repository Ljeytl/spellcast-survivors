extends Node2D
## Runs one part of a generic spell (doc 18 §4): projectile, volume, field, aura, trap or self.
## The owning GenericCast steps it; parts never tick themselves, so tests can drive them frame by frame.

const Effects = preload("res://scripts/engine/Effects.gd")
const COLORS = {"": Color(0.85, 0.85, 0.9), "arcane": Color(0.7, 0.5, 1.0), "fire": Color(1.0, 0.5, 0.15),
	"water": Color(0.45, 0.8, 1.0), "storm": Color(0.95, 0.95, 0.4), "earth": Color(0.65, 0.5, 0.3),
	"plague": Color(0.55, 0.85, 0.25), "life": Color(0.35, 0.9, 0.45)}
const ENEMY_RADIUS = 14.0

var cast = null              # GenericCast
var part_name := ""
var def: Dictionary = {}
var delivery := ""
var direction := Vector2.RIGHT
var power_scale := 1.0
var size_scale := 1.0
var depth := 0
var hops := 0
var chain_range := 220.0
var exclude: Dictionary = {}
var assigned = null
var parent_hit = null
var age := 0.0
var done := false
var hits: Dictionary = {}     # instance id -> age of last hit
var hit_count := 0
var phase := 0
var phase_travel := 0.0
var phase_time := 0.0
var released := true
var orbit_angle := 0.0
var front := 0.0
var armed := false
var tick_acc: Dictionary = {}
var start_pos := Vector2.ZERO
var drift_speed := 0.0

func setup(p_cast, p_name: String, p_def: Dictionary, pos: Vector2, dir: Vector2) -> void:
	cast = p_cast
	part_name = p_name
	def = p_def
	delivery = str(def.get("delivery", "projectile"))
	global_position = pos
	start_pos = pos
	direction = dir.normalized() if dir.length() > 0.0 else Vector2.RIGHT
	drift_speed = float(def.get("drift", {}).get("speed", 0.0))
	for ph in def.get("motion", []):
		if str(ph.type) == "orbit" and str(ph.get("until", "")) == "released":
			released = false
		break
	_aim_once()

# --- geometry -------------------------------------------------------------------------
func geo(key: String, fallback: float = 0.0) -> float:
	return float(def.get("geometry", {}).get(key, fallback)) * size_scale

func geo_type() -> String:
	return str(def.get("geometry", {}).get("type", "body"))

func contains(point: Vector2, pad: float = ENEMY_RADIUS) -> bool:
	var offset = point - global_position
	match geo_type():
		"body", "disk":
			return offset.length() <= geo("radius", 12.0) + pad
		"ring":
			# Expanding rings hit everything inside the front once (enemies never skip a ring by standing inside it).
			var r = front if _propagation() == "expanding" else geo("radius", 100.0)
			return offset.length() <= r + geo("thickness", 20.0) * 0.5 + pad
		"cone":
			if offset.length() > geo("radius", 100.0) + pad:
				return false
			if offset.length() < pad:
				return true
			return absf(direction.angle_to(offset)) <= deg_to_rad(float(def.geometry.get("angle", 90.0))) * 0.5
		"line":
			var axis = direction.orthogonal() if delivery in ["field", "aura", "trap"] else direction
			var along = offset.dot(axis)
			var across = absf(offset.dot(axis.orthogonal()))
			var half = geo("length", 200.0) * 0.5
			if delivery in ["field", "aura", "trap"]:
				return absf(along) <= half + pad and across <= geo("width", 30.0) * 0.5 + pad
			return along >= -pad and along <= geo("length", 200.0) + pad and across <= geo("width", 30.0) * 0.5 + pad
		"rect":
			var along2 = offset.dot(direction)
			var across2 = absf(offset.dot(direction.orthogonal()))
			var center = front if _propagation() == "travelling" else 0.0
			return absf(along2 - center) <= geo("length", 60.0) * 0.5 + pad and across2 <= geo("width", 200.0) * 0.5 + pad
	return offset.length() <= geo("radius", 12.0) + pad

func _propagation() -> String:
	return str(def.get("propagation", {}).get("type", "instant"))

# --- stepping -------------------------------------------------------------------------
func step(delta: float) -> void:
	if done:
		return
	age += delta
	match delivery:
		"projectile":
			_step_projectile(delta)
		"volume":
			_step_volume(delta)
		"field", "aura":
			_step_periodic(delta)
		"trap":
			_step_trap(delta)
		"self":
			_apply_self()
			finish(false)
	if not done:
		var lifetime = float(def.get("limits", {}).get("lifetime", 0.0))
		if lifetime > 0.0 and age >= lifetime:
			finish(true)
	queue_redraw()

func _step_projectile(delta: float) -> void:
	var phases: Array = def.get("motion", [])
	if phase >= phases.size():
		if phases.is_empty():
			finish(true)
		return
	var ph: Dictionary = phases[phase]
	phase_time += delta
	match str(ph.type):
		"orbit":
			var center = cast.caster_position()
			orbit_angle += float(ph.get("speed", 3.0)) * delta
			global_position = center + Vector2.RIGHT.rotated(orbit_angle) * float(ph.get("radius", 80.0))
			direction = Vector2.RIGHT.rotated(orbit_angle + PI * 0.5)
			var until = str(ph.get("until", ""))
			var advance = false
			if until == "released":
				advance = released
			elif until == "enemy_in_range":
				var near = cast.nearest_enemy(center, float(ph.get("range", 400.0)), exclude)
				advance = near != null or phase_time >= float(ph.get("hold", 2.5))
			if advance:
				_next_phase(true)
		"straight", "guided", "spiral":
			if str(ph.type) == "guided":
				var target = assigned if _alive(assigned) else cast.nearest_enemy(global_position, INF, exclude)
				if target:
					var want = global_position.direction_to(target.global_position)
					var turn = float(ph.get("turn", 6.0)) * delta
					direction = direction.rotated(clampf(direction.angle_to(want), -turn, turn))
			elif str(ph.type) == "spiral":
				direction = direction.rotated(float(ph.get("spin", 4.0)) * delta)
			var move = float(ph.get("speed", 600.0)) * delta
			global_position += direction * move
			phase_travel += move
			if ph.has("range") and phase_travel >= float(ph.range):
				_next_phase(false)
		"none":
			pass
	if not done:
		_collide()

func _next_phase(retarget: bool) -> void:
	phase += 1
	phase_travel = 0.0
	phase_time = 0.0
	var phases: Array = def.get("motion", [])
	if phase >= phases.size():
		finish(true)
		return
	if retarget:
		var target = assigned if _alive(assigned) else cast.nearest_enemy(global_position, INF, exclude)
		if target:
			direction = global_position.direction_to(target.global_position)
			if assigned == null:
				assigned = target

func _collide() -> void:
	var limits: Dictionary = def.get("limits", {})
	var pierce = int(limits.get("pierce", 0))
	var rehit = float(limits.get("rehit", 0.0))
	for enemy in cast.enemies():
		if done:
			return
		if exclude.has(enemy.get_instance_id()) or not contains(enemy.global_position):
			continue
		if not _can_hit(enemy, rehit):
			continue
		hit(enemy)
		if pierce >= 0 and hit_count > pierce:
			finish(false)
			return

func _can_hit(enemy, rehit: float) -> bool:
	var id = enemy.get_instance_id()
	if not hits.has(id):
		return true
	return rehit > 0.0 and age - float(hits[id]) >= rehit

func _step_volume(delta: float) -> void:
	match _propagation():
		"instant":
			_hit_all_inside(0.0)
			finish(true)
		"expanding":
			front += float(def.propagation.get("speed", 600.0)) * delta
			var full = geo("radius", 100.0)
			front = minf(front, full)
			_hit_all_inside(0.0)
			if front >= full:
				finish(true)
		"travelling":
			front += float(def.propagation.get("speed", 400.0)) * delta
			_hit_all_inside(0.0)
			if front >= geo("reach", 600.0):
				finish(true)

func _hit_all_inside(rehit: float) -> void:
	for enemy in cast.enemies():
		if done:
			return
		if exclude.has(enemy.get_instance_id()) or not contains(enemy.global_position):
			continue
		if _can_hit(enemy, rehit):
			hit(enemy)

func _step_periodic(delta: float) -> void:
	var anchor = str(def.get("anchor", ""))
	if anchor == "caster":
		global_position = cast.caster_position()
	elif anchor == "hit_target" and _alive(parent_hit):
		global_position = parent_hit.global_position
	if drift_speed > 0.0:
		var near = cast.nearest_enemy(global_position, INF, exclude)
		if near:
			global_position = global_position.move_toward(near.global_position, drift_speed * delta)
	var timing: Dictionary = def.get("timing", {})
	var interval = float(timing.get("interval", 0.5))
	if not def.get("payload", []).is_empty():
		tick_acc["payload"] = float(tick_acc.get("payload", interval)) + delta
		if float(tick_acc.payload) >= interval:
			tick_acc.payload = float(tick_acc.payload) - interval
			_hit_all_inside(maxf(0.0, interval - 0.001) if float(def.get("limits", {}).get("rehit", 0.0)) <= 0.0 else float(def.limits.rehit))
	for key in def.get("events", {}):
		if str(key).split("#")[0] != "on_tick":
			continue
		var ev: Dictionary = def.events[key]
		var every = float(ev.get("interval", interval))
		tick_acc[key] = float(tick_acc.get(key, 0.0)) + delta
		while float(tick_acc[key]) >= every and not done:
			tick_acc[key] = float(tick_acc[key]) - every
			var at = global_position
			var victim = null
			if str(ev.get("at", "")) == "random_enemy_in_range":
				var pool = cast.enemies().filter(func(e): return e.global_position.distance_to(global_position) <= geo("radius", 100.0) + ENEMY_RADIUS)
				if pool.is_empty():
					continue
				victim = pool[cast.rng.randi() % pool.size()]
				at = victim.global_position
			cast.spawn_event(self, ev, at, victim)
	if age >= float(timing.get("duration", 3.0)):
		finish(true)

func _step_trap(_delta: float) -> void:
	var timing: Dictionary = def.get("timing", {})
	if drift_speed > 0.0:
		var near = cast.nearest_enemy(global_position, INF, exclude)
		if near:
			global_position = global_position.move_toward(near.global_position, drift_speed * _delta)
	if not armed and age >= float(timing.get("arming", 0.4)):
		armed = true
	if armed:
		for enemy in cast.enemies():
			if contains(enemy.global_position):
				fire("on_trigger", global_position, enemy)
				if not def.get("payload", []).is_empty():
					_hit_all_inside(0.0)
				finish(false)
				return
	if age >= float(timing.get("duration", 8.0)):
		finish(true)

func _apply_self() -> void:
	for item in def.get("payload", []):
		if str(item.type) == "heal":
			cast.heal_caster(float(item.amount) * power_scale)

# --- hits and events ------------------------------------------------------------------
func hit(enemy) -> void:
	if not _alive(enemy):
		return
	hits[enemy.get_instance_id()] = age
	hit_count += 1
	var at = enemy.global_position
	for item in def.get("payload", []):
		match str(item.type):
			"damage":
				var entries := []
				for e in item.entries:
					var scaled = e.duplicate()
					scaled.amount = float(e.amount) * power_scale
					entries.append(scaled)
				Effects.apply(enemy, {"type": "damage", "entries": entries, "element": str(item.get("element", "raw"))}, cast.source, global_position)
			"status":
				if not _alive(enemy):
					continue
				var eff = item.duplicate()
				eff.type = "status"
				eff.hit = float(item.get("hit", 0.0)) * power_scale
				Effects.apply(enemy, eff, cast.source, global_position)
			"impulse":
				if not _alive(enemy):
					continue
				var dir := Vector2.ZERO
				match str(item.get("direction", "away")):
					"away":
						dir = global_position.direction_to(at)
					"toward":
						dir = at.direction_to(global_position)
					"travel":
						dir = direction
				if dir == Vector2.ZERO:
					dir = direction
				Effects.apply(enemy, {"type": "impulse", "direction": dir, "force": float(item.get("force", 0.0))}, cast.source, global_position)
	cast.record_hit(self, enemy)
	var killed = not _alive(enemy)
	if hit_count == 1:
		fire("on_first_hit", at, enemy)
	fire("on_hit", at, enemy)
	if killed:
		fire("on_kill", at, enemy)

func fire(event: String, at: Vector2, victim) -> void:
	for key in def.get("events", {}):
		if str(key).split("#")[0] == event:
			cast.spawn_event(self, def.events[key], at, victim)

func finish(natural: bool) -> void:
	if done:
		return
	done = true
	if natural:
		fire("on_expire", global_position, null)
	cast.part_finished(self)

func _alive(node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	if node.get("dying") == true:
		return false
	var hp = node.get("current_health")
	return hp == null or float(hp) > 0.0

func _aim_once() -> void:
	var aim: Dictionary = def.get("aim", {})
	match str(aim.get("type", "")):
		"nearest":
			var near = cast.nearest_enemy(global_position, INF, exclude)
			if near:
				direction = global_position.direction_to(near.global_position)
		"densest":
			var best = cast.densest_enemy(global_position)
			if best:
				direction = global_position.direction_to(best.global_position)

# --- placeholder art (doc 18 §10: shape from delivery, colour from element) ----------------
func _draw() -> void:
	if done:
		return
	var color: Color = COLORS.get(cast.plan.get("element", "") if cast else "", COLORS[""])
	match geo_type():
		"body":
			draw_circle(Vector2.ZERO, geo("radius", 12.0), color)
		"disk":
			var fill = color
			fill.a = 0.25 if delivery in ["field", "aura", "trap"] else 0.45
			draw_circle(Vector2.ZERO, geo("radius", 60.0), fill)
			draw_arc(Vector2.ZERO, geo("radius", 60.0), 0, TAU, 40, color, 2.0)
		"ring":
			var r = front if _propagation() == "expanding" else geo("radius", 100.0)
			draw_arc(Vector2.ZERO, maxf(1.0, r), 0, TAU, 48, color, maxf(2.0, geo("thickness", 20.0) * 0.5))
		"cone":
			var half = deg_to_rad(float(def.geometry.get("angle", 90.0))) * 0.5
			var pts = PackedVector2Array([Vector2.ZERO])
			for i in 9:
				pts.append(direction.rotated(lerpf(-half, half, i / 8.0)) * geo("radius", 100.0))
			var c2 = color
			c2.a = 0.5
			draw_colored_polygon(pts, c2)
		"line":
			var axis = direction.orthogonal() if delivery in ["field", "aura", "trap"] else direction
			var a = -axis * geo("length", 200.0) * 0.5 if delivery in ["field", "aura", "trap"] else Vector2.ZERO
			var b = axis * geo("length", 200.0) * 0.5 if delivery in ["field", "aura", "trap"] else axis * geo("length", 200.0)
			draw_line(a, b, color, geo("width", 30.0))
		"rect":
			var c3 = direction * front
			var half_w = direction.orthogonal() * geo("width", 200.0) * 0.5
			var half_l = direction * geo("length", 60.0) * 0.5
			var c4 = color
			c4.a = 0.5
			draw_colored_polygon(PackedVector2Array([c3 - half_w - half_l, c3 + half_w - half_l, c3 + half_w + half_l, c3 - half_w + half_l]), c4)
