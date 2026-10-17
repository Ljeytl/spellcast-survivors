extends Node2D
## Chunky-magic VFX service (autoload "Vfx"). See docs/VFX_PORT_BRIEF.md.
##
## Coordinates: the simulation runs in SANDBOX UNITS (1 su = WPS world px), so
## every number in tools/vfx-reference/spell_vfx_sandbox.html ports verbatim.
## The sandbox frame is 192 su wide; the game's view is 1280 world px wide at
## 1080p, hence WPS = 1280 / 192.
##
## Rendering: effects are rasterized onto a world-anchored grid of CELL world px
## (CELL 4 = 2x2 art px = 6 screen px at 1080p). K = cells per su. Shapes keep
## the sandbox's proportions; only the pixels get finer. One-pixel details
## (embers, sparks) stay one cell: the "many tiny" end of the size range.
##
## Two layers in world space (the camera world-locks them; z orders them):
##   ground (GROUND_Z): field floors + rims (vfx_ground.gdshader), floor light,
##                      decals  -> under actors
##   air    (AIR_Z):    heat field, smoke, embers (vfx_heat.gdshader) -> over actors
##
## Effect motion steps every frame by default ("on ones"); on_twos steps at
## STEP_HZ instead (console "vfx twos"). Ones won the side-by-side comparison. Hit-stop freezes only this simulation.

var spirit_form_override := "auto"
var impact_light

const CELL := 4.0
const WPS := 1280.0 / 192.0          # world px per sandbox unit
const K := WPS / CELL                # cells per sandbox unit
const SANDBOX_SCALE := 1.0 / K       # kept for callers: su per cell
const MARGIN := 10                   # cells of slack around the view (grid re-places only when the view nears its edge)
const GROUND_Z := -1
const AIR_Z := 50
const STEP_HZ := 30.0                # twos
const ONES_HZ := 60.0                # ones: animation "on ones" is 60 Hz, also on 120 Hz displays (half the cost there)
# The reference sandbox advances a fixed 1/60 s per animation frame; on the
# 120 Hz displays it was tuned on, its effects ran at twice their nominal speed.
# Effect motion (flames, embers, smoke, debris, rings) runs at that speed here.
# Gameplay objects (projectiles, areas) are never affected.
const FX_SPEED := 2.0
const MAX_FLAMES := 1000             # web budget, see docs/VFX_PORT_BRIEF.md
const MAX_FLAMES_REDUCED := 400
const MAX_FIELDS := 32
const LIGHT_SU := 4.0                # sandbox floor-light grid: 4 su per light cell

const HEAT_SHADER := preload("res://shaders/vfx_heat.gdshader")
const GROUND_SHADER := preload("res://shaders/vfx_ground.gdshader")
const DECAL_SHADER := preload("res://shaders/vfx_decal.gdshader")
const PRESENTER := preload("res://scripts/vfx/VfxPresenter.gd")
const ELEMENTS := preload("res://scripts/vfx/VfxElements.gd")
const SHADOW := Color("#16141b")
const FROST := [Color("#2a3c50"), Color("#3d5a78")]
const PUDDLE := [Color("#1b3050"), Color("#2a4f80")]
const STAIN := [Color("#16201a"), Color("#1f3322")]

