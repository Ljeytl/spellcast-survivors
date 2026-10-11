extends RefCounted
## Turns spell-engine events into chunky-magic VFX (docs/VFX_EVENTS.md).
##
## The spell engine (GenericCast / SpellPart) announces moments; this class
## decides how they look, from the cast plan's element (native look) and its
## keyword elements (accent look). It only READS gameplay objects: positions,
## geometry, statuses. It never changes them.
##
## A part is "presented" when its look and its delivery/geometry are supported
## here; SpellPart then skips its placeholder drawing. Anything unsupported keeps
## the placeholder, so the game never shows nothing.

const WPS := 1280.0 / 192.0

# Looks implemented so far. Element ids are the spell engine's (SpellDefs.ELEMENTS).
const NATIVE_LOOK := {"": "arcane", "arcane": "arcane", "fire": "fire"}
const ACCENT_LOOK := {"fire": "fire"}

# Body palettes (sandbox MAT.*.body): core, light, mid, dark, outline.
const BODY := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#c2361a"), Color("#4a1610")],
	"arcane": [Color("#ffffff"), Color("#c9f4ff"), Color("#8fb6f5"), Color("#6a4ad0"), Color("#1c1650")],
}
const SPARK := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#e0401c")],
	"arcane": [Color("#ffffff"), Color("#bdf3ff"), Color("#a98af5"), Color("#6a4ad0")],
}
const RIM := {"fire": Color("#ff8a1f"), "arcane": Color("#8fb6f5")}
const INK := Color("#120e14")

# Sandbox projectile presets (SPELLS.bolt / spear / fireball / fiery), sandbox units.
const FAMILY := {
	"bolt": {"body": {"t": "diamond", "a": 4.0, "b": 2.0}, "trail": {"rate": 2.0, "per_dist": 0.5, "heat": 1.0, "spread": 0.8, "grip": 0.15, "inh": 0.25, "ember": 0.15}, "impact": 0.55},
	"spear": {"body": {"t": "diamond", "a": 8.0, "b": 1.4}, "trail": {"rate": 3.0, "per_dist": 0.8, "heat": 1.1, "spread": 0.8, "grip": 0.2, "inh": 0.35, "ember": 0.3}, "impact": 0.35},
	"ball": {"body": {"t": "orb", "r": 3.5}, "trail": {"rate": 5.0, "per_dist": 0.9, "heat": 1.35, "spread": 2.2, "grip": 0.35, "inh": 0.3, "ember": 0.35}, "impact": 1.4},
}
# Keyword-accent trail (sandbox "Fiery Bolt"): light flames under the native body.
const ACCENT_TRAIL := {"rate": 1.0, "per_dist": 0.25, "heat": 0.65, "spread": 0.6, "grip": 0.1, "inh": 0.2, "ember": 0.3, "small": 1.0}

const MAX_BURNING := 24          # burning enemies drawn at once (nearest the camera)

var vfx                          # the Vfx autoload
var _parts := {}                 # instance id -> state
var enabled := true              # console "vfx present off" shows the placeholders

func _init(owner):
	vfx = owner

# ------------------------------------------------------------------ look resolution

static func look_of(plan: Dictionary) -> Dictionary:
	var native = NATIVE_LOOK.get(str(plan.get("element", "")), "")
	var accent := ""
	for e in plan.get("elements", []):
		var a = ACCENT_LOOK.get(str(e.get("element", "")), "")
		if a != "" and a != native:
			accent = a
			break
	return {"native": native, "accent": accent}

static func family_of(part) -> String:
	var hint = str(part.def.get("vfx", {}).get("family", ""))
	if hint != "":
		return hint
	var pierce = int(part.def.get("limits", {}).get("pierce", 0))
	if pierce != 0:
		return "spear"
	return "ball" if float(part.geo("radius", 12.0)) >= 16.0 else "bolt"

static func _kind(part) -> String:
	match part.delivery:
		"projectile":
			return "projectile" if part.geo_type() == "body" else ""
		"volume":
			if part.geo_type() == "disk" and part._propagation() == "instant":
				return "burst"
		"field", "aura":
			if part.geo_type() == "disk":
				return "field"
	return ""

func presents(part) -> bool:
	return enabled and _parts.has(part.get_instance_id())

# ------------------------------------------------------------------ events

