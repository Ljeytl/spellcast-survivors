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
const NATIVE_LOOK := {"": "arcane", "arcane": "arcane", "fire": "fire", "water": "water", "storm": "lightning", "life": "life"}
const ACCENT_LOOK := {"fire": "fire", "water": "water", "storm": "lightning", "life": "life"}
# The engine has one "water" element for water and ice spells (plan section 7:
# Water/Ice spells pick Water or Ice). Cold statuses or a vfx.look hint pick Ice.
const COLD := ["chilled", "frozen"]
const BUILT := ["arcane", "fire", "ice", "lightning", "water", "life"]
const ICE := preload("res://scripts/vfx/VfxElements.gd").ICE
const LIT := preload("res://scripts/vfx/VfxElements.gd").LIGHTNING
const WAT := preload("res://scripts/vfx/VfxElements.gd").WATER
const LIFE := preload("res://scripts/vfx/VfxElements.gd").LIFE

# Body palettes (sandbox MAT.*.body): core, light, mid, dark, outline.
const BODY := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#c2361a"), Color("#4a1610")],
	"arcane": [Color("#ffffff"), Color("#c9f4ff"), Color("#8fb6f5"), Color("#6a4ad0"), Color("#1c1650")],
	"ice": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8"), Color("#1a2e5a")],
	"lightning": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff"), Color("#7a5cf0"), Color("#2a1f5e")],
	"water": [Color("#ffffff"), Color("#a6e6ff"), Color("#3f9fe4"), Color("#2063b0"), Color("#0f1d3a")],
	"life": [Color("#f0ffc0"), Color("#c8f07a"), Color("#7fcf4a"), Color("#3e8f3a"), Color("#1e2e16")],
}
const SPARK := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#e0401c")],
	"arcane": [Color("#ffffff"), Color("#bdf3ff"), Color("#a98af5"), Color("#6a4ad0")],
	"ice": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8")],
	"lightning": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff"), Color("#7a5cf0")],
	"water": [Color("#ffffff"), Color("#cdeffd"), Color("#7cc4f2"), Color("#3f9fe4")],
	"life": [Color("#d4f58a"), Color("#86d24c"), Color("#46963c"), Color("#275c2e")],
}
const RIM := {"fire": Color("#ff8a1f"), "arcane": Color("#8fb6f5"), "ice": Color("#d6f6ff"), "lightning": Color("#8fb2ff"), "water": Color("#4fb2f0"), "life": Color("#7fcf4a")}
const NOVA_RIM := {"ice": [Color("#8fd3ee"), Color("#ffffff")], "lightning": [Color("#8fb2ff"), Color("#ffffff")], "water": [Color("#4fb2f0"), Color("#e8f8ff")], "life": [Color("#7fcf4a"), Color("#d4f58a")]}
# Rigid looks keep a drawn body (that IS the technique: crystal sprites).
const LIFE_BODY := {"bolt": {"t": "diamond", "a": 5.0, "b": 2.0}, "spear": {"t": "diamond", "a": 8.0, "b": 1.4}, "ball": {"t": "orb", "r": 3.5}}
const ICE_BODY := {"bolt": {"t": "diamond", "a": 4.5, "b": 2.0}, "spear": {"t": "diamond", "a": 8.0, "b": 1.6}, "ball": {"t": "diamond", "a": 5.0, "b": 3.2}}
const INK := Color("#120e14")
# Magma core (fireball): dark crust, glowing cracks, hot seams. Hue-shifted
# toward red in the dark end, white kept out (white is for impacts).
const MAGMA := [Color("#2a0f0c"), Color("#4a1a12"), Color("#c2361a"), Color("#ff8a1f"), Color("#ffd54a")]

# Sandbox projectile presets (SPELLS.bolt / spear / fireball / fiery), sandbox units.
const FAMILY := {
	"bolt": {"body": {"t": "diamond", "a": 4.0, "b": 2.0}, "trail": {"rate": 2.0, "per_dist": 0.5, "heat": 1.0, "spread": 0.8, "grip": 0.15, "inh": 0.25, "ember": 0.15}, "impact": 0.55},
	"spear": {"body": {"t": "diamond", "a": 8.0, "b": 1.4}, "trail": {"rate": 3.0, "per_dist": 0.8, "heat": 1.1, "spread": 0.8, "grip": 0.2, "inh": 0.35, "ember": 0.3}, "impact": 0.35},
	"ball": {"body": {"t": "orb", "r": 3.5}, "trail": {"rate": 6.0, "per_dist": 1.1, "heat": 1.0, "spread": 3.0, "grip": 0.35, "inh": 0.3, "ember": 0.35}, "impact": 1.4},
}
# Fire-native projectiles have no drawn shape: the body is a knot of hot,
# high-grip flames riding the projectile plus a tiny white core. "r" = knot
# radius (su), "n" = flames per 60 fps frame, "len" stretches the knot along
# the motion (spears), "core" = white core half-size in cells.
const FIRE_BODY := {
	"bolt": {"r": 1.3, "n": 1.5, "len": 1.6, "heat": 0.45, "core": 1},
	"spear": {"r": 0.7, "n": 2.0, "len": 5.0, "heat": 0.45, "core": 1},
	"ball": {"r": 3.6, "n": 5.0, "len": 1.0, "heat": 0.4, "core": 0, "magma": 3.2},
}
# Keyword-accent trail (sandbox "Fiery Bolt"): light flames under the native body.
const ACCENT_TRAIL := {"rate": 1.0, "per_dist": 0.25, "heat": 0.65, "spread": 0.6, "grip": 0.1, "inh": 0.2, "ember": 0.3, "small": 1.0}

const MAX_BURNING := 24          # burning enemies drawn at once (nearest the camera)

var vfx                          # the Vfx autoload
var _parts := {}                 # instance id -> state
var _presented := {}             # instance id -> weakref: parts we draw, kept until freed so
                                 # finished parts (e.g. a blast's 0.12 s tail) never flash placeholder art
var enabled := true              # console "vfx present off" shows the placeholders

func _init(owner):
	vfx = owner

# ------------------------------------------------------------------ look resolution

static func look_of(plan: Dictionary) -> Dictionary:
	var native: String = NATIVE_LOOK.get(str(plan.get("element", "")), "")
	if native == "water":
		native = "ice" if _plan_is_cold(plan) else "water"
	if not native in BUILT:
		native = ""
	var accent := ""
	for e in plan.get("elements", []):
		var a: String = ACCENT_LOOK.get(str(e.get("element", "")), "")
		if a == "water":
			a = "ice" if str(e.get("status", "")) in COLD else "water"
		if a in BUILT and a != native:
			accent = a
			break
	return {"native": native, "accent": accent}

static func _plan_is_cold(plan: Dictionary) -> bool:
	for pname in plan.get("parts", {}):
		var pd: Dictionary = plan.parts[pname]
		var hint := str(pd.get("vfx", {}).get("look", ""))
		if hint != "":
			return hint == "ice"
		for pay in pd.get("payload", []):
			if str(pay.get("status", "")) in COLD:
				return true
	return false

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
		"self":
			return "self"
		"projectile":
			return "projectile" if part.geo_type() == "body" else ""
		"volume":
			if part.geo_type() == "disk" and part._propagation() == "instant":
				return "burst"
			if part.geo_type() == "ring" and part._propagation() == "expanding":
				return "nova"
			if part.geo_type() == "rect" and part._propagation() == "travelling":
				return "wave"
		"field", "aura":
			if part.geo_type() == "disk" and part.def.get("payload", []).is_empty() and part.def.get("events", {}).size() > 0:
				# no payload: the disk is a range for its events, not a damage area
				var dur := float(part.def.get("timing", {}).get("duration", 3.0))
				return "charge" if dur <= 1.0 and part.def.events.has("on_expire") else "zone"
			if part.geo_type() in ["disk", "line"]:
				return "field"
	return ""

