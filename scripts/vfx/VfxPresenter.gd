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
const NATIVE_LOOK := {"": "arcane", "arcane": "arcane", "fire": "fire", "water": "water", "storm": "lightning", "life": "life", "plague": "plague", "earth": "earth"}
const ACCENT_LOOK := {"fire": "fire", "water": "water", "storm": "lightning", "life": "life", "plague": "plague", "earth": "earth"}
# The engine has one "water" element for water and ice spells (plan section 7:
# Water/Ice spells pick Water or Ice). Cold statuses or a vfx.look hint pick Ice.
const COLD := ["chilled", "frozen"]
const BUILT := ["arcane", "fire", "ice", "lightning", "water", "life", "plague", "earth"]
const ICE := preload("res://scripts/vfx/VfxElements.gd").ICE
const LIT := preload("res://scripts/vfx/VfxElements.gd").LIGHTNING
const WAT := preload("res://scripts/vfx/VfxElements.gd").WATER
const LIFE := preload("res://scripts/vfx/VfxElements.gd").LIFE
const ARC := preload("res://scripts/vfx/VfxElements.gd").ARCANE
const PLG := preload("res://scripts/vfx/VfxElements.gd").PLAGUE
const EAR := preload("res://scripts/vfx/VfxElements.gd").EARTH

# Body palettes (sandbox MAT.*.body): core, light, mid, dark, outline.
const BODY := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#c2361a"), Color("#4a1610")],
	"arcane": [Color("#ffffff"), Color("#c9f4ff"), Color("#8fb6f5"), Color("#6a4ad0"), Color("#1c1650")],
	"ice": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8"), Color("#1a2e5a")],
	"lightning": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff"), Color("#7a5cf0"), Color("#2a1f5e")],
	"water": [Color("#ffffff"), Color("#a6e6ff"), Color("#3f9fe4"), Color("#2063b0"), Color("#0f1d3a")],
	"life": [Color("#f0ffc0"), Color("#c8f07a"), Color("#7fcf4a"), Color("#3e8f3a"), Color("#1e2e16")],
	"plague": [Color("#e4fbb0"), Color("#a6e45e"), Color("#56b23e"), Color("#2c6e3a"), Color("#1b1a2c")],
	"earth": [Color("#e8dcc0"), Color("#c9b48c"), Color("#9a7d5a"), Color("#5e4630"), Color("#2a1e16")],
}
const SPARK := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#e0401c")],
	"arcane": [Color("#ffffff"), Color("#bdf3ff"), Color("#a98af5"), Color("#6a4ad0")],
	"ice": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8")],
	"lightning": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff"), Color("#7a5cf0")],
	"water": [Color("#ffffff"), Color("#cdeffd"), Color("#7cc4f2"), Color("#3f9fe4")],
	"life": [Color("#d4f58a"), Color("#86d24c"), Color("#46963c"), Color("#275c2e")],
	"plague": [Color("#e4fbb0"), Color("#a6e45e"), Color("#56b23e"), Color("#2c6e3a")],
	"earth": [Color("#c9b48c"), Color("#9a7d5a"), Color("#7a6a58"), Color("#5e4630")],
}
const RIM := {"fire": Color("#ff8a1f"), "arcane": Color("#8fb6f5"), "ice": Color("#d6f6ff"), "lightning": Color("#8fb2ff"), "water": Color("#4fb2f0"), "life": Color("#7fcf4a"), "plague": Color("#6fd04a"), "earth": Color("#c9a46a")}
const NOVA_RIM := {"ice": [Color("#8fd3ee"), Color("#ffffff")], "lightning": [Color("#8fb2ff"), Color("#ffffff")], "water": [Color("#4fb2f0"), Color("#e8f8ff")], "life": [Color("#7fcf4a"), Color("#d4f58a")], "arcane": [Color("#8fa8f5"), Color("#e2f6ff")],
	"plague": [Color("#6fd04a"), Color("#c4f383")], "earth": [Color("#c9a46a"), Color("#e8dcc0")]}
# Slash smear colours (sandbox smearCols): core, light, mid.
const SMEAR := {
	"fire": [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f")], "arcane": [Color("#ffffff"), Color("#c9f4ff"), Color("#8fb6f5")],
	"ice": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee")], "lightning": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff")],
	"water": [Color("#ffffff"), Color("#a6e6ff"), Color("#3f9fe4")], "life": [Color("#f0ffc0"), Color("#c8f07a"), Color("#7fcf4a")],
	"plague": [Color("#e4fbb0"), Color("#a6e45e"), Color("#56b23e")], "earth": [Color("#e8dcc0"), Color("#c9b48c"), Color("#9a7d5a")],
}
const EARTH_BODY := {"sphere": {"t": "orb", "r": 3.4}, "shard": {"t": "diamond", "a": 6.0, "b": 1.4}, "dart": {"t": "diamond", "a": 3.0, "b": 1.2}, "orbiter": {"t": "diamond", "a": 3.5, "b": 2.2}, "bolt": {"t": "orb", "r": 3.2}, "spear": {"t": "diamond", "a": 8.0, "b": 2.0}, "ball": {"t": "orb", "r": 4.6}}
# Rigid looks keep a drawn body (that IS the technique: crystal sprites).
const LIFE_BODY := {"sphere": {"t": "orb", "r": 3.4}, "shard": {"t": "diamond", "a": 6.0, "b": 1.4}, "dart": {"t": "diamond", "a": 3.0, "b": 1.2}, "orbiter": {"t": "diamond", "a": 3.5, "b": 2.0}, "bolt": {"t": "diamond", "a": 5.0, "b": 2.0}, "spear": {"t": "diamond", "a": 8.0, "b": 1.4}, "ball": {"t": "orb", "r": 3.5}}
const ICE_BODY := {"sphere": {"t": "diamond", "a": 4.0, "b": 3.4}, "shard": {"t": "diamond", "a": 7.0, "b": 1.3}, "dart": {"t": "diamond", "a": 3.0, "b": 1.2}, "orbiter": {"t": "diamond", "a": 3.5, "b": 2.0}, "bolt": {"t": "diamond", "a": 4.5, "b": 2.0}, "spear": {"t": "diamond", "a": 8.0, "b": 1.6}, "ball": {"t": "diamond", "a": 5.0, "b": 3.2}}
const INK := Color("#120e14")
# Magma core (fireball): dark crust, glowing cracks, hot seams. Hue-shifted
# toward red in the dark end, white kept out (white is for impacts).
const MAGMA := [Color("#2a0f0c"), Color("#4a1a12"), Color("#c2361a"), Color("#ff8a1f"), Color("#ffd54a")]

# Sandbox projectile presets (SPELLS.bolt / spear / fireball / fiery), sandbox units.
const FAMILY := {
	# Arcane Orbit: a big glowing sphere with a soft sparkle wake (not a bolt).
	"sphere": {"body": {"t": "orb", "r": 3.4}, "trail": {"rate": 2.5, "per_dist": 0.4, "heat": 0.9, "spread": 1.6, "grip": 0.2, "inh": 0.2, "ember": 0.25}, "impact": 0.5},
	# Magic Missile: a thin force dart, quick sparkle trail (not the Bolt's fat diamond).
	"dart": {"body": {"t": "diamond", "a": 3.2, "b": 1.0}, "trail": {"rate": 1.2, "per_dist": 0.6, "heat": 0.9, "spread": 0.3, "grip": 0.1, "inh": 0.3, "ember": 0.05}, "impact": 0.35},
	# Ice Blast: a long thin ice shard.
	"shard": {"body": {"t": "diamond", "a": 7.0, "b": 1.3}, "trail": {"rate": 1.5, "per_dist": 0.5, "heat": 0.8, "spread": 0.4, "grip": 0.1, "inh": 0.3, "ember": 0.05}, "impact": 0.4},
	"bolt": {"body": {"t": "diamond", "a": 4.0, "b": 2.0}, "trail": {"rate": 2.0, "per_dist": 0.5, "heat": 1.0, "spread": 0.8, "grip": 0.15, "inh": 0.25, "ember": 0.15}, "impact": 0.55},
	"spear": {"body": {"t": "diamond", "a": 8.0, "b": 1.4}, "trail": {"rate": 3.0, "per_dist": 0.8, "heat": 1.1, "spread": 0.8, "grip": 0.2, "inh": 0.35, "ember": 0.3}, "impact": 0.35},
	"orbiter": {"body": {"t": "diamond", "a": 3.5, "b": 2.0}, "trail": {"rate": 1.5, "per_dist": 0.3, "heat": 0.9, "spread": 0.6, "grip": 0.15, "inh": 0.2, "ember": 0.15}, "impact": 0.4},
	"ball": {"body": {"t": "orb", "r": 3.5}, "trail": {"rate": 6.0, "per_dist": 1.1, "heat": 1.0, "spread": 3.0, "grip": 0.35, "inh": 0.3, "ember": 0.35}, "impact": 1.4},
	"blade": {"body": {"t": "orb", "r": 2.0}, "trail": {"rate": 1.0, "per_dist": 0.2, "heat": 0.6, "spread": 0.6, "grip": 0.1, "inh": 0.2, "ember": 0.1}, "impact": 0.5},
	"ghost": {"body": {"t": "orb", "r": 2.0}, "trail": {"rate": 1.0, "per_dist": 0.2, "heat": 0.6, "spread": 0.6, "grip": 0.1, "inh": 0.2, "ember": 0.1}, "impact": 0.4},
}
# Fire-native projectiles have no drawn shape: the body is a knot of hot,
# high-grip flames riding the projectile plus a tiny white core. "r" = knot
# radius (su), "n" = flames per 60 fps frame, "len" stretches the knot along
# the motion (spears), "core" = white core half-size in cells.
const FIRE_BODY := {
	"sphere": {"r": 2.4, "n": 3.0, "len": 1.0, "heat": 0.6, "core": 2},
	"dart": {"r": 1.0, "n": 1.0, "len": 1.4, "heat": 0.4, "core": 1},
	"shard": {"r": 1.0, "n": 1.0, "len": 1.8, "heat": 0.4, "core": 1},
	"bolt": {"r": 1.3, "n": 1.5, "len": 1.6, "heat": 0.45, "core": 1},
	"orbiter": {"r": 1.2, "n": 1.5, "len": 1.4, "heat": 0.45, "core": 1},
	"spear": {"r": 0.7, "n": 2.0, "len": 5.0, "heat": 0.45, "core": 1},
	"ball": {"r": 3.6, "n": 5.0, "len": 1.0, "heat": 0.4, "core": 0, "magma": 3.2},
}
# Keyword-accent trail (sandbox "Fiery Bolt"): light flames under the native body.
const ACCENT_TRAIL := {"rate": 1.0, "per_dist": 0.25, "heat": 0.65, "spread": 0.6, "grip": 0.1, "inh": 0.2, "ember": 0.3, "small": 1.0}

const METEOR_WARN := [Color("#8a3a1a"), Color("#e8603a")]
const METEOR_WARN_HOT := [Color("#ff9a3a"), Color("#fff1b0")]

const RAINBOW := [Color("#ff5a5a"), Color("#ffb03a"), Color("#ffe85a"), Color("#6ee07a"), Color("#5ac8ff"), Color("#9a7aff")]


const BLADE_COL := [Color("#ffffff"), Color("#e8eef6"), Color("#a9b4c2"), Color("#5c6675")]

const MAX_BURNING := 24          # burning enemies drawn at once (nearest the camera)

var vfx                          # the Vfx autoload
var _missile_ribbons: Array = []
var _orbit_visuals: Array = []
var _parts := {}                 # instance id -> state
var _presented := {}             # instance id -> weakref: parts we draw, kept until freed so
                                 # finished parts (e.g. a blast's 0.12 s tail) never flash placeholder art
var enabled := true              # console "vfx present off" shows the placeholders
var _props := {}                 # instance id -> {node: WeakRef, kind}: spell objects the engine does not own
var _shield_fractures: Array = []

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
	# a rejected element word changes nothing in play, so it must not show either
	var rejected := {}
	var words: Dictionary = preload("res://scripts/engine/KeywordParser.gd").data().get("words", {})
	for r in plan.get("rejected", []):
		var w = words.get(str(r.get("word", "")), {})
		if str(w.get("category", "")) == "element":
			rejected[str(w.get("element", ""))] = true
	for e in plan.get("elements", []):
		if rejected.has(str(e.get("element", ""))):
			continue
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
	var motion: Array = part.def.get("motion", [])
	if not motion.is_empty() and str(motion[0].get("type", "")) == "orbit" and str(motion[0].get("until", "")) == "":
		return "orbiter"
	var pierce = int(part.def.get("limits", {}).get("pierce", 0))
	if pierce != 0:
		return "spear"
	return "ball" if float(part.geo("radius", 12.0)) >= 16.0 else "bolt"

static func _kind(part) -> String:
	match part.delivery:
		"beam":
			return "beam"
		"infection":
			return "infection"
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
			if part.geo_type() == "cone" and part._propagation() == "instant":
				return "slash"
			if part.geo_type() == "cone" and part._propagation() == "expanding":
				return "eruption"
		"trap":
			if part.geo_type() == "disk":
				return "trap"
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

## Delayed / charged casts (plan 5.2): energy gathers at the staff and a ring
## grows until the cast releases. Also remembers where the caster stood, for blinking.
var _charges: Array = []      # {caster (weakref), age, dur, key, big}
var _queued_from := {}        # cast instance id -> caster position (su) when queued

func cast_queued(cast) -> void:
	if not enabled or cast == null or not is_instance_valid(cast.caster):
		return
	_queued_from[cast.get_instance_id()] = cast.caster.global_position / WPS
	var look = look_of(cast.plan)
	if look.native == "" or cast.pending.is_empty():
		return
	var first: float = float(cast.pending[0].at)
	if first > 0.05:
		var key: String = look.accent if look.accent != "" else look.native
		var hostile := str(cast.get("target_group")) == "player"
		var hp: Array = hostile_cols(cast.plan) if hostile else []
		# A monster's charge glows in its hostile colour, like its telegraph.
		_charges.append({"caster": weakref(cast.caster), "age": 0.0, "dur": first, "key": key,
			"big": cast.plan.get("flags", {}).has("charged") or hostile,
			"pal": [Color.WHITE, hp[0], hp[1]] if hostile else SPARK[key]})

func cast_started(cast) -> void:
	if not enabled or cast == null or not is_instance_valid(cast.caster):
		return
	var look = look_of(cast.plan)
	if look.native == "":
		return
	var key: String = look.accent if look.accent != "" else look.native
	var flags: Dictionary = cast.plan.get("flags", {})
	var from = _queued_from.get(cast.get_instance_id())
	_queued_from.erase(cast.get_instance_id())
	if flags.has("blinking") and from != null:
		_blink_fx(from, cast.caster.global_position / WPS, key)
	if flags.has("sanguine"):
		_blood_fx(cast.caster.global_position / WPS + Vector2(0.0, -5.0))
	# Cast flash at the staff (2-4 steps), principle 7: anticipation before release.
	var at := _staff_su(cast.caster)
	if str(cast.plan.get("id", "")) == "mana_bolt" and str(cast.get("target_group")) != "player":
		vfx.flash(at.x, at.y, 0.7, 0.04, Color("#d9ccff"))
		return
	vfx.star(at.x, at.y, 3.2, 0.1, 4, BODY[key][0])
	vfx.flash(at.x, at.y, 1.4, 0.07, BODY[key][1])
	for i in 6:
		var ang := randf() * TAU
		vfx.spark(at.x, at.y, cos(ang) * 28.0, sin(ang) * 22.0 - 8.0, 0.25 + randf() * 0.15, SPARK[key])