func cast_started(cast) -> void:
	if not enabled or cast == null or not is_instance_valid(cast.caster):
		return
	var look = look_of(cast.plan)
	if look.native == "":
		return
	var key: String = look.accent if look.accent != "" else look.native
	# Cast flash at the staff (2-4 steps), principle 7: anticipation before release.
	var at := _staff_su(cast.caster)
	vfx.star(at.x, at.y, 3.2, 0.1, 4, BODY[key][0])
	vfx.flash(at.x, at.y, 1.4, 0.07, BODY[key][1])
	for i in 6:
		var ang := randf() * TAU
		vfx.spark(at.x, at.y, cos(ang) * 28.0, sin(ang) * 22.0 - 8.0, 0.25 + randf() * 0.15, SPARK[key])

func part_spawned(part) -> void:
	if not enabled:
		return
	var look = look_of(part.cast.plan)
	var kind := _kind(part)
	if look.native == "" or kind == "":
		return
	var pos: Vector2 = part.global_position / WPS
	var st := {"part": weakref(part), "kind": kind, "look": look, "last": pos, "acc": 0.0}
	match kind:
		"projectile":
			st.family = family_of(part)
		"burst":
			if look.native != "fire" and look.accent != "fire":
				return
			var r_su: float = part.geo("radius", 90.0) / WPS
			_damage_disk(pos.x, pos.y, maxf(0.35, (r_su - 3.0) / 9.0), {})
		"field":
			if look.native != "fire" and look.accent != "fire":
				return
			var life := float(part.def.get("timing", {}).get("duration", 3.0))
			st.field = vfx.field(pos.x, pos.y, part.geo("radius", 60.0) / WPS, life + 0.5)
	_parts[part.get_instance_id()] = st

func part_hit(part, _enemy, at: Vector2) -> void:
	var st = _parts.get(part.get_instance_id())
	if st == null or st.kind != "projectile":
		return
	var p: Vector2 = part.global_position / WPS
	var impact_look: String = st.look.accent if st.look.accent != "" else st.look.native
	var spawns_burst := false
	for key in part.def.get("events", {}):
		if str(key).begins_with("on_hit"):
			spawns_burst = true
	if impact_look == "fire":
		if st.family == "spear":
			_damage_disk(p.x, p.y, 0.35, {"nodecal": true, "stop": 0})
		elif spawns_burst:
			vfx.flash(p.x, p.y, 2.0, 0.06, BODY.fire[0])
		else:
			_damage_disk(p.x, p.y, FAMILY[st.family].impact, {})
	else:
		for i in 8:
			var ang := randf() * TAU
			vfx.spark(p.x, p.y, cos(ang) * 30.0, sin(ang) * 30.0, 0.3, SPARK[impact_look])
		vfx.star(p.x, p.y, 2.4, 0.07, 4, BODY[impact_look][0])

func part_finished(part, natural: bool) -> void:
	var id = part.get_instance_id()
	var st = _parts.get(id)
	if st == null:
		return
	_parts.erase(id)
	match st.kind:
		"projectile":
			if natural and part.def.get("events", {}).is_empty():
				var p: Vector2 = part.global_position / WPS
				var key: String = st.look.accent if st.look.accent != "" else st.look.native
				for i in 4:
					vfx.spark(p.x, p.y, (randf() - 0.5) * 20.0, -(6.0 + randf() * 12.0), 0.3 + randf() * 0.2, SPARK[key])
				if key == "fire":
					vfx.puff(p.x, p.y - 1.0, 2)
		"field":
			# Break up, don't fade: the field erodes over its last half second.
			var f: Dictionary = st.field
			f.life = minf(f.life, f.age + 0.5)

# ------------------------------------------------------------------ per step

func step(dt: float) -> void:
	for id in _parts.keys():
		var st: Dictionary = _parts[id]
		var part = st.part.get_ref()
		if part == null or not is_instance_valid(part):
			_parts.erase(id)
			continue
		var pos: Vector2 = part.global_position / WPS
		match st.kind:
			"projectile":
				_trail(part, st, pos, dt)
			"field":
				st.field.x = pos.x
				st.field.y = pos.y
		st.last = pos
	_burning(dt)

