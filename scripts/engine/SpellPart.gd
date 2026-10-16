extends Node2D
## Runs one part of a generic spell (doc 18 §4): projectile, volume, field, aura, trap or self.
## The owning GenericCast steps it; parts never tick themselves, so tests can drive them frame by frame.

const Effects = preload("res://scripts/engine/Effects.gd")
const COLORS = {"": Color(0.85, 0.85, 0.9), "arcane": Color(0.7, 0.5, 1.0), "fire": Color(1.0, 0.5, 0.15),
	"water": Color(0.45, 0.8, 1.0), "storm": Color(0.95, 0.95, 0.4), "earth": Color(0.65, 0.5, 0.3),
	"plague": Color(0.55, 0.85, 0.25), "life": Color(0.35, 0.9, 0.45)}
const ENEMY_RADIUS = 14.0
const Targeting = preload("res://scripts/SpellTargeting.gd")

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
var spirit_ending := false
var finishing_hunt := false
var hunted_targets: Dictionary = {}
var returning_life := false
var stolen_life := 0.0
var return_age := 0.0
var visual_remaining := 0.0
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
var prev_pos := Vector2.ZERO
var geo_override: Dictionary = {}  # per-part geometry (already scaled), e.g. a growing trail's length
var trail_parent: WeakRef = null   # trail fields follow the projectile that laid them
var trail_from := Vector2.ZERO
var life_total := -1.0             # set when a recast extends this part (old "extend" spells)
var segments: Array = []           # queued recasts: {def, length}; each takes over when the last runs out
var segment_end := -1.0
var beam_end := Vector2.ZERO       # beams: where the beam stops, local to the part (last enemy it reaches)
var target_ref: WeakRef = null     # beams: the enemy it tracks (other beams avoid it)
var beam_offset := Vector2.ZERO    # beams: lane offset from the caster
var infection = null               # "infection" delivery state (scripts/engine/Infection.gd)
var hit_mult := 1.0                # phase damage share (Cross Blade: x2 on the way back, x0.5 pulses)
var phase_mix: Dictionary = {}     # a phase's own damage mix, multiples of the base hit (doc 21 §5: Cross Blade)
var phase_status_repeat := 1       # a phase that applies its statuses more than once (Cross Blade's return: 2 bleed)
var emit_last := Vector2.INF        # emitters: where the last patch was laid
var emit_timer := 0.0
var heal_zone_done := false             # healing words: an area impact leaves one healing circle
var _vfx = null               # Vfx autoload: reads this part, never changes it (docs/VFX_EVENTS.md)

func setup(p_cast, p_name: String, p_def: Dictionary, pos: Vector2, dir: Vector2) -> void:
	cast = p_cast
	part_name = p_name
	def = p_def
	delivery = str(def.get("delivery", "projectile"))
	global_position = pos
	start_pos = pos
	prev_pos = pos
	direction = dir.normalized() if dir.length() > 0.0 else Vector2.RIGHT
	drift_speed = float(def.get("drift", {}).get("speed", 0.0))
	for ph in def.get("motion", []):
		if str(ph.type) == "orbit" and str(ph.get("until", "")) == "released":
			released = false
		break
	_aim_once()
	_enforce_cap()
	if delivery == "projectile":
		# Targeting (SpellTargeting.incoming) skips enemies this projectile will already kill.
		add_to_group("engine_projectiles")
	if not def.get("motion", []).is_empty() and str(def.motion[0].get("type", "")) == "chase":
		add_to_group("engine_spirits")
	if delivery == "infection":
		infection = preload("res://scripts/engine/Infection.gd").new(self, def.get("infection", {}))
	if delivery == "beam":
		# The style meter holds while a beam channels; other beams avoid this one's target.
		add_to_group("active_spell_channels")
		beam_end = direction * geo("length", 450.0)
	if delivery == "projectile" and def.has("trail"):
		cast.spawn_trail(self, def.trail)
	_vfx = get_node_or_null("/root/Vfx")
	if _vfx:
		_vfx.part_spawned(self)

# --- geometry -------------------------------------------------------------------------
func geo(key: String, fallback: float = 0.0) -> float:
	if geo_override.has(key):
		return float(geo_override[key])
	return float(def.get("geometry", {}).get(key, fallback)) * size_scale

## Extra reach for an enemy's body. Ported spells set geometry.pad 0 to keep their old hitboxes.
func hit_pad() -> float:
	var pad = def.get("geometry", {}).get("pad", ENEMY_RADIUS)
	return ENEMY_RADIUS if pad is String else float(pad)