func part_spawned(part) -> void:
	if not enabled:
		return
	if str(part.cast.plan.get("id", "")) == "lightning" and part.part_name == "mark" and not is_hostile(part):
		var visual = preload("res://scripts/vfx/LightningWarningVisual.gd").new()
		visual.setup(part, vfx)
		vfx.add_child(visual)
		_presented[part.get_instance_id()] = weakref(part)
		return
	var vfam0 := str(part.def.get("vfx", {}).get("family", ""))
	if vfam0 == "none":
		var aura = preload("res://scripts/vfx/RegenerationAura.gd").new()
		aura.part_ref = weakref(part)
		aura.visual_size = clampf(float(part.def.get("visual_size", 1.0)), 0.6, 2.0)
		vfx.add_child(aura)
		aura.global_position = part.cast.caster.global_position
		_presented[part.get_instance_id()] = weakref(part)
		return
	if bool(part.def.get("vfx", {}).get("warn", false)):
		# The telegraph before a landing: the true area as a bright ring, an inner ring closing on it.
		_parts[part.get_instance_id()] = {"part": weakref(part), "kind": "warn", "look": look_of(part.cast.plan), "last": part.global_position / WPS,
			"acc": 0.0, "age": 0.0, "life": maxf(0.05, float(part.total_life())), "r": float(part.geo("radius", 60.0)) / WPS}
		if str(part.cast.plan.get("id", "")) in ["rune_trap", "frost_sigil"] and not is_hostile(part):
			_parts[part.get_instance_id()].life = maxf(0.01, float(part.def.get("propagation", {}).get("linger", 0.4)))
		_presented[part.get_instance_id()] = weakref(part)
		return
	if vfam0 == "ray":
		var pos: Vector2 = part.global_position / WPS
		# Prism Ray's refraction: a brief coloured laser fanning out behind the target (doc 21 §5.6).
		var key2 := str(part.def.vfx.get("look", "arcane"))
		var cols: Array = BODY.get(key2, BODY.arcane)
		var dir2: Vector2 = Vector2(part.direction).normalized()
		var length_su: float = part.geo("length", 250.0) / WPS
		# A real laser: a thick band in the element's colours that holds a moment and thins out.
		var hw_su: float = maxf(1.5, part.geo("width", 28.0) * 0.5 / WPS)
		var prism := str(part.cast.plan.get("id", "")) == "prism_ray"
		_lasers.append([pos, dir2, length_su, hw_su, 0.0, 0.32, cols, key2, prism])
		if prism and part.part_name == "ray_fire":
			vfx.star(pos.x, pos.y, 2.5, 0.12, 4, Color("#ecdeff"))
		_ray_flavour(key2, pos, dir2, length_su, hw_su, prism)
		var tip: Vector2 = pos + dir2 * length_su
		vfx.flash(tip.x, tip.y, 1.5, 0.06, cols[1])
		for i in 3:
			vfx.spark(tip.x, tip.y, dir2.x * 20.0 + (randf() - 0.5) * 20.0, dir2.y * 20.0 + (randf() - 0.5) * 20.0, 0.2, [cols[0], cols[1], cols[2]])
		_presented[part.get_instance_id()] = weakref(part)
		return
	var look = look_of(part.cast.plan)
	var kind := _kind(part)
	if look.native == "" or kind == "":
		return
	var pos: Vector2 = part.global_position / WPS
	var st := {"part": weakref(part), "kind": kind, "look": look, "last": pos, "acc": 0.0}
	var vfam := str(part.def.get("vfx", {}).get("family", ""))
	if vfam == "emitter":
		return   # an invisible emitter (Fire Walk): its patches carry the look
	if vfam == "firewalk":
		# Fire Walk patch: low flames and embers while it burns, char on the ground.
		st.kind = "patch"
		st.r = float(part.geo("radius", 25.0)) / WPS
		st.ground = preload("res://scripts/vfx/FirewalkVisual.gd").new()
		part.add_child(st.ground)
		st.ground.setup(part)
		_parts[part.get_instance_id()] = st
		_presented[part.get_instance_id()] = weakref(part)
		return
	if vfam == "meteor":
		# A meteor mark: the rock falls from the sky onto the true radius, landing with the real impact.
		st.kind = "meteor"
		st.age = 0.0
		st.life = float(part.total_life())
		st.r = float(part.geo("radius", 60.0)) / WPS
		st.sky = Vector2(-16.0, -72.0) * clampf(st.r / 8.0, 0.8, 1.6)
		_parts[part.get_instance_id()] = st
		_presented[part.get_instance_id()] = weakref(part)
		return
	if kind == "infection":
		st.infection_wakes = {}
		st.infection_pulses = {}
		st.infection_hosts = {}
		var infection_visual = preload("res://scripts/vfx/InfectionVisual.gd").new()
		infection_visual.setup(part, st, vfx)
		vfx.add_child(infection_visual)
		st.infection_visual = infection_visual
	match kind:
		"projectile":
			st.family = family_of(part)
			if st.family == "ghost":
				var spirit = preload("res://scripts/vfx/SpiritVisual.gd").new()
				part.add_child(spirit)
				st.spirit = spirit
		"burst":
			var r_su: float = part.geo("radius", 90.0) / WPS
			# the accent owns the impact (plan 5.1); an arcane base adds its glyph flourish
			var pw := _power(part)
			if str(part.cast.plan.get("id", "")) == "frost_sigil" and not is_hostile(part):
				_frost_trap_burst(part, pos, r_su)
				if look.accent != "" and look.accent not in ["ice", "water"]:
					_burst(look.accent, pos, r_su * 0.4, pw)
				_force_fx(part.cast.plan, pos, look.accent if look.accent != "" else "ice")
				_parts[part.get_instance_id()] = st
				_presented[part.get_instance_id()] = weakref(part)
				return
			_burst(look.accent if look.accent != "" else look.native, pos, r_su, pw)
			if look.accent != "" and look.native == "arcane":
				_arcane_impact(pos.x, pos.y, 0.5)
			elif look.accent != "":
				_burst(look.native, pos, r_su * 0.45, 1.0)      # the native keeps a small say in the impact
				_react(look.native, look.accent, pos, clampf(r_su / 11.0, 0.6, 2.5))
			_force_fx(part.cast.plan, pos, look.accent if look.accent != "" else look.native)
			var heavy := float(part.def.get("vfx", {}).get("heavy", 0.0))
			if heavy > 0.0:
				_heavy_landing(pos, r_su, look.native, heavy, _area_cols(part))
		"slash":
			_slash(part, look, pos)
		"trap":
			st.k = randi() % 4
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
			if look.native == "earth":
				vfx.shake(0.4)
				vfx.crack_decal(pos.x, pos.y, 8, float(part.geo("radius", 100.0)) / WPS * 0.6)
		"wave":
			if look.native != "water":
				return
			st.acc = 0.0
		"self":
			pass
		"charge", "zone":
			if look.native != "lightning":
				return
			st.off = (randf() - 0.5) * 12.0
			st.age = 0.0
			st.life = float(part.def.get("timing", {}).get("duration", 0.45))
		"field":
			if look.native in ["ice", "lightning", "water", "life", "arcane", "plague", "earth"]:
				var r_su2: float = part.geo("radius", 60.0) / WPS
				if part.geo_type() != "disk":
					return
				var life2 := float(part.def.get("timing", {}).get("duration", 3.0))
				if part.def.get("timing", {}).get("duration") == null:
					life2 = 4.0
				st.field = vfx.field(pos.x, pos.y, r_su2, life2 + 0.5, {"look": vfx.field_look(look.native), "goo": {"water": 1, "plague": 2}.get(look.native, 0)})
				st.field.part = weakref(part)
				if look.native == "life":
					_life_field_start(st.field)
				elif look.native == "earth":
					_earth_field_start(st.field)
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
				var line_o := {"axis": axis / WPS}
				if str(part.def.get("vfx", {}).get("style", "")) == "smoulder":
					# A burning trail, not a wall: sparse low flames and embers along the line.
					line_o.rate = 0.1
					line_o.heat_k = 0.5
					line_o.style = 2
				st.field = vfx.field(pos.x, pos.y, hw / WPS, life + 0.5, line_o)
			elif str(part.def.get("vfx", {}).get("style", "")) == "steam":
				# Steam Field: connected rolling vapor above the active area.
				var sr: float = part.geo("radius", 60.0) / WPS
				st.field = {"x": pos.x, "y": pos.y, "r": sr, "age": 0.0, "life": life + 0.5}
				st.steam = true
				st.cloud = preload("res://scripts/vfx/SteamCloud.gd").new()
				st.cloud.setup(sr * WPS, life, vfx.reduced_effects)
				vfx.add_child(st.cloud)
				st.cloud.global_position = part.global_position + Vector2(0, -sr * WPS * 0.25)
			elif str(part.def.get("vfx", {}).get("style", "")) == "rubble":
				# Meteor crater: cracked, charred ground with low fire, rocks kicked up while it burns.
				var cr: float = part.geo("radius", 60.0) / WPS
				st.field = vfx.field(pos.x, pos.y, cr, life + 0.5, {"rate": 0.35, "heat_k": 0.6, "style": 2})
				st.rubble = true
				vfx.crack_decal(pos.x, pos.y, 7, cr * 0.9, life + 1.0)
				vfx.scorch(pos.x, pos.y, cr * 0.8, life + 1.0)
			else:
				st.field = vfx.field(pos.x, pos.y, part.geo("radius", 60.0) / WPS, life + 0.5, {"profile": "cinder" if str(part.cast.plan.get("id", "")) == "cinder_field" else "default"})
	if st.has("field") and not st.get("steam", false):
		st.field.part = weakref(part)
	_parts[part.get_instance_id()] = st
	_presented[part.get_instance_id()] = weakref(part)

var _prism_contact_frame := -1
var _prism_contacts := {}

func part_hit(part, enemy, at: Vector2) -> void:
	if str(part.cast.plan.get("id", "")) == "focus_ray" and str(part.def.get("delivery", "")) == "beam" and not is_hostile(part):
		var state = _parts.get(part.get_instance_id())
		if state != null and state.kind == "beam":
			var terminal: Vector2 = (part.global_position + Vector2(part.beam_end)) / WPS
			var palette: Array = SPARK.get(state.look.native, SPARK.arcane)
			vfx.star(terminal.x, terminal.y, 1.5, 0.07, 4, palette[0])
			for side in [-1.0, 1.0]:
				var velocity := Vector2(part.beam_end).normalized().rotated(side * 0.9) * 18.0
				vfx.spark(terminal.x, terminal.y, velocity.x, velocity.y, 0.14, palette)
		return
	if str(part.cast.plan.get("id", "")) == "prism_ray" and str(part.def.get("vfx", {}).get("family", "")) == "ray" and is_instance_valid(enemy):
		var frame := Engine.get_physics_frames()
		if frame != _prism_contact_frame:
			_prism_contacts.clear()
			_prism_contact_frame = frame
		var target: int = enemy.get_instance_id()
		if not _prism_contacts.has(target):
			_prism_contacts[target] = true
			var palette: Array = BODY.get(str(part.def.vfx.get("look", "arcane")), BODY.arcane)
			vfx.star(at.x / WPS, at.y / WPS, 1.6, 0.07, 4, palette[1])
		return
	var st = _parts.get(part.get_instance_id())
	if st != null and st.kind == "infection":
		if not st.has("infection_pulses"):
			st.infection_pulses = {}
		if is_instance_valid(enemy):
			st.infection_pulses[enemy.get_instance_id()] = 0.18
		return
	if st == null or st.kind != "projectile":
		return
	_part_hit_look(part, enemy, at)
	var p: Vector2 = part.global_position / WPS
	if not _is_arcane_orbit(part) and not ((_is_ice_blast(part) or _is_magic_missile(part)) and st.look.accent == ""):
		_contact_punch(part, st, p)
	var light_strength := float(part.def.get("vfx", {}).get("impact_light", 0.0))
	if light_strength > 0.0 and not is_hostile(part):
		var light_key: String = st.look.accent if st.look.accent != "" else st.look.native
		vfx.impact_light.emit(at, clampf(float(part.geo("radius", 12.0)) * 4.0, 32.0, 80.0), RIM.get(light_key, Color.WHITE), light_strength)
	_force_fx(part.cast.plan, p, st.look.accent if st.look.accent != "" else st.look.native)
	if st.look.accent != "" and st.look.native != "arcane":
		_react(st.look.native, st.look.accent, p, 0.6)

func _part_hit_look(part, _enemy, at: Vector2) -> void:
	var st = _parts.get(part.get_instance_id())
	var p: Vector2 = part.global_position / WPS
	var impact_look: String = st.look.accent if st.look.accent != "" else st.look.native
	if _is_arcane_orbit(part):
		if st.has("orbit_visual"):
			st.orbit_visual.pulse()
		if impact_look == "arcane":
			var direction: Vector2 = st.orbit_visual.direction if st.has("orbit_visual") else Vector2(part.direction).normalized()
			var tip := p + direction * float(part.geo("radius", 42.0)) / WPS * 0.85
			vfx.star(tip.x, tip.y, 1.8 * float(part.size_scale), 0.065, 4, Color("#f1eaff"))
			for side in [-1.0, 1.0]:
				var velocity := direction.rotated(side * 0.6) * 24.0
				vfx.spark(tip.x, tip.y, velocity.x, velocity.y, 0.18, SPARK.arcane)
			return
	if _is_magic_missile(part) and impact_look == "arcane":
		var tip := _missile_position(part) + Vector2(part.direction).normalized() * 2.9 * float(part.size_scale)
		vfx.star(tip.x, tip.y, 1.6, 0.055, 4, Color("#fff4ff"))
		for i in 2:
			var velocity := Vector2(part.direction).rotated((float(i) - 0.5) * 1.1) * (18.0 + i * 4.0)
			vfx.spark(tip.x, tip.y, velocity.x, velocity.y, 0.18 + i * 0.02, [Color("#c8adff"), Color("#a18ae4"), Color("#668de4")])
		return
	if _is_ice_blast(part) and impact_look == "ice":
		_ice_blast_contact(part, at / WPS)
		return
	if st.family == "blade" and st.look.accent == "":
		var hit := at / WPS
		var returning: bool = int(part.phase) >= 2
		var direction := Vector2(part.direction).normalized().rotated(-0.65)
		for sign_value in [-1.0, 1.0]:
			var velocity: Vector2 = direction * sign_value * (38.0 if returning else 25.0)
			vfx.spark(hit.x, hit.y, velocity.x, velocity.y, 0.13 if returning else 0.10, [Color("#f1ffff"), Color("#a5d6e8"), Color("#627c9a")])
		vfx.star(hit.x, hit.y, 2.4 if returning else 1.7, 0.065, 4, Color("#e0f7ff"))
		return
	var spawns_burst := false
	for key in part.def.get("events", {}):
		if str(key).begins_with("on_hit"):
			spawns_burst = true
	if impact_look == "lightning":
		_zap(p.x, p.y)
		return
	if st.family == "ghost":
		vfx.ring(p.x, p.y, 3.5, 0.16, [Color("#ffffff"), Color("#c8dcec"), Color("#93a8c0")])
		if is_instance_valid(st.get("spirit")):
			st.spirit.pulse()
		return
	var many: bool = st.family in ["blade", "shard"]   # many hits a cast: keep each one small (playtest)
	if impact_look == "earth" and many:
		_earth_contact(p.x, p.y)
		return
	if impact_look == "ice" and many:
		_ice_impact(p.x, p.y, 0.22)   # thirteen shards a cast: each hit a small chip (playtest: too noisy)
		return
	if impact_look == "plague" or impact_look == "earth":
		if st.family == "spear" or st.look.native != impact_look:
			if impact_look == "plague":
				_plague_contact(p.x, p.y)
			else:
				_earth_contact(p.x, p.y)
		elif not spawns_burst:
			_burst(impact_look, p, 11.0)
		return
	if impact_look == "life" and str(part.cast.plan.get("id", "")) == "life_bolt":
		_life_bolt_contact(p, Vector2(part.direction))
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
	if is_instance_valid(st.get("ground")):
		st.ground.hide()
		st.ground.queue_free()
	if st.has("orbit_visual"):
		st.orbit_visual.finished = true
		if natural:
			var end: Vector2 = part.global_position / WPS
			var key: String = st.look.accent if st.look.accent != "" else st.look.native
			for i in 4:
				var velocity: Vector2 = st.orbit_visual.direction.rotated((i - 1.5) * 0.18) * (16.0 + i * 4.0)
				vfx.spark(end.x, end.y, velocity.x, velocity.y, 0.18 + i * 0.04, SPARK[key])
			if key == "fire":
				vfx.puff(end.x, end.y - 1.0, 2)
		return
	if st.has("missile_ribbon"):
		st.missile_ribbon.finished = true
	if is_instance_valid(st.get("cloud")):
		st.cloud.finish()
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
			f.erase("part")
			f.life = f.age + 0.5