func _trail(part, st: Dictionary, pos: Vector2, dt: float) -> void:
	var vel: Vector2 = (pos - st.last) / maxf(dt, 0.0001)
	var dist := pos.distance_to(st.last)
	var native: String = st.look.native
	var accent: String = st.look.accent
	if native == "fire":
		_emit_trail(part, st, "acc", FAMILY[st.family].trail, pos, vel, dist, dt)
	elif accent == "fire":
		_emit_trail(part, st, "acc", ACCENT_TRAIL, pos, vel, dist, dt)
	if native == "arcane":
		for i in 2:
			vfx.spark(pos.x + (randf() - 0.5) * 3.0, pos.y + (randf() - 0.5) * 3.0, -vel.x * 0.05, -vel.y * 0.05, 0.35 + randf() * 0.25, SPARK.arcane)

func _emit_trail(part, st: Dictionary, key: String, t: Dictionary, pos: Vector2, vel: Vector2, dist: float, dt: float) -> void:
	var body: Dictionary = FAMILY[st.family].body
	var sp := vel.length()
	var dir := vel / sp if sp > 0.001 else Vector2(part.direction)
	var back := float(body.get("a", body.get("r", 3.0))) * 0.9
	st[key] = float(st.get(key, 0.0)) + float(t.rate) * dt * 60.0 + dist * float(t.per_dist)
	while st[key] >= 1.0:
		st[key] -= 1.0
		var spread := float(t.spread)
		vfx.flame(part, pos, {
			"lx": -dir.x * back + (randf() + randf() - 1.0) * spread,
			"ly": -dir.y * back + (randf() + randf() - 1.0) * spread * 0.8,
			"inh": float(t.inh), "grip": float(t.grip), "heat": float(t.heat),
			"rise": 16.0 + randf() * 10.0, "life": 0.28 + randf() * 0.3, "small": float(t.get("small", 0.0)),
			"avx": vel.x, "avy": vel.y})
	if randf() < float(t.ember) * dt * 60.0:
		vfx.ember(pos.x, pos.y, vel.x * 0.3 + (randf() - 0.5) * 16.0, -(12.0 + randf() * 16.0), 0.6 + randf() * 0.7)