## Reach for this enemy's body: geometry.pad "hurtbox" uses the enemy's own hurtbox, as the old
## projectiles' collision did (none for a bare test target).
func pad_for(enemy) -> float:
	var pad = def.get("geometry", {}).get("pad", ENEMY_RADIUS)
	if not (pad is String):
		return float(pad)
	var shape_node = enemy.get_node_or_null("HurtBox/HurtBoxShape") as CollisionShape2D if enemy is Node else null
	if shape_node == null or shape_node.shape == null or shape_node.disabled:
		return 0.0
	var sc: Vector2 = shape_node.global_transform.get_scale().abs()
	if shape_node.shape is RectangleShape2D:
		var half: Vector2 = shape_node.shape.size * 0.5 * sc
		return (half.x + half.y) * 0.5
	if shape_node.shape is CircleShape2D:
		return shape_node.shape.radius * maxf(sc.x, sc.y)
	return ENEMY_RADIUS

func geo_type() -> String:
	return str(def.get("geometry", {}).get("type", "body"))

func contains(point: Vector2, pad: float = -1.0) -> bool:
	if pad < 0.0:
		pad = hit_pad()
	var offset = point - global_position
	match geo_type():
		"body", "disk":
			return offset.length() <= geo("radius", 12.0) + pad
		"ring":
			# Expanding rings hit everything inside the front once (enemies never skip a ring by standing inside it).
			var r = front if _propagation() == "expanding" else geo("radius", 100.0)
			return offset.length() <= r + geo("thickness", 20.0) * 0.5 + pad
		"cone":
			var reach = front if _propagation() == "expanding" else geo("radius", 100.0)
			if offset.length() > reach + pad:
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
## How long this part lives in all: its own duration or lifetime, plus any recast extensions.
func total_life() -> float:
	if life_total >= 0.0:
		return life_total
	if delivery == "infection" and infection != null:
		return infection.end_at
	if delivery in ["field", "aura", "trap", "beam"]:
		return float(def.get("timing", {}).get("duration", 3.0 if delivery != "trap" else 8.0))
	var lifetime = float(def.get("limits", {}).get("lifetime", 0.0))
	return lifetime if lifetime > 0.0 else INF

func remaining_life() -> float:
	return total_life() - age

## A recast of an "extend" spell: queue its numbers (they take over when the current cast runs
## out) and lengthen this part's life by `added` seconds.
func extend_with(new_def: Dictionary, added: float) -> void:
	if segment_end < 0.0:
		segment_end = total_life()
	life_total = total_life() + added
	segments.append({"def": new_def, "length": added})

func step(delta: float) -> void:
	if done:
		return
	age += delta
	# A tick on the boundary still belongs to the running numbers; the queued ones take over after it.
	while not segments.is_empty() and age - 0.000001 > segment_end:
		var seg: Dictionary = segments.pop_front()
		def = seg.def
		segment_end += float(seg.length)
	match delivery:
		"projectile":
			_step_projectile(delta)
		"volume":
			_step_volume(delta)
		"field", "aura":
			_step_periodic(delta)
		"trap":
			_step_trap(delta)
		"beam":
			_step_beam(delta)
		"infection":
			if infection != null:
				infection.step(delta)
		"self":
			_apply_self()
			finish(false)
	if not done:
		if delivery == "projectile":
			if not def.has("leech_return") and age + 0.000001 >= total_life():
				finish(true)
		elif float(def.get("limits", {}).get("lifetime", 0.0)) > 0.0 and age >= float(def.limits.lifetime):
			finish(true)
	queue_redraw()