# ------------------------------------------------------------------ per step

func step(dt: float) -> void:
	for orbit in _orbit_visuals:
		orbit.advance(dt / maxf(vfx.fx_speed, 0.001))
	_orbit_visuals = _orbit_visuals.filter(func(orbit): return not orbit.finished or not orbit.samples.is_empty())
	for ribbon in _missile_ribbons:
		ribbon.advance(dt / maxf(vfx.fx_speed, 0.001))
	_missile_ribbons = _missile_ribbons.filter(func(ribbon): return not ribbon.finished or not ribbon.samples.is_empty())
	_advance_transients(dt / maxf(vfx.fx_speed, 0.001))
	for id in _presented.keys():
		if _presented[id].get_ref() == null:
			_presented.erase(id)
	for id in _parts.keys():
		var st: Dictionary = _parts[id]
		var part = st.part.get_ref()
		if part == null or not is_instance_valid(part):
			if st.has("orbit_visual"):
				st.orbit_visual.finished = true
			if st.has("missile_ribbon"):
				st.missile_ribbon.finished = true
			_parts.erase(id)
			continue
		var pos: Vector2 = part.global_position / WPS
		match st.kind:
			"projectile":
				_trail(part, st, pos, dt)
			"field":
				st.field.x = pos.x
				st.field.y = pos.y
				st.field.r = part.geo("width", 30.0) * 0.5 / WPS if part.geo_type() == "line" else part.geo("radius", 60.0) / WPS
				if is_instance_valid(st.get("cloud")):
					st.cloud.global_position = part.global_position + Vector2(0, -float(st.field.r) * WPS * 0.25)
				if part.geo_type() == "line":
					# Lines can grow (a spear's burning trail follows the spear): keep the axis on the hitbox.
					var hw: float = part.geo("width", 30.0) * 0.5
					st.field.axis = Vector2(part.direction).orthogonal().normalized() * maxf(0.0, part.geo("length", 200.0) * 0.5 - hw) / WPS
				if st.look.native == "ice":
					_ice_field(st.field, dt)
				elif st.look.native == "lightning":
					_lightning_field(st.field, dt)
				elif st.look.native == "water":
					_water_field(st.field, dt)
				elif st.look.native == "life":
					_life_field(st.field, dt)
				elif st.look.native == "arcane":
					_arcane_field(st.field, dt)
				elif st.look.native == "plague":
					_plague_field(st.field, dt)
				elif st.look.native == "earth":
					_earth_field(st.field, dt)
				if st.look.accent != "" and not st.get("steam", false):
					_accent_field(st.look.accent, st.field, dt)
					_steam_if(st.look, _in_disk(st.field.x, st.field.y, st.field.r), dt)
				_field_force(part.cast.plan, st.field, st.look.accent if st.look.accent != "" else st.look.native, dt)
				if st.get("rubble", false):
					_rubble(st.field, dt)

			"wave":
				_water_wave(part, st, dt)
			"meteor":
				_meteor_fall(part, st, pos, dt)
			"warn":
				st.age = float(st.age) + dt
			"patch":
				if not is_instance_valid(st.get("ground")):
					st.ground = preload("res://scripts/vfx/FirewalkVisual.gd").new()
					part.add_child(st.ground)
					st.ground.setup(part)
				var warmth := preload("res://scripts/vfx/FirewalkVisual.gd").heat(float(part.age), float(part.total_life()))
				if randf() < 0.12 * dt * 60.0 * warmth:
					var a := randf() * TAU
					var d := sqrt(randf()) * float(st.r) * 0.8
					var fp: Vector2 = pos + Vector2(cos(a), sin(a) * 0.7) * d
					# Flames rise on the air layer: none at the wizard's feet, so fire never covers
					# the wizard (playtest F41); embers and char still show there.
					var walker = part.cast.caster if part.cast != null else null
					if walker == null or not is_instance_valid(walker) or fp.distance_to(walker.global_position / WPS) > 7.0:
						# low ground fire: short tongues that stay under head height
						vfx.flame(null, fp, {"heat": 0.6, "rise": 4.0 + randf() * 4.0, "life": 0.25 + randf() * 0.25, "small": 1.0})
				if randf() < 0.02 * dt * 60.0 * warmth:
					vfx.ember(pos.x + (randf() - 0.5) * float(st.r), pos.y, (randf() - 0.5) * 8.0, -(14.0 + randf() * 10.0), 0.8 + randf())
			"beam":
				_beam_step(part, st, pos, dt)
			"infection":
				_infection_step(part, st, dt)
			"eruption":
				_eruption_step(part, st, pos, dt)
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
				elif st.look.native == "arcane":
					_arcane_nova(pos, float(part.front) / WPS, dt)
				elif st.look.native == "plague":
					_plague_nova(pos, float(part.front) / WPS, dt)
				elif st.look.native == "earth":
					_earth_nova(pos, float(part.front) / WPS, dt)
				elif st.look.native == "lightning":
					_lightning_nova(pos, float(part.front) / WPS, st.seed, dt)
				if st.look.accent != "":
					if st.look.accent == "fire" and str(part.cast.plan.get("id", "")) == "nova" and not is_hostile(part):
						_fire_nova(pos, float(part.front) / WPS, float(part.front) / maxf(1.0, float(part.geo("radius", 100.0))), dt * 0.5, true)
					else:
						_accent_nova(st.look.accent, pos, float(part.front) / WPS, float(part.front) / maxf(1.0, float(part.geo("radius", 100.0))), dt)
					var na := randf() * TAU
					_steam_if(st.look, pos + Vector2(cos(na), sin(na)) * float(part.front) / WPS, dt * 3.0)
		st.last = pos
	_step_props(dt)
	_step_charges(dt)
	_burning(dt)
	_chilled(dt)
	_shocked(dt)
	_entangled(dt)
	_vulnerable(dt)
	_poisoned(dt)
	_stunned(dt)

func _trail(part, st: Dictionary, pos: Vector2, dt: float) -> void:
	if st.family == "ghost":
		return
	if st.family == "blade":
		if randf() < 0.25 * dt * 60.0:
			var a := randf() * TAU
			vfx.spark(pos.x + cos(a) * 2.0, pos.y + sin(a) * 2.0, cos(a) * 25.0, sin(a) * 25.0, 0.2, BLADE_COL)
		return
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
		if _is_ice_blast(part):
			_ice_blast_trail(part, st, pos, dist)
		else:
			_ice_trail(pos, vel, dt, 0.3 if st.family == "shard" else 1.0)
	if native == "lightning" or accent == "lightning":
		_lightning_trail(st, pos, vel, dt)
	if native == "water" or accent == "water":
		_water_trail(st, pos, vel, dt, native == "water")
	if native == "life" or accent == "life":
		_life_trail(st, pos, vel, dt)
	if native == "plague" or accent == "plague":
		_plague_trail(pos, vel, dt)
	if native == "earth" or accent == "earth":
		_earth_trail(pos, vel, dt)
	if native == "arcane" and _is_arcane_orbit(part):
		if not st.has("orbit_visual"):
			st.orbit_visual = preload("res://scripts/vfx/ArcaneOrbitVisual.gd").new()
			st.orbit_visual.phase = float(part.get_instance_id() % 100) * 0.37
			_orbit_visuals.append(st.orbit_visual)
		st.orbit_visual.sample(pos, float(part.geo("radius", 42.0)) / WPS)
	elif native == "arcane" and _is_magic_missile(part):
		if not st.has("missile_ribbon"):
			st.missile_ribbon = preload("res://scripts/vfx/MissileRibbon.gd").new()
			_missile_ribbons.append(st.missile_ribbon)
		var shown := _missile_position(part)
		var direction := Vector2(part.direction).normalized()
		st.missile_ribbon.sample(shown - direction * 1.8 * float(part.size_scale), direction, float(part.size_scale))
	elif native == "arcane":
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
const STATUS_ALPHA := 0.55   # status marks on enemies are see-through, so spells read over them

## A palette made see-through for status marks.
static func _ghost(cols: Array, a: float = STATUS_ALPHA) -> Array:
	var out: Array = []
	for c in cols:
		out.append(Color(c, a))
	return out

const LANDING_SOUND := {"fire": "SPELL_IMPACT_FIRE", "lightning": "SPELL_IMPACT_LIGHTNING", "earth": "SPELL_IMPACT_EARTH",
	"water": "SPELL_IMPACT_ICE", "ice": "SPELL_IMPACT_ICE"}

## A spell that lands (Meteor Shower, Lightning, Rune Trap's blast, Meteor Spear's meteors,
## Lightning Bolt's strike) lands with weight: white flash, star, shockwave rings, rocks thrown up,
## a scorch, a VFX hit-pause, camera shake and an impact sound. `w` scales it (playtest: "no bam").
func _heavy_landing(p: Vector2, r: float, el: String, w: float, area: Array = []) -> void:
	var cols: Array = SPARK.get(el, SPARK.fire)
	vfx.flash(p.x, p.y, maxf(4.0, r * 0.7) * w, 0.09, Color.WHITE)
	vfx.star(p.x, p.y, maxf(4.0, r * 0.45) * w, 0.12, 8, cols[0])
	vfx.ring(p.x, p.y, r * 1.15, 0.32, cols)
	vfx.ring(p.x, p.y, r * 0.6, 0.2, [Color.WHITE, cols[1], cols[2]])
	for i in roundi(8 * w):
		var a := randf() * TAU
		var sp := 10.0 + randf() * 22.0
		vfx.chunk(p.x + cos(a) * r * 0.3, p.y + sin(a) * r * 0.2, cos(a) * sp, sin(a) * sp * 0.6, 30.0 + randf() * 40.0 * w, EAR.debris, 0.7 + randf() * 0.4, 1 + int(randf() < 0.3 * w))
	vfx.scorch(p.x, p.y, r * 0.6, 3.0)
	vfx.hitstop(roundi(2.0 + 2.0 * w))
	vfx.shake(0.6 + 0.4 * w)
	# The damage area itself: a red ring at the true radius that holds a beat, so you see what was hit.
	if area.is_empty():
		var one: Array = AREA_COL.get(el, AREA_COL.arcane)
		area = [one, one]
	_hit_rings.append([p.x, p.y, r, 0.0, 0.35, area])
	var snd: String = LANDING_SOUND.get(el, "SPELL_IMPACT_FIRE")
	var audio = vfx.get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sound(audio.SoundType.get(snd, audio.SoundType.SPELL_IMPACT_FIRE))

## Meteor crater: rocks and hot grit popping up out of the ground, smoke drifting off it.
func _rubble(f: Dictionary, dt: float) -> void:
	var r: float = float(f.r)
	if randf() < 0.35 * dt * 60.0:
		var q := _in_disk(float(f.x), float(f.y), r)
		vfx.chunk(q.x, q.y, (randf() - 0.5) * 10.0, (randf() - 0.5) * 6.0, 18.0 + randf() * 26.0, EAR.debris, 0.6 + randf() * 0.4, 1 + int(randf() < 0.25))
	if randf() < 0.2 * dt * 60.0:
		var q2 := _in_disk(float(f.x), float(f.y), r)
		vfx.ember(q2.x, q2.y, (randf() - 0.5) * 6.0, -(10.0 + randf() * 10.0), 0.6)
	if randf() < 0.06 * dt * 60.0:
		var q3 := _in_disk(float(f.x), float(f.y), r * 0.8)
		vfx.puff(q3.x, q3.y)

# Area circles take the spell's element colour, split in halves for a two-element spell; red is
# for enemies and fire only (playtest). [bright, mid] per damage type.
const AREA_COL := {"arcane": [Color("#e2d4ff"), Color("#9b7cf0")], "fire": [Color("#ffd54a"), Color("#ff6a1f")],
	"water": [Color("#e8f8ff"), Color("#6fc8f0")], "ice": [Color("#e8f8ff"), Color("#8fd3ee")], "storm": [Color("#ffffff"), Color("#8fb2ff")],
	"lightning": [Color("#ffffff"), Color("#8fb2ff")], "earth": [Color("#f0e2c0"), Color("#c9a46a")], "plague": [Color("#d8f8a0"), Color("#6fd04a")],
	"life": [Color("#e6ffb0"), Color("#7fcf4a")], "raw": [Color("#ffffff"), Color("#c8ccd4")]}

## A monster's spell (an elite's word spell): its telegraph is drawn in loud, saturated element
## colours, never the soft ones your own spells use, so a hostile area reads at a glance.
const HOSTILE_COL := {"fire": [Color("#fff27a"), Color("#ff3a12")], "water": [Color("#ffffff"), Color("#18d6ff")],
	"ice": [Color("#ffffff"), Color("#18d6ff")], "storm": [Color("#ffffff"), Color("#ffe11a")], "lightning": [Color("#ffffff"), Color("#ffe11a")],
	"earth": [Color("#ffe9b8"), Color("#ff9a2a")], "plague": [Color("#f0ff9a"), Color("#8cff2a")], "life": [Color("#f0ff9a"), Color("#8cff2a")],
	"arcane": [Color("#ffd6ff"), Color("#ff3ad8")]}

## Is this a monster's spell aimed at the player?
static func is_hostile(part) -> bool:
	return part != null and part.cast != null and str(part.cast.get("target_group")) == "player"

## A hostile spell's [bright, deep] pair: the elite word's own colour when it has one, else its element's.
func hostile_cols(plan: Dictionary) -> Array:
	var hc := str(plan.get("hostile_color", ""))
	if hc != "":
		var deep := Color(hc)
		return [deep.lerp(Color.WHITE, 0.6), deep]
	var native := str(look_of(plan).native)
	return HOSTILE_COL.get(native, HOSTILE_COL.get(str(plan.get("element", "")), HOSTILE_COL.arcane))

## The two colours an area of this spell is drawn in: its two biggest damage types (data/spell_damage.json),
## else its element and any keyword accent. Both the same for a one-element spell.
func _area_cols(part) -> Array:
	var plan: Dictionary = part.cast.plan if part != null and part.cast != null else {}
	if str(plan.get("id", "")) == "frost_sigil" and not is_hostile(part):
		var cold: Array = AREA_COL.ice
		var look := look_of(plan)
		var accent: Array = AREA_COL.get(look.accent, cold) if look.accent not in ["", "water", "ice"] else cold
		return [cold, accent]
	if is_hostile(part):
		var pair := hostile_cols(plan)
		return [pair, pair]
	var prof: Dictionary = preload("res://scripts/engine/SpellDamage.gd").profile(str(plan.get("id", "")), str(part.part_name) if part != null else "")
	var mix: Dictionary = prof.get("damage", {})
	var keys: Array = mix.keys().filter(func(k): return AREA_COL.has(str(k)) and str(k) != "raw" and float(mix[k]) > 0.0)
	keys.sort_custom(func(a, b): return float(mix[a]) > float(mix[b]))
	var look := look_of(plan)
	if keys.is_empty():
		keys = [look.native if look.native != "" else "arcane"]
	if keys.size() == 1 and look.accent != "" and AREA_COL.has(look.accent) and look.accent != keys[0]:
		keys.append(look.accent)
	var a: Array = AREA_COL.get(str(keys[0]), AREA_COL.arcane)
	var b: Array = AREA_COL.get(str(keys[1]), a) if keys.size() > 1 else a
	return [a, b]