# Fire material (sandbox MAT_SRC.fire). Thresholds descending.
const FIRE_HEAT := [[1.6, Color("#fff7d6")], [1.1, Color("#ffd54a")], [0.7, Color("#ff8a1f")], [0.35, Color("#e0401c")], [0.12, Color("#7a1f14")]]
# The sandbox halo (#3a1a12) is darker than flame but lighter than its near-black
# floor. On the game's grass it read as dirt, so it is a warm translucent tint.
const FIRE_GLOW := Color("#7a1f14")   # solid deep-red fringe; the sandbox #3a1a12 read as dirt on grass, a translucent tint read as haze
const FIRE_EMBER := [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#e0401c")]
const FIRE_SMOKE := [Color("#5b4258"), Color("#3f2c44")]   # plum, not gray
const FIRE_SCORCH := [Color("#2b2117"), Color("#3e3022")]   # burnt-earth browns: black read as a hole on grass
const FIRE_RIM := [Color("#ff8a1f"), Color("#ffd54a")]
const FIRE_FLOOR := [Color("#2a1416"), Color("#3a1512"), Color("#5a1a12")]
# Floor light: warm tints over whatever ground is there (sandbox lit1/lit2).
const FIRE_LIT := [Color(1.0, 0.55, 0.2, 0.1), Color(1.0, 0.6, 0.22, 0.2)]   # faint: stronger read as yellow haze on grass

# Field floor looks, indexed by field "look" (0 = fire). Ground shader style:
# 0 = fire floor (sandbox drawAreas), 1 = element floor (sandbox drawEFields).
const FIELD_LOOKS := [
	{"name": "fire", "style": 0},
	{"name": "ice", "style": 1, "floor": ["#1c2433", "#233247", "#2f4560"], "rim": ["#8fd3ee", "#ffffff"]},
	{"name": "lightning", "style": 1, "floor": ["#1c1a2c", "#211e38", "#2a2550"], "rim": ["#8fb2ff", "#ffffff"]},
	{"name": "water", "style": 1, "floor": ["#151d2e", "#192842", "#20385e"], "rim": ["#4fb2f0", "#e8f8ff"]},
	{"name": "life", "style": 1, "floor": ["#19221a", "#1f2e1e", "#2a4026"], "rim": ["#7fcf4a", "#d4f58a"]},
	{"name": "arcane", "style": 1, "floor": ["#1a1830", "#201d3e", "#2a2656"], "rim": ["#8fa8f5", "#e2f6ff"]},
	{"name": "plague", "style": 1, "floor": ["#17201a", "#1d2c1f", "#25402a"], "rim": ["#6fd04a", "#c4f383"]},
	{"name": "earth", "style": 1, "floor": ["#1e1a18", "#262019", "#30281c"], "rim": ["#c9a46a", "#e8dcc0"]},
]
static func field_look(name: String) -> int:
	for i in FIELD_LOOKS.size():
		if FIELD_LOOKS[i].name == name:
			return i
	return 0

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var reduced_effects := false
var on_twos := false                 # ones by default: picked over twos in the arena side-by-side (Oct 2026)
var fx_speed := FX_SPEED
var wind := 0.0                      # su/s^2 scale as in the sandbox; visual only
var stats := {"flames": 0, "sim_ms": 0.0, "draw_ms": 0.0, "cells": 0}

var _t := 0.0
var _step_acc := 0.0
var _steps := 0
var _bench := {}
var _stop := 0                       # VFX-only hit-stop, in steps
var _active := false
var _origin := Vector2i.ZERO         # world cell of texel (0,0)
var _size := Vector2i.ZERO

# Flames: interleaved, stride FS, all in sandbox units.
enum { AX, AY, LX, LY, WX, WY, VX, VY, DVX, DX, DY, RISE, AGE, LIFE, HEAT, GX, SMALL, ROUND, FS }
var _fd := PackedFloat32Array()
var _f_anchor: Array = []
var _f_count := 0

var _embers: Array = []              # [x, y, vx, vy, age, life]   (su)
var _smoke: Array = []               # [x, y, vx, rise, age, life, s]
var _fields: Array = []              # {x, y, r, age, life, acc}    (su)
var _decals: Array = []              # [sprite, material, age, life]
var _sparks: Array = []              # [x, y, vx, vy, age, life, palette]
var _flashes: Array = []             # [x, y, r, age, life, color]
var _stars: Array = []               # [x, y, size, age, life, points, color]
var _rings: Array = []               # [x, y, max, age, life, palette, seed]
var _debris: Array = []              # [x, y, z, vx, vy, vz, palette, age, life, size, bounced]
var presenter                        # VfxPresenter: spell-engine events -> looks
var elements                         # VfxElements: motes, shards, crystals (non-fire looks)

var _heat := PackedFloat32Array()
var _water := PackedFloat32Array()     # goo fields, 4 per cell: water air, water ground, plague air, plague ground
var _water_used := false
var _wave = null                       # [origin, dir, front, half, hw, fade] su, set by the presenter each frame
var _under := PackedByteArray()
var _over := PackedByteArray()
var _ground := PackedByteArray()
var _light := PackedFloat32Array()
var _light_origin := Vector2i.ZERO
var _light_size := Vector2i.ZERO

var _ground_layer: Sprite2D
var _decal_root: Node2D
var _air_layer: Sprite2D
var _tex := {}


## Flame splat footprints for sandbox radius 0, 1, 2. Each sandbox pixel maps
## to K cells, so a radius-r flame covers about (r + 0.5) * K cells. Footprints
## are tall ellipses biased upward (flames rise, so tips stretch) with a ragged
## edge, in FLAME_VARIANTS shapes per radius; each particle keeps one shape.
const FLAME_ASPECT := 1.5          # height / width
const FLAME_RAGGED := 0.55         # edge irregularity
const FLAME_VARIANTS := 6
# Particle density relative to the sandbox (embers and smoke coming off flames).
const EMBER_RATE := 3.0
const SMOKE_RATE := 1.5
const TIP_EMBERS := 0.35        # embers per second shed by each hot flame tip
static var DISK_XY: Array = _make_disks()   # [r (+3 for round)][variant] -> PackedInt32Array of x, y pairs
var _disks: Array = []
var _disk_w := -1

static func _make_disks() -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# 0..2: tall rising tongues (fields, burning). 3..5: round, for flames that
	# travel sideways (projectile trails), where tall shapes made trails fat.
	for idx in 6:
		var r := idx % 3
		var round_shape := idx >= 3
		var variants := []
		var rx := (r + 0.5) * K * (1.0 if round_shape else 0.85)
		var ry := rx * (1.0 if round_shape else FLAME_ASPECT)
		for v in FLAME_VARIANTS:
			var offs := PackedInt32Array()
			var R := ceili(ry + 1.0)
			var seed := rng.randi() & 0xFFFF
			for qy in range(-R, R + 1):
				for qx in range(-R, R + 1):
					# centre sits low: more of the shape extends upward
					var ny := (qy + (0.0 if round_shape else ry * 0.2)) / ry
					var nx := qx / rx
					var edge := 1.0 + (hs(qx + seed, qy * 7 + seed) - 0.5) * (0.3 if round_shape else FLAME_RAGGED)
					if nx * nx + ny * ny <= edge:
						offs.append_array([qx, qy])
			if offs.is_empty():
				offs.append_array([0, 0])
			variants.append(offs)
		out.append(variants)
	return out

func _ready():
	reduced_effects = preload("res://scripts/EffectPreferences.gd").reduced()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	presenter = PRESENTER.new(self)
	elements = ELEMENTS.new(self)
	impact_light = preload("res://scripts/vfx/ImpactLight.gd").new()
	impact_light.owner_vfx = self
	add_child(impact_light)
	var gmat := ShaderMaterial.new()
	gmat.shader = GROUND_SHADER
	var fc := PackedColorArray(FIRE_FLOOR)
	var rc := PackedColorArray(FIRE_RIM)
	for look in FIELD_LOOKS.slice(1):
		for h in look.floor:
			fc.append(Color(h))
		for h in look.rim:
			rc.append(Color(h))
	fc.resize(24)
	rc.resize(16)
	gmat.set_shader_parameter("floor_cols", fc)
	gmat.set_shader_parameter("rim_cols", rc)
	gmat.set_shader_parameter("lit1", FIRE_LIT[0])
	gmat.set_shader_parameter("lit2", FIRE_LIT[1])
	gmat.set_shader_parameter("k", K)
	gmat.set_shader_parameter("light_cell", LIGHT_SU * K)
	_ground_layer = _make_layer(GROUND_Z, gmat)
	_decal_root = Node2D.new()
	add_child(_decal_root)
	var mat := ShaderMaterial.new()
	mat.shader = HEAT_SHADER
	var th := PackedFloat32Array()
	var cols := PackedColorArray()
	for b in FIRE_HEAT:
		th.append(b[0]); cols.append(b[1])
	mat.set_shader_parameter("thresholds", th)
	mat.set_shader_parameter("colors", cols)
	mat.set_shader_parameter("glow", FIRE_GLOW)
	_air_layer = _make_layer(AIR_Z, mat)
	_set_visible(false)

func _make_layer(z: int, mat: ShaderMaterial) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.z_index = z
	s.z_as_relative = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(CELL, CELL)
	s.material = mat
	add_child(s)
	return s

func _set_visible(v: bool):
	_active = v
	_decal_root.visible = v
	_ground_layer.visible = v
	_air_layer.visible = v

## Removes every effect. Called when the world changes (scene switch).
func clear():
	if impact_light:
		impact_light.clear()
	for child in get_children():
		if child.is_in_group("steam_clouds") or child.is_in_group("lightning_visuals") or child.is_in_group("healing_visuals") or child.is_in_group("infection_visuals"):
			child.queue_free()
	if presenter:
		presenter.clear_transients()
	_fd.resize(0)
	_f_anchor.clear()
	_f_count = 0
	_embers.clear(); _smoke.clear(); _fields.clear()
	if elements:
		elements.clear()
	_sparks.clear(); _flashes.clear(); _stars.clear(); _rings.clear(); _debris.clear()
	for d in _decals:
		d[0].queue_free()
	_decals.clear()

# ------------------------------------------------------------------ coords

static func world_to_su(p: Vector2) -> Vector2:
	return p / WPS

static func su_to_world(s: Vector2) -> Vector2:
	return s * WPS

## World position -> grid cell (float). Kept for tests and callers.
static func world_to_cell(p: Vector2) -> Vector2:
	return p / CELL

func _visible_world_rect() -> Rect2:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var r := vp.get_visible_rect()
	var a := inv * r.position
	var b := inv * r.end
	return Rect2(a, b - a).abs()

# ------------------------------------------------------------------ juice

## Freezes the VFX simulation only, for `frames` 60 fps frames. Gameplay time is never touched.
func hitstop(frames: int):
	_stop = max(_stop, ceili(frames * STEP_HZ / 60.0) if on_twos else frames)

# ------------------------------------------------------------------ noise (sandbox hs / vn)

static func hs(x: int, y: int) -> float:
	var n := (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(n ^ (n >> 16)) / 4294967296.0

static func vn(x: float, y: float) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var xf := x - xi
	var yf := y - yi
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := yf * yf * (3.0 - 2.0 * yf)
	var a := hs(xi, yi)
	var b := hs(xi + 1, yi)
	var c := hs(xi, yi + 1)
	var d := hs(xi + 1, yi + 1)
	return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v

# 256x256 lattice of hs() so per-particle turbulence avoids hashing.
static var LATTICE: PackedFloat32Array = _make_lattice()

static func _make_lattice() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(65536)
	for y in 256:
		for x in 256:
			out[y * 256 + x] = hs(x, y)
	return out

static func vn_fast(x: float, y: float) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var xf := x - xi
	var yf := y - yi
	var u := xf * xf * (3.0 - 2.0 * xf)
	var v := yf * yf * (3.0 - 2.0 * yf)
	var x0 := xi & 255
	var x1 := (xi + 1) & 255
	var y0 := (yi & 255) << 8
	var y1 := ((yi + 1) & 255) << 8
	var a := LATTICE[y0 | x0]
	var b := LATTICE[y0 | x1]
	var c := LATTICE[y1 | x0]
	var d := LATTICE[y1 | x1]
	return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v

func _turb(x: float, y: float, s: float) -> float:
	return (vn_fast(x * 0.12, y * 0.12 + _t * 3.0) - 0.5) * s

static func _drag(v: float, dt: float, k: float) -> float:
	return v * pow(k, dt * 60.0)

# ------------------------------------------------------------------ particles (sandbox units)

## Spawns one flame (sandbox flame()). anchor: Node2D to follow, or null.
## `at` is in sandbox units; o keys: lx, ly, vx, vy, inh, grip, rise, life, heat, small.
func flame(anchor, at: Vector2, o: Dictionary = {}):
	if _f_count >= (MAX_FLAMES_REDUCED if reduced_effects else MAX_FLAMES):
		return
	var ax := at.x
	var ay := at.y
	var avx := 0.0
	var avy := 0.0
	if anchor is Node2D:
		var c := world_to_su((anchor as Node2D).global_position)
		ax = c.x; ay = c.y
		if "velocity" in anchor:
			var vel: Vector2 = anchor.velocity / WPS
			avx = vel.x; avy = vel.y
	if o.has("avx"):
		avx = o.avx; avy = o.avy
	var lx: float = o.get("lx", 0.0)
	var ly: float = o.get("ly", 0.0)
	var inh: float = o.get("inh", 0.0)
	_fd.append_array(PackedFloat32Array([
		ax, ay, lx, ly, ax + lx, ay + ly,
		o.get("vx", 0.0) + avx * inh, o.get("vy", 0.0) + avy * inh,
		0.0, 0.0, 0.0,
		o.get("rise", 20.0), 0.0, o.get("life", 0.6),
		o.get("heat", 1.2), 0.2 + o.get("grip", 0.0) * 2.8, o.get("small", 0.0), 1.0 if o.get("round", false) else 0.0,
	]))
	_f_anchor.append(anchor if anchor is Node2D else null)
	_f_count += 1

func ember(x: float, y: float, vx: float, vy: float, life: float):
	if _embers.size() < (250 if reduced_effects else 800):
		_embers.append([x, y, vx, vy, 0.0, life])

func puff(x: float, y: float, s: int = 0):
	if _smoke.size() < (80 if reduced_effects else 240):
		_smoke.append([x, y, 0.0, 6.0 + randf() * 5.0, 0.0, 1.6 + randf() * 1.2, s if s > 0 else 2 + randi() % 2])

## Persistent fire field (sandbox field()): dim banded floor, bright rim at the
## true radius, rising flame tongues, embers, smoke. Position/radius in su.
## o.axis (su, half-length vector) makes it a line field (sandbox wall()): a rect
## |along| <= |axis| + r, |across| <= r, with tall flames rising along it.
func field(x: float, y: float, r: float, life: float, o: Dictionary = {}) -> Dictionary:
	var f := {"x": x, "y": y, "r": r, "age": 0.0, "life": life, "acc": 0.0,
		"profile": str(o.get("profile", "default")), "rate": o.get("rate", 1.0), "heat_k": o.get("heat_k", 0.8), "trail": o.get("trail", false),
		"axis": o.get("axis", Vector2.ZERO), "look": int(o.get("look", 0)), "goo": int(o.get("goo", 0))}
	if o.has("style"):
		f.style = int(o.style)   # 2 = smoulder: sparse char floor (a burning trail)
	_fields.append(f)
	if _fields.size() > MAX_FIELDS:
		_fields.pop_front()
	return f

## Scorch decal (sandbox drawDecals), rasterized once into a world-locked sprite;
## the dissolve runs in vfx_decal.gdshader. Position/radius in su.
## inner > 0 leaves the middle clear (a ring: the frost a nova leaves behind).
func scorch(x: float, y: float, r: float, life: float = 6.0, kind: String = "scorch", inner: float = 0.0):
	if _decals.size() >= 40:
		var old = _decals.pop_front()
		old[0].queue_free()
	var seed := randf() * 100.0
	var rc := r * K
	var R := ceili(rc + 3.0 * K)
	var cx := roundi(x * K)
	var cy := roundi(y * K)
	var img := Image.create_empty(2 * R + 1, 2 * R + 1, false, Image.FORMAT_RGBA8)
	for qy in range(-R, R + 1):
		for qx in range(-R, R + 1):
			var X := cx + qx
			var Y := cy + qy
			var dist := Vector2(qx, qy * 1.25).length()
			var edge := rc * (0.7 + 0.55 * vn(X / K * 0.3 + seed, Y / K * 0.3))
			if dist < edge and dist >= edge * inner:
				var c: Color
				if kind == "stain":
					c = STAIN[0] if dist < edge * 0.55 else STAIN[1]
				elif kind == "puddle":
					c = PUDDLE[0] if dist < edge * 0.55 else PUDDLE[1]
				elif kind == "frost":
					# sandbox drawEDecals 'frost': rime with a lighter rim and glints
					c = FROST[1] if dist > edge * 0.6 or hs(X, Y) > 0.8 else FROST[0]
				else:
					c = FIRE_SCORCH[0] if dist < edge * 0.55 else FIRE_SCORCH[1]
				c.a = (BAYER[((Y & 3) << 2) | (X & 3)] + 1) / 17.0
				img.set_pixel(qx + R, qy + R, c)
	var mat := ShaderMaterial.new()
	mat.shader = DECAL_SHADER
	mat.set_shader_parameter("limit", 0.0)   # dithers in after the blast covers it, no black pop
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = ImageTexture.create_from_image(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(CELL, CELL)
	spr.position = Vector2(cx - R, cy - R) * CELL
	spr.z_index = GROUND_Z
	spr.z_as_relative = false
	spr.material = mat
	_decal_root.add_child(spr)
	_decals.append([spr, mat, 0.0, life])

## Spidering scorch where lightning struck (sandbox decal 'spider').
func spider(x: float, y: float, life: float = 5.0):
	var rays := []
	for r in 6:
		var a := randf() * TAU
		var L := 5.0 + randf() * 5.0
		rays.append(elements.jag(x, y, x + cos(a) * L, y + sin(a) * L * 0.8, 1.5))
	path_decal(x, y, rays, [Color("#2a2342"), Color("#2a2342")], life, Color("#14111c"))

## Ground cracks (sandbox crackDecal): n jagged rays of length ~L from the centre.
func crack_decal(x: float, y: float, n: int, L: float, life: float = 6.0, cols: Array = [Color("#0d0b0b"), Color("#3a2e22")]):
	var rays := []
	for i in n:
		var a := float(i) / n * TAU + randf() * 0.5
		rays.append(elements.jag(x, y, x + cos(a) * L * (0.6 + randf() * 0.5), y + sin(a) * L * 0.7 * (0.6 + randf() * 0.5), 1.5))
	path_decal(x, y, rays, cols, life)

## Bakes jagged paths (su) into a dithering decal: sandbox-pixel Bresenham lines,
## first half of each path in cols[0], the rest in cols[1]; optional dark centre.
func path_decal(x: float, y: float, paths: Array, cols: Array, life: float, centre = null):
	if _decals.size() >= 40:
		var old = _decals.pop_front()
		old[0].queue_free()
	var reach := 2.0
	for pts in paths:
		for q in pts:
			reach = maxf(reach, Vector2(q.x - x, q.y - y).length())
	var R := ceili((reach + 2.0) * K)
	var cx := roundi(x * K)
	var cy := roundi(y * K)
	var img := Image.create_empty(2 * R + 1, 2 * R + 1, false, Image.FORMAT_RGBA8)
	var plot := func(X: int, Y: int, c: Color):
		for py in range(floori(Y * K), maxi(floori((Y + 1) * K), floori(Y * K) + 1)):
			for px in range(floori(X * K), maxi(floori((X + 1) * K), floori(X * K) + 1)):
				var ix: int = px - cx + R
				var iy: int = py - cy + R
				if ix >= 0 and iy >= 0 and ix <= 2 * R and iy <= 2 * R:
					var cc := c
					cc.a = (BAYER[((py & 3) << 2) | (px & 3)] + 1) / 17.0
					img.set_pixel(ix, iy, cc)
	for pts in paths:
		var n: int = pts.size()
		for i in range(1, n):
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			var c: Color = cols[0] if i < n / 2.0 else cols[1]
			var x0 := roundi(a.x)
			var y0 := roundi(a.y)
			var x1 := roundi(b.x)
			var y1 := roundi(b.y)
			var dx := absi(x1 - x0)
			var dy := -absi(y1 - y0)
			var sx := 1 if x0 < x1 else -1
			var sy := 1 if y0 < y1 else -1
			var e := dx + dy
			for k in 200:
				plot.call(x0, y0, c)
				if x0 == x1 and y0 == y1:
					break
				var e2 := 2 * e
				if e2 >= dy:
					e += dy
					x0 += sx
				if e2 <= dx:
					e += dx
					y0 += sy
	if centre != null:
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				plot.call(roundi(x) + ox, roundi(y) + oy, centre)
	_add_decal(img, cx - R, cy - R, life)

func _add_decal(img: Image, x0: int, y0: int, life: float):
	var mat := ShaderMaterial.new()
	mat.shader = DECAL_SHADER
	mat.set_shader_parameter("limit", 0.0)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.texture = ImageTexture.create_from_image(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(CELL, CELL)
	spr.position = Vector2(x0, y0) * CELL
	spr.z_index = GROUND_Z
	spr.z_as_relative = false
	spr.material = mat
	_decal_root.add_child(spr)
	_decals.append([spr, mat, 0.0, life])

## One-cell spark with a colour ramp over its life (sandbox sparks).
func spark(x: float, y: float, vx: float, vy: float, life: float, palette: Array):
	if _sparks.size() < (150 if reduced_effects else 500):
		_sparks.append([x, y, vx, vy, 0.0, life, palette])

## Filled flash disk for one or two steps (sandbox flashes). Radius in su.
func flash(x: float, y: float, r: float, life: float = 0.07, color: Color = Color("#fff7d6")):
	_flashes.append([x, y, r, 0.0, life, color])

## Designed impact silhouette: a 4- or 8-point star that pops to 120% and
## settles (principles 2 and 6). Size in su.
func star(x: float, y: float, size: float, life: float, points: int, color: Color):
	_stars.append([x, y, size, 0.0, life, points, color])

## Shockwave ring on the ground: eases out, then breaks into segments instead of
## fading (principles 5 and 6). Radius in su.
func ring(x: float, y: float, max_r: float, life: float, palette: Array):
	_rings.append([x, y, max_r, 0.0, life, palette, randf() * 100.0])

## Debris with z-physics: arcs up, falls, bounces once, settles (sandbox chunk()).
func chunk(x: float, y: float, vx: float, vy: float, vz: float, palette: Array, life: float, size: int = 1):
	if _debris.size() < (60 if reduced_effects else 200):
		_debris.append([x, y, 1.0, vx, vy, vz, palette, 0.0, life, size, false])

## Camera shake through the game's own shaker (respects its reduced-effects setting).
func shake(strength: float):
	if reduced_effects or strength <= 0.0:
		return
	# The live game camera's shaker registers itself (the game is not always current_scene).
	var cs = preload("res://scripts/CameraShake.gd").active
	if cs == null or not is_instance_valid(cs):
		return
	if strength >= 0.6 and cs.has_method("shake_impact"):
		cs.shake_impact(6.0 + strength * 5.0, 0.18 + strength * 0.08)
	elif cs.has_method("shake"):
		cs.shake(clampf(strength * 10.0, 0.0, 6.0), 0.1 + strength * 0.2)

# ------------------------------------------------------------------ spell-engine events (docs/VFX_EVENTS.md)

# Events are ignored while no game camera is up (menus, headless engine tests),
# so nothing piles up off-screen.
func cast_queued(cast) -> void:
	if _active:
		presenter.cast_queued(cast)

func cast_started(cast) -> void:
	if _active:
		presenter.cast_started(cast)

func part_spawned(part) -> void:
	if _active:
		presenter.part_spawned(part)

func part_hit(part, enemy, at: Vector2) -> void:
	if _active:
		presenter.part_hit(part, enemy, at)

func part_finished(part, natural: bool) -> void:
	if _active:
		presenter.part_finished(part, natural)

func part_ticked(_part) -> void:
	pass

## Spell objects outside the engine (healing seeds, Earth Shield charges) and one-off moments
## (heals, pickups, blocks). Props register even while the layer is down, so they are drawn as
## soon as a game camera is up.
func prop_added(node, kind: String) -> void:
	presenter.prop_added(node, kind)

func presents_prop(node) -> bool:
	return _active and presenter.presents_prop(node)

func shield_charge_ended(node, index: int, direction: Vector2 = Vector2.ZERO) -> void:
	if _active and presenter.presents_prop(node):
		presenter.shield_charge_ended(node, index, direction)

## False when the layer is down: the caller shows its own feedback instead.
func prop_burst(kind: String, world_pos: Vector2, size: float = 1.0) -> bool:
	if not _active or not presenter.enabled:
		return false
	presenter.prop_burst(kind, world_pos, size)
	return true

## True when the VFX layer draws this part, so SpellPart skips its placeholder.
func presents(part) -> bool:
	return _active and presenter.presents(part)

# ------------------------------------------------------------------ test effects

## Debug: the sandbox Cinder Field (radius 20 su) at a world point.
func add_test_flame(world_pos: Vector2, radius_world: float = 20.0 * WPS, life: float = 1e9) -> Dictionary:
	var s := world_to_su(world_pos)
	return field(s.x, s.y, radius_world / WPS, life)

func clear_test_flames():
	_fields.clear()

# ------------------------------------------------------------------ update

func _process(delta: float):
	var cam := get_viewport().get_camera_2d()
	if cam == null or not is_instance_valid(cam):
		if _active:
			_set_visible(false)
			clear()
		return
	if not _active:
		_set_visible(true)
	var t0 := Time.get_ticks_usec()
	var stepped := false
	if on_twos:
		_step_acc = minf(_step_acc + delta, 2.0 / STEP_HZ)
		while _step_acc >= 1.0 / STEP_HZ:
			_step_acc -= 1.0 / STEP_HZ
			_tick(1.0 / STEP_HZ)
			stepped = true
	else:
		_step_acc = minf(_step_acc + delta, 3.0 / ONES_HZ)
		while _step_acc >= 1.0 / ONES_HZ - 0.0005:
			_step_acc = maxf(0.0, _step_acc - 1.0 / ONES_HZ)
			_tick(1.0 / ONES_HZ)
			stepped = true
	var t1 := Time.get_ticks_usec()
	# The camera moves every frame, so the grid is re-placed every frame; the
	# effect pixels themselves only change on step frames.
	_render(stepped)
	var t2 := Time.get_ticks_usec()
	stats.flames = _f_count
	stats.sim_ms = (t1 - t0) / 1000.0
	stats.draw_ms = (t2 - t1) / 1000.0
	if not _bench.is_empty():
		_bench_frame(delta)

func _tick(dt: float):
	_steps += 1
	if _stop > 0:
		_stop -= 1
		return
	_step(dt * fx_speed)

signal bench_done(summary: String)

## Measures frame time and VFX cost over `frames` frames; prints and emits the summary.
func bench(frames: int = 300):
	_bench = {"left": frames, "n": 0, "frame": 0.0, "worst": 0.0, "sim": 0.0, "draw": 0.0, "flames": 0}

func _bench_frame(delta: float):
	_bench.n += 1
	_bench.frame += delta
	_bench.worst = maxf(_bench.worst, delta)
	_bench.sim += stats.sim_ms
	_bench.draw += stats.draw_ms
	_bench.flames = maxi(_bench.flames, _f_count)
	_bench.left -= 1
	if _bench.left <= 0:
		var n: int = _bench.n
		var summary := "VFX bench [%s]: %d frames, avg frame %.2f ms (%.0f fps), worst %.2f ms, vfx sim %.2f ms + draw %.2f ms, peak %d flames, %d cells, twos %s" % [
			OS.get_name(), n, _bench.frame * 1000.0 / n, n / maxf(_bench.frame, 0.0001), _bench.worst * 1000.0,
			_bench.sim / n, _bench.draw / n, _bench.flames, stats.cells, str(on_twos)]
		_bench = {}
		print(summary)
		bench_done.emit(summary)

func _update_fields(dt: float):
	var keep: Array = []
	for A in _fields:
		A.age += dt
		if A.age > A.life:
			continue
		keep.append(A)
		var r: float = A.r
		var axis: Vector2 = A.axis
		if axis != Vector2.ZERO:
			_update_line_field(A, axis, dt)
			continue
		if A.look != 0:
			continue          # element fields: their look's presenter emits the particles
		# Sandbox: max(1, n/3) tongues per 60 fps frame, made frame-rate independent.
		var n: float = r * r * 0.0042 * A.rate
		A.acc += maxf(1.0, n / 3.0) * dt * 60.0
		while A.acc >= 1.0:
			A.acc -= 1.0
			var ang := randf() * TAU
			var d := sqrt(randf()) * r * 0.9
			var at := Vector2(A.x + cos(ang) * d, A.y + sin(ang) * d)
			var low: bool = A.get("profile", "") == "cinder"
			var rise := randf_range(9.0, 17.0) if low else randf_range(20.0, 32.0)
			var lf := randf_range(0.28, 0.48) if low else randf_range(0.45, 0.80)
			for j in 3:
				flame(null, at, {"lx": (randf() - 0.5) * 1.5, "ly": randf() - 0.5, "heat": A.heat_k * 0.46,
					"rise": rise * (0.9 + j * 0.18), "life": lf * (1.0 - j * 0.15), "small": 1.0 if j > 0 else 0.0})
		var ne := r * 0.004 * EMBER_RATE * dt * 60.0
		while ne > 0.0:
			if randf() < ne:
				ember(A.x + (randf() - 0.5) * r, A.y + (randf() - 0.5) * r * 0.6, (randf() - 0.5) * 10.0, -(14.0 + randf() * 14.0), 0.8 + randf())
			ne -= 1.0
		if not A.trail and randf() < r * 0.003 * SMOKE_RATE * dt * 60.0:
			puff(A.x + (randf() - 0.5) * r, A.y - 6.0 + (randf() - 0.5) * r * 0.4)
	_fields = keep

## Sandbox updateAreas, kind 'line': len*0.09 tall flames per 60 fps frame
## scattered across the band, heat 1.15, plus embers along the line.
func _update_line_field(A: Dictionary, axis: Vector2, dt: float):
	var r: float = A.r
	var half := axis.length() + r
	var u := axis / axis.length()
	var nrm := Vector2(-u.y, u.x)
	A.acc += 2.0 * half * 0.09 * A.rate * dt * 60.0
	while A.acc >= 1.0:
		A.acc -= 1.0
		var at := Vector2(A.x, A.y) + u * (randf() * 2.0 - 1.0) * half + nrm * (randf() - 0.5) * r * 1.4
		flame(null, at, {"heat": 1.15 * A.heat_k / 0.8, "rise": 24.0 + randf() * 12.0, "life": 0.45 + randf() * 0.35})
	if randf() < 0.2 * EMBER_RATE * dt * 60.0:
		var e := Vector2(A.x, A.y) + u * (randf() * 2.0 - 1.0) * half
		ember(e.x, e.y, (randf() - 0.5) * 8.0, -(20.0 + randf() * 14.0), 1.0 + randf())
	if randf() < half * 0.002 * SMOKE_RATE * dt * 60.0:
		var sp := Vector2(A.x, A.y) + u * (randf() * 2.0 - 1.0) * half
		puff(sp.x, sp.y - 8.0)

func _step(dt: float):
	_t += dt
	presenter.step(dt)
	elements.step(dt)
	_update_fields(dt)
	_step_impacts(dt)
	var k93 := pow(0.93, dt * 60.0)
	var k92 := pow(0.92, dt * 60.0)
	var j := 0
	for i in _f_count:
		var b := i * FS
		var age := _fd[b + AGE] + dt
		if age > _fd[b + LIFE]:
			continue
		_fd[b + AGE] = age
		var a = _f_anchor[i]
		if a != null:
			if is_instance_valid(a):
				var c := world_to_su(a.global_position)
				_fd[b + AX] = c.x; _fd[b + AY] = c.y
			else:
				a = null
		var wx := _fd[b + WX]
		var wy := _fd[b + WY]
		var dvx := (_fd[b + DVX] + (_turb(wx + _fd[b + DX], wy + _fd[b + DY], 80.0) + wind * 1.5) * dt) * k92
		_fd[b + DVX] = dvx
		_fd[b + DX] += dvx * dt
		_fd[b + DY] -= _fd[b + RISE] * dt
		_fd[b + WX] = wx + _fd[b + VX] * dt
		_fd[b + WY] = wy + _fd[b + VY] * dt
		_fd[b + VX] *= k93
		_fd[b + VY] *= k93
		# hot flames shed embers from their tips, so sparks visibly come off the fire
		if age > _fd[b + LIFE] * 0.4 and _fd[b + HEAT] > 0.3 and _fd[b + HEAT] < 0.5 and randf() < TIP_EMBERS * dt:   # field tongues only; trails already shed embers
			var tk := age / _fd[b + LIFE]
			var tb := pow(tk, _fd[b + GX])
			var tx := (_fd[b + AX] + _fd[b + LX] + _fd[b + DX]) * (1.0 - tb) + (_fd[b + WX] + _fd[b + DX]) * tb
			var ty := (_fd[b + AY] + _fd[b + LY] + _fd[b + DY]) * (1.0 - tb) + (_fd[b + WY] + _fd[b + DY]) * tb
			ember(tx, ty - 2.0, dvx * 0.5 + (randf() - 0.5) * 8.0, -(16.0 + randf() * 14.0), 0.5 + randf() * 0.6)
		if j != i:
			var jb := j * FS
			for q in FS:
				_fd[jb + q] = _fd[b + q]
		_f_anchor[j] = a
		j += 1
	_f_count = j
	_fd.resize(j * FS)
	_f_anchor.resize(j)
	var ke := pow(0.96, dt * 60.0)
	var keep: Array = []
	for e in _embers:
		e[4] += dt
		if e[4] > e[5]:
			continue
		e[2] = e[2] * ke + (_turb(e[0], e[1], 30.0) + wind * 1.8) * dt
		e[0] += e[2] * dt
		e[1] += e[3] * dt
		e[3] = _drag(e[3], dt, 0.99)
		keep.append(e)
	_embers = keep
	keep = []
	for s in _smoke:
		s[4] += dt
		if s[4] > s[5]:
			continue
		s[2] = _drag(s[2] + wind * 2.2 * dt, dt, 0.98)
		s[0] += (s[2] + _turb(s[0], s[1], 20.0)) * dt
		s[1] -= s[3] * dt
		keep.append(s)
	_smoke = keep
	keep = []
	for d in _decals:
		d[2] += dt
		if d[2] < d[3]:
			var fade_in := clampf((d[2] - 0.12) / 0.2, 0.0, 1.0)
			d[1].set_shader_parameter("limit", minf(fade_in, 1.0 - d[2] / d[3]) * 0.95)
			keep.append(d)
		else:
			d[0].queue_free()
	_decals = keep

func _step_impacts(dt: float):
	var keep: Array = []
	for s in _sparks:
		s[4] += dt
		if s[4] >= s[5]:
			continue
		s[0] += s[2] * dt
		s[1] += s[3] * dt
		s[2] = _drag(s[2], dt, 0.9)
		s[3] = _drag(s[3], dt, 0.9)
		keep.append(s)
	_sparks = keep
	for arr in [_flashes, _stars, _rings]:
		var k2: Array = []
		for f in arr:
			f[3] += dt
			if f[3] < f[4]:
				k2.append(f)
		arr.clear()
		arr.append_array(k2)
	keep = []
	for d in _debris:
		d[7] += dt
		if d[7] > d[8]:
			continue
		d[5] -= 170.0 * dt
		d[2] += d[5] * dt
		d[0] += d[3] * dt
		d[1] += d[4] * dt
		if d[2] <= 0.0:
			d[2] = 0.0
			if not d[10]:
				d[5] = -d[5] * 0.35; d[3] *= 0.5; d[4] *= 0.5; d[10] = true
			else:
				d[5] = 0.0; d[3] = _drag(d[3], dt, 0.8); d[4] = _drag(d[4], dt, 0.8)
		keep.append(d)
	_debris = keep

# ------------------------------------------------------------------ render

## Old particles past `start` (seed = any per-particle random value). The
## sandbox blinked them every other frame: a shimmer at its 120 Hz, a 7.5 Hz
## strobe when stepping on twos.
## On ones (every display frame, like the sandbox) keep the sandbox's blink: at
## full frame rate it reads as a shimmer. On twos it would strobe, so there
## each particle drops out for good at its own moment instead.
func dissolved(seed: float, k: float, start: float) -> bool:
	if k <= start:
		return false
	if not on_twos:
		return (_steps & 1) != 0      # 60 Hz steps: toggling every step = the sandbox's 120 Hz frame & 2
	return fposmod(seed * 7919.371, 1.0) < (k - start) / (1.0 - start)

func _bayer(x: int, y: int) -> float:
	return BAYER[((y & 3) << 2) | (x & 3)] / 16.0

func _put(buf: PackedByteArray, x: int, y: int, c: Color):
	x -= _origin.x
	y -= _origin.y
	if x < 0 or y < 0 or x >= _size.x or y >= _size.y:
		return
	var i := (y * _size.x + x) * 4
	buf[i] = c.r8; buf[i + 1] = c.g8; buf[i + 2] = c.b8; buf[i + 3] = 255

func _place_grid() -> bool:
	var vis := _visible_world_rect()
	# Hysteresis: keep the grid where it is while it still covers the view, so
	# a walking camera does not force a full redraw every display frame.
	var want := Vector2i(ceili(vis.size.x / CELL) + 2 * MARGIN, ceili(vis.size.y / CELL) + 2 * MARGIN)
	if want == _size and _size != Vector2i.ZERO:
		var have := Rect2(Vector2(_origin) * CELL, Vector2(_size) * CELL).grow(-CELL)
		if have.encloses(vis):
			return false
	var tl := Vector2i(floori(vis.position.x / CELL) - MARGIN, floori(vis.position.y / CELL) - MARGIN)
	var br := tl + want
	var size := br - tl
	if size.x <= 0 or size.y <= 0 or size.x * size.y > 400000:
		return false
	var moved := tl != _origin or size != _size
	_origin = tl
	if size != _size:
		_size = size
		var n := size.x * size.y
		_heat.resize(n)
		_water.resize(n * 4)
		_water.fill(0.0)
		_under.resize(n * 4)
		_over.resize(n * 4)
		_ground.resize(n * 4)
		_ground.fill(0)
		_upload("ground", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _ground))
	stats.cells = size.x * size.y
	return moved

func _render(stepped: bool):
	var moved := _place_grid()
	if stepped or moved:
		_draw_air()
		_draw_light()
	var world_origin := Vector2(_origin) * CELL
	_ground_layer.texture = _tex.ground
	_ground_layer.position = world_origin
	_air_layer.texture = _tex.over
	_air_layer.position = world_origin
	var mat: ShaderMaterial = _air_layer.material
	mat.set_shader_parameter("heat_tex", _tex.heat)
	mat.set_shader_parameter("under_tex", _tex.under)
	if _tex.has("water"):
		mat.set_shader_parameter("water_tex", _tex.water)
		(_ground_layer.material as ShaderMaterial).set_shader_parameter("water_tex", _tex.water)
	mat.set_shader_parameter("origin", _origin)
	var g: ShaderMaterial = _ground_layer.material
	g.set_shader_parameter("origin", _origin)
	g.set_shader_parameter("light_tex", _tex.light)
	g.set_shader_parameter("light_origin", Vector2(_light_origin))
	g.set_shader_parameter("t", _t)
	g.set_shader_parameter("tick", int(_t * 60.0) >> 3)
	var fl := PackedVector4Array()
	var fa := PackedVector4Array()
	var fg := PackedVector2Array()
	for A in _fields:
		var v := minf(1.0, minf(A.age / 0.25, (A.life - A.age) / 0.5))
		fl.append(Vector4(roundf(A.x * K), roundf(A.y * K), A.r * K, v))
		var ax: Vector2 = A.axis * K
		fa.append(Vector4(ax.x, ax.y, float(A.look), float(A.get("style", FIELD_LOOKS[A.look].style))))
		fg.append(Vector2(float(A.goo), A.age))
	g.set_shader_parameter("field_count", fl.size())
	fl.resize(MAX_FIELDS)
	fa.resize(MAX_FIELDS)
	fg.resize(MAX_FIELDS)
	g.set_shader_parameter("field_goo", fg)
	g.set_shader_parameter("fields", fl)
	g.set_shader_parameter("field_axis", fa)

## Goo splat (sandbox gsplat): linear falloff to 2*re. Layers: 0 water air,
## 1 water ground, 2 plague air, 3 plague ground. Position and radius in su.
## Thresholded in the shaders.
func gsplat(layer: int, x: float, y: float, re: float, v: float = 1.0):
	var r := re * 2.0 * K
	var R := ceili(r)
	var cx := roundi(x * K) - _origin.x
	var cy := roundi(y * K) - _origin.y
	var w := _size.x
	for oy in range(-R, R + 1):
		var Y := cy + oy
		if Y < 0 or Y >= _size.y:
			continue
		for ox in range(-R, R + 1):
			var X := cx + ox
			if X < 0 or X >= w:
				continue
			var d := sqrt(float(ox * ox + oy * oy))
			if d >= r:
				continue
			_water[(Y * w + X) * 4 + layer] += v * (1.0 - d / r)
	_water_used = true

## Adds goo to one cell (world cell coords): area fills like the sandbox pool.
func water_cell(layer: int, X: int, Y: int, v: float):
	X -= _origin.x
	Y -= _origin.y
	if X < 0 or Y < 0 or X >= _size.x or Y >= _size.y:
		return
	_water[(Y * _size.x + X) * 4 + layer] += v
	_water_used = true

func _draw_water():
	var was_used := _water_used
	if was_used:
		_water.fill(0.0)
	_water_used = false
	_wave = null
	elements.accumulate_water()
	presenter.accumulate_water()
	if _water_used or was_used or not _tex.has("water"):   # also once after the last splat, so no stale goo shows
		_upload("water", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBAF, _water.to_byte_array()))
	var am := _air_layer.material as ShaderMaterial
	am.set_shader_parameter("wave_on", _wave != null)
	am.set_shader_parameter("t", _t)
	am.set_shader_parameter("k", K)
	if _wave != null:
		_water_used = true
		am.set_shader_parameter("wave_a", Vector4(_wave[0].x * K, _wave[0].y * K, _wave[1].x, _wave[1].y))
		am.set_shader_parameter("wave_b", Vector4(_wave[2] * K, _wave[3] * K, _wave[4] * K, _wave[5]))
	am.set_shader_parameter("water_on", _water_used)
	(_ground_layer.material as ShaderMaterial).set_shader_parameter("water_on", _water_used)

var prof := {}                       # per-stage draw cost (ms), last step; console "vfx stats"

func _draw_air():
	var p0 := Time.get_ticks_usec()
	_draw_water()
	var p1 := Time.get_ticks_usec()
	_heat.fill(0.0)
	_under.fill(0)
	_over.fill(0)
	var w := _size.x
	var hgt := _size.y
	if _disk_w != w:
		_disk_w = w
		_disks = []
		for variants in DISK_XY:
			var lv := []
			for offs in variants:
				var lin := PackedInt32Array()
				for q in range(0, offs.size(), 2):
					lin.append(offs[q + 1] * w + offs[q])
				lv.append(lin)
			_disks.append(lv)
	var disks := _disks
	var pad := ceili(2.5 * K * 0.85 * FLAME_ASPECT) + 3
	for i in _f_count:
		var fb := i * FS
		var k := _fd[fb + AGE] / _fd[fb + LIFE]
		var b := pow(k, _fd[fb + GX])
		var x := (_fd[fb + AX] + _fd[fb + LX] + _fd[fb + DX]) * (1.0 - b) + (_fd[fb + WX] + _fd[fb + DX]) * b
		var y := (_fd[fb + AY] + _fd[fb + LY] + _fd[fb + DY]) * (1.0 - b) + (_fd[fb + WY] + _fd[fb + DY]) * b
		var r := maxi(0, (2 if k < 0.3 else (1 if k < 0.65 else 0)) - int(_fd[fb + SMALL]))
		var h := pow(1.0 - k, 0.7) * _fd[fb + HEAT]
		var cx := roundi(x * K) - _origin.x
		var cy := roundi(y * K) - _origin.y
		var shape := i % FLAME_VARIANTS
		if _fd[fb + ROUND] > 0.5 and k < 0.35:
			r += 3   # round only while young: old trail flames break into ragged bits, not beads
		if cx >= pad and cy >= pad and cx < w - pad and cy < hgt - pad:
			var base := cy * w + cx
			for o in disks[r][shape]:
				_heat[base + o] += h
		else:
			var offs: PackedInt32Array = DISK_XY[r][shape]
			for q in range(0, offs.size(), 2):
				var xx := cx + offs[q]
				var yy := cy + offs[q + 1]
				if xx >= 0 and yy >= 0 and xx < w and yy < hgt:
					_heat[yy * w + xx] += h
	var p2 := Time.get_ticks_usec()
	# smoke under heat (sandbox drawSmoke); puff size scales, dither stays per cell
	for s in _smoke:
		var k: float = s[4] / s[5]
		var c: Color = FIRE_SMOKE[0] if k < 0.5 else FIRE_SMOKE[1]
		var x0 := roundi(s[0] * K)
		var y0 := roundi(s[1] * K)
		var sz := roundi(s[6] * K)
		for qy in sz:
			for qx in sz:
				if _bayer(x0 + qx, y0 + qy) < (1.0 - k) * 0.85:
					_put(_under, x0 + qx, y0 + qy, c)
	# embers over heat (sandbox drawTop): one cell, the finest detail
	for e in _embers:
		var k: float = e[4] / e[5]
		if dissolved(e[5], k, 0.7):
			continue
		var ex := roundi(e[0] * K)
		var ey := roundi(e[1] * K)
		var ec: Color = FIRE_EMBER[mini(3, int(k * 4.0))]
		_put(_over, ex, ey, ec)
		if k < 0.5:
			_put(_over, ex + 1, ey, ec)   # young embers are a full sandbox pixel (2x2)
			_put(_over, ex, ey + 1, ec)
			_put(_over, ex + 1, ey + 1, ec)
		elif absf(e[3]) > 10.0:
			_put(_over, ex, ey + 1, ec)   # older fast embers streak 1x2
	var p3 := Time.get_ticks_usec()
	_draw_impacts()
	var p4 := Time.get_ticks_usec()
	_upload("heat", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RF, _heat.to_byte_array()))
	_upload("under", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _under))
	_upload("over", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _over))
	var p5 := Time.get_ticks_usec()
	prof.water = (p1 - p0) / 1000.0
	prof.flames = (p2 - p1) / 1000.0
	prof.smoke_embers = (p3 - p2) / 1000.0
	prof.impacts = (p4 - p3) / 1000.0
	prof.upload = (p5 - p4) / 1000.0