func _step_projectile(delta: float) -> void:
	if def.has("leech_return"):
		if not is_instance_valid(cast.caster) or (cast.caster.get("health") != null and float(cast.caster.health) <= 0.0):
			finish(false)
			return
		if not spirit_ending and age >= total_life():
			_begin_spirit_ending()
		if spirit_ending:
			_step_spirit_ending(delta)
			return
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
			prev_pos = global_position
			global_position = center + Vector2.RIGHT.rotated(orbit_angle) * float(ph.get("radius", 80.0))
			direction = Vector2.RIGHT.rotated(orbit_angle + PI * 0.5)
			var until = str(ph.get("until", ""))
			var advance = false
			if until == "released":
				advance = released
			elif until == "enemy_in_range":
				var near = cast.nearest_enemy(center, float(ph.get("range", 400.0)), exclude)
				# ORBITING circles the caster at least `min_orbit` seconds first, so it reads as orbiting
				# even in a horde where an enemy is always in range (playtest).
				advance = (near != null and phase_time >= float(ph.get("min_orbit", 0.0))) or phase_time >= float(ph.get("hold", 2.5))
			if advance:
				_next_phase(true)
		"chase":
			# Old Seeker: drift toward the enemy it hunts (the caster when there is none).
			var prey = _spirit_target(float(ph.get("range", 600.0)))
			var dest: Vector2 = prey.global_position if prey else cast.caster_position()
			if prey != null and def.has("leech_return") and global_position.distance_to(dest) < geo("radius", 24.0) * 2.0:
				dest += Vector2.from_angle(age * 3.5) * geo("radius", 24.0) * 0.7
			prev_pos = global_position
			global_position = global_position.move_toward(dest, float(ph.get("speed", 220.0)) * delta)
			if global_position != prev_pos:
				direction = prev_pos.direction_to(global_position)
		"straight", "guided", "spiral":
			if str(ph.type) == "guided":
				if not _alive(assigned) and cast.plan.get("legacy", false) and depth == 0:
					# Old homing shots (Magic Missile, Lightning Bolt): a dead target hands the shot to
					# the nearest enemy still worth hitting (overkill-aware), which it then reserves.
					assigned = Targeting.select(get_tree(), global_position, 600.0, exclude, self)
					if assigned != null:
						reserve_until = age + global_position.distance_to(assigned.global_position) / maxf(float(ph.get("speed", 600.0)), 1.0) + 0.25
				var target = assigned if _alive(assigned) else cast.nearest_enemy(global_position, INF, exclude)
				if target:
					var want = global_position.direction_to(target.global_position)
					if ph.has("lerp"):
						# Old homing projectiles: blend toward the target each step, so a wide miss turns hard
						# (no turning circle to orbit in), which is how they always connected.
						direction = direction.lerp(want, clampf(float(ph.lerp) * delta, 0.0, 1.0)).normalized()
					else:
						var turn = float(ph.get("turn", 6.0)) * delta
						direction = direction.rotated(clampf(direction.angle_to(want), -turn, turn))
			elif str(ph.type) == "spiral":
				direction = direction.rotated(float(ph.get("spin", 4.0)) * delta)
			var move = float(ph.get("speed", 600.0)) * delta
			prev_pos = global_position
			global_position += direction * move
			phase_travel += move
			if ph.has("range") and phase_travel + 0.001 >= float(ph.range):
				_next_phase(false)
		"hold":
			# Old Cross Blade linger: stay put; pulse everything inside every interval at a share of the hit.
			var pulse: Dictionary = ph.get("pulse", {})
			if not pulse.is_empty():
				tick_acc["hold"] = float(tick_acc.get("hold", 0.0)) + delta
				while float(tick_acc.hold) + 0.000001 >= float(pulse.get("interval", 0.3)) and not done:
					tick_acc.hold = float(tick_acc.hold) - float(pulse.get("interval", 0.3))
					var keep = hit_mult
					var keep_mix = phase_mix
					hit_mult = float(pulse.get("mult", 0.5))
					phase_mix = pulse.get("mix", {})
					for enemy in cast.enemies():
						if enemy.global_position.distance_to(global_position) <= geo("radius", 12.0) + pad_for(enemy):
							hit(enemy)
					hit_mult = keep
					phase_mix = keep_mix
			if phase_time + 0.000001 >= float(ph.get("time", 0.9)):
				_next_phase(false)
			return
		"return":
			# Old Cross Blade return: fly back to the caster; caught within `catch`.
			var home: Vector2 = cast.caster_position()
			prev_pos = global_position
			global_position = global_position.move_toward(home, float(ph.get("speed", 500.0)) * delta)
			if global_position != prev_pos:
				direction = prev_pos.direction_to(global_position)
			_collide()
			if not done and global_position.distance_to(home) <= float(ph.get("catch", 18.0)):
				finish(true)
			return
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
	var next: Dictionary = phases[phase]
	hit_mult = float(next.get("mult", 1.0))
	phase_mix = next.get("mix", {})
	phase_status_repeat = int(next.get("status_repeat", 1))
	if bool(next.get("fresh_hits", false)):
		hits.clear()   # a new leg: every enemy can be hit again once
	if next.has("on_enter"):
		cast.spawn_event(self, next.on_enter, global_position, null)
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
	var contact_all = bool(limits.get("contact_all", false)) and pierce == 0
	var touching: Array = []
	for enemy in cast.enemies():
		if done or returning_life:
			return
		if exclude.has(enemy.get_instance_id()) or not _swept_contains(enemy):
			continue
		if bool(limits.get("visible_only", false)) and not _on_screen(enemy):
			continue
		if not _can_hit(enemy, rehit):
			continue
		if contact_all:
			touching.append(enemy)
			continue
		hit(enemy)
		if not returning_life and pierce >= 0 and hit_count > pierce:
			if def.has("leech_return") and not done:
				_begin_spirit_ending()
			else:
				finish(false)
			return
	if not touching.is_empty():
		# Old bolts: one contact hits everything the bolt overlaps at that moment, then it is spent.
		for enemy in touching:
			hit(enemy)
		finish(false)