## A dashed ring, left half in one element's colours and right half in the other's.
## `sweep` < 1 draws only that fraction of it, clockwise from the top (a ring being drawn).
func _split_ring(buf: PackedByteArray, c: Vector2, r: float, cols: Array, hot: bool, density: float = 1.2, sweep: float = 1.0) -> void:
	var el = vfx.elements
	var steps := ceili(TAU * r * density)
	var frame: int = vfx._steps
	for i in steps:
		if ((i + (frame >> 2)) & 3) == 0:
			continue
		if sweep < 1.0 and float(i) / steps > sweep:
			break
		var a := TAU * i / steps - (PI * 0.5 if sweep < 1.0 else 0.0)
		var pair: Array = cols[0] if cos(a) <= 0.0 else cols[1]
		el.spx(buf, roundi(c.x + cos(a) * r), roundi(c.y + sin(a) * r), pair[0] if hot or (i & 1) == 0 else pair[1])

## Every projectile hit lands with a punch scaled to the spell (playtest: "haptic feedback on all
## spells"): a white star at the contact, a frame of hit-pause, and a small shake for heavy bodies.
## Many-hit spells (blades, shards, missiles) get a lighter touch so a volley isn't noise.
func _contact_punch(part, st: Dictionary, p: Vector2) -> void:
	var fam := str(st.get("family", "bolt"))
	var light: bool = fam in ["blade", "shard", "dart", "orbiter", "ghost"]
	var sz: float = clampf(float(part.size_scale), 0.6, 2.5)
	vfx.star(p.x, p.y, (2.0 if light else 3.5) * sz, 0.05, 4, Color.WHITE)
	if light:
		return
	vfx.flash(p.x, p.y, 2.5 * sz, 0.05, Color.WHITE)
	vfx.hitstop(1 if fam == "bolt" else 2)
	if fam in ["ball", "spear"] or sz >= 1.4:
		vfx.shake(0.35)

## Prism Ray: each refracted ray carries its element along it, so the six read apart at a glance.
func _ray_flavour(look: String, a: Vector2, d: Vector2, L: float, hw: float, prism: bool = false) -> void:
	var el = vfx.elements
	var n := Vector2(-d.y, d.x)
	match look:
		"fire":
			for i in 5:
				var q: Vector2 = a + d * L * randf() + n * (randf() - 0.5) * hw * 2.0
				vfx.flame(null, q, {"heat": 1.2, "rise": 10.0 + randf() * 8.0, "life": 0.25 + randf() * 0.2, "small": 1.0})
		"ice":
			for i in 3:
				var q: Vector2 = a + d * L * randf() + n * (randf() - 0.5) * hw * 2.0
				el.flake(q.x, q.y, (randf() - 0.5) * 4.0, 2.0, 0.6, 1 if randf() < 0.4 else 0, 3.0)
		"lightning":
			var b: Vector2 = a + d * L
			el.arc(a.x, a.y, b.x, b.y, 3.0, 0.3, 0, true, true, false)
		"earth":
			for i in 3:
				var q: Vector2 = a + d * L * randf()
				vfx.chunk(q.x, q.y, n.x * (randf() - 0.5) * 30.0, n.y * (randf() - 0.5) * 30.0, 20.0 + randf() * 25.0, EAR.debris, 0.6, 1)
		"plague":
			for i in 4:
				var q: Vector2 = a + d * L * randf() + n * (randf() - 0.5) * hw * 2.0
				if prism:
					vfx.spark(q.x, q.y, d.x * 12.0, d.y * 12.0, 0.18, [BODY.plague[1], BODY.plague[2]])
				else:
					el.bubble(q.x, q.y, randf() < 0.3)
		"life":
			for i in 3:
				var q: Vector2 = a + d * L * randf() + n * (randf() - 0.5) * hw * 2.0
				el.leaf(q.x, q.y, (randf() - 0.5) * 6.0, -3.0, LIFE.petal if randf() < 0.4 else LIFE.leaf, 0.8)

## Telegraph: the exact area as a dashed blue ring that brightens, and a solid ring growing from
## the centre that meets the edge the moment it lands (playtest: "blue ring, then BAM").
func _draw_warn(buf: PackedByteArray, c: Vector2, st: Dictionary) -> void:
	var el = vfx.elements
	var k: float = clampf(float(st.age) / float(st.life), 0.0, 1.0)
	var r: float = float(st.r)
	var wp = st.part.get_ref()
	if not st.has("cols"):
		st.cols = _area_cols(wp)
	var cols: Array = st.cols
	if is_hostile(wp):
		_hostile_ring(buf, c, r, cols, k)
		return
	var trap_id := str(wp.cast.plan.get("id", "")) if wp != null else ""
	if trap_id in ["rune_trap", "frost_sigil"]:
		_split_ring(buf, c, r, cols, k >= 0.6)
		if trap_id == "frost_sigil":
			_frost_glyph(buf, c, minf(r * 0.65, 22.0) * (0.55 + k * 0.45), AREA_COL.ice[0], k)
		else:
			for i in 4:
				var a := float(i) * TAU / 4.0
				var at := c + Vector2.from_angle(a) * r * (0.65 - 0.5 * k)
				el.draw_glyph(buf, at.x, at.y, i, cols[0][0])
		return
	_split_ring(buf, c, r, cols, k >= 0.6)
	var inner := r * k
	if inner > 1.0:
		var steps := ceili(TAU * inner * 0.6)
		for i in steps:
			var a := TAU * i / steps
			var pair: Array = cols[0] if cos(a) <= 0.0 else cols[1]
			el.spx(buf, roundi(c.x + cos(a) * inner), roundi(c.y + sin(a) * inner), pair[1] if k < 0.75 else pair[0])

## A monster's telegraph, in three beats over its life k (0..1): the rim is drawn around the area
## like a spell being inscribed (to HOSTILE_DRAW), then a ring swells from the centre to the rim, and
## in the last beat the rim doubles and flashes before the blast. A pip marks the exact centre.
const HOSTILE_DRAW := 0.35
func _hostile_ring(buf: PackedByteArray, c: Vector2, r: float, cols: Array, k: float) -> void:
	var el = vfx.elements
	var sweep := clampf(k / HOSTILE_DRAW, 0.0, 1.0)
	_split_ring(buf, c, r, cols, true, 1.8, sweep)
	if sweep < 1.0:
		var tip := TAU * sweep - PI * 0.5
		var at := c + Vector2(cos(tip), sin(tip)) * r
		el.spx(buf, roundi(at.x), roundi(at.y), Color.WHITE)
		if randf() < 0.5:
			vfx.spark(at.x, at.y, (randf() - 0.5) * 16.0, (randf() - 0.5) * 16.0, 0.18, [cols[0][0], cols[0][1], cols[0][1]])
	else:
		var grow := clampf((k - HOSTILE_DRAW) / (1.0 - HOSTILE_DRAW), 0.0, 1.0)
		var inner := r * grow * grow * (3.0 - 2.0 * grow)
		if inner > 1.0:
			var steps := ceili(TAU * inner * 0.7)
			for i in steps:
				var a := TAU * i / steps
				el.spx(buf, roundi(c.x + cos(a) * inner), roundi(c.y + sin(a) * inner), cols[0][1] if grow < 0.7 else cols[0][0])
		if k >= 0.8:
			_split_ring(buf, c, r + 0.7, cols, (vfx._steps & 2) == 0, 1.8)
	var pip: Color = cols[0][1] if (vfx._steps & 4) else cols[0][0]
	for d in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		el.spx(buf, roundi(c.x + d.x), roundi(c.y + d.y), pip)

## An enemy's body in su: centre and half-height, so status effects sit ON it, not above it.
func _body(e) -> Array:
	var p: Vector2 = e.global_position / WPS
	var h := 3.0
	var spr = e.get_node_or_null("Sprite2D")
	if spr is Sprite2D and spr.texture != null:
		h = clampf(spr.texture.get_height() * absf(spr.global_scale.y) * 0.5 / WPS, 2.0, 8.0)
		p = spr.global_position / WPS
	return [p, h]

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
		var b := _body(e)
		var p: Vector2 = b[0]
		var h: float = b[1]
		# Burning is a few faint embers on the body, never flames: spells own the big fire (playtest).
		if randf() < 0.45 * dt * 60.0:
			vfx.spark(p.x + (randf() - 0.5) * h * 1.3, p.y + (randf() - 0.2) * h, (randf() - 0.5) * 1.5, -(3.0 + randf() * 3.0),
				0.3 + 0.2 * randf(), _ghost([BODY.fire[1], BODY.fire[2], BODY.fire[3]]))

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

func _fire_nova(c: Vector2, r: float, k: float, dt: float, accent: bool = false) -> void:
	var n := TAU * r * 0.17 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		var rr := r - randf() * 2.5
		vfx.flame(null, Vector2(c.x + cos(a) * rr, c.y + sin(a) * rr), {"vx": cos(a) * 22.0, "vy": sin(a) * 16.0,
			"heat": (0.95 if accent else 1.5) * (1.0 - k * 0.45), "rise": 16.0 + randf() * 12.0,
			"life": (0.16 + randf() * 0.12) if accent else (0.28 + randf() * 0.25), "small": 1.0 if accent else 0.0})
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

static func _is_arcane_orbit(part) -> bool:
	return part.cast != null and str(part.cast.plan.get("id", "")) == "arcane_orbit" and not is_hostile(part)

static func _is_magic_missile(part) -> bool:
	return part.cast != null and str(part.cast.plan.get("id", "")) == "mana_bolt" and not is_hostile(part)

func _missile_pixel(buf: PackedByteArray, x: int, y: int, color: Color) -> void:
	var local := Vector2i(x, y) - Vector2i(vfx._origin)
	if local.x < 0 or local.y < 0 or local.x >= vfx._size.x or local.y >= vfx._size.y:
		return
	var index: int = (local.y * vfx._size.x + local.x) * 4
	var old_alpha: float = float(buf[index + 3]) / 255.0
	var alpha := color.a + old_alpha * (1.0 - color.a)
	if alpha <= 0.0:
		return
	var old := Color(float(buf[index]) / 255.0, float(buf[index + 1]) / 255.0, float(buf[index + 2]) / 255.0)
	var mixed := (color * color.a + old * old_alpha * (1.0 - color.a)) / alpha
	buf[index] = mixed.r8
	buf[index + 1] = mixed.g8
	buf[index + 2] = mixed.b8
	buf[index + 3] = roundi(alpha * 255.0)

func _missile_position(part) -> Vector2:
	var age := float(part.age)
	var bend := sin(clampf(age / 0.28, 0.0, 1.0) * PI) * 1.1
	return part.global_position / WPS + Vector2(part.direction).normalized().orthogonal() * bend

func _draw_magic_missile(buf: PackedByteArray, p: Vector2, direction: Vector2, part, accent: String) -> void:
	var scale := maxf(float(part.size_scale), 0.01)
	var dir := direction.normalized()
	var side := dir.orthogonal()
	var extent := ceili(3.0 * scale * vfx.K)
	var center := Vector2i(roundi(p.x * vfx.K), roundi(p.y * vfx.K))
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var local: Vector2 = Vector2(x, y) / (vfx.K * scale)
			var u := local.dot(dir)
			var v := local.dot(side)
			var edge := absf(u) / 2.9 + absf(v) / 1.8
			if edge > 1.0:
				continue
			var color := Color("#baa5f3")
			if v < 0.0:
				color = Color("#eee3ff") if u > -0.5 else Color("#d3bdfa")
			else:
				color = Color("#7b9de4")
			if absf(v) < 0.27 and u > -1.5:
				color = Color("#fff4ff")
			if u > 0.2 and edge > 0.72:
				color = Color("#a58bdd")
			if u > 2.0:
				color = Color("#fff4ff")
			if accent != "" and edge > 0.68:
				color = RIM[accent]
			color.a = 0.95 if edge < 0.75 else 0.84
			_missile_pixel(buf, center.x + x, center.y + y, color)

static func _is_ice_blast(part) -> bool:
	return str(part.cast.plan.get("id", "")) == "ice_blast" and not is_hostile(part)

func _draw_ice_blast_shard(buf: PackedByteArray, p: Vector2, direction: Vector2, part, accent: String) -> void:
	var scale: float = maxf(float(part.size_scale), 0.01) * lerpf(0.55, 1.0, clampf(float(part.age) / 0.07, 0.0, 1.0))
	var dir := direction.normalized()
	var perpendicular := dir.orthogonal()
	var inverse_scale: float = 1.0 / (vfx.K * scale)
	var base_color := Color("#68bddf")
	var light_color := Color("#c4f5ff")
	var shade_color := Color("#367caa")
	var ridge_color := Color("#ecffff")
	var extent := ceili(6.0 * scale * vfx.K)
	var center := Vector2i(roundi(p.x * vfx.K), roundi(p.y * vfx.K))
	for y in range(-extent, extent + 1):
		for x in range(-extent, extent + 1):
			var local: Vector2 = Vector2(x, y) * inverse_scale
			var u: float = local.dot(dir)
			var side: float = local.dot(perpendicular) + u * 0.08
			var width: float = 1.65 * (1.0 - u / 5.8) if u >= 0.0 else 1.65 * (1.0 + u / 3.8)
			if width <= 0.0 or absf(side) > width:
				continue
			var color := base_color
			if side < -width * 0.45:
				color = light_color
			elif side > width * 0.4:
				color = shade_color
			elif side < 0.1 and side > -0.25:
				color = ridge_color
			if accent != "" and absf(side) > width - 0.3:
				color = RIM[accent]
			vfx._put(buf, center.x + x, center.y + y, color)

func _ice_blast_trail(part, st: Dictionary, p: Vector2, distance: float) -> void:
	st.ice_wake = float(st.get("ice_wake", 0.0)) + distance
	var spacing := 4.0 if vfx.reduced_effects else 2.0
	if st.ice_wake < spacing:
		return
	st.ice_wake = fmod(st.ice_wake, spacing)
	var dir := Vector2(part.direction).normalized()
	var scale := maxf(float(part.size_scale), 0.01) * lerpf(0.55, 1.0, clampf(float(part.age) / 0.07, 0.0, 1.0))
	var rear := p - dir * 3.8 * scale
	var tail := rear - dir * 4.0 * scale
	vfx.elements.streak(rear.x, rear.y, tail.x, tail.y, 0.16, [Color("#91dce9"), Color("#629eae"), Color(0.35, 0.6, 0.65, 0.15)])
	if not vfx.reduced_effects and randf() < 0.35:
		var drift := -dir * 9.0 + dir.orthogonal() * randf_range(-4.0, 4.0)
		vfx.elements.mote(rear.x, rear.y, drift.x, drift.y, ICE.mote, 0.24, 0.0, 0.0)

func _ice_blast_contact(part, p: Vector2) -> void:
	var dir := Vector2(part.direction).normalized()
	var el = vfx.elements
	for i in (2 if vfx.reduced_effects else 4):
		var heading := dir.rotated(randf_range(-1.2, 1.2))
		var speed := randf_range(18.0, 34.0)
		el.shard(p.x, p.y, heading.x * speed, heading.y * speed, randf_range(15.0, 28.0), randf_range(1.2, 2.1), 0.5)
	for i in (3 if vfx.reduced_effects else 7):
		var heading := dir.rotated(randf_range(-1.6, 1.6))
		el.mote(p.x, p.y, heading.x * 24.0, heading.y * 24.0, ICE.mote, randf_range(0.2, 0.4), 0.0, 0.0)
	vfx.flash(p.x, p.y, 1.5, 0.04, Color("#c8f7ff"))
	vfx.scorch(p.x, p.y, 3.0, 0.7, "frost")
	var last: float = part.cast.get_meta("ice_contact_feedback", -100.0)
	if float(part.cast.clock) - last >= 0.12:
		part.cast.set_meta("ice_contact_feedback", float(part.cast.clock))
		vfx.hitstop(1)
		vfx.shake(0.24)