func presents(part) -> bool:
	return enabled and _presented.has(part.get_instance_id())

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
			var r_su: float = part.geo("radius", 90.0) / WPS
			if look.native == "ice":
				_ice_impact(pos.x, pos.y, maxf(0.6, r_su / 12.0))
			elif look.native == "lightning":
				_strike(pos.x, pos.y, clampf(r_su / 10.0, 0.6, 2.0))
			elif look.native == "water":
				_water_impact(pos.x, pos.y, clampf(r_su / 11.0, 0.6, 2.5))
			elif look.native == "life":
				_life_impact(pos.x, pos.y, clampf(r_su / 10.0, 0.6, 2.5))
			elif look.native == "fire" or look.accent == "fire":
				_damage_disk(pos.x, pos.y, maxf(0.35, (r_su - 3.0) / 9.0), {})
			else:
				return
		"nova":
			if not NOVA_RIM.has(look.native) and look.native != "fire":
				return
			st.seed = randf() * 6.0
			if look.native == "life":
				var R0: float = float(part.geo("radius", 100.0)) / WPS
				var sp0: float = float(part.def.get("propagation", {}).get("speed", 600.0)) / WPS
				for i in 10:
					vfx.elements.vine(pos.x, pos.y, float(i) / 10.0 * TAU + randf() * 0.3, R0, R0 / maxf(1.0, sp0) * vfx.fx_speed, R0 / maxf(1.0, sp0) * vfx.fx_speed + 0.5, 0.45)
			if look.native == "fire":
				_fire_nova_start(pos, float(part.geo("radius", 100.0)) / WPS)
		"wave":
			if look.native != "water":
				return
			st.acc = 0.0
		"self":
			if look.native != "life":
				return
			_life_bloom(_staff_su(part.cast.caster) + Vector2(-1.5, 5.0) if is_instance_valid(part.cast.caster) else pos)
		"charge", "zone":
			if look.native != "lightning":
				return
			st.off = (randf() - 0.5) * 12.0
			st.age = 0.0
			st.life = float(part.def.get("timing", {}).get("duration", 0.45))
		"field":
			if look.native == "ice" or look.native == "lightning" or look.native == "water" or look.native == "life":
				var r_su2: float = part.geo("radius", 60.0) / WPS
				if part.geo_type() != "disk":
					return
				var life2 := float(part.def.get("timing", {}).get("duration", 3.0))
				if part.def.get("timing", {}).get("duration") == null:
					life2 = 4.0
				st.field = vfx.field(pos.x, pos.y, r_su2, life2 + 0.5, {"look": vfx.field_look(look.native)})
				if look.native == "life":
					_life_field_start(st.field)
				_parts[part.get_instance_id()] = st
				_presented[part.get_instance_id()] = weakref(part)
				return
			if look.native != "fire" and look.accent != "fire":
				return
			var life := float(part.def.get("timing", {}).get("duration", 3.0))
			if part.geo_type() == "line":
				# Field lines lie across the cast direction (SpellPart.contains). Axis =
				# half-length minus half-width, so the rim lands exactly on the hitbox.
				var hw: float = part.geo("width", 30.0) * 0.5
				var axis: Vector2 = Vector2(part.direction).orthogonal().normalized() * maxf(0.0, part.geo("length", 200.0) * 0.5 - hw)
				st.field = vfx.field(pos.x, pos.y, hw / WPS, life + 0.5, {"axis": axis / WPS})
			else:
				st.field = vfx.field(pos.x, pos.y, part.geo("radius", 60.0) / WPS, life + 0.5)
	_parts[part.get_instance_id()] = st
	_presented[part.get_instance_id()] = weakref(part)

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
	if impact_look == "lightning":
		_zap(p.x, p.y)
		return
	if impact_look == "life":
		if st.family == "spear" or st.look.native != "life":
			_life_contact(p.x, p.y)
		elif not spawns_burst:
			_life_impact(p.x, p.y, 1.0)
		return
	if impact_look == "water":
		if st.family == "spear" or st.look.native != "water":
			_water_contact(p.x, p.y)
		elif not spawns_burst:
			_water_impact(p.x, p.y, 1.0)
		return
	if impact_look == "ice":
		if st.family == "spear" or st.look.native != "ice":
			_ice_contact(p.x, p.y)
		elif not spawns_burst:
			_ice_impact(p.x, p.y, 1.0)
		return
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
		"nova":
			if st.look.native == "fire" and natural:
				_fire_nova_end(part.global_position / WPS, float(part.geo("radius", 100.0)) / WPS)
			if st.look.native == "ice" and natural:
				_ice_nova_end(part.global_position / WPS, float(part.geo("radius", 100.0)) / WPS)
		"field":
			# Break up, don't fade: the field erodes over its last half second.
			var f: Dictionary = st.field
			f.life = minf(f.life, f.age + 0.5)

# ------------------------------------------------------------------ per step

func step(dt: float) -> void:
	for id in _presented.keys():
		if _presented[id].get_ref() == null:
			_presented.erase(id)
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
				if st.look.native == "ice":
					_ice_field(st.field, dt)
				elif st.look.native == "lightning":
					_lightning_field(st.field, dt)
				elif st.look.native == "water":
					_water_field(st.field, dt)
				elif st.look.native == "life":
					_life_field(st.field, dt)
			"wave":
				_water_wave(part, st, dt)
			"charge":
				st.age += dt / vfx.fx_speed      # telegraph runs on game time: it must land with the real strike
				if randf() < 0.5 * dt * 60.0:
					var k: float = minf(1.0, st.age / st.life)
					var a := randf() * TAU
					var d := 9.0 * (1.0 - k) + 2.0
					vfx.elements.hop(pos.x + cos(a) * d, pos.y - 3.0 + sin(a) * d * 0.7, 0.12)
			"zone":
				if randf() < 0.15 * dt * 60.0:
					var a2 := randf() * TAU
					vfx.elements.arc(pos.x, pos.y - 3.0, pos.x + cos(a2) * 6.0, pos.y - 3.0 + sin(a2) * 4.0, 1.5, 0.06, 1)
			"nova":
				if st.look.native == "ice":
					_ice_nova(pos, float(part.front) / WPS, dt)
				elif st.look.native == "fire":
					_fire_nova(pos, float(part.front) / WPS, float(part.front) / maxf(1.0, float(part.geo("radius", 100.0))), dt)
				elif st.look.native == "water":
					_water_nova(pos, float(part.front) / WPS, dt)
				elif st.look.native == "life":
					_life_nova(pos, float(part.front) / WPS, dt)
				else:
					_lightning_nova(pos, float(part.front) / WPS, st.seed, dt)
		st.last = pos
	_burning(dt)
	_chilled(dt)
	_shocked(dt)
	_entangled(dt)