## A body sweeps the segment it moved along this step, so fast projectiles cannot skip enemies.
func _swept_contains(enemy) -> bool:
	var point: Vector2 = enemy.global_position
	var pad = pad_for(enemy)
	if geo_type() != "body" or prev_pos == global_position:
		return contains(point, pad)
	var closest = Geometry2D.get_closest_point_to_segment(point, prev_pos, global_position)
	return closest.distance_to(point) <= geo("radius", 12.0) + pad

## Damage this projectile has committed to `enemy` (its assigned target), for overkill-aware targeting.
## Like the old projectiles, the reservation lapses when the shot can no longer arrive: past its
## estimated arrival (+0.25 s), or when the target is behind it or well off its line.
var reserve_until := INF
func reserved_damage(enemy) -> float:
	if done or enemy != assigned or not _alive(enemy) or age > reserve_until:
		return 0.0
	var offset: Vector2 = enemy.global_position - global_position
	var phases: Array = def.get("motion", [])
	var steering = phase < phases.size() and str(phases[phase].get("type", "")) == "guided"
	if not steering and (offset.dot(direction) < -24.0 or absf(offset.cross(direction)) > 60.0):
		return 0.0   # a straight shot that has passed or left its target's line no longer arrives
	var total := 0.0
	for item in def.get("payload", []):
		if str(item.type) == "damage":
			total += float(item.get("hit", 0.0)) * power_scale
	return total

func _can_hit(enemy, rehit: float) -> bool:
	var id = enemy.get_instance_id()
	if bool(def.get("limits", {}).get("rehit_shared", false)):
		# Old Arcane Orbit: one cooldown per enemy across all the orbs of a cast.
		return not cast.shared_hits.has(id) or rehit > 0.0 and cast.clock - float(cast.shared_hits[id]) >= rehit - 0.000001
	if not hits.has(id):
		return true
	return rehit > 0.0 and age - float(hits[id]) >= rehit

func _step_volume(delta: float) -> void:
	match _propagation():
		"instant":
			# linger: the burst stays live that long and still hits late entrants, each once
			# (old Lightning: 0.2 s, scaled by Duration).
			_hit_all_inside(0.0)
			if age + 0.000001 >= float(def.get("propagation", {}).get("linger", 0.0)):
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
		if done or returning_life:
			return
		if exclude.has(enemy.get_instance_id()) or not contains(enemy.global_position, pad_for(enemy)):
			continue
		if _can_hit(enemy, rehit):
			hit(enemy)

func _step_periodic(delta: float) -> void:
	_follow_trail()
	var anchor = str(def.get("anchor", ""))
	if anchor == "caster":
		global_position = cast.caster_position()
	elif anchor == "hit_target" and _alive(parent_hit):
		global_position = parent_hit.global_position
	if drift_speed > 0.0:
		var near = cast.nearest_enemy(global_position, INF, exclude)
		if near:
			global_position = global_position.move_toward(near.global_position, drift_speed * delta)
	if def.has("emit"):
		_emit_patches(delta)
	var timing: Dictionary = def.get("timing", {})
	var interval = float(timing.get("interval", 0.5))
	if not def.get("payload", []).is_empty() and bool(timing.get("per_target", false)):
		# Each enemy is hit as it enters, then every interval while it stays inside.
		_hit_all_inside(interval)
	elif not def.get("payload", []).is_empty() and bool(timing.get("shared_clock", false)):
		# Old Fire Walk: one tick for the whole trail, on the cast's clock, so a moving enemy is hit
		# every interval however many patches it crosses (patch phases never stagger the cooldown).
		var beat = int(floor((cast.clock + 0.000001) / interval))
		if not tick_acc.has("beat"):
			tick_acc.beat = beat
		elif beat > int(tick_acc.beat):
			tick_acc.beat = beat
			_hit_all_inside(maxf(0.0, interval - 0.001) if float(def.get("limits", {}).get("rehit", 0.0)) <= 0.0 else float(def.limits.rehit))
	elif not def.get("payload", []).is_empty():
		tick_acc["payload"] = float(tick_acc.get("payload", 0.0 if bool(timing.get("delay_first", false)) else interval)) + delta
		if float(tick_acc.payload) + 0.000001 >= interval:
			tick_acc.payload = float(tick_acc.payload) - interval
			_hit_all_inside(maxf(0.0, interval - 0.001) if float(def.get("limits", {}).get("rehit", 0.0)) <= 0.0 else float(def.limits.rehit))
	for key in def.get("events", {}):
		if str(key).split("#")[0] != "on_tick":
			continue
		var ev: Dictionary = def.events[key]
		var every = float(ev.get("interval", interval))
		tick_acc[key] = float(tick_acc.get(key, 0.0)) + delta
		while float(tick_acc[key]) + 0.000001 >= every and not done:
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
	if def.has("heal_ground") and is_instance_valid(cast.caster) and contains(cast.caster_position(), 0.0):
		# Healing words on a field or trail: the ground heals the caster standing in it.
		cast.heal_caster(cast.spend_heal(float(def.heal_ground.rate) * delta))
	if def.has("heal_rate"):
		# Old Regeneration: healing flows every frame while the aura lasts.
		cast.heal_caster(float(def.heal_rate) * power_scale * delta, float(def.get("visual_size", 1.0)))
	if age + 0.000001 >= total_life():
		finish(true)