func _ice_trail(p: Vector2, vel: Vector2, dt: float, k: float = 1.0) -> void:
	dt *= k   # Ice Blast's many shards trail lighter (playtest: too much noise)
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
		var body := _body(e)
		var p: Vector2 = body[0]
		var h: float = body[1]
		if randf() < (0.025 if vfx.reduced_effects else 0.055) * dt * 60.0:
			var side := -1.0 if randf() < 0.5 else 1.0
			vfx.elements.flake(p.x + side * (h + 1.5), p.y - h * 0.5, side * 1.5, 3.0 + randf() * 3.0, 0.5 + randf() * 0.25, 0, 4.0)

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
		var p: Vector2 = _body(e)[0]
		# Shocked: the odd faint spark on the body, not a constant crackle (playtest).
		if randf() < 0.12 * dt * 60.0:
			vfx.spark(p.x + (randf() - 0.5) * 5.0, p.y + (randf() - 0.5) * 4.0, (randf() - 0.5) * 4.0, (randf() - 0.5) * 4.0, 0.12, _ghost(SPARK.lightning))

# ------------------------------------------------------------------ water (sandbox FX.water, polish pass 2)

## Goo for the shaders: drop bodies (air), pools (ground), tsunami walls (air).
func accumulate_water() -> void:
	var t: float = vfx._t
	for st in _parts.values():
		if str(st.get("family", "")) == "ghost":
			continue   # a spirit is mist, not goo
		if st.look.native == "plague":
			_plague_goo(st, t)
			continue
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
			"wave":
				if vfx._wave == null:
					var w := _wave_frame(part)
					vfx._wave = [w.o, w.dir, w.front, w.half, w.hw, w.fade]
				else:
					_wave_goo(part, t)     # a second wave at once: CPU splats

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
	st.acc += minf(w.hw, 24.0) * 0.6 * dt * 60.0 * w.fade      # sandbox caps the wave at hw 24
	while st.acc >= 1.0:
		st.acc -= 1.0
		var p: Vector2 = w.o + dir * (w.front + w.half) + w.nrm * ((randf() * 2.0 - 1.0) * w.hw)
		if randf() < 0.15:
			el.wblob(p.x - dir.x * 2.0, p.y - dir.y * 2.0, dir.x * 50.0, dir.y * 38.0, 1.3 + randf() * 0.8, 0.25, false)
		if randf() < 0.3:
			el.foam_streak(p.x, p.y, dir.x, dir.y, 6.0)
		if randf() < 0.7:
			el.droplet(p.x, p.y, dir.x * 40.0 + (randf() - 0.5) * 10.0, dir.y * 30.0, 30.0 + randf() * 40.0)
		if randf() < 0.2:
			el.mote(p.x, p.y - 3.0, dir.x * 30.0, -12.0, WAT.foam, 0.4, 20.0, 0.0)
		if st.look.accent != "" and randf() < 0.35:
			_emit_at(st.look.accent, p.x, p.y, dir.x, dir.y)
		if st.look.accent == "fire" and randf() < 0.12:
			# reaction (fire + water): the wall boils, steam pours off the crest
			vfx.elements.mist(p.x - dir.x * 3.0, p.y - 2.0, dir.x * 10.0 + (randf() - 0.5) * 6.0, -10.0 - randf() * 8.0, 2.6, 7.0, 0.8 + randf() * 0.6)
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

func _life_bolt_contact(at: Vector2, direction: Vector2) -> void:
	var tangent := direction.normalized().orthogonal()
	for sign_value in [-1.0, 1.0]:
		var velocity: Vector2 = tangent * sign_value * 30.0
		vfx.spark(at.x, at.y, velocity.x, velocity.y, 0.12, [Color("#eaffdc"), Color("#a1df86"), Color("#53915c")])
	for i in 3:
		vfx.elements.leaf(at.x, at.y, direction.x * 16.0 + tangent.x * (i - 1) * 12.0, direction.y * 16.0 + tangent.y * (i - 1) * 12.0 - 5.0, LIFE.leaf, 0.35)

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
		list.append(_body(e)[0])
		if randf() < 0.03 * dt * 60.0:
			var p: Vector2 = _body(e)[0]
			vfx.elements.leaf(p.x, p.y + 1.0, (randf() - 0.5) * 5.0, -3.0, _ghost(LIFE.leaf), 0.45)
	_wrapped = list

var _wrapped: Array = []

func _advance_transients(dt: float) -> void:
	for fracture in _shield_fractures:
		fracture.age += dt
	_shield_fractures = _shield_fractures.filter(func(fracture): return fracture.age < 0.32)
	for ring in _hit_rings:
		ring[3] += dt
	_hit_rings = _hit_rings.filter(func(ring): return ring[3] < ring[4])
	for ray in _lasers:
		ray[4] += dt
	_lasers = _lasers.filter(func(ray): return ray[4] < ray[5])

func clear_transients() -> void:
	_shield_fractures.clear()
	_orbit_visuals.clear()
	for state in _parts.values():
		state.erase("orbit_visual")
		if is_instance_valid(state.get("ground")):
			state.ground.hide()
			state.ground.queue_free()
			state.erase("ground")
	_missile_ribbons.clear()
	_hit_rings.clear()
	_lasers.clear()
	_prism_contacts.clear()
	_prism_contact_frame = -1

func draw_statuses(buf: PackedByteArray) -> void:
	var el = vfx.elements
	var t: float = vfx._t
	for hr in _hit_rings:
		var hk: float = hr[3] / hr[4]
		_split_ring(buf, Vector2(hr[0], hr[1]), hr[2], hr[5], hk < 0.5)
	for L in _lasers:
		var lk: float = L[4] / L[5]
		var a0: Vector2 = L[0]
		var d0: Vector2 = L[1]
		var b0: Vector2 = a0 + d0 * float(L[2])
		var nrm: Vector2 = d0.orthogonal()
		var hw := maxi(1, roundi(float(L[3]) * (1.0 - lk * 0.5)))
		var lc: Array = L[6]
		var prism: bool = L.size() > 8 and bool(L[8])
		var fade := clampf((1.0 - lk) / 0.65, 0.0, 1.0) if prism else 1.0
		if str(L[7]) == "lightning":
			el.line(buf, a0, b0, Color(lc[0], lc[0].a * fade))
			continue
		for o in range(-hw, hw + 1):
			var c: Color = lc[0] if o == 0 else (lc[1] if absi(o) < hw else lc[mini(3, lc.size() - 1)])
			c.a *= fade * (lerpf(0.6, 0.2, float(absi(o)) / float(hw)) if prism and o != 0 else 1.0)
			el.line(buf, a0 + nrm * o, b0 + nrm * o, c)
	# Stunned: three little stars circling the top of the body.
	for q in _dazed:
		var c: Vector2 = q[0]
		var hh: float = q[1]
		for i in 3:
			var a := t * 7.0 + float(i) / 3.0 * TAU
			el.spx(buf, roundi(c.x + cos(a) * hh * 0.8), roundi(c.y - hh * 0.55 + sin(a) * hh * 0.25), Color(Color("#fff3a0"), 0.8))
	if (vfx._steps >> 3) & 1:
		for p in _marked:
			el.draw_glyph(buf, p.x, p.y - 1.0, 0, Color(ARC.spark[2], STATUS_ALPHA))   # on the body, not floating above it
	for p in _wrapped:
		for i in 18:
			var a := float(i) / 18.0 * TAU
			if sin(a * 3.0 + t * 3.0) <= -0.3:
				continue
			el.spx(buf, roundi(p.x + cos(a) * 4.0), roundi(p.y + 1.0 + sin(a) * 1.6 - (0.0 if i % 9 < 4 else 2.0)), Color(LIFE.vine[i & 1], STATUS_ALPHA))
		el.spx(buf, roundi(p.x + 3.0), roundi(p.y - 1.0), Color(LIFE.leaf[1], STATUS_ALPHA))

# ------------------------------------------------------------------ arcane + shapes (sandbox FX.arcane, eSlash, traps)

## Impact scale from cast power (tier / power / charged / sanguine words): one
## impact tier up for strong casts; MEGA-class casts add shake and hit-stop.
static func _power(part) -> float:
	return clampf(sqrt(maxf(0.01, float(part.power_scale))), 0.8, 1.7)

func _burst(look: String, pos: Vector2, r_su: float, pw: float = 1.0) -> void:
	r_su *= pw
	if pw > 1.3:
		vfx.shake(0.6)
		vfx.hitstop(3)
	match look:
		"ice":
			_ice_impact(pos.x, pos.y, maxf(0.6, r_su / 12.0))
		"lightning":
			_strike(pos.x, pos.y, clampf(r_su / 10.0, 0.6, 2.0))
			if r_su >= 8.0:
				# One big bolt (a second only on a huge circle) and the true edge; the heavy landing
				# carries the rest (playtest: six bolts read as noise).
				if r_su >= 16.0:
					var a := randf() * TAU
					_strike(pos.x + cos(a) * r_su * 0.5, pos.y + sin(a) * r_su * 0.4, 0.7)
				vfx.ring(pos.x, pos.y, r_su, 0.2, LIT.arc)
		"water":
			_water_impact(pos.x, pos.y, clampf(r_su / 11.0, 0.6, 2.5))
		"life":
			_life_impact(pos.x, pos.y, clampf(r_su / 10.0, 0.6, 2.5))
		"fire":
			_damage_disk(pos.x, pos.y, maxf(0.35, (r_su - 3.0) / 9.0), {})
		"arcane":
			_arcane_impact(pos.x, pos.y, clampf(r_su / 12.0, 0.6, 2.5))
			vfx.ring(pos.x, pos.y, r_su, 0.25, SPARK.arcane)
		"plague":
			_plague_impact(pos.x, pos.y, clampf(r_su / 11.0, 0.6, 2.5))
		"earth":
			_earth_impact(pos.x, pos.y, clampf(r_su / 12.0, 0.6, 2.5))

## Rune burst: glyph ring, spark spray, ring, rune decal.
func _arcane_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in 6:
		var a := float(i) / 6.0 * TAU
		el.glyph(x + cos(a) * 8.0 * s, y + sin(a) * 6.0 * s, -4.0, 0.45)
	for i in roundi(16 * s):
		var a2 := randf() * TAU
		var sp := (20.0 + randf() * 40.0) * sqrt(s)
		vfx.spark(x, y, cos(a2) * sp, sin(a2) * sp * 0.8, 0.35 + randf() * 0.2, SPARK.arcane)
	vfx.ring(x, y, 12.0 * s, 0.3, SPARK.arcane)
	vfx.flash(x, y, 2.5 * s, 0.05, BODY.arcane[0])
	vfx.star(x, y, 2.6 * s, 0.06, 4, BODY.arcane[0])
	el.rune(x, y, 8.0 * s)
	vfx.hitstop(1)

func _arcane_field(A: Dictionary, dt: float) -> void:
	var f := dt * 60.0 * maxf(1.0, A.r / 20.0)
	if randf() < 0.5 * f:
		var q := _in_disk(A.x, A.y, A.r)
		vfx.spark(q.x, q.y, 0.0, -12.0 - randf() * 8.0, 0.6 + randf() * 0.4, SPARK.arcane)
	if randf() < 0.04 * f:
		var q2 := _in_disk(A.x, A.y, A.r)
		vfx.elements.glyph(q2.x, q2.y, -10.0, 0.9)

## Inner dashed circle with six glyphs orbiting it (sandbox fieldDraw).
func _draw_arcane_field(buf: PackedByteArray, A: Dictionary) -> void:
	var el = vfx.elements
	var r: float = A.r * 0.62
	var steps := ceili(TAU * r * 1.3)
	for i in steps:
		if i % 3 == 0:
			continue
		var a := TAU * i / steps
		el.spx(buf, roundi(A.x + cos(a) * r), roundi(A.y + sin(a) * r), ARC.rim[0])
	var t: float = vfx._t
	var frame: int = vfx._steps
	for i in 6:
		var a2 := t * 0.8 + float(i) / 6.0 * TAU
		el.draw_glyph(buf, A.x + cos(a2) * r, A.y + sin(a2) * r, i % 4, ARC.spark[2] if (i + (frame >> 3)) % 3 != 0 else ARC.spark[1])

func _arcane_nova(c: Vector2, r: float, dt: float) -> void:
	var n := TAU * r * 0.08 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		vfx.spark(c.x + cos(a) * r, c.y + sin(a) * r, cos(a) * 18.0, sin(a) * 14.0, 0.35, SPARK.arcane)
		i += 1.0
	if randf() < 0.25 * dt * 60.0:
		var a2 := randf() * TAU
		vfx.elements.glyph(c.x + cos(a2) * r, c.y + sin(a2) * r, 0.0, 0.3)

## Keyword accent on a field or nova: the accent element's particles at half rate
## over the native look (fiery field, icy nova...).
func _accent_field(accent: String, A: Dictionary, dt: float) -> void:
	match accent:
		"fire":
			if randf() < 0.35 * dt * 60.0 * maxf(1.0, A.r / 20.0):
				var q := _in_disk(A.x, A.y, A.r * 0.9)
				vfx.flame(null, q, {"heat": 0.45, "rise": 20.0 + randf() * 10.0, "life": 0.45 + randf() * 0.3, "small": 1.0})
		"ice":
			_ice_field(A, dt * 0.5)
		"lightning":
			_lightning_field(A, dt * 0.5)
		"water":
			_water_field(A, dt * 0.5)
		"life":
			_life_field(A, dt * 0.5)
		"plague":
			_plague_field(A, dt * 0.5)
		"earth":
			_earth_field(A, dt * 0.5)

func _accent_nova(accent: String, c: Vector2, r: float, k: float, dt: float) -> void:
	match accent:
		"fire":
			_fire_nova(c, r, k, dt * 0.5)
		"ice":
			_ice_nova(c, r, dt * 0.5)
		"lightning":
			if randf() < 0.5:
				_lightning_nova(c, r, randf() * 6.0, dt)
		"water":
			_water_nova(c, r, dt * 0.5)
		"life":
			_life_nova(c, r, dt)
		"plague":
			_plague_nova(c, r, dt * 0.5)
		"earth":
			_earth_nova(c, r, dt * 0.5)

## Slash (instant cone): the sandbox smear sweeping the cone's real arc and
## radius, emitting the impact look along its leading edge.
var _flip := 1

func _slash(part, look: Dictionary, pos: Vector2) -> void:
	var key: String = look.native      # body = native (plan 5.1); the accent emits along the edge too
	var acc: String = look.accent
	var R: float = float(part.geo("radius", 100.0)) / WPS
	var span := deg_to_rad(float(part.def.get("geometry", {}).get("angle", 90.0)))
	var mid: float = Vector2(part.direction).angle()
	_flip = -_flip
	var emit := func(x: float, y: float, fx: float, fy: float):
		_emit_at(key, x, y, fx, fy)
		if acc != "" and randf() < 0.5:
			_emit_at(acc, x, y, fx, fy)
	vfx.elements.slash(pos.x, pos.y, mid - span * 0.5 * _flip, span, _flip, R * 0.3, R, SMEAR[key], emit, 0.13, str(part.cast.plan.get("id", "")) == "slash" and not is_hostile(part))