func _trail(part, st: Dictionary, pos: Vector2, dt: float) -> void:
	var vel: Vector2 = (pos - st.last) / maxf(dt, 0.0001)
	var dist := pos.distance_to(st.last)
	var native: String = st.look.native
	var accent: String = st.look.accent
	if native == "fire":
		_fire_body(part, st, pos, vel, dt)
		_emit_trail(part, st, "acc", FAMILY[st.family].trail, pos, vel, dist, dt)
	elif accent == "fire":
		_emit_trail(part, st, "acc", ACCENT_TRAIL, pos, vel, dist, dt)
	if native == "ice" or accent == "ice":
		_ice_trail(pos, vel, dt)
	if native == "lightning" or accent == "lightning":
		_lightning_trail(st, pos, vel, dt)
	if native == "water" or accent == "water":
		_water_trail(st, pos, vel, dt, native == "water")
	if native == "life" or accent == "life":
		_life_trail(st, pos, vel, dt)
	if native == "arcane":
		for i in 2:
			vfx.spark(pos.x + (randf() - 0.5) * 3.0, pos.y + (randf() - 0.5) * 3.0, -vel.x * 0.05, -vel.y * 0.05, 0.35 + randf() * 0.25, SPARK.arcane)

func _fire_body(part, st: Dictionary, pos: Vector2, vel: Vector2, dt: float) -> void:
	var fb: Dictionary = FIRE_BODY[st.family]
	var sp := vel.length()
	var dir := vel / sp if sp > 0.001 else Vector2(part.direction).normalized()
	var r: float = float(fb.r) * float(part.size_scale)
	st.body_acc = float(st.get("body_acc", 0.0)) + float(fb.n) * dt * 60.0
	while st.body_acc >= 1.0:
		st.body_acc -= 1.0
		var ang := randf() * TAU
		var d := sqrt(randf()) * r
		# lean the knot backwards a little: the leading edge is the hottest, flames lag
		var along := cos(ang) * d * float(fb.len) - absf(randf() - randf()) * r * float(fb.len) * 0.6
		var off := dir * along + dir.orthogonal() * sin(ang) * d
		vfx.flame(part, pos, {"lx": off.x, "ly": off.y, "inh": 1.0, "grip": 1.0, "heat": float(fb.heat),
			"rise": 4.0 + randf() * 6.0, "life": 0.1 + randf() * 0.12, "round": true, "avx": vel.x, "avy": vel.y})