## Beam (old Focus Ray / Prism Ray): anchored at the caster, turns toward the enemy it tracks,
## and every interval hits the first `targets` enemies along it (every enemy when piercing).
func _step_beam(delta: float) -> void:
	global_position = cast.caster_position() + beam_offset
	var reach_len = geo("length", 450.0)
	var turn = float(def.get("aim", {}).get("turn", 4.0))
	if turn > 0.0:
		var target = _beam_track(reach_len)
		if target != null:
			var desired = global_position.direction_to(target.global_position).angle()
			direction = Vector2.from_angle(rotate_toward(direction.angle(), desired, turn * delta))
	var piercing = bool(def.get("limits", {}).get("beam_piercing", false))
	var reach = global_position + direction * reach_len
	var found: Array = []
	for enemy in cast.enemies():
		var along = (enemy.global_position - global_position).dot(direction)
		var closest = Geometry2D.get_closest_point_to_segment(enemy.global_position, global_position, reach)
		if closest.distance_to(enemy.global_position) <= geo("width", 24.0) * 0.5 + pad_for(enemy):
			found.append({"enemy": enemy, "contact": clampf(_beam_front(enemy, along), 0.0, reach_len)})
	found.sort_custom(func(a, b): return a.contact < b.contact)
	var struck = found if piercing else found.slice(0, int(def.get("limits", {}).get("targets", 1)))
	if turn <= 0.0:
		target_ref = weakref(struck[0].enemy) if not struck.is_empty() else null
	beam_end = direction * reach_len
	if not piercing and not struck.is_empty():
		beam_end = direction * minf(reach_len, float(struck[-1].contact) + 8.0)
	var interval = float(def.get("timing", {}).get("interval", 0.25))
	tick_acc["payload"] = float(tick_acc.get("payload", 0.0)) + delta
	while float(tick_acc.payload) + 0.000001 >= interval and not done:
		tick_acc.payload = float(tick_acc.payload) - interval
		for entry in struck:
			if _alive(entry.enemy):
				hit(entry.enemy)
	if age + 0.000001 >= total_life():
		finish(true)

## Where the beam first touches an enemy along its length: the near face of its hurtbox (old
## Focus Ray stopped at body contact, not the centre).
func _beam_front(enemy, along: float) -> float:
	var shape_node = enemy.get_node_or_null("HurtBox/HurtBoxShape") as CollisionShape2D if enemy is Node else null
	if shape_node != null and not shape_node.disabled and shape_node.shape is RectangleShape2D:
		var half: Vector2 = shape_node.shape.size * 0.5
		var first = INF
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
			first = minf(first, (shape_node.to_global(corner) - global_position).dot(direction))
		return first
	return along - pad_for(enemy)

## The enemy a beam keeps on: its current one while alive and in reach, else the nearest one no
## other live beam is already on.
func _beam_track(reach_len: float):
	var target = target_ref.get_ref() if target_ref else null
	if _alive(target) and global_position.distance_to(target.global_position) <= reach_len:
		return target
	var reserved: Array = []
	for other in get_tree().get_nodes_in_group("active_spell_channels"):
		if other != self and other.has_method("is_style_channel_active") and other.is_style_channel_active() and other.get("target_ref"):
			var o = other.target_ref.get_ref()
			if _alive(o):
				reserved.append(o)
	target = null
	var best = INF
	for enemy in cast.enemies():
		var d = global_position.distance_to(enemy.global_position)
		if d <= reach_len:
			var score = d + (reach_len + 1.0 if enemy in reserved else 0.0)
			if score < best:
				best = score
				target = enemy
	target_ref = weakref(target) if target else null
	return target