## Per-element emission along a moving edge (sandbox emitAt).
func _emit_at(el_name: String, x: float, y: float, fx: float, fy: float) -> void:
	var el = vfx.elements
	match el_name:
		"fire":
			vfx.flame(null, Vector2(x, y), {"vx": fx * 30.0, "vy": fy * 24.0, "rise": 18.0 + randf() * 10.0, "life": 0.28 + randf() * 0.2, "heat": 1.35})
		"ice":
			if randf() < 0.4:
				el.mote(x, y, fx * 20.0, fy * 14.0 - 4.0, ICE.mote, 0.6, 6.0, 3.0)
			if randf() < 0.12:
				el.flake(x, y, fx * 16.0, fy * 12.0 - 4.0, 0.7, 0, 4.0)
		"lightning":
			if randf() < 0.25:
				el.hop(x, y, 0.2)
		"water":
			if randf() < 0.3:
				el.foam_streak(x, y, fx, fy, 6.0)
			if randf() < 0.5:
				el.droplet(x, y, fx * 40.0 + (randf() - 0.5) * 10.0, fy * 30.0, 30.0 + randf() * 40.0)
		"life":
			if randf() < 0.3:
				el.blade(x, y, 2 + randi() % 3, 0.0, 0.9 + randf() * 0.5, randf() < 0.15)
			if randf() < 0.15:
				el.leaf(x, y - 2.0, fx * 14.0, -8.0, LIFE.petal if randf() < 0.3 else LIFE.leaf, 0.9)
		"plague":
			if randf() < 0.12:
				el.gblob(x, y, fx * 40.0 + (randf() - 0.5) * 10.0, fy * 30.0 + (randf() - 0.5) * 8.0, 1.4 + randf(), 0.45 + randf() * 0.3, true)
			if randf() < 0.45:
				el.bubble(x, y, randf() < 0.2)
		"earth":
			if randf() < 0.15:
				el.crystal(x, y, 5.0 + randf() * 5.0, 0.4 + randf() * 0.3, EAR.body)
			if randf() < 0.35:
				el.dust(x, y, fx * 16.0, fy * 10.0)
		"arcane":
			if randf() < 0.6:
				vfx.spark(x, y, fx * 30.0, fy * 24.0, 0.4, SPARK.arcane)
			if randf() < 0.05:
				el.glyph(x, y, -6.0, 0.4)

## Rune trap (sandbox traps): the ring draws itself around the real radius while
## arming, then pulses; the glyph in the middle lights up when armed.
func _draw_trap(buf: PackedByteArray, part, st: Dictionary) -> void:
	var el = vfx.elements
	var c: Vector2 = part.global_position / WPS
	var r: float = float(part.geo("radius", 45.0)) / WPS
	var arming := float(part.def.get("timing", {}).get("arming", 0.4))
	var k := clampf(float(part.age) / maxf(0.01, arming), 0.0, 1.0)
	var armed: bool = part.armed
	if not st.has("cols"):
		st.cols = _area_cols(part)
	var cols: Array = st.cols
	var ready := armed and float(part.age) - arming < 0.18
	var expiry := clampf(float(part.remaining_life()) / 0.25, 0.0, 1.0)
	var steps := ceili(TAU * r * 1.3)
	for i in steps:
		if not armed and float(i) / steps > k:
			continue
		var a := TAU * i / steps - PI / 2.0
		var pair: Array = cols[0] if cos(a) <= 0.0 else cols[1]
		var color: Color = pair[0] if ready or (not armed and absf(float(i) / steps - k) < 0.05) else pair[1]
		color.a *= expiry
		el.spx(buf, roundi(c.x + cos(a) * r), roundi(c.y + sin(a) * r), color)
	if str(part.cast.plan.get("id", "")) == "frost_sigil":
		_frost_glyph(buf, c, minf(r * 0.65, 9.0) * k, Color(AREA_COL.ice[0] if armed else AREA_COL.ice[1], expiry))
	else:
		el.draw_glyph(buf, c.x, c.y, 3, Color(cols[0][0] if armed else cols[0][1], expiry))
	if ready:
		for i in 4:
			var at := c + Vector2.from_angle(float(i) * PI / 2.0) * r
			el.line(buf, at - Vector2.ONE, at + Vector2.ONE, cols[0][0])

func _frost_glyph(buf: PackedByteArray, c: Vector2, radius: float, color: Color, growth: float = 1.0) -> void:
	if radius < 1.5:
		return
	var el = vfx.elements
	for i in 6:
		var axis := Vector2.from_angle(float(i) * TAU / 6.0 - PI / 2.0)
		el.line(buf, c + axis * 1.5, c + axis * radius, color)
		if growth > 0.25:
			for side in [-1.0, 1.0]:
				var fork := c + axis * radius * 0.58
				el.line(buf, fork, fork + axis.rotated(side * PI / 3.0) * radius * 0.32, color)

func _frost_trap_burst(part, pos: Vector2, radius: float) -> void:
	var el = vfx.elements
	var count := 12 if vfx.reduced_effects else 24
	for i in count:
		var a := float(i) / count * TAU
		var axis := Vector2.from_angle(a)
		var start := pos + axis * radius * 0.3
		el.shard(start.x, start.y, axis.x * radius * 2.0, axis.y * radius * 1.4, 18.0 + randf() * 12.0, 2.0 + randf() * 2.0, 0.4 + randf() * 0.2)
		el.flake(start.x, start.y, axis.x * 5.0, axis.y * 4.0, 0.8, 0, 0.0)
	vfx.star(pos.x, pos.y, minf(radius * 0.3, 5.0), 0.08, 6, AREA_COL.ice[0])
	_hit_rings.append([pos.x, pos.y, radius, 0.0, 0.35, _area_cols(part)])
	vfx.hitstop(4)
	vfx.shake(0.92)
	var audio = vfx.get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sound(audio.SoundType.get(LANDING_SOUND.get("arcane", "SPELL_IMPACT_FIRE"), audio.SoundType.SPELL_IMPACT_FIRE))

## Vulnerable (arcane status): rising sparks and a blinking glyph overhead.
func _vulnerable(dt: float) -> void:
	var tree = vfx.get_tree()
	if tree == null:
		return
	var list := []
	for e in tree.get_nodes_in_group("enemies"):
		if list.size() >= MAX_BURNING:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if s.has_method("has") and s.has("vulnerable"):
			var p: Vector2 = _body(e)[0]
			list.append(p)
			if randf() < 0.08 * dt * 60.0:
				vfx.spark(p.x + (randf() - 0.5) * 5.0, p.y + (randf() - 0.5) * 4.0, 0.0, -5.0, 0.3, _ghost(SPARK.arcane))
	_marked = list

var _marked: Array = []
var _dazed: Array = []
var _hit_rings: Array = []   # [x, y, r, age, life] landing damage areas
var _lasers: Array = []      # [from su, dir, length su, half-width su, age, life, palette, look]  Prism Ray refraction

## Stunned (Meteor Shower, shock): collected for draw_statuses.
func _stunned(_dt: float) -> void:
	var tree = vfx.get_tree()
	var list := []
	if tree == null:
		_dazed = list
		return
	for e in tree.get_nodes_in_group("enemies"):
		if list.size() >= MAX_BURNING:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if s.has_method("has") and s.has("stunned"):
			list.append(_body(e))
	_dazed = list

# ------------------------------------------------------------------ plague (sandbox FX.plague, polish pass 2: bubbles first)

func _plague_goo(st: Dictionary, t: float) -> void:
	var part = st.part.get_ref()
	if part == null or not is_instance_valid(part) or part.done:
		return
	var pos: Vector2 = part.global_position / WPS
	match st.kind:
		"infection":
			return
		"projectile":
			var d: Vector2 = pos - st.last
			var u: Vector2 = d.normalized() if d.length() > 0.01 else Vector2(part.direction).normalized()
			if st.family == "spear":
				for i in 5:
					vfx.gsplat(2, pos.x - u.x * i * 2.2, pos.y - u.y * i * 2.2, 2.3 - i * 0.3)
				return
			var big := 1.35 if st.family == "ball" else 1.0
			vfx.gsplat(2, pos.x, pos.y, (3.4 + sin(t * 13.0) * 0.3) * big)
			vfx.gsplat(2, pos.x - u.x * 3.0 + cos(t * 11.0) * 0.6, pos.y - u.y * 3.0 + sin(t * 9.0) * 0.6, 2.3 * big)
			vfx.gsplat(2, pos.x - u.x * 5.5, pos.y - u.y * 5.5, 1.4 * big)
		"field_cpu_unused":
			var A: Dictionary = st.field
			var K: float = vfx.K
			var R := ceili((A.r - 2.0) * K)
			var cx := roundi(A.x * K)
			var cy := roundi(A.y * K)
			var thr: float = 0.9 - minf(1.0, A.age * 2.0) * 0.06
			for oy in range(-R, R + 1):
				for ox in range(-R, R + 1):
					if ox * ox + oy * oy > R * R:
						continue
					var X := (cx + ox) / K
					var Y := (cy + oy) / K
					if vfx.vn_fast(X * 0.16, Y * 0.16 + t * 0.25) + vfx.vn_fast(X * 0.4 + 5.0, Y * 0.4 - t * 0.5) * 0.3 > thr:
						vfx.water_cell(3, cx + ox, cy + oy, 1.1)

func _plague_trail(p: Vector2, vel: Vector2, dt: float) -> void:
	var el = vfx.elements
	if randf() < 0.15 * dt * 60.0:
		el.gblob(p.x, p.y, 0.0, 0.0, 0.9, 0.3, false, 60.0)
	if randf() < 0.6 * dt * 60.0:
		el.bubble(p.x - vel.x * 0.03 + (randf() - 0.5) * 4.0, p.y + (randf() - 0.5) * 4.0, randf() < 0.2)

func _plague_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in roundi(24 * s):
		el.bubble(x + (randf() - 0.5) * 14.0 * s, y + (randf() - 0.5) * 14.0 * s * 0.6, randf() < 0.3)
	for i in roundi(5 * s):
		var a := randf() * TAU
		el.gblob(x, y, cos(a) * 25.0, sin(a) * 18.0, 1.1, 0.5, true)
	vfx.ring(x, y, 11.0 * s, 0.3, [PLG.hi, PLG.light, PLG.mid])
	vfx.scorch(x, y, 6.0 * s, 6.0, "stain")
	vfx.hitstop(1)

func _plague_contact(x: float, y: float) -> void:
	for i in 6:
		var a := randf() * TAU
		vfx.elements.gblob(x, y, cos(a) * 30.0, sin(a) * 22.0, 1.3, 0.5, true)
	vfx.elements.bubble(x, y - 2.0, false)

func _plague_field(A: Dictionary, dt: float) -> void:
	if randf() < minf(1.0, 1.0 * dt * 60.0 * maxf(1.0, A.r / 20.0)):
		var q := _in_disk(A.x, A.y, A.r)
		vfx.elements.bubble(q.x, q.y, randf() < 0.25)

func _plague_nova(c: Vector2, r: float, dt: float) -> void:
	var n := TAU * r * 0.07 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		vfx.elements.bubble(c.x + cos(a) * r, c.y + sin(a) * r, randf() < 0.3)
		i += 1.0

## Poison: bubbles boiling off the enemy.
func _poisoned(dt: float) -> void:
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
		if s.has_method("has") and s.has("poison"):
			n += 1
			var b := _body(e)
			var p: Vector2 = b[0]
			var h: float = b[1]
			# Small bubbles popping on the body, short-lived so they never float off above it.
			if randf() < 0.28 * dt * 60.0:
				vfx.elements.bubble(p.x + (randf() - 0.5) * h * 1.4, p.y + (randf() - 0.3) * h, false, 0.35, 0.42)
		elif s.has_method("has") and s.has("bleed") and randf() < 0.15 * dt * 60.0:
			var p2: Vector2 = _body(e)[0]
			# Bleed is blood, not earth: dark red drops falling off the body.
			vfx.spark(p2.x + (randf() - 0.5) * 5.0, p2.y - 2.0 - randf() * 3.0, (randf() - 0.5) * 2.0, 5.0 + randf() * 3.0, 0.25 + 0.1 * randf(), _ghost([Color("e0443a"), Color("a82828"), Color("5a1010")], 0.7))

# ------------------------------------------------------------------ earth (sandbox FX.earth, rigid)

func _earth_trail(p: Vector2, vel: Vector2, dt: float) -> void:
	if randf() < 0.5 * dt * 60.0:
		vfx.elements.dust(p.x - vel.x * 0.03, p.y + 1.0, (randf() - 0.5) * 6.0, -2.0)
	if randf() < 0.12 * dt * 60.0:
		vfx.chunk(p.x, p.y, vel.x * 0.1, vel.y * 0.1, 5.0, EAR.debris, 0.6, 1)

## Boulder hit: rubble on z-physics (1:3:9), dust ring, stone spikes, cracks.
func _earth_impact(x: float, y: float, s: float) -> void:
	var el = vfx.elements
	for i in roundi(14 * s):
		var a := randf() * TAU
		var sp := (18.0 + randf() * 34.0) * sqrt(s)
		vfx.chunk(x, y, cos(a) * sp, sin(a) * sp * 0.7, 50.0 + randf() * 60.0, EAR.debris, 1.4 + randf(), 2 if randf() < 0.5 else 1)
	for i in roundi(12 * s):
		var a2 := randf() * TAU
		el.dust(x + cos(a2) * 4.0, y + sin(a2) * 3.0, cos(a2) * 18.0, sin(a2) * 10.0)
	for i in roundi(3 * s):
		el.crystal(x + (randf() - 0.5) * 8.0 * s, y + (randf() - 0.5) * 5.0 * s, 5.0 + randf() * 4.0, 0.6 + randf() * 0.4, EAR.body)
	vfx.crack_decal(x, y, 5, 10.0 * s)
	vfx.shake(0.4)
	vfx.hitstop(3)

func _earth_contact(x: float, y: float) -> void:
	for i in 5:
		var a := randf() * TAU
		vfx.chunk(x, y, cos(a) * 20.0, sin(a) * 14.0, 30.0 + randf() * 30.0, EAR.debris, 0.8, 1)
	vfx.elements.dust(x, y, 0.0, -4.0)

func _earth_field_start(A: Dictionary) -> void:
	var el = vfx.elements
	for i in roundi(9.0 * maxf(1.0, A.r * A.r / 400.0)):
		var q := _in_disk(A.x, A.y, A.r)
		var h := 6.0 + randf() * 6.0
		var life: float = A.life - 1.1
		el.later.append([randf() * 0.5, func(): el.crystal(q.x, q.y, h, life, EAR.body)])
	vfx.crack_decal(A.x, A.y, 7, A.r, A.life)

func _earth_field(A: Dictionary, dt: float) -> void:
	if randf() < 0.4 * dt * 60.0 * maxf(1.0, A.r / 20.0):
		var q := _in_disk(A.x, A.y, A.r)
		vfx.elements.dust(q.x, q.y, (randf() - 0.5) * 6.0, -2.0)

## Earth nova: stone spikes burst up along the live front (an earth-spike nova
## is exactly right here), dust thrown outward.
func _earth_nova(c: Vector2, r: float, dt: float) -> void:
	var n := TAU * r * 0.018 * dt * 60.0
	var i := 0.0
	while i < n:
		if i + 1.0 > n and randf() > n - i:
			break
		var a := randf() * TAU
		vfx.elements.crystal(c.x + cos(a) * r, c.y + sin(a) * r, 5.0 + randf() * 5.0, 0.4 + randf() * 0.3, EAR.body)
		i += 1.0
	if randf() < 0.7 * dt * 60.0:
		var a2 := randf() * TAU
		vfx.elements.dust(c.x + cos(a2) * r, c.y + sin(a2) * r, cos(a2) * 14.0, sin(a2) * 8.0)

# ------------------------------------------------------------------ keywords (plan 5.2) and reactions (plan 5.3)

func _step_charges(dt: float) -> void:
	var keep := []
	var rt: float = dt / vfx.fx_speed
	for c in _charges:
		var caster = c.caster.get_ref()
		c.age += rt
		if caster == null or not is_instance_valid(caster) or c.age > c.dur:
			continue
		keep.append(c)
		var at := _staff_su(caster)
		var k: float = c.age / c.dur
		var rate: float = (14.0 if c.big else 9.0) * (0.4 + k)
		if randf() < rate * rt * 3.0:
			var a := randf() * TAU
			var r := (10.0 if c.big else 7.0) + randf() * 5.0
			# gathering: sparks start out on a ring and fly into the staff
			vfx.spark(at.x + cos(a) * r, at.y + sin(a) * r * 0.8, -cos(a) * r * 3.2, -sin(a) * r * 2.6, 0.3, c.pal)
	_charges = keep