func _emit_trail(part, st: Dictionary, key: String, t: Dictionary, pos: Vector2, vel: Vector2, dist: float, dt: float) -> void:
	var body: Dictionary = FAMILY[st.family].body
	var sp := vel.length()
	var dir := vel / sp if sp > 0.001 else Vector2(part.direction)
	var back := float(body.get("a", body.get("r", 3.0))) * 0.9
	st[key] = float(st.get(key, 0.0)) + float(t.rate) * dt * 60.0 + dist * float(t.per_dist)
	var n := floori(st[key])
	st[key] -= n
	var last: Vector2 = st.last
	for j in n:
		# Spread this step's flames along the path covered during the step, so a
		# fast body leaves a continuous tube instead of a bead per step.
		var at := last.lerp(pos, (j + randf()) / n)
		var spread := float(t.spread)
		vfx.flame(part, pos, {
			"lx": at.x - pos.x - dir.x * back + (randf() + randf() - 1.0) * spread,
			"ly": at.y - pos.y - dir.y * back + (randf() + randf() - 1.0) * spread * 0.8,
			"inh": float(t.inh), "grip": float(t.grip), "heat": float(t.heat),
			"rise": 16.0 + randf() * 10.0, "life": 0.28 + randf() * 0.3, "small": float(t.get("small", 0.0)), "round": true,
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

## Fire nova (sandbox novaFront): flash, inner shock ring and a burst of flame at
## the caster; the live front (the hitbox) is a band of flame tongues thrown
## outward, embers flying; scorch marks where it stops.
func _fire_nova_start(c: Vector2, R: float) -> void:
	vfx.flash(c.x, c.y, 4.0, 0.07, BODY.fire[0])
	vfx.star(c.x, c.y, 4.0, 0.07, 8, BODY.fire[0])
	vfx.ring(c.x, c.y, R * 0.55, 0.22, SPARK.fire)
	for i in 18:
		var a := randf() * TAU
		vfx.flame(null, c, {"vx": cos(a) * 40.0, "vy": sin(a) * 30.0, "rise": 12.0, "life": 0.25, "heat": 1.6})
	vfx.shake(0.3)
	vfx.hitstop(2)

func _fire_nova(c: Vector2, r: float, k: float, dt: float) -> void:
	var n := TAU * r * 0.17 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		var rr := r - randf() * 2.5
		vfx.flame(null, Vector2(c.x + cos(a) * rr, c.y + sin(a) * rr), {"vx": cos(a) * 22.0, "vy": sin(a) * 16.0,
			"heat": 1.5 * (1.0 - k * 0.45), "rise": 16.0 + randf() * 12.0, "life": 0.28 + randf() * 0.25})
		i += 1.0
	if randf() < 0.8 * dt * 60.0:
		var a2 := randf() * TAU
		vfx.chunk(c.x + cos(a2) * r, c.y + sin(a2) * r, cos(a2) * 30.0, sin(a2) * 22.0, 30.0 + randf() * 30.0, SPARK.fire, 0.6 + randf() * 0.4, 1)

func _fire_nova_end(c: Vector2, R: float) -> void:
	for i in 9:
		var a := float(i) / 9.0 * TAU + randf() * 0.4
		vfx.scorch(c.x + cos(a) * R, c.y + sin(a) * R, 2.5 + randf() * 1.5, 4.0)

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

# ------------------------------------------------------------------ ice (sandbox FX.ice)

func _ice_trail(p: Vector2, vel: Vector2, dt: float) -> void:
	if randf() < 0.25 * dt * 60.0:
		vfx.elements.flake(p.x - vel.x * 0.02 + (randf() - 0.5) * 3.0, p.y + (randf() - 0.5) * 3.0,
			vel.x * 0.06 + (randf() - 0.5) * 6.0, 2.0 + randf() * 4.0, 0.7 + randf() * 0.5, 0 if randf() < 0.7 else 1, 5.0)
	if randf() < 0.6 * dt * 60.0:
		vfx.elements.mote(p.x - vel.x * 0.02 + (randf() - 0.5) * 3.0, p.y + (randf() - 0.5) * 3.0,
			vel.x * 0.08 + (randf() - 0.5) * 6.0, 4.0 + randf() * 6.0, ICE.mote, 0.6 + randf() * 0.6, 4.0, 6.0)

## Shatter: shards tumble and bounce on z-physics, frost burst, rime decal.
func _ice_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in roundi(8 * s):
		var a := randf() * TAU
		var sp := (18.0 + randf() * 36.0) * sqrt(s)
		el.shard(x, y, cos(a) * sp, sin(a) * sp * 0.7, 35.0 + randf() * 45.0, 2.0 + randf() * 1.5, 1.0 + randf() * 0.6)
	for i in roundi(16 * s):
		var a := randf() * TAU
		var sp := (15.0 + randf() * 35.0) * sqrt(s)
		el.mote(x, y, cos(a) * sp, sin(a) * sp * 0.7, ICE.mote, 0.6 + randf() * 0.6, 8.0, 4.0)
	for i in roundi(5 * s):
		var a := randf() * TAU
		var sp := (10.0 + randf() * 22.0) * sqrt(s)
		el.flake(x, y - 2.0, cos(a) * sp, sin(a) * sp * 0.7 - 6.0, 0.9 + randf() * 0.6, 1 if randf() < 0.6 else 2, 5.0)
	if s > 1.2:
		for i in roundi(4 * s):
			var a := randf() * TAU
			var d := sqrt(randf()) * 6.0 * s
			el.crystal(x + cos(a) * d, y + sin(a) * d * 0.8, 6.0 + randf() * 5.0, 0.35 + randf() * 0.35)
	vfx.star(x, y, 2.6 * maxf(0.8, s), 0.06, 4, ICE.body[0])
	vfx.flash(x, y, 2.5 * s, 0.05, ICE.body[0])
	vfx.scorch(x, y, 8.0 * s, 6.0, "frost")
	vfx.hitstop(2)

## Per-contact pop (spears, keyword accent): sandbox eContact ice.
func _ice_contact(x: float, y: float) -> void:
	var el = vfx.elements
	for i in 3:
		var a := randf() * TAU
		el.shard(x, y, cos(a) * 25.0, sin(a) * 18.0, 30.0 + randf() * 20.0, 1.8, 0.7)
	for i in 6:
		el.mote(x, y, (randf() - 0.5) * 30.0, (randf() - 0.5) * 20.0, ICE.mote, 0.5, 6.0, 3.0)
	vfx.flash(x, y, 1.5, 0.04, ICE.body[0])

## Rime field: crystals snap up and shatter, motes drift.
func _ice_field(A: Dictionary, dt: float) -> void:
	var el = vfx.elements
	var r: float = A.r
	var left: float = A.life - A.age - 0.5
	if el.crystals.size() < 10 + int(r * 0.4) and left > 0.3 and randf() < 0.2 * dt * 60.0 * maxf(1.0, r / 20.0):
		var q := _in_disk(A.x, A.y, r)
		el.crystal(q.x, q.y, 7.0 + randf() * 6.0, minf(left, 1.6 + randf() * 1.5))
	if randf() < 0.5 * dt * 60.0 * maxf(1.0, r / 20.0):
		var q2 := _in_disk(A.x, A.y, r)
		el.mote(q2.x, q2.y - 4.0, (randf() - 0.5) * 3.0, 2.0 + randf() * 3.0, ICE.mote, 1.0 + randf(), 1.0, 5.0)
	if randf() < 0.12 * dt * 60.0 * maxf(1.0, r / 20.0):
		var q4 := _in_disk(A.x, A.y, r)
		el.flake(q4.x, q4.y - 10.0, (randf() - 0.5) * 4.0, 3.0 + randf() * 3.0, 1.4 + randf(), 0 if randf() < 0.6 else 1, 2.0)

## Nova front: a frost wave. Snowflakes spill off the live front (the hitbox)
## and drift outward; crystals only snap up where the wave stops (_ice_nova_end).
## Crystals all along the front read as an earth-spike nova.
func _ice_nova(c: Vector2, r: float, dt: float) -> void:
	var el = vfx.elements
	var rt: float = dt / vfx.fx_speed
	var n := TAU * r * 1.6 * rt
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		var roll := randf()
		var size := 0 if roll < 0.5 else (1 if roll < 0.85 else 2)
		el.flake(c.x + cos(a) * r, c.y + sin(a) * r, cos(a) * 22.0, sin(a) * 15.0 - 4.0, 0.7 + randf() * 0.5, size, 4.0)
		i += 1.0
	var m := TAU * r * 1.2 * rt
	while m > 0.0:
		if randf() < m:
			var a2 := randf() * TAU
			el.mote(c.x + cos(a2) * r, c.y + sin(a2) * r, cos(a2) * 26.0, sin(a2) * 18.0, ICE.mote, 0.45, 4.0, 3.0)
		m -= 1.0

## Where the wave stops: a burst of snow along the edge (flakes thrown outward,
## a puff of motes). No rime decal (read as netting) and no crystals (read as
## random diamonds / an earth-spike nova).
func _ice_nova_end(c: Vector2, R: float) -> void:
	var el = vfx.elements
	var n := roundi(R * 1.1)
	for i in n:
		var a := TAU * (i + randf()) / n
		var rr := R * (0.94 + randf() * 0.08)
		var roll := randf()
		el.flake(c.x + cos(a) * rr, c.y + sin(a) * rr, cos(a) * (14.0 + randf() * 14.0), sin(a) * (10.0 + randf() * 10.0) - 6.0,
			0.8 + randf() * 0.6, 1 if roll < 0.6 else (2 if roll < 0.8 else 0), 5.0)
	for i in roundi(R * 1.6):
		var a2 := randf() * TAU
		el.mote(c.x + cos(a2) * R, c.y + sin(a2) * R, cos(a2) * (20.0 + randf() * 20.0), sin(a2) * 14.0, ICE.mote, 0.4 + randf() * 0.3, 6.0, 3.0)
	vfx.hitstop(1)

## Chilled / frozen status: frost motes on the enemy (reads StatusComponent).
func _chilled(dt: float) -> void:
	var tree = vfx.get_tree()
	if tree == null:
		return
	var n := 0
	for e in tree.get_nodes_in_group("enemies"):
		if n >= MAX_BURNING:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if not s.has_method("has") or not (s.has("chilled") or s.has("frozen")):
			continue
		n += 1
		var p: Vector2 = e.global_position / WPS
		if randf() < 0.2 * dt * 60.0:
			vfx.elements.mote(p.x + (randf() - 0.5) * 7.0, p.y - 6.0 + randf() * 3.0, (randf() - 0.5) * 3.0, 3.0 + randf() * 4.0, ICE.mote, 0.6, 3.0, 4.0)
		if randf() < 0.03 * dt * 60.0:
			vfx.elements.flake(p.x + (randf() - 0.5) * 6.0, p.y - 8.0, (randf() - 0.5) * 3.0, 2.0, 0.8, 0, 3.0)

static func _in_disk(x: float, y: float, r: float) -> Vector2:
	var a := randf() * TAU
	var d := sqrt(randf()) * r * 0.9
	return Vector2(x + cos(a) * d, y + sin(a) * d)

# ------------------------------------------------------------------ lightning (sandbox FX.lightning, paths)

func _lightning_trail(st: Dictionary, p: Vector2, vel: Vector2, dt: float) -> void:
	var el = vfx.elements
	# A few arcs with gaps between them, at a fixed real-time rate (the sandbox
	# rate was per display frame: on ones that was a continuous sheet of arcs).
	var rt: float = dt / vfx.fx_speed
	st.arc_acc = float(st.get("arc_acc", 0.0)) + LIGHTNING_RATE.trail * rt
	while st.arc_acc >= 1.0:
		st.arc_acc -= 1.0
		el.arc(p.x, p.y, p.x - vel.x * 0.035 + (randf() - 0.5) * 8.0, p.y - vel.y * 0.035 + (randf() - 0.5) * 8.0, 2.5, 0.1, 1)
	st.hop_acc = float(st.get("hop_acc", 0.0)) + LIGHTNING_RATE.hops * rt
	while st.hop_acc >= 1.0:
		st.hop_acc -= 1.0
		el.hop(p.x, p.y, 0.2 + randf() * 0.25)

## Lightning cadence, events per real second. Bodies re-roll their arcs on a
## held beat instead of every frame.
const LIGHTNING_RATE := {"trail": 9.0, "hops": 14.0, "body_hold": 0.09, "field_bursts": 8.0, "zap": 0.6, "status": 3.0}

## Body = a small knot of arcs (bolt) or a jagged rod (spear); the shape holds
## for body_hold seconds, then re-rolls.
func _draw_lightning_body(buf: PackedByteArray, pos: Vector2, dir: Vector2, family: String, sc: float, st: Dictionary = {}) -> void:
	var el = vfx.elements
	var A: Array = LIT.arc
	var now: float = Time.get_ticks_msec() / 1000.0
	if float(st.get("body_t", -1.0)) < now:
		st.body_t = now + LIGHTNING_RATE.body_hold * (0.6 + randf() * 0.8)
		var shapes := []
		if family == "spear":
			shapes.append([el.jag(-10.0 * sc, 0.0, 0.0, 0.0, 1.5), 1])
			if randf() < 0.6:
				var a0 := (randf() - 0.5) * 2.4
				shapes.append([el.jag(0.0, 0.0, cos(a0) * 4.0, sin(a0) * 4.0, 1.0), 2])
		else:
			var n := 3 if family == "bolt" else 5
			var reach := 1.0 if family == "bolt" else 1.5
			for i in n:
				var a := randf() * TAU
				var r := (4.0 + randf() * 3.0) * reach * sc
				shapes.append([el.jag(0.0, 0.0, cos(a) * r, sin(a) * r, 1.5), 1 if i < 1 else 2])
		st.body_shapes = shapes
	# spear shapes are built along +x: rotate into the motion direction
	for sh in st.get("body_shapes", []):
		var pts := PackedVector2Array()
		for q in sh[0]:
			pts.append(pos + (q.rotated(dir.angle()) if family == "spear" else q))
		el.path(buf, pts, A[sh[1]])
	if family == "spear":
		el.line(buf, pos - dir * 7.0 * sc, pos, A[0])
		return
	# sandbox: 3x3 sandbox-pixel core, white plus, pale corners
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			el.spx(buf, roundi(pos.x) + ox, roundi(pos.y) + oy, A[0] if absi(ox) + absi(oy) < 2 else A[1])

## Strike telegraph (sandbox drawCharges): a ring closes on the target while a
## stepped leader reaches down; the strike part lands when the charge ends.
func _draw_charge(buf: PackedByteArray, c: Vector2, st: Dictionary) -> void:
	var el = vfx.elements
	var A: Array = LIT.arc
	var k: float = minf(1.0, st.age / st.life)
	var r := 10.0 * (1.0 - k) + 3.0
	var steps := ceili(TAU * r * 1.3)
	var frame: int = vfx._steps
	var blink: int = (frame & 1) if k > 0.6 else ((frame >> 2) & 1)
	for i in steps:
		if blink == 0 and (i & 1) == 1:
			continue
		var a := TAU * i / steps
		el.spx(buf, roundi(c.x + cos(a) * r), roundi(c.y + sin(a) * r * 0.6), A[0] if k > 0.7 else A[2])
	if k > 0.6:
		var t := (k - 0.6) / 0.4
		var top := c.y - 70.0
		el.path(buf, el.jag(c.x + st.off, top, c.x + st.off * (1.0 - t), top + (c.y - top) * t, 3.0), A[3])

## Strike range (payload-less aura): a quiet dashed rim, so the zone reads
## without filling it; the strikes are the show.
func _draw_zone(buf: PackedByteArray, c: Vector2, r: float) -> void:
	var el = vfx.elements
	var steps := ceili(TAU * r * 0.5)
	var march: int = vfx._steps >> 3
	for i in steps:
		if ((i + march) % 4) != 0:
			continue
		var a := TAU * i / steps
		el.spx(buf, roundi(c.x + cos(a) * r), roundi(c.y + sin(a) * r), LIT.arc[3])

## Contact (sandbox eContact lightning): flash, hopping sparks, short forks.
func _zap(x: float, y: float) -> void:
	var el = vfx.elements
	vfx.flash(x, y, 2.0, 0.04, LIT.arc[0])
	for i in 5:
		el.hop(x, y, 0.18)
	for i in 3:
		var a := randf() * TAU
		el.arc(x, y, x + cos(a) * 7.0, y + sin(a) * 5.0, 1.5, 0.06, 1)

## Sky strike (sandbox FX.lightning.strike): thick bolt from above with a fork,
## flash, spark spray, spidering scorch, hit-stop. No charge telegraph here: the
## engine only reports a strike once its damage has happened.
func _strike(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	var sx := x + (randf() - 0.5) * 10.0
	el.arc(sx, y - 70.0, x, y, 4.0, 0.13, 0, true, true, true)
	vfx.flash(x, y, 5.0 * s, 0.05, LIT.arc[0])
	vfx.star(x, y, 3.5 * s, 0.05, 4, LIT.arc[0])
	for i in roundi(12 * s):
		el.hop(x + (randf() - 0.5) * 4.0 * s, y + (randf() - 0.5) * 3.0 * s, 0.15 + randf() * 0.25)
	vfx.spider(x, y)
	vfx.hitstop(2)
	vfx.shake(0.2 * s)

func _lightning_field(A: Dictionary, dt: float) -> void:
	var el = vfx.elements
	var r: float = A.r
	var scale := clampf(r * r / 400.0, 1.0, 1.5)
	# expected sandbox frames' worth of spawns this step (a capped probability
	# under-spawns at low frame rates)
	var ev: float = LIGHTNING_RATE.field_bursts * dt / vfx.fx_speed * scale
	var bursts := floori(ev) + (1 if randf() < ev - floorf(ev) else 0)
	for b in bursts:
		for i in 2:
			var q := _in_disk(A.x, A.y, r)
			var a := randf() * TAU
			var L := 8.0 + randf() * 12.0
			var e := Vector2(q.x + cos(a) * L, q.y + sin(a) * L * 0.8)
			if e.distance_to(Vector2(A.x, A.y)) < r:
				el.arc(q.x, q.y, e.x, e.y, 3.0, 0.2, 0 if randf() < 0.3 else 1)
	if randf() < LIGHTNING_RATE.zap * dt / vfx.fx_speed:
		var inside := []
		for e2 in vfx.get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e2) and (e2.global_position / WPS).distance_to(Vector2(A.x, A.y)) < r:
				inside.append(e2)
		if not inside.is_empty():
			var t: Vector2 = inside[randi() % inside.size()].global_position / WPS + Vector2(0.0, -3.0)
			var q2 := _in_disk(A.x, A.y, r)
			el.arc(q2.x, q2.y, t.x, t.y, 3.0, 0.08, 0)
			for i in 5:
				el.hop(t.x, t.y, 0.2)
	if randf() < 4.0 * dt / vfx.fx_speed * scale:
		var q3 := _in_disk(A.x, A.y, r)
		el.hop(q3.x, q3.y, 0.2)

## Nova: radial arcs out to the live front, regenerated every frame.
func _lightning_nova(c: Vector2, r: float, seed: float, dt: float) -> void:
	var el = vfx.elements
	for i in 7:
		var a := float(i) / 7.0 * TAU + seed + (randf() - 0.5) * 0.3
		el.arc(c.x, c.y, c.x + cos(a) * r, c.y + sin(a) * r, 3.0, 0.02, i & 1, true)
	if randf() < 0.5 * dt * 60.0:
		var a2 := randf() * TAU
		el.hop(c.x + cos(a2) * r, c.y + sin(a2) * r, 0.2)

## Shocked status: hopping sparks and a crackle across the enemy.
func _shocked(dt: float) -> void:
	var tree = vfx.get_tree()
	if tree == null:
		return
	var n := 0
	for e in tree.get_nodes_in_group("enemies"):
		if n >= MAX_BURNING:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if not s.has_method("has") or not s.has("shocked"):
			continue
		n += 1
		var p: Vector2 = e.global_position / WPS
		if randf() < 0.08 * dt * 60.0:
			vfx.elements.hop(p.x + (randf() - 0.5) * 6.0, p.y - 3.0, 0.12)
		if randf() < LIGHTNING_RATE.status * dt / vfx.fx_speed:
			vfx.elements.arc(p.x - 3.0, p.y - 5.0 + randf() * 3.0, p.x + 3.0, p.y - 2.0 - randf() * 3.0, 2.0, 0.1, 1)

# ------------------------------------------------------------------ water (sandbox FX.water, polish pass 2)

## Goo for the shaders: drop bodies (air), pools (ground), tsunami walls (air).
func accumulate_water() -> void:
	var t: float = vfx._t
	for st in _parts.values():
		if st.look.native != "water":
			continue
		var part = st.part.get_ref()
		if part == null or not is_instance_valid(part) or part.done:
			continue
		var pos: Vector2 = part.global_position / WPS
		match st.kind:
			"projectile":
				if st.family == "spear":
					continue
				var d: Vector2 = (pos - st.last)
				var dir: Vector2 = d.normalized() if d.length() > 0.01 else Vector2(part.direction).normalized()
				var big := 1.4 if st.family == "ball" else 1.0
				vfx.gsplat(0, pos.x, pos.y, 3.0 * big * float(part.size_scale))
				vfx.gsplat(0, pos.x - dir.x * 3.0 * big, pos.y - dir.y * 3.0 * big + sin(t * 12.0) * 0.5, 2.0 * big)
			"field":
				_pool_goo(st.field, t)
			"wave":
				_wave_goo(part, t)

## Pool (sandbox fieldGoo): mostly-filled water surface with drifting gaps.
func _pool_goo(A: Dictionary, t: float) -> void:
	var K: float = vfx.K
	var r: float = A.r - 1.5
	var fill := maxf(0.0, 1.0 - A.age * 2.0) * 0.6
	var R := ceili(r * K)
	var cx := roundi(A.x * K)
	var cy := roundi(A.y * K)
	for oy in range(-R, R + 1):
		for ox in range(-R, R + 1):
			if ox * ox + oy * oy > R * R:
				continue
			var X := (cx + ox) / K
			var Y := (cy + oy) / K
			var n: float = vfx.vn_fast(X * 0.14 + t * 0.3, Y * 0.14) * 0.7 + vfx.vn_fast(X * 0.35, Y * 0.35 - t * 0.6) * 0.3
			if n > 0.34 + fill:
				vfx.water_cell(1, cx + ox, cy + oy, 1.1)

func _water_trail(st: Dictionary, p: Vector2, vel: Vector2, dt: float, native: bool) -> void:
	var el = vfx.elements
	var f := dt * 60.0
	if randf() < 0.9 * f:
		el.mote(p.x - vel.x * 0.03 + (randf() - 0.5) * 2.0, p.y + (randf() - 0.5) * 2.0, vel.x * 0.15 + (randf() - 0.5) * 14.0, (randf() - 0.5) * 10.0, WAT.foam, 0.3, 40.0, 0.0)
	if randf() < (0.5 if native else 0.25) * f:
		el.droplet(p.x, p.y, vel.x * 0.15 + (randf() - 0.5) * 14.0, (randf() - 0.5) * 8.0, 15.0 + randf() * 20.0)
	st.streak_acc = float(st.get("streak_acc", 0.0)) + 0.5 * f
	while st.streak_acc >= 1.0:
		st.streak_acc -= 1.0
		el.foam_streak(p.x - vel.x * 0.03, p.y + (randf() - 0.5) * 3.0, vel.x, vel.y, 5.0 + randf() * 4.0)

## Splash: tall crown of droplets on z-physics, spray rays, three ripples, puddle.
func _water_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in roundi(30 * s):
		var a := randf() * TAU
		var sp := (20.0 + randf() * 45.0) * sqrt(s)
		el.droplet(x + cos(a) * 2.0, y + sin(a), cos(a) * sp, sin(a) * sp * 0.6, 60.0 + randf() * 70.0)
	for i in 10:
		el.ray(x, y, float(i) / 10.0 * TAU + randf() * 0.3, (7.0 + randf() * 5.0) * sqrt(s), 0.22, [WAT.hi, WAT.foam[1], WAT.foam[2]], 2.0)
	for i in roundi(4 * s):
		var a2 := randf() * TAU
		el.wblob(x, y, cos(a2) * 18.0, sin(a2) * 12.0, 1.2, 0.4, true)
	vfx.flash(x, y, 2.5 * s, 0.05, WAT.hi)
	el.ripple(x, y, 9.0 * s)
	el.ripple(x, y, 14.0 * s, 0.12)
	el.ripple(x, y, 19.0 * s, 0.26)
	vfx.scorch(x, y, 6.0 * s, 4.0, "puddle")
	vfx.hitstop(2)

func _water_contact(x: float, y: float) -> void:
	var el = vfx.elements
	for i in 12:
		var a := randf() * TAU
		el.droplet(x, y, cos(a) * 28.0, sin(a) * 18.0, 35.0 + randf() * 30.0)
	el.ripple(x, y + 2.0, 7.0)

func _water_field(A: Dictionary, dt: float) -> void:
	var el = vfx.elements
	var f := dt * 60.0 * maxf(1.0, A.r / 20.0)
	if randf() < 0.12 * f:
		var q := _in_disk(A.x, A.y, A.r)
		el.ripple(q.x, q.y, 4.0 + randf() * 4.0)
	if randf() < 0.08 * f:
		var q2 := _in_disk(A.x, A.y, A.r)
		for i in 4:
			el.droplet(q2.x, q2.y, (randf() - 0.5) * 16.0, (randf() - 0.5) * 10.0, 25.0 + randf() * 20.0)

func _water_nova(c: Vector2, r: float, dt: float) -> void:
	var el = vfx.elements
	var n := TAU * r * 0.08 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		el.droplet(c.x + cos(a) * r, c.y + sin(a) * r, cos(a) * 30.0, sin(a) * 20.0, 40.0 + randf() * 40.0)
		i += 1.0
	if randf() < 0.6 * dt * 60.0:
		var a2 := randf() * TAU
		el.foam_streak(c.x + cos(a2) * r, c.y + sin(a2) * r, cos(a2), sin(a2), 5.0)

## Tsunami (rect travelling): the hitbox band is a churning wall of goo, the
## leading edge a bright foam rim, water thrown forward off it, puddles behind.
func _wave_frame(part) -> Dictionary:
	var dir: Vector2 = Vector2(part.direction).normalized()
	var nrm := dir.orthogonal()
	var o: Vector2 = part.global_position / WPS
	var front: float = float(part.front) / WPS
	var half_len: float = float(part.geo("length", 60.0)) * 0.5 / WPS
	var hw: float = float(part.geo("width", 200.0)) * 0.5 / WPS
	var reach: float = float(part.geo("reach", 600.0)) / WPS
	return {"dir": dir, "nrm": nrm, "o": o, "front": front, "half": half_len, "hw": hw, "fade": clampf((reach - front) / 25.0, 0.0, 1.0)}

func _wave_goo(part, t: float) -> void:
	var w := _wave_frame(part)
	var o: Vector2 = w.o
	var dir: Vector2 = w.dir
	var nrm: Vector2 = w.nrm
	var hw: float = w.hw
	var tt := -hw
	while tt <= hw:
		var wob := sin(tt * 0.4 + t * 6.0) * 1.2
		var base: Vector2 = o + dir * (w.front + w.half * 0.4 + wob) + nrm * tt
		vfx.gsplat(0, base.x, base.y, 2.6 * w.fade)
		vfx.gsplat(0, base.x - dir.x * w.half * 0.8, base.y - dir.y * w.half * 0.8, 1.8 * w.fade)
		tt += 2.4

func _water_wave(part, st: Dictionary, dt: float) -> void:
	var w := _wave_frame(part)
	var el = vfx.elements
	var dir: Vector2 = w.dir
	st.acc += minf(w.hw, 40.0) * 0.75 * dt * 60.0 * w.fade
	while st.acc >= 1.0:
		st.acc -= 1.0
		var p: Vector2 = w.o + dir * (w.front + w.half) + w.nrm * ((randf() * 2.0 - 1.0) * w.hw)
		if randf() < 0.3:
			el.wblob(p.x - dir.x * 2.0, p.y - dir.y * 2.0, dir.x * 50.0, dir.y * 38.0, 1.3 + randf() * 0.8, 0.25, false)
		if randf() < 0.3:
			el.foam_streak(p.x, p.y, dir.x, dir.y, 6.0)
		if randf() < 0.7:
			el.droplet(p.x, p.y, dir.x * 40.0 + (randf() - 0.5) * 10.0, dir.y * 30.0, 30.0 + randf() * 40.0)
		if randf() < 0.2:
			el.mote(p.x, p.y - 3.0, dir.x * 30.0, -12.0, WAT.foam, 0.4, 20.0, 0.0)
		if randf() < 0.035:
			var back: Vector2 = w.o + dir * (w.front - w.half) + w.nrm * ((randf() * 2.0 - 1.0) * w.hw)
			el.wblob(back.x, back.y, 0.0, 0.0, 1.6 + randf(), 1.2 + randf(), true)

func _draw_wave_rim(buf: PackedByteArray, part) -> void:
	var w := _wave_frame(part)
	var el = vfx.elements
	var steps := ceili(w.hw * 4.0)
	var frame: int = vfx._steps
	for i in steps + 1:
		var tt: float = -w.hw + float(i) / steps * 2.0 * w.hw
		var p: Vector2 = w.o + w.dir * (w.front + w.half) + w.nrm * tt
		if vfx._bayer(roundi(p.x), roundi(p.y)) > w.fade:
			continue
		el.spx(buf, roundi(p.x), roundi(p.y), WAT.rim[1] if ((i + (frame >> 2)) % 5) == 0 else WAT.rim[0])
		el.spx(buf, roundi(p.x - w.dir.x * 1.2), roundi(p.y - w.dir.y * 1.2), WAT.rim[0])

# ------------------------------------------------------------------ life (sandbox FX.life, growth)

func _life_trail(st: Dictionary, p: Vector2, vel: Vector2, dt: float) -> void:
	st.leaf_acc = float(st.get("leaf_acc", 0.0)) + vel.length() * dt * 0.22
	while st.leaf_acc >= 1.0:
		st.leaf_acc -= 1.0
		vfx.elements.leaf(p.x - vel.x * 0.02, p.y, vel.x * 0.12 + (randf() - 0.5) * 10.0, -6.0 - randf() * 8.0, LIFE.leaf, 1.0 + randf() * 0.7)

## Bloom: leaves and petals burst, a ring of flowers pops open, grass tuft.
func _life_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in roundi(26 * s):
		var a := randf() * TAU
		var sp := (18.0 + randf() * 40.0) * sqrt(s)
		el.leaf(x, y, cos(a) * sp, sin(a) * sp * 0.7 - 10.0, LIFE.petal if randf() < 0.55 else LIFE.leaf, 1.1 + randf() * 0.9)
	var n := roundi(9 * s)
	for i in n:
		var a2 := float(i) / n * TAU
		var d := (5.0 + randf() * 3.0) * s
		el.blade(x + cos(a2) * d, y + sin(a2) * d * 0.7, 2, 0.05 + i * 0.03, 3.0, true)
	vfx.flash(x, y, 2.0, 0.05, LIFE.petal[2])
	el.grass_tuft(x, y, 6.0 * s)
	vfx.ring(x, y, 10.0 * s, 0.25, LIFE.petal)
	vfx.hitstop(2)

func _life_contact(x: float, y: float) -> void:
	for i in 7:
		var a := randf() * TAU
		vfx.elements.leaf(x, y, cos(a) * 25.0, sin(a) * 18.0 - 6.0, LIFE.petal if randf() < 0.4 else LIFE.leaf, 0.8)

func _life_field_start(A: Dictionary) -> void:
	var el = vfx.elements
	var n := roundi(70.0 * maxf(1.0, A.r * A.r / 400.0))
	for i in mini(n, 260):
		var q := _in_disk(A.x, A.y, A.r)
		el.blade(q.x, q.y, 2 + randi() % 3, Vector2(q.x - A.x, q.y - A.y).length() / A.r * 0.6, A.life - 0.5, randf() < 0.1)
	for i in 5:
		el.vine(A.x, A.y, float(i) / 5.0 * TAU + randf() * 0.5, A.r * (0.6 + randf() * 0.3), 1.2, A.life - 0.5, 0.7)

func _life_field(A: Dictionary, dt: float) -> void:
	if randf() < 0.12 * dt * 60.0 * maxf(1.0, A.r / 20.0):
		var q := _in_disk(A.x, A.y, A.r)
		vfx.elements.leaf(q.x, q.y - 3.0, (randf() - 0.5) * 6.0, -4.0, LIFE.petal if randf() < 0.3 else LIFE.leaf, 1.4)

func _life_nova(c: Vector2, r: float, dt: float) -> void:
	if randf() < 0.5 * dt * 60.0:
		var a := randf() * TAU
		vfx.elements.leaf(c.x + cos(a) * r, c.y + sin(a) * r, cos(a) * 14.0, -8.0, LIFE.petal if randf() < 0.3 else LIFE.leaf, 0.9)

## Self heal (Regrowth): not in the sandbox; built from growth parts. Flowers
## pop open in a ring at the caster's feet, petals and leaves lift, grass tuft.
func _life_bloom(at: Vector2) -> void:
	var el = vfx.elements
	for i in 10:
		var a := float(i) / 10.0 * TAU + randf() * 0.3
		var d := 5.0 + randf() * 2.0
		el.blade(at.x + cos(a) * d, at.y + sin(a) * d * 0.6, 2 + randi() % 2, 0.03 * i, 1.8, true)
	for i in 16:
		var a2 := randf() * TAU
		el.leaf(at.x + cos(a2) * 4.0, at.y - 2.0, cos(a2) * 10.0, -18.0 - randf() * 14.0, LIFE.petal if randf() < 0.5 else LIFE.leaf, 0.9 + randf() * 0.6)
	for i in 8:
		el.mote(at.x + (randf() - 0.5) * 8.0, at.y - 4.0 - randf() * 6.0, 0.0, -10.0 - randf() * 8.0, [LIFE.petal[2], LIFE.leaf[0], LIFE.leaf[1]], 0.7, 0.0, 3.0)
	el.grass_tuft(at.x, at.y, 5.0, 3.0)
	vfx.ring(at.x, at.y, 9.0, 0.3, [LIFE.petal[2], LIFE.leaf[0], LIFE.leaf[1]])

## Entangled / rooted: a vine wrapped around the enemy, a leaf now and then.
func _entangled(dt: float) -> void:
	var tree = vfx.get_tree()
	if tree == null:
		return
	var n := 0
	var list := []
	for e in tree.get_nodes_in_group("enemies"):
		if n >= MAX_BURNING:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if not s.has_method("has") or not (s.has("entangled") or s.has("rooted")):
			continue
		n += 1
		list.append(e.global_position / WPS)
		if randf() < 0.03 * dt * 60.0:
			var p: Vector2 = e.global_position / WPS
			vfx.elements.leaf(p.x, p.y - 5.0, (randf() - 0.5) * 8.0, -6.0, LIFE.leaf, 0.8)
	_wrapped = list

var _wrapped: Array = []

func draw_statuses(buf: PackedByteArray) -> void:
	var el = vfx.elements
	var t: float = vfx._t
	for p in _wrapped:
		for i in 18:
			var a := float(i) / 18.0 * TAU
			if sin(a * 3.0 + t * 3.0) <= -0.3:
				continue
			el.spx(buf, roundi(p.x + cos(a) * 4.0), roundi(p.y - 2.0 + sin(a) * 1.6 - (0.0 if i % 9 < 4 else 2.0)), LIFE.vine[i & 1])
		el.spx(buf, roundi(p.x + 3.0), roundi(p.y - 5.0), LIFE.leaf[1])

func _staff_su(caster) -> Vector2:
	for c in caster.get_children():
		if c is Node2D and "staff" in str(c.name).to_lower():
			return (c as Node2D).global_position / WPS + Vector2(0.0, -2.0)
	return caster.global_position / WPS + Vector2(1.5, -5.0)

# ------------------------------------------------------------------ bodies

## Magma ball: lumpy disk (noise on the radius), crust with crack bands that
## crawl over time, a brighter leading face. Pattern is in body-local cells so
## the cracks ride with the ball instead of sliding through it.
func _draw_magma(buf: PackedByteArray, pos: Vector2, dir: Vector2, r_su: float, seed: int) -> void:
	var K: float = vfx.K
	var cx := roundi(pos.x * K)
	var cy := roundi(pos.y * K)
	var R: float = r_su * K
	var t: float = vfx._t
	var sd := float(seed % 97)
	var n := ceili(R + 2.0)
	for oy in range(-n, n + 1):
		for ox in range(-n, n + 1):
			var d := Vector2(ox, oy).length()
			var ang := atan2(float(oy), float(ox))
			var edge: float = R * (0.86 + 0.22 * vfx.vn(cos(ang) * 1.6 + sd + t * 2.0, sin(ang) * 1.6))
			if d > edge:
				continue
			var cr: float = vfx.vn(ox * 0.55 + sd + t * 1.3, oy * 0.55 - t * 0.9)
			var lead := (ox * dir.x + oy * dir.y) / maxf(R, 1.0)
			var c: Color
			if absf(cr - 0.5) < 0.07 + 0.05 * lead:
				c = MAGMA[4] if lead > 0.3 else MAGMA[3]
			elif absf(cr - 0.5) < 0.14:
				c = MAGMA[2]
			elif d > edge - 1.0:
				c = MAGMA[0] if lead < 0.2 else MAGMA[2]
			else:
				c = MAGMA[1] if cr > 0.5 else MAGMA[0]
			vfx._put(buf, cx + ox, cy + oy, c)

## Projectile bodies (sandbox drawBody): shaded shape in the native palette,
## oriented to motion, dark outer outline so the hitbox reads over its own tail,
## edge in the accent colour when a keyword element is present.
func draw_bodies(buf: PackedByteArray) -> void:
	var K: float = vfx.K
	for st in _parts.values():
		if st.kind == "wave":
			var wp = st.part.get_ref()
			if wp != null and is_instance_valid(wp) and not wp.done:
				_draw_wave_rim(buf, wp)
			continue
		if st.kind == "charge" or st.kind == "zone":
			var zp = st.part.get_ref()
			if zp != null and is_instance_valid(zp) and not zp.done:
				var zc: Vector2 = zp.global_position / WPS
				if st.kind == "charge":
					_draw_charge(buf, zc, st)
				else:
					_draw_zone(buf, zc, float(zp.geo("radius", 100.0)) / WPS)
			continue
		if st.kind == "nova" and NOVA_RIM.has(st.look.native):
			var np = st.part.get_ref()
			if np != null and is_instance_valid(np) and not np.done:
				var c: Vector2 = np.global_position / WPS
				vfx.elements.draw_nova(buf, c.x, c.y, float(np.front) / WPS, NOVA_RIM[st.look.native])
			continue
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
		if st.look.native == "lightning":
			_draw_lightning_body(buf, pos, dir, st.family, sc, st)
			continue
		if st.look.native == "life":
			vfx.elements.body(buf, pos, dir, LIFE_BODY[st.family], BODY.life, RIM[st.look.accent] if st.look.accent != "" else null, true, sc)
			continue
		if st.look.native == "water":
			if st.family == "spear":
				vfx.elements.body(buf, pos, dir, {"t": "diamond", "a": 8.0, "b": 1.4}, BODY.water, null, false, sc)
			continue       # drop body is goo: accumulate_water
		if st.look.native == "ice":
			var ib: Dictionary = ICE_BODY[st.family]
			var rim_c = RIM[st.look.accent] if st.look.accent != "" else null
			vfx.elements.body(buf, pos, dir, ib, BODY.ice, rim_c, true, sc)
			# glint: one core pixel blinks near the tail every few frames
			if (vfx._steps >> 1) % 6 == 0:
				vfx._put(buf, roundi((pos.x - dir.x) * K), roundi((pos.y - 1.0) * K), BODY.ice[0])
			continue
		if st.look.native == "fire":
			# No shape: the flame knot is the body. A small white-hot core keeps the
			# hitbox readable over its own tail (white only for the hottest point).
			var fbd: Dictionary = FIRE_BODY[st.family]
			if fbd.has("magma"):
				_draw_magma(buf, pos, dir, float(fbd.magma) * sc, part.get_instance_id())
				continue
			var cc: int = fbd.core
			var ccx := roundi(pos.x * K + dir.x * K * 0.5)
			var ccy := roundi(pos.y * K + dir.y * K * 0.5)
			for oy in range(-cc, cc):
				for ox in range(-cc, cc):
					if cc > 1 and absi(ox * 2 + 1) + absi(oy * 2 + 1) > cc * 3:
						continue
					vfx._put(buf, ccx + ox, ccy + oy, pal[0])
			continue
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