func _on_screen(enemy) -> bool:
	return enemy.is_visible_in_tree() and get_viewport().get_visible_rect().has_point(enemy.get_global_transform_with_canvas().origin)

## The enemy a spirit hunts: its current one while it qualifies, else the nearest on-screen enemy
## within range of the caster that no other spirit of this caster is hunting (old select_spirit).
func _spirit_target(reach: float):
	var current = target_ref.get_ref() if target_ref else null
	var reserved: Array = []
	for other in get_tree().get_nodes_in_group("engine_spirits"):
		if other == self or other.done or other.cast == null or other.cast.caster != cast.caster:
			continue
		var o = other.target_ref.get_ref() if other.target_ref else null
		if _alive(o):
			reserved.append(o)
	var chosen = null
	var best = INF
	var origin = cast.caster_position()
	for enemy in cast.enemies():
		if not _on_screen(enemy):
			continue
		var d = origin.distance_to(enemy.global_position)
		if d > reach:
			continue
		var score = (0.0 if enemy == current else d + 1.0) + (reach + 2.0 if enemy in reserved else 0.0)
		if score < best:
			best = score
			chosen = enemy
	target_ref = weakref(chosen) if chosen else null
	if chosen != null and def.has("leech_return"):
		hunted_targets[chosen.get_instance_id()] = true
	return chosen

func is_style_channel_active() -> bool:
	return delivery == "beam" and not done and cast != null and is_instance_valid(cast.caster) \
		and (cast.caster.get("health") == null or float(cast.caster.health) > 0.0)

## Old Fire Walk: while the emitter lasts, lay patches along the caster's path (every `every`
## seconds once it has moved `min_step`, `spacing` apart so the patches overlap into a strip).
func _emit_patches(delta: float) -> void:
	var em: Dictionary = def.emit
	var here: Vector2 = cast.caster_position()
	if emit_last == Vector2.INF:
		emit_last = here
		cast.spawn_event(self, {"part": str(em.part)}, here, null)
	emit_timer -= delta
	if emit_timer > 0.000001:
		return
	emit_timer = float(em.get("every", 0.1))
	var dist = emit_last.distance_to(here)
	if dist < float(em.get("min_step", 24.0)):
		return
	var count = maxi(1, ceili(dist / maxf(1.0, float(em.get("spacing", 25.0)))))
	for i in count:
		cast.spawn_event(self, {"part": str(em.part)}, emit_last.lerp(here, float(i + 1) / count), null)
	emit_last = here

## A trail is a line field from where the projectile was thrown to where it is now.
func _follow_trail() -> void:
	if trail_parent == null:
		return
	var p = trail_parent.get_ref()
	if p != null and is_instance_valid(p) and not p.done:
		var a := trail_from
		var b: Vector2 = p.global_position
		global_position = (a + b) * 0.5
		geo_override.length = a.distance_to(b)
		if a.distance_to(b) > 0.5:
			# Field lines lie across `direction` (contains), so turn it a quarter to run along the throw.
			direction = a.direction_to(b).orthogonal()
	else:
		trail_parent = null

## limits.cap: at most `max` of this part alive at once; the oldest goes out first.
func _enforce_cap() -> void:
	var cap = int(def.get("limits", {}).get("cap", 0))
	if cap <= 0 or cast == null:
		return
	var group = "spell_part_%s_%s" % [str(cast.plan.get("id", "")), part_name]
	var live: Array = get_tree().get_nodes_in_group(group).filter(func(n): return is_instance_valid(n) and not n.done) if is_inside_tree() else []
	while live.size() >= cap:
		var oldest = live[0]
		for n in live:
			if n.age > oldest.age:
				oldest = n
		oldest.finish(false)
		live.erase(oldest)
	add_to_group(group)

func _step_trap(_delta: float) -> void:
	var timing: Dictionary = def.get("timing", {})
	if drift_speed > 0.0:
		var near = cast.nearest_enemy(global_position, INF, exclude)
		if near:
			global_position = global_position.move_toward(near.global_position, drift_speed * _delta)
	if not armed and age + 0.000001 >= float(timing.get("arming", 0.4)):
		armed = true
	if armed:
		for enemy in cast.enemies():
			if contains(enemy.global_position, pad_for(enemy)):
				fire("on_trigger", global_position, enemy)
				if not def.get("payload", []).is_empty():
					_hit_all_inside(0.0)
				finish(false)
				return
	if age + 0.000001 >= total_life():
		finish(true)