## Warm light on the ground near flames (sandbox drawFloorLight): flames are
## binned into a coarse world-anchored grid (LIGHT_SU per cell); the radial
## falloff and banding run in vfx_ground.gdshader.
func _draw_light():
	var lc := LIGHT_SU * K
	var lo := Vector2i(floori(_origin.x / lc) - 2, floori(_origin.y / lc) - 2)
	var ls := Vector2i(ceili(_size.x / lc) + 5, ceili(_size.y / lc) + 5)
	if ls != _light_size:
		_light_size = ls
		_light.resize(ls.x * ls.y)
	_light_origin = lo
	_light.fill(0.0)
	for i in _f_count:
		var fb := i * FS
		var k := _fd[fb + AGE] / _fd[fb + LIFE]
		var h := pow(1.0 - k, 0.7) * _fd[fb + HEAT]
		if h < 0.25:
			continue
		var b := pow(k, _fd[fb + GX])
		var x := (_fd[fb + AX] + _fd[fb + LX] + _fd[fb + DX]) * (1.0 - b) + (_fd[fb + WX] + _fd[fb + DX]) * b
		var y := (_fd[fb + AY] + _fd[fb + LY] + _fd[fb + DY]) * (1.0 - b) + (_fd[fb + WY] + _fd[fb + DY]) * b
		var qx := x / LIGHT_SU - lo.x - 0.5
		var qy := y / LIGHT_SU - lo.y - 0.5
		var ix := floori(qx)
		var iy := floori(qy)
		if ix < 0 or iy < 0 or ix >= ls.x - 1 or iy >= ls.y - 1:
			continue
		var fx := qx - ix
		var fy := qy - iy
		var base := iy * ls.x + ix
		_light[base] += h * (1.0 - fx) * (1.0 - fy)
		_light[base + 1] += h * fx * (1.0 - fy)
		_light[base + ls.x] += h * (1.0 - fx) * fy
		_light[base + ls.x + 1] += h * fx * fy
	_upload("light", Image.create_from_data(ls.x, ls.y, false, Image.FORMAT_RF, _light.to_byte_array()))