func draw_charges(buf: PackedByteArray) -> void:
	var el = vfx.elements
	for c in _charges:
		var caster = c.caster.get_ref()
		if caster == null or not is_instance_valid(caster):
			continue
		var at := _staff_su(caster)
		var k: float = clampf(c.age / c.dur, 0.0, 1.0)
		var r: float = (2.0 + k * (9.0 if c.big else 6.0))
		var steps := maxi(8, ceili(TAU * r * 1.2))
		var col: Color = c.pal[0] if k > 0.8 and (vfx._steps & 2) else c.pal[1 if k > 0.5 else 2]
		for i in steps:
			if (i + (vfx._steps >> 2)) % 3 == 0:
				continue
			var a := TAU * i / steps
			el.spx(buf, roundi(at.x + cos(a) * r), roundi(at.y + sin(a) * r * 0.8), col)
		if c.big and k > 0.5:
			el.draw_glyph(buf, at.x, at.y - r - 3.0, 3, c.pal[1])

## Blinking: a poof where the caster stood, a dotted streak, a flash on arrival.
func _blink_fx(from: Vector2, to: Vector2, key: String) -> void:
	var el = vfx.elements
	for i in 10:
		var a := randf() * TAU
		vfx.spark(from.x, from.y - 4.0, cos(a) * 26.0, sin(a) * 20.0, 0.35, SPARK[key])
	el.mist(from.x, from.y - 4.0, 0.0, -6.0, 2.4, 5.0, 0.5)
	vfx.ring(from.x, from.y, 6.0, 0.2, SPARK[key])
	var d := to - from
	var n := maxi(2, int(d.length() / 3.0))
	for i in n:
		var q := from + d * (float(i) / n)
		vfx.spark(q.x, q.y - 4.0, d.x * 0.05, d.y * 0.05, 0.15 + 0.25 * float(i) / n, SPARK[key])
	vfx.star(to.x, to.y - 4.0, 3.5, 0.08, 4, BODY[key][0])
	vfx.flash(to.x, to.y - 4.0, 2.0, 0.06, BODY[key][1])

## Sanguine: the cast is paid in blood.
const BLOOD := [Color("#ff5a5a"), Color("#c41f2e"), Color("#7a0f1e")]
func _blood_fx(at: Vector2) -> void:
	for i in 12:
		var a := randf() * TAU
		vfx.chunk(at.x, at.y, cos(a) * (14.0 + randf() * 18.0), sin(a) * 10.0, 25.0 + randf() * 30.0, BLOOD, 0.7 + randf() * 0.4, 1)
	vfx.ring(at.x, at.y + 3.0, 8.0, 0.25, BLOOD)
	vfx.flash(at.x, at.y, 1.8, 0.05, BLOOD[0])

## Pulling / repulsing: rings and streaks show the push direction at the hit.
func _force_fx(plan: Dictionary, p: Vector2, key: String) -> void:
	var flags: Dictionary = plan.get("flags", {})
	if flags.has("repulsing"):
		vfx.ring(p.x, p.y, 9.0, 0.22, SPARK[key])
		for i in 6:
			var a := float(i) / 6.0 * TAU + randf() * 0.3
			vfx.elements.streak(p.x + cos(a) * 4.0, p.y + sin(a) * 3.0, p.x + cos(a) * 10.0, p.y + sin(a) * 8.0, 0.16, SPARK[key])
	elif flags.has("pulling"):
		vfx.elements.pull_ring(p.x, p.y, 14.0, 0.3, SPARK[key])
		for i in 6:
			var a2 := float(i) / 6.0 * TAU + randf() * 0.3
			vfx.elements.streak(p.x + cos(a2) * 12.0, p.y + sin(a2) * 9.0, p.x + cos(a2) * 5.0, p.y + sin(a2) * 4.0, 0.18, SPARK[key])

## Pulling / repulsing on areas: streaks drift in from (or out to) the rim.
func _field_force(plan: Dictionary, A: Dictionary, key: String, dt: float) -> void:
	var flags: Dictionary = plan.get("flags", {})
	var pull := flags.has("pulling")
	if not pull and not flags.has("repulsing"):
		return
	if randf() < 0.5 * dt * 60.0:
		var a := randf() * TAU
		var r: float = A.r
		var outer := Vector2(A.x + cos(a) * r, A.y + sin(a) * r)
		var inner := Vector2(A.x + cos(a) * r * 0.7, A.y + sin(a) * r * 0.7)
		if pull:
			vfx.elements.streak(outer.x, outer.y, inner.x, inner.y, 0.2, SPARK[key])
		else:
			vfx.elements.streak(inner.x, inner.y, outer.x, outer.y, 0.2, SPARK[key])

## Reaction table (plan 5.3): pairs where plain body + accent would miss the payoff.
func _react(native: String, accent: String, p: Vector2, s: float) -> void:
	var el = vfx.elements
	var pair := [native, accent]
	pair.sort()
	var a: String = pair[0]
	var b: String = pair[1]
	if a == "fire" and (b == "water" or b == "ice"):
		for i in roundi(10 * s):           # steam burst
			var ang := randf() * TAU
			var sp := 10.0 + randf() * 18.0
			el.mist(p.x, p.y - 2.0, cos(ang) * sp, sin(ang) * sp * 0.6 - 8.0, 2.4 + randf(), 7.0 + randf() * 4.0, 0.8 + randf() * 0.5)
	elif a == "earth" and b == "fire":
		vfx.crack_decal(p.x, p.y, 6, 9.0 * s, 4.0, [Color("#ff8a1f"), Color("#c2361a")])    # magma cracks
	elif a == "fire" and b == "life":
		for i in roundi(12 * s):           # burning leaves, ember to ash
			var ang2 := randf() * TAU
			el.leaf(p.x, p.y, cos(ang2) * 22.0, sin(ang2) * 14.0 - 10.0, [Color("#ffd54a"), Color("#ff8a1f"), Color("#c2361a"), Color("#3a2a24")], 1.0 + randf() * 0.6)
	elif a == "lightning" and b == "water":
		for i in 5:                        # arcs run across the splash
			var q1 := p + Vector2(randf() - 0.5, randf() - 0.5) * 18.0 * s
			var q2 := p + Vector2(randf() - 0.5, randf() - 0.5) * 18.0 * s
			el.arc(q1.x, q1.y, q2.x, q2.y, 2.0, 0.12, 1)
		for i in 6:
			el.hop(p.x + (randf() - 0.5) * 14.0 * s, p.y + (randf() - 0.5) * 8.0 * s, 0.25)
	elif a == "earth" and b == "ice":
		vfx.crack_decal(p.x, p.y, 6, 9.0 * s, 5.0, [Color("#8fd3ee"), Color("#3d5a78")])    # permafrost
	elif a == "life" and b == "plague":
		for i in 7:                        # stains bloom into flowers
			var ang3 := float(i) / 7.0 * TAU
			el.blade(p.x + cos(ang3) * 5.0 * s, p.y + sin(ang3) * 3.5 * s, 2, 0.15 + i * 0.04, 2.5, true)

## Continuous reaction on areas: fire meeting water / ice steams.
func _steam_if(look: Dictionary, p: Vector2, dt: float) -> void:
	var pair := [look.native, look.accent]
	if pair.has("fire") and (pair.has("water") or pair.has("ice")) and randf() < 0.25 * dt * 60.0:
		vfx.elements.mist(p.x, p.y - 2.0, (randf() - 0.5) * 6.0, -8.0 - randf() * 6.0, 2.2, 6.0, 0.9 + randf() * 0.5)

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
	_draw_props(buf)
	for orbit in _orbit_visuals:
		orbit.draw_wake(buf, self)
	for ribbon in _missile_ribbons:
		ribbon.draw(buf, self)
	for st in _parts.values():
		if st.kind == "trap":
			var tp = st.part.get_ref()
			if tp != null and is_instance_valid(tp) and not tp.done:
				_draw_trap(buf, tp, st)
			continue
		if st.kind == "field" and st.look.native == "arcane":
			var fp = st.part.get_ref()
			if fp != null and is_instance_valid(fp) and not fp.done:
				_draw_arcane_field(buf, st.field)
			continue
		if st.kind == "wave":
			var wp = st.part.get_ref()
			if wp != null and is_instance_valid(wp) and not wp.done:
				_draw_wave_rim(buf, wp)
			continue
		if st.kind == "beam":
			var bp = st.part.get_ref()
			if bp != null and is_instance_valid(bp) and not bp.done:
				_draw_beam(buf, bp, st)
			continue
		if st.kind == "warn":
			var wpart = st.part.get_ref()
			if wpart != null and is_instance_valid(wpart) and not wpart.done:
				_draw_warn(buf, wpart.global_position / WPS, st)
			continue
		if st.kind == "meteor":
			var mp = st.part.get_ref()
			if mp != null and is_instance_valid(mp) and not mp.done:
				st.age = float(mp.age)
				st.life = float(mp.total_life())
				var mc: Vector2 = mp.global_position / WPS
				var k: float = _meteor_k(st)
				# warning: the true radius, dashed and marching, brightening as the rock comes down
				if is_hostile(mp):
					var hp := hostile_cols(mp.cast.plan)
					_hostile_ring(buf, mc, float(st.r), [hp, hp], clampf(float(st.age) / maxf(0.05, float(st.life)), 0.0, 1.0))
				else:
					vfx.elements.draw_nova(buf, mc.x, mc.y, float(st.r), METEOR_WARN if k < 0.7 else METEOR_WARN_HOT)
				if float(st.age) >= float(st.life) - METEOR_FALL:
					var rock: Vector2 = mc + st.sky * (1.0 - k)
					_draw_magma(buf, rock, -Vector2(st.sky).normalized(), 2.6 * clampf(float(st.r) / 8.0, 0.8, 1.5), mp.get_instance_id())
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
		if st.family == "ghost":
			continue
		if st.family == "blade":
			_draw_blade(buf, pos, part)
			continue
		var b: Dictionary = FAMILY[st.family].body
		var sc: float = float(part.size_scale)
		if st.family == "sphere":
			sc = float(part.geo("radius", 42.0)) / (WPS * float(b.r))
		var pal: Array = BODY[st.look.native]
		if _is_arcane_orbit(part) and st.look.native == "arcane" and st.has("orbit_visual"):
			st.orbit_visual.draw_body(buf, self, pos, st.look.accent)
			continue
		if _is_magic_missile(part) and st.look.native == "arcane":
			_draw_magic_missile(buf, _missile_position(part), dir, part, st.look.accent)
			continue
		if st.look.native == "lightning":
			_draw_lightning_body(buf, pos, dir, st.family, sc, st)
			continue
		if st.look.native == "plague":
			continue       # plague body is goo: accumulate_water
		if st.look.native == "earth":
			vfx.elements.body(buf, pos, dir, EARTH_BODY[st.family], BODY.earth, RIM[st.look.accent] if st.look.accent != "" else null, true, sc)
			if st.family != "spear":
				vfx.elements.spx(buf, roundi(pos.x) + 1, roundi(pos.y), BODY.earth[3])
			continue
		if st.look.native == "life":
			vfx.elements.body(buf, pos, dir, LIFE_BODY[st.family], BODY.life, RIM[st.look.accent] if st.look.accent != "" else null, true, sc)
			continue
		if st.look.native == "water":
			if st.family == "spear":
				vfx.elements.body(buf, pos, dir, {"t": "diamond", "a": 8.0, "b": 1.4}, BODY.water, null, false, sc)
			continue       # drop body is goo: accumulate_water
		if st.look.native == "ice":
			if _is_ice_blast(part):
				_draw_ice_blast_shard(buf, pos, dir, part, st.look.accent)
				continue
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

## Meteor Shower: the rock falls on game time (it must land with the real impact), wrapped in
## flames with a smoky tail; the volume that follows owns the explosion.
const METEOR_FALL := 0.65   # seconds the rock is in the air; the mark shows from the cast

func _meteor_fall(part, st: Dictionary, target: Vector2, dt: float) -> void:
	st.age = float(part.age)
	st.life = float(part.total_life())
	if float(st.age) < float(st.life) - METEOR_FALL:
		return
	var k: float = _meteor_k(st)
	var rock: Vector2 = target + Vector2(st.sky) * (1.0 - k)
	var vel: Vector2 = -Vector2(st.sky) / METEOR_FALL * vfx.fx_speed * maxf(0.1, 2.0 * sqrt(k))
	var scale := clampf(float(st.r) / 8.0, 0.8, 1.5)
	st.body_acc = float(st.get("body_acc", 0.0)) + 4.0 * dt * 60.0
	while st.body_acc >= 1.0:
		st.body_acc -= 1.0
		var ang := randf() * TAU
		var d := sqrt(randf()) * 3.0 * scale
		vfx.flame(null, rock + Vector2(cos(ang), sin(ang)) * d - vel.normalized() * randf() * 4.0 * scale,
			{"heat": 0.55, "rise": 6.0 + randf() * 8.0, "life": 0.18 + randf() * 0.2, "round": true, "avx": vel.x * 0.2, "avy": vel.y * 0.2})
	if randf() < 0.5 * dt * 60.0:
		vfx.puff(rock.x - vel.normalized().x * 5.0, rock.y - vel.normalized().y * 5.0)

## 0 when the rock leaves the sky, 1 when it lands.
func _meteor_k(st: Dictionary) -> float:
	var progress := clampf((float(st.age) - (float(st.life) - METEOR_FALL)) / METEOR_FALL, 0.0, 1.0)
	return progress * progress

## Beams (sandbox drawBeams): bands across the true width; arcane is a white core in blue with an
## orb where it stops, a piercing (prism) beam is rainbow bands that shift along.
func _beam_step(part, st: Dictionary, pos: Vector2, dt: float) -> void:
	if str(part.cast.plan.get("id", "")) == "focus_ray" and not is_hostile(part):
		return
	var end: Vector2 = pos + Vector2(part.beam_end) / WPS
	var pierce: bool = bool(part.def.get("limits", {}).get("beam_piercing", false))
	if pierce:
		if randf() < 0.4 * dt * 60.0:
			var t := randf()
			var at := pos.lerp(end, t)
			vfx.spark(at.x, at.y, (randf() - 0.5) * 20.0, (randf() - 0.5) * 20.0, 0.3, [RAINBOW[randi() % 6], RAINBOW[randi() % 6]])
	elif randf() < 0.3 * dt * 60.0:
		var pal: Array = SPARK.get(st.look.native, SPARK.arcane)
		vfx.spark(end.x, end.y, (randf() - 0.5) * 30.0, (randf() - 0.5) * 30.0, 0.25, pal)

func _draw_beam(buf: PackedByteArray, part, st: Dictionary) -> void:
	var el = vfx.elements
	var a: Vector2 = part.global_position / WPS
	var b: Vector2 = a + Vector2(part.beam_end) / WPS
	var d: Vector2 = (b - a)
	if d.length() < 0.5:
		return
	var n: Vector2 = d.normalized().orthogonal()
	var age: float = float(part.age)
	var k: float = minf(1.0, minf(age / 0.1, (float(part.total_life()) - age) / 0.15))
	var hw: int = maxi(1, roundi(float(part.geo("width", 24.0)) * 0.5 / WPS * k))
	var pierce: bool = bool(part.def.get("limits", {}).get("beam_piercing", false))
	var pal: Array = SPARK.get(st.look.native, SPARK.arcane)
	for o in range(-hw, hw + 1):
		var c: Color
		if pierce:
			c = Color.WHITE if o == 0 else RAINBOW[posmod(o + 3 + (vfx._steps >> 2), 6)]
		else:
			c = pal[0] if o == 0 else (pal[1] if absi(o) < hw else pal[3])
		if str(part.cast.plan.get("id", "")) == "prism_ray":
			var edge := float(absi(o)) / float(hw)
			c.a = 1.0 if o == 0 else (0.65 if absi(o) == hw else lerpf(0.85, 0.24, edge))
		el.line(buf, a + n * o, b + n * o, c)
	# (no orb at the tip: playtest called it "the dumb pixel thing"; the tip sparks carry the contact)