func _apply_self() -> void:
	for item in def.get("payload", []):
		if str(item.type) == "heal":
			cast.heal_caster(float(item.amount) * power_scale, float(item.get("visual_size", 1.0)))

# --- hits and events ------------------------------------------------------------------
func hit(enemy) -> void:
	if done or returning_life or not _alive(enemy) or (finishing_hunt and hunted_targets.has(enemy.get_instance_id())):
		return
	if def.has("leech_return") and not finishing_hunt:
		hunted_targets[enemy.get_instance_id()] = true
	hits[enemy.get_instance_id()] = age
	cast.shared_hits[enemy.get_instance_id()] = cast.clock
	hit_count += 1
	var at = enemy.global_position
	var dealt := 0.0
	var health_before = enemy.get("current_health")
	for idx in def.get("payload", []).size():
		var item: Dictionary = def.payload[idx]
		if bool(item.get("once_per_cast", false)):
			# Old Ice Blast: shards stack damage, but push and slow land once per enemy per cast.
			var key = "%s/%d@%d" % [part_name, idx, enemy.get_instance_id()]
			if cast.once.has(key):
				continue
			cast.once[key] = true
		match str(item.type):
			"seed":
				# Old Life Bolt: a hit that dealt damage plants a healing seed to collect. Healing words'
				# seeds draw on the cast's healing budget and stop when it is spent.
				if dealt > 0.0:
					if bool(item.get("budget", false)):
						var amount = cast.spend_heal(float(item.amount))
						if amount > 0.0:
							var s = item.duplicate()
							s.amount = amount
							cast.spawn_seed(at, s)
					elif item.has("share_of_dealt"):
						var s2 = item.duplicate()
						s2.amount = dealt * float(item.share_of_dealt)
						cast.spawn_seed(at, s2)
					else:
						cast.spawn_seed(at, item)
			"heal_zone":
				# Healing words on an area impact: one healing circle the size of the impact.
				if dealt > 0.0 and not heal_zone_done:
					heal_zone_done = true
					cast.spawn_heal_zone(global_position, geo("radius", 60.0), cast.spend_heal(float(item.amount)), float(item.get("duration", 3.0)))
			"overload":
				if _alive(enemy):
					Effects.apply(enemy, item, cast.source, global_position)
			"slow":
				if _alive(enemy):
					Effects.apply(enemy, {"type": "slow", "factor": float(item.get("factor", 0.6)), "duration": float(item.get("duration", 2.0))}, cast.source, global_position)
			"damage":
				var entries := []
				var source_entries: Array = item.entries
				if not phase_mix.is_empty():
					# This phase deals its own mix of the base hit; words' added elements stay.
					source_entries = item.entries.filter(func(x): return not bool(x.get("base", false)))
					var el = str(item.get("element", "raw"))
					for kind in phase_mix:
						source_entries.append({"amount": float(item.get("hit", 0.0)) * float(phase_mix[kind]), "damage_type": str(kind), "chart_element": el if str(kind) == "raw" and el != "raw" else str(kind)})
				for e in source_entries:
					var scaled = e.duplicate()
					scaled.amount = float(e.amount) * power_scale * hit_mult
					entries.append(scaled)
				# Infestation's ticks are its own damage over time, credited as "infection" (doc 21 §5.5).
				var src = cast.source if delivery != "infection" else preload("res://scripts/engine/StatusComponent.gd").tag(cast.source, "infection")
				dealt += Effects.apply(enemy, {"type": "damage", "entries": entries, "element": str(item.get("element", "raw"))}, src, global_position)
			"status":
				if not _alive(enemy):
					continue
				var eff = item.duplicate()
				eff.type = "status"
				eff.hit = float(item.get("hit", 0.0)) * power_scale * hit_mult
				if not phase_mix.is_empty():
					# Sized from the hit that applied it (doc 21 §5): this phase's own share of the base hit.
					var total := 0.0
					for kind in phase_mix:
						total += float(phase_mix[kind])
					eff.hit *= total
				for i in phase_status_repeat:
					if _alive(enemy):
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
				var force = float(item.get("force", 0.0))
				if item.has("falloff") and delivery == "projectile":
					# [near, far] multipliers over the projectile's range (old Ice Blast: 2.0 near, 1.2 at full reach)
					var reach = 0.0
					for ph in def.get("motion", []):
						reach = float(ph.get("range", 0.0))
						break
					var k = clampf(phase_travel / maxf(reach, 1.0), 0.0, 1.0)
					force *= lerpf(float(item.falloff[0]), float(item.falloff[1]), k)
				Effects.apply(enemy, {"type": "impulse", "direction": dir, "force": force}, cast.source, global_position)
	var health_after = enemy.get("current_health") if is_instance_valid(enemy) else 0.0
	if not def.has("leech_return"):
		cast.leech(dealt)
	cast.record_hit(self, enemy)
	if _vfx:
		_vfx.part_hit(self, enemy, at)
	var killed = not _alive(enemy)
	if hit_count == 1:
		fire("on_first_hit", at, enemy)
	fire("on_hit", at, enemy)
	if killed:
		fire("on_kill", at, enemy)
	if def.has("leech_return"):
		if finishing_hunt:
			_spirit_arrival(false)
			finish(false)
			return
		var actual := minf(dealt, maxf(0.0, float(health_before) - maxf(0.0, float(health_after)))) if health_before != null else 0.0
		var available := maxf(0.0, float(def.leech_return.get("cap", 2.0)) - cast.spirit_heal_reserved)
		var share := float(def.leech_return.get("share", 0.15)) + float(cast.plan.get("flags", {}).get("leeching", {}).get("share", 0.0))
		var collected := minf(actual * share, available)
		stolen_life += collected
		cast.spirit_heal_reserved += collected