## Burning status: small flames gripping each burning enemy (sandbox updateEnemies).
## Reads StatusComponent state; never touches it.
func _burning(dt: float) -> void:
	var tree = vfx.get_tree()
	if tree == null:
		return
	var center: Vector2 = vfx._visible_world_rect().get_center()
	var burning := []
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if s.has_method("has") and s.has("burn"):
			burning.append(e)
	if burning.size() > MAX_BURNING:
		burning.sort_custom(func(a, b): return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
		burning.resize(MAX_BURNING)
	for e in burning:
		var p: Vector2 = e.global_position / WPS
		for i in 2:
			if randf() < 0.6 * dt * 60.0:
				vfx.flame(e, p, {"lx": (randf() - 0.5) * 6.0, "ly": -2.0 - randf() * 4.0, "inh": 0.1, "grip": 0.9,
					"heat": 1.05, "rise": 18.0 + randf() * 10.0, "life": 0.3 + randf() * 0.3, "small": 1.0 if randf() < 0.5 else 0.0})
		if randf() < 0.03 * dt * 60.0:
			vfx.ember(p.x, p.y - 5.0, (randf() - 0.5) * 8.0, -(14.0 + randf() * 10.0), 0.7)

# ------------------------------------------------------------------ components

## Sandbox damageDisk(): impact recipe for a fire hit of size s (1 = big).
func _damage_disk(x: float, y: float, s: float, o: Dictionary) -> void:
	var lk := 0.8 + 0.3 * s
	var big := s >= 1.0
	# Designed silhouette first (principle 2): one frame of a hard star, then the bloom.
	vfx.star(x, y, (5.0 if big else 3.0) * maxf(0.6, s), 0.07 if big else 0.05, 8 if big else 4, BODY.fire[0])
	if s >= 0.8:
		vfx.flash(x, y, 3.5 * s, 0.07, BODY.fire[0])
	var n := roundi((40.0 if big else 26.0) * s)
	for i in n:
		var ang := randf() * TAU
		var sp := (20.0 + randf() * 75.0 if big else 25.0 + randf() * 55.0) * s
		vfx.flame(null, Vector2(x, y), {"lx": cos(ang), "ly": sin(ang), "vx": cos(ang) * sp, "vy": sin(ang) * sp * 0.8,
			"rise": 10.0 + randf() * 12.0, "life": (0.35 + randf() * 0.35 if big else 0.28 + randf() * 0.3) * lk, "heat": 1.75 if big else 1.5})
	if big:
		for i in roundi(10 * s):
			vfx.flame(null, Vector2(x, y), {"lx": (randf() - 0.5) * 4.0 * s, "ly": (randf() - 0.5) * 3.0 * s,
				"rise": 24.0 + randf() * 14.0, "life": 0.6 + randf() * 0.4, "heat": 1.3})
		vfx.field(x, y, 7.0 * s, 1.3, {"rate": 0.9, "heat_k": 0.75})
	# 1:3:9 size contrast: a few big chunks, many small bits (principle 4).
	for i in roundi((16.0 if big else 10.0) * s):
		var ang := randf() * TAU
		var sp := (18.0 + randf() * 34.0) * s
		vfx.chunk(x, y, cos(ang) * sp, sin(ang) * sp * 0.7, 40.0 + randf() * 60.0, SPARK.fire, 0.8 + randf() * 0.6, 2 if i < 3 and big else 1)
	for i in roundi((7.0 if big else 4.0) * s):
		vfx.puff(x + (randf() - 0.5) * 8.0 * s, y - 4.0 * s - randf() * 4.0, 3 if big else 2)
	if s >= 0.8:
		vfx.ring(x, y, (20.0 if big else 14.0) * s, 0.42 if big else 0.35, SPARK.fire)
	if not o.get("nodecal", false):
		vfx.scorch(x, y, 6.5 * s, 6.0)
	if big:
		vfx.hitstop(int(o.get("stop", 3)))
		vfx.shake(0.2)
	elif s >= 0.5:
		vfx.hitstop(1)

func _staff_su(caster) -> Vector2:
	for c in caster.get_children():
		if c is Node2D and "staff" in str(c.name).to_lower():
			return (c as Node2D).global_position / WPS + Vector2(0.0, -2.0)
	return caster.global_position / WPS + Vector2(1.5, -5.0)

# ------------------------------------------------------------------ bodies

## Projectile bodies (sandbox drawBody): shaded shape in the native palette,
## oriented to motion, dark outer outline so the hitbox reads over its own tail,
## edge in the accent colour when a keyword element is present.
func draw_bodies(buf: PackedByteArray) -> void:
	var K: float = vfx.K
	for st in _parts.values():
		if st.kind != "projectile":
			continue
		var part = st.part.get_ref()
		if part == null or not is_instance_valid(part):
			continue
		var pos: Vector2 = part.global_position / WPS
		var d: Vector2 = pos - st.last
		var dir: Vector2 = d.normalized() if d.length() > 0.01 else Vector2(part.direction).normalized()
		var b: Dictionary = FAMILY[st.family].body
		var sc: float = float(part.size_scale)
		var pal: Array = BODY[st.look.native]
		var rim = RIM[st.look.accent] if st.look.accent != "" else null
		var cx := roundi(pos.x * K)
		var cy := roundi(pos.y * K)
		var orb: bool = b.t == "orb"
		var ra: float = (float(b.get("r", 0.0)) if orb else float(b.a)) * K * sc
		var rb: float = (float(b.get("r", 0.0)) if orb else float(b.b)) * K * sc
		var R := ceili(maxf(ra, rb) + 1.0)
		var inside := func(ox: int, oy: int) -> bool:
			if orb:
				return ox * ox + oy * oy <= ra * ra + 0.5
			var u := ox * dir.x + oy * dir.y
			var v := -ox * dir.y + oy * dir.x
			return absf(u) / ra + absf(v) / maxf(rb, 0.75) <= 1.0
		for oy in range(-R - 1, R + 2):
			for ox in range(-R - 1, R + 2):
				var c = null
				if inside.call(ox, oy):
					var edge: bool = not inside.call(ox + 1, oy) or not inside.call(ox - 1, oy) or not inside.call(ox, oy + 1) or not inside.call(ox, oy - 1)
					if edge:
						c = rim if rim != null else pal[4]
					elif not orb and ox * dir.x + oy * dir.y > ra * 0.45:
						c = pal[0]
					else:
						var s: float = -(ox + oy) / maxf(ra, 1.0) if orb else -(ox * 0.35 + oy) / maxf(rb, 1.0)
						c = pal[1] if s > 0.5 else (pal[3] if s < -0.5 else pal[2])
						if orb and ox == -1 and oy == -1:
							c = pal[0]
				elif inside.call(ox + 1, oy) or inside.call(ox - 1, oy) or inside.call(ox, oy + 1) or inside.call(ox, oy - 1):
					c = INK
				if c != null:
					vfx._put(buf, cx + ox, cy + oy, c)