## Cross Blade: a four-armed blade spinning at the true radius, steel with a bright edge.
func _draw_blade(buf: PackedByteArray, pos: Vector2, part) -> void:
	var k: float = vfx.K
	var radius: float = float(part.geo("radius", 33.6)) / WPS * k
	var center := pos * k
	var returning: bool = int(part.phase) >= 2
	var spin: float = float(part.age) * 16.0
	var polygon := PackedVector2Array([Vector2(0.05, -0.12), Vector2(0.42, -0.30), Vector2(0.96, -0.12), Vector2(0.72, 0.20), Vector2(0.30, 0.27), Vector2(0.08, 0.13)])
	var bounds := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0).intersection(Rect2(Vector2(vfx._origin), Vector2(vfx._size)))
	for y in range(floori(bounds.position.y), ceili(bounds.end.y)):
		for x in range(floori(bounds.position.x), ceili(bounds.end.x)):
			var local := (Vector2(x, y) + Vector2.ONE * 0.5 - center) / radius
			var distance := local.length()
			if distance > 1.0:
				continue
			var angle := fposmod(local.angle() - spin + PI * 0.25, PI * 0.5) - PI * 0.25
			var q := Vector2(cos(angle), sin(angle)) * distance
			var color := Color.TRANSPARENT
			if distance < 0.19:
				color = Color("#ccebf1") if distance < 0.10 else Color("#40546d")
			elif Geometry2D.is_point_in_polygon(q, polygon):
				color = Color("#718ca9") if q.y > 0.01 else Color("#c4d7e4")
				var edge := Geometry2D.get_closest_point_to_segment(q, polygon[1], polygon[2])
				if q.distance_to(edge) * radius < 0.85:
					color = Color("#eeffff") if returning else Color("#e2f4ff")
				elif q.y > 0.10:
					color = Color("#4d6484")
			elif distance > 0.71 and distance < 0.96 and angle < -0.14:
				var strength := clampf((angle + PI * 0.25) / 0.62, 0.0, 1.0)
				color = Color("#9bd8ee") if returning else Color("#89abc6")
				color.a = strength * (0.43 if returning else 0.22)
			if returning and color.a > 0.8:
				color = color.lerp(Color("#c3f3ff"), 0.19)
			if color.a > 0.001:
				_missile_pixel(buf, x, y, color)

## Infestation: infected hosts bubble on their bodies (see-through, so the host stays readable);
## resting spores pop now and then.
func _infection_step(part, st: Dictionary, dt: float) -> void:
	var inf = part.infection
	if inf == null:
		return
	if not st.has("infection_wakes"):
		st.infection_wakes = {}
		st.infection_pulses = {}
		st.infection_hosts = {}
	var active_links: Dictionary = {}
	for l in inf.links:
		active_links[l.id] = true
		var wake: Array = st.infection_wakes.get(l.id, [])
		for sample in wake:
			sample.age += dt
		wake = wake.filter(func(sample): return sample.age < 0.16)
		var point: Vector2 = Vector2(l.position) / WPS + Vector2(0, -3.0)
		if wake.is_empty() or Vector2(wake.back().pos).distance_to(point) >= 0.45:
			wake.append({"pos": point, "age": 0.0})
		while wake.size() > 12:
			wake.pop_front()
		st.infection_wakes[l.id] = wake
	for id in st.infection_wakes.keys():
		if not active_links.has(id):
			st.infection_wakes.erase(id)
	var active_hosts: Dictionary = {}
	for h in inf.hosts:
		active_hosts[h.id] = true
		if not st.infection_hosts.has(h.id):
			st.infection_pulses[h.id] = 0.18
	for id in st.infection_pulses.keys():
		if not active_hosts.has(id):
			st.infection_pulses.erase(id)
		else:
			st.infection_pulses[id] = maxf(0.0, float(st.infection_pulses[id]) - dt)
	st.infection_hosts = active_hosts

## Earth Shield eruption: stone spikes burst up along the growing cone front (earth nova kit),
## dust thrown outward; other looks spray their sparks along the front.
func _eruption_step(part, st: Dictionary, pos: Vector2, dt: float) -> void:
	if part.done:
		return
	var r: float = float(part.front) / WPS
	var half: float = deg_to_rad(float(part.def.get("geometry", {}).get("angle", 100.0))) * 0.5
	var base: float = Vector2(part.direction).angle()
	var n := maxf(1.0, r * half * 2.0 * 0.06) * dt * 60.0
	while n > 0.0:
		if n < 1.0 and randf() > n:
			break
		n -= 1.0
		var a := base + (randf() * 2.0 - 1.0) * half
		var p := pos + Vector2(cos(a), sin(a)) * r * (0.8 + randf() * 0.2)
		if st.look.native == "earth":
			vfx.elements.crystal(p.x, p.y, 4.0 + randf() * 5.0, 0.35 + randf() * 0.3, EAR.body)
			if randf() < 0.4:
				vfx.elements.dust(p.x, p.y, cos(a) * 16.0, sin(a) * 9.0)
		else:
			var pal: Array = SPARK.get(st.look.native, SPARK.arcane)
			vfx.spark(p.x, p.y, cos(a) * 20.0, sin(a) * 20.0, 0.3, pal)

# ------------------------------------------------------------------ props: spell objects the engine does not own
# Healing seeds (Life Bolt, Soul Bloom) and Earth Shield's stored charges are gameplay nodes of
# their own; they register here and skip their placeholder drawing while the layer is up.

const SEED_STEM := [Color("#7ab24a"), Color("#4e823a")]
# Earth Shield charge: a small pebble circling the wizard (playtest: one big rock on his head looked goofy).
const STONE := [
	".ab",
	"abc",
	"bcd",
]

func prop_added(node, kind: String) -> void:
	_props[node.get_instance_id()] = {"node": weakref(node), "kind": kind}

func shield_charge_ended(node, index: int, direction: Vector2) -> void:
	var at: Vector2 = (node.global_position + direction * 30.0) / WPS
	var origin: Vector2 = _stone_at(node, index, node.global_position / WPS) if index < 12 else at
	if direction.is_zero_approx():
		if index < 12:
			for i in 3:
				vfx.chunk(origin.x, origin.y, float(i - 1) * 2.0, 2.0, 3.0, EAR.debris, 0.3, 1)
		return
	_shield_fractures.append({"origin": origin, "at": at, "direction": direction, "age": 0.0})
	var count := 2 if vfx.reduced_effects else 4
	for i in count:
		var velocity := direction.rotated((float(i) - float(count - 1) * 0.5) * 0.2) * (25.0 + i * 4.0)
		vfx.chunk(at.x, at.y, velocity.x, velocity.y, 17.0 + i * 3.0, EAR.debris, 0.38, 1)

func _draw_shield_fractures(buf: PackedByteArray) -> void:
	var el = vfx.elements
	for fracture in _shield_fractures:
		var age: float = fracture.age
		var direction: Vector2 = fracture.direction
		var tangent := direction.orthogonal()
		var at: Vector2 = fracture.origin.lerp(fracture.at, minf(age / 0.04, 1.0))
		var split := maxf(0.0, age - 0.07) / 0.25
		var alpha := 1.0 - split
		for side in [-1, 1]:
			var centre: Vector2 = at + tangent * side * (1.5 + split * 5.0) + direction * split * 11.0
			for row in 3:
				var a: Vector2 = centre + tangent * side * row
				var b: Vector2 = a + direction * (2.0 if row < 2 else 1.0)
				el.line(buf, a - direction, b, Color(EAR.body[3], alpha))
				el.line(buf, a, b, Color(EAR.body[1 if row < 2 else 2], alpha))
			el.line(buf, centre + direction, centre + direction * 2.0 + tangent * side, Color(EAR.body[0], alpha))
		if age > 0.03 and age < 0.12:
			el.line(buf, at - tangent * 2.0, at + direction, EAR.debris[0])
			el.line(buf, at + direction, at + tangent * 2.0, EAR.debris[0])

func presents_prop(node) -> bool:
	return enabled and _props.has(node.get_instance_id())

## One-off moments on props and the player: a heal, a seed picked up, a charge spent on a block.
func prop_burst(kind: String, world_pos: Vector2, size: float = 1.0) -> void:
	if not enabled:
		return
	var at := world_pos / WPS
	var el = vfx.elements
	match kind:
		"life", "regeneration":
			var pulse = preload("res://scripts/vfx/HealingPulse.gd").new()
			pulse.gentle = kind == "regeneration"
			pulse.visual_size = clampf(size, 0.6, 2.0)
			vfx.add_child(pulse)
			pulse.global_position = world_pos
		"heal":
			# Small and quick: heals arrive often (Regeneration, seeds), the cast itself blooms bigger.
			var s := clampf(size, 0.6, 2.0)
			for i in roundi(7 * s):
				var a := randf() * TAU
				el.leaf(at.x + cos(a) * 3.0, at.y - 3.0, cos(a) * 6.0, -14.0 - randf() * 10.0, LIFE.petal if randf() < 0.4 else LIFE.leaf, 0.7 + randf() * 0.4)
			for i in roundi(5 * s):
				el.mote(at.x + (randf() - 0.5) * 7.0, at.y - 3.0 - randf() * 5.0, 0.0, -9.0 - randf() * 6.0, [LIFE.petal[2], LIFE.leaf[0], LIFE.leaf[1]], 0.6, 0.0, 3.0)
			vfx.ring(at.x, at.y, 6.0 * s, 0.22, [LIFE.petal[2], LIFE.leaf[0], LIFE.leaf[1]])
		"life_bolt_seed":
			for i in 3:
				var angle := float(i) / 3.0 * TAU
				var offset := Vector2.from_angle(angle) * 5.0
				el.mote(at.x + offset.x, at.y - 2.0 + offset.y * 0.65, -offset.x / 0.24, -offset.y * 0.65 / 0.24, [Color("#eaffdf"), Color("#a4e8b7"), Color("#69b68b")], 0.24, 0.0, 0.0)
		"seed":
			_life_contact(at.x, at.y)
			vfx.ring(at.x, at.y, 5.0, 0.2, [LIFE.petal[2], LIFE.leaf[0]])
		"block":
			_earth_contact(at.x, at.y)
			for i in 6:
				var a2 := randf() * TAU
				vfx.chunk(at.x + cos(a2) * 4.0, at.y + sin(a2) * 3.0, cos(a2) * 26.0, sin(a2) * 18.0, 40.0 + randf() * 30.0, EAR.debris, 0.9, 2 if randf() < 0.4 else 1)
			vfx.flash(at.x, at.y, 2.0, 0.05, EAR.body[0])

func _step_props(dt: float) -> void:
	for id in _props.keys():
		var pr: Dictionary = _props[id]
		var node = pr.node.get_ref()
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			_props.erase(id)
			continue
		var at: Vector2 = node.global_position / WPS
		match pr.kind:
			"seed", "life_bolt_seed":
				if randf() < 0.06 * dt * 60.0:
					vfx.elements.mote(at.x + (randf() - 0.5) * 4.0, at.y - 3.0, 0.0, -6.0, [LIFE.petal[2], LIFE.leaf[0]], 0.6, 0.0, 2.0)
			"shield":
				for i in mini(node.charges.size(), 12):
					if randf() < 0.015 * dt * 60.0:
						var q := _stone_at(node, i, at)
						vfx.elements.dust(q.x, q.y + 2.0, (randf() - 0.5) * 4.0, 2.0)

func _stone_at(node, index: int, centre: Vector2) -> Vector2:
	var count := maxi(1, mini(node.charges.size(), 12))
	var age: float = float(node.age)
	# The pebbles orbit (never parked over the head) on a flattened ring around the body.
	var angle := index * TAU / count + age * 1.6
	var r := 42.0 + 2.0 * sin(age * 2.0 + index)
	return centre + Vector2(cos(angle) * r, sin(angle) * r * 0.55 + 4.0) / WPS

func _draw_life_bolt_seed(buf: PackedByteArray, at: Vector2, node) -> void:
	var el = vfx.elements
	var radius := float(node.radius) / WPS
	var count := maxi(12, roundi(radius * 2.5))
	for i in count:
		var angle := float(i) / count * TAU
		el.spx(buf, roundi(at.x + cos(angle) * radius), roundi(at.y + sin(angle) * radius), Color("#87aa78"))
	var x := roundi(at.x)
	var y := roundi(at.y)
	var grow := clampf(float(node.presentation_age) / 0.24, 0.0, 1.0)
	var height := 2 + roundi(grow * 4.0)
	for j in height:
		el.spx(buf, x, y - j, Color("#77bc82"))
	for sign_value in [-1, 1]:
		el.spx(buf, x + sign_value, y - height + 2, Color("#b4e7a7"))
		el.spx(buf, x + sign_value * 2, y - height + 3, Color("#7eca8e"))
		el.spx(buf, x + sign_value, y - height + 3, Color("#8dd79b"))
	el.spx(buf, x, y - height, Color("#edffd0"))
	el.spx(buf, x - 1, y - height + 1, Color("#b3efbc"))
	el.spx(buf, x, y - height + 1, Color("#e7ffdc"))
	el.spx(buf, x + 1, y - height + 1, Color("#b3efbc"))

func _draw_props(buf: PackedByteArray) -> void:
	if not enabled:
		return
	_draw_shield_fractures(buf)
	var el = vfx.elements
	for pr in _props.values():
		var node = pr.node.get_ref()
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var at: Vector2 = node.global_position / WPS
		match pr.kind:
			"seed", "life_bolt_seed":
				var left: float = float(node.remaining)
				if left < 1.5 and (vfx._steps >> 2) % 2 == 0:
					continue          # blinking out
				if pr.kind == "life_bolt_seed":
					_draw_life_bolt_seed(buf, at, node)
					continue
				# pickup range: a quiet dashed ring at the real radius
				el.draw_nova(buf, at.x, at.y, float(node.radius) / WPS, LIFE.rim)
				# sprout: stem, two leaves, a bud that opens and closes
				var X := roundi(at.x)
				var Y := roundi(at.y)
				el.spx(buf, X, Y, SEED_STEM[1])
				el.spx(buf, X, Y - 1, SEED_STEM[0])
				el.spx(buf, X - 1, Y - 1, LIFE.leaf[1])
				el.spx(buf, X + 1, Y - 2, LIFE.leaf[0])
				el.spx(buf, X, Y - 2, SEED_STEM[0])
				var open := sin(float(Time.get_ticks_msec()) * 0.006 + float(X)) > 0.0
				el.spx(buf, X, Y - 3, LIFE.petal[1])
				if open:
					el.spx(buf, X - 1, Y - 3, LIFE.petal[0])
					el.spx(buf, X + 1, Y - 3, LIFE.petal[0])
					el.spx(buf, X, Y - 4, LIFE.petal[2])
			"shield":
				var cols := {"a": EAR.body[0], "b": EAR.body[1], "c": EAR.body[2], "d": EAR.body[3]}
				for i in mini(node.charges.size(), 12):
					var remaining: float = float(node.charges[i].get("remaining", 1.0))
					if remaining < 1.0 and (vfx._steps >> 2) % 2 == 0:
						continue      # about to crumble
					var q := _stone_at(node, i, at)
					var bob := sin(float(node.age) * 3.0 + i) * 0.6
					for j in STONE.size():
						var row: String = STONE[j]
						for k in row.length():
							if row[k] == ".":
								continue
							el.spx(buf, roundi(q.x) + k - 1, roundi(q.y + bob) + j - 1, cols[row[k]])