func _begin_spirit_ending() -> void:
	if spirit_ending:
		return
	spirit_ending = true
	return_age = 0.0
	target_ref = null
	var player = cast.caster
	returning_life = is_instance_valid(player) and player.get("health") != null and float(player.health) < float(player.max_health) and stolen_life > 0.0
	finishing_hunt = not returning_life

func _step_spirit_ending(delta: float) -> void:
	return_age += delta
	if return_age >= 4.0:
		finish(false)
		return
	var player = cast.caster
	if returning_life and float(player.health) >= float(player.max_health):
		returning_life = false
		finishing_hunt = true
		stolen_life = 0.0
		target_ref = null
	var prey = null
	var dest: Vector2 = cast.caster_position()
	if finishing_hunt:
		var current = target_ref.get_ref() if target_ref else null
		var best := INF
		for candidate in cast.enemies():
			if hunted_targets.has(candidate.get_instance_id()) or exclude.has(candidate.get_instance_id()) or not _on_screen(candidate):
				continue
			var distance := global_position.distance_to(candidate.global_position)
			var score := 0.0 if candidate == current else distance + 1.0
			if score < best and distance <= 600.0:
				best = score
				prey = candidate
		target_ref = weakref(prey) if prey else null
		if prey == null:
			return
		dest = prey.global_position
	prev_pos = global_position
	var travel_speed := float(def.leech_return.get("return_speed", 320.0))
	if returning_life:
		for motion in def.get("motion", []):
			if str(motion.get("type", "")) in ["chase", "straight", "guided"]:
				travel_speed = float(motion.get("speed", 220.0)) * 0.8
				break
	global_position = global_position.move_toward(dest, travel_speed * delta)
	if global_position != prev_pos:
		direction = prev_pos.direction_to(global_position)
	if returning_life:
		if global_position.distance_to(dest) <= 18.0:
			cast.heal_caster(minf(stolen_life, float(player.max_health) - float(player.health)))
			_spirit_arrival(true)
			finish(false)
	elif prey != null and _swept_contains(prey):
		hit(prey)

func _spirit_arrival(healed: bool) -> void:
	if _vfx == null:
		return
	var point := global_position / (1280.0 / 192.0)
	var colors := [Color("#c7ffdc"), Color("#38ff94"), Color("#168b57")] if healed else [Color("#ffe1c4"), Color("#ff4a61"), Color("#a91b48")]
	_vfx.ring(point.x, point.y, 4.2, 0.24, colors)
	_vfx.star(point.x, point.y, 2.0, 0.14, 4 if healed else 6, colors[0])

func fire(event: String, at: Vector2, victim) -> void:
	for key in def.get("events", {}):
		if str(key).split("#")[0] == event:
			cast.spawn_event(self, def.events[key], at, victim)

func finish(natural: bool) -> void:
	if done:
		return
	done = true
	visual_remaining = 0.12 if delivery == "volume" else 0.0
	if visual_remaining <= 0.0:
		queue_free()
	if _vfx:
		_vfx.part_finished(self, natural)
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
func _process(delta: float) -> void:
	if not done:
		return
	visual_remaining = maxf(0.0, visual_remaining - delta)
	if visual_remaining <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if done and visual_remaining <= 0.0:
		return
	if _vfx and _vfx.presents(self):
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