func _disk(buf: PackedByteArray, cx: int, cy: int, r: float, c: Color):
	var R := ceili(r)
	for qy in range(-R, R + 1):
		for qx in range(-R, R + 1):
			if qx * qx + qy * qy <= r * r:
				_put(buf, cx + qx, cy + qy, c)

func _draw_impacts():
	# rings sit on the ground (sandbox draws them before actors)
	_ground.fill(0)
	for r in _rings:
		var k: float = r[3] / r[4]
		var rad: float = r[2] * (1.0 - pow(1.0 - k, 3.0)) * K
		var pal: Array = r[5]
		var c: Color = pal[mini(pal.size() - 1, int(k * pal.size()))]
		var steps := maxi(12, ceili(TAU * rad * 1.5))
		for i in steps:
			var a := TAU * i / steps
			# break into segments: whole arcs drop out as the ring ages
			if k > 0.4 and vn_fast(a * 2.2 + r[6], k * 3.0) < (k - 0.4) * 1.9:
				continue
			var X := roundi(r[0] * K + cos(a) * rad)
			var Y := roundi(r[1] * K + sin(a) * rad)
			# one sandbox pixel thick (about K cells), doubled while fresh
			var th := 2 if k < 0.3 else 1
			for q in th + 1:
				_put(_ground, X + int(signf(cos(a))) * q, Y, c)
				_put(_ground, X, Y + int(signf(sin(a))) * q, c)
	var q0 := Time.get_ticks_usec()
	elements.draw_ground(_ground)
	_upload("ground", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _ground))
	var q1 := Time.get_ticks_usec()
	presenter.draw_bodies(_over)
	presenter.draw_statuses(_over)
	presenter.draw_charges(_over)
	var q2 := Time.get_ticks_usec()
	elements.draw_over(_over)
	var q3 := Time.get_ticks_usec()
	prof.el_ground = (q1 - q0) / 1000.0
	prof.bodies = (q2 - q1) / 1000.0
	prof.el_over = (q3 - q2) / 1000.0
	for f in _flashes:
		_disk(_over, roundi(f[0] * K), roundi(f[1] * K), f[2] * K, f[5])
	for s in _stars:
		var k: float = s[3] / s[4]
		var pop: float = 1.2 - 0.2 * minf(1.0, k * 2.0)            # 120% then settle
		var L: float = s[2] * K * pop
		var cx := roundi(s[0] * K)
		var cy := roundi(s[1] * K)
		var pts: int = s[5]
		for i in pts:
			var a := TAU * i / pts
			var len := L if i % 2 == 0 or pts == 4 else L * 0.55
			var n := ceili(len)
			for j in n:
				var w := 1 if j > n * 0.5 else 0
				var X := cx + roundi(cos(a) * j)
				var Y := cy + roundi(sin(a) * j)
				_put(_over, X, Y, s[6])
				if w == 0:
					_put(_over, X + roundi(-sin(a)), Y + roundi(cos(a)), s[6])
	for d in _debris:
		var k: float = d[7] / d[8]
		if dissolved(d[8], k, 0.75):
			continue
		var pal: Array = d[6]
		var c: Color = pal[mini(pal.size() - 1, int(k * pal.size()))]
		var X := roundi(d[0] * K)
		var Y := roundi(d[1] * K)
		var Z := roundi(d[2] * K)
		var sz: int = maxi(1, roundi(d[9] * K))   # sandbox px -> cells: chunks stay readable squares
		if Z > 2:
			_put(_over, X, Y, SHADOW)
		for qy in sz:
			for qx in sz:
				_put(_over, X + qx, Y - Z + qy, c)
	for s in _sparks:
		var k: float = s[4] / s[5]
		var pal: Array = s[6]
		var c: Color = pal[mini(pal.size() - 1, int(k * pal.size()))]
		var X := roundi(s[0] * K)
		var Y := roundi(s[1] * K)
		_put(_over, X, Y, c)
		if k < 0.25:
			_put(_over, X + 1, Y, c); _put(_over, X - 1, Y, c); _put(_over, X, Y + 1, c); _put(_over, X, Y - 1, c)

func _upload(key: String, img: Image):
	var t: ImageTexture = _tex.get(key)
	if t == null or t.get_size() != Vector2(img.get_size()):
		_tex[key] = ImageTexture.create_from_image(img)
	else:
		t.update(img)
