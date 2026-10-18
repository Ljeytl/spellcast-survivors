extends RefCounted
## Element particle kit (sandbox "WIDE SLICE" techniques) shared by the looks
## that are not fire: rigid sprites (crystals, shards, z-physics), motes, nova
## fronts. Simulation in sandbox units like Vfx.gd; drawn into Vfx's CPU
## buffers (ground = under actors, over = above the heat layer).
##
## Sandbox pixels map to cells as in Vfx.gd: K cells per su. Points are one
## cell (young ones a small cross, like sandbox ice motes); bodies use the
## shared body rasterizer so they keep the sandbox proportions.

const WPS := 1280.0 / 192.0

# Sandbox EL.ice
const ICE := {
	"body": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8"), Color("#1a2e5a")],
	"mote": [Color("#ffffff"), Color("#d6f6ff"), Color("#8fd3ee"), Color("#3f86c8")],
	"rim": [Color("#8fd3ee"), Color("#ffffff")],
	"floor": [Color("#1c2433"), Color("#233247"), Color("#2f4560")],
	"frost": [Color("#2a3c50"), Color("#3d5a78")],
}
# Sandbox EL.lightning
const LIGHTNING := {
	"arc": [Color("#ffffff"), Color("#cfe6ff"), Color("#8fb2ff"), Color("#7a5cf0")],
	"dark": Color("#2a1f5e"),
	"rim": [Color("#8fb2ff"), Color("#ffffff")],
	"floor": [Color("#1c1a2c"), Color("#211e38"), Color("#2a2550")],
	"spider": [Color("#14111c"), Color("#2a2342")],
}
# Snowflake sprites (cells). 0 = core (white), 1 = arm (light), 2 = tip (mid).
# Two poses per size, upright (+) and diagonal (x); alternating them reads as a
# slow spin. Sizes follow 1:3:9-ish contrast with the one-cell motes.
static var FLAKES: Array = _make_flakes()

static func _make_flakes() -> Array:
	var art := [
		# size 0: 3x3
		[[". 1 .", "1 0 1", ". 1 ."], ["1 . 1", ". 0 .", "1 . 1"]],
		# size 1: 5x5
		[["2 . 1 . 2", ". . 1 . .", "1 1 0 1 1", ". . 1 . .", "2 . 1 . 2"],
		 [". . 2 . .", ". 1 . 1 .", "2 . 0 . 2", ". 1 . 1 .", ". . 2 . ."]],
		# size 2: 7x7
		[[". . . 2 . . .", ". 2 . 1 . 2 .", ". . 1 1 1 . .", "2 1 1 0 1 1 2", ". . 1 1 1 . .", ". 2 . 1 . 2 .", ". . . 2 . . ."],
		 [". 2 . . . 2 .", "2 1 . 1 . 1 2", ". . 1 . 1 . .", ". 1 . 0 . 1 .", ". . 1 . 1 . .", "2 1 . 1 . 1 2", ". 2 . . . 2 ."]],
	]
	var out := []
	for size in art:
		var poses := []
		for rows in size:
			var px := []
			var h: int = rows.size()
			for y in h:
				var cells: PackedStringArray = str(rows[y]).split(" ")
				for x in cells.size():
					if cells[x] != ".":
						px.append([x - cells.size() / 2, y - h / 2, int(cells[x])])
			poses.append(px)
		out.append(poses)
	return out

# Sandbox EL.water (polish pass 2: no dark outline, mostly light)
const WATER := {
	"hi": Color("#ffffff"), "light": Color("#a6e6ff"), "mid": Color("#3f9fe4"), "dark": Color("#2063b0"),
	"foam": [Color("#ffffff"), Color("#cdeffd"), Color("#7cc4f2")],
	"rim": [Color("#4fb2f0"), Color("#e8f8ff")],
}
# Sandbox EL.life
const LIFE := {
	"leaf": [Color("#d4f58a"), Color("#86d24c"), Color("#46963c"), Color("#275c2e")],
	"vine": [Color("#7ab24a"), Color("#4e823a"), Color("#2a4a22")],
	"petal": [Color("#ffb0d0"), Color("#ffe27a"), Color("#ffffff")],
	"body": [Color("#f0ffc0"), Color("#c8f07a"), Color("#7fcf4a"), Color("#3e8f3a"), Color("#1e2e16")],
	"rim": [Color("#7fcf4a"), Color("#d4f58a")],
}
# Sandbox EL.arcane (wide slice) + GLYPH sprites (5x5 sandbox pixels)
const ARCANE := {
	"spark": [Color("#ffffff"), Color("#bdf3ff"), Color("#a98af5"), Color("#6a4ad0")],
	"rim": [Color("#8fa8f5"), Color("#e2f6ff")],
	"floor2": Color("#2a2656"),
}
const GLYPH := [[".x.x.", "xxxxx", "..x..", ".x.x.", "x...x"], ["xxx..", "..x..", ".xxx.", "..x..", "..xxx"], ["x...x", ".x.x.", "..x..", ".x.x.", "x...x"], [".xxx.", "x...x", "x.x.x", "x...x", ".xxx."]]
# Sandbox EL.plague / EL.earth
const PLAGUE := {
	"hi": Color("#e4fbb0"), "light": Color("#a6e45e"), "mid": Color("#56b23e"), "dark": Color("#2c6e3a"), "outline": Color("#1b1a2c"),
	"rim": [Color("#6fd04a"), Color("#c4f383")],
}
const EARTH := {
	"body": [Color("#e8dcc0"), Color("#c9b48c"), Color("#9a7d5a"), Color("#5e4630"), Color("#2a1e16")],
	"debris": [Color("#c9b48c"), Color("#9a7d5a"), Color("#5e4630")],
	"dust": [Color("#9a8670"), Color("#7a6a58"), Color("#5a4c40")],
	"rim": [Color("#c9a46a"), Color("#e8dcc0")],
}
# Sandbox EL.steam (soft technique): reactions (fire + water/ice) make steam.
const STEAM := [Color("#f2f6f8"), Color("#c5d0d9"), Color("#8e9cab")]
const SHADOW := Color("#16141b")
const INK := Color("#120e14")

var vfx
var motes: Array = []       # [x, y, vx, vy, cols, age, life, g, sway, ph, big]
var shards: Array = []      # [x, y, z, vx, vy, vz, ang, spin, len, age, life, pal, bounced]
var crystals: Array = []    # [x, y, h, tilt, age, life, pal]
var arcs: Array = []        # [x0, y0, x1, y1, amp, age, life, c, thick, branch, pts]  pts null = regenerate every step
var hops: Array = []        # [x, y, vx, vy, age, life, next]  hopping spark
var flakes: Array = []      # [x, y, vx, vy, age, life, size, spin, ph, g]
var blobs: Array = []       # [x, y, vx, vy, r, age, life, g, stick, layer]   goo blobs; layer 0 water, 2 plague
var poison_status_visible := true
var bubbles: Array = []     # [x, y, vy, r, age, life]                 plague bubbles
var mists: Array = []       # [x, y, vx, vy, r, grow, age, life]       steam puffs (sandbox mist)
var pulls: Array = []       # [x, y, r0, age, life, cols]              rings closing in (pulling keyword)
var streaks: Array = []     # [x0, y0, x1, y1, age, life, cols]        foam streaks
var rays: Array = []        # [x, y, ang, len, age, life, cols, r0]    spray rays
var later: Array = []       # [t, Callable]                            delayed spawns (ripples)
var leaves: Array = []      # [x, y, vx, vy, cols, age, life, ph]
var blades: Array = []      # [x, y, h, delay, age, life, c, ph, flower]  grass growing out of the ground
var vines: Array = []       # [x, y, ang, len, grow_t, age, life, curl, ph]
var tufts: Array = []       # [x, y, c, age, life]                     grass decal (sandbox 'grass')
var glyphs: Array = []      # [x, y, vy, age, life, k, cols]           rising rune glyphs
var runes: Array = []       # [x, y, r, age, life, seed]               rune decal (sandbox 'rune')
var slashes: Array = []     # {cx, cy, a0, span, dir, t, dur, linger, rin, rout, cols, emit}

func _init(owner):
	vfx = owner

func clear():
	motes.clear(); shards.clear(); crystals.clear(); arcs.clear(); hops.clear(); flakes.clear()
	blobs.clear(); streaks.clear(); rays.clear(); later.clear(); bubbles.clear(); mists.clear(); pulls.clear()
	leaves.clear(); blades.clear(); vines.clear(); tufts.clear()
	glyphs.clear(); runes.clear(); slashes.clear()

# ------------------------------------------------------------------ spawners (sandbox signatures)

func mote(x: float, y: float, vx: float, vy: float, cols: Array, life: float, g: float = 0.0, sway: float = 0.0):
	if motes.size() < (200 if vfx.reduced_effects else 700):
		motes.append([x, y, vx, vy, cols, 0.0, life, g, sway, randf() * 6.0])

func shard(x: float, y: float, vx: float, vy: float, vz: float, len: float, life: float, pal: Array = ICE.body):
	if shards.size() < (80 if vfx.reduced_effects else 260):
		shards.append([x, y, 3.0, vx, vy, vz, randf() * TAU, (randf() - 0.5) * 20.0, len, 0.0, life, pal, false])

## Snowflake: drifts with a little gravity and sway; spin = pose swaps per second.
func flake(x: float, y: float, vx: float, vy: float, life: float, size: int = 1, g: float = 6.0):
	if flakes.size() < (80 if vfx.reduced_effects else 260):
		flakes.append([x, y, vx, vy, 0.0, life, clampi(size, 0, 2), 1.5 + randf() * 3.0, randf() * 6.0, g])

# --- water (sandbox FX.water helpers)
func wblob(x: float, y: float, vx: float, vy: float, r: float, life: float, stick: bool, g: float = 0.0):
	if blobs.size() < (60 if vfx.reduced_effects else 200):
		blobs.append([x, y, vx, vy, r, 0.0, life, g, stick, 0])

## Plague goo blob (sandbox blobs, non-water): outlined green goo.
func gblob(x: float, y: float, vx: float, vy: float, r: float, life: float, stick: bool, g: float = 0.0):
	if blobs.size() < (60 if vfx.reduced_effects else 200):
		blobs.append([x, y, vx, vy, r, 0.0, life, g, stick, 2])

## Bubble: rises and wobbles, swells, pops into a few motes (sandbox bubble).
func bubble(x: float, y: float, big: bool, life_scale: float = 1.0, alpha: float = 1.0, poison_status: bool = false):
	if bubbles.size() < (80 if vfx.reduced_effects else 240):
		bubbles.append([x, y, -(5.0 + randf() * 7.0) * life_scale, 2.0 if big else 1.2, 0.0, (0.5 + randf() * 0.7) * life_scale, alpha, poison_status])

## Steam puff (sandbox mist): grows and drifts with the wind, dithered.
func mist(x: float, y: float, vx: float, vy: float, r: float, grow: float, life: float, cols: Array = STEAM):
	if mists.size() < (60 if vfx.reduced_effects else 200):
		mists.append([x, y, vx, vy, r, grow, 0.0, life, cols])

## Ring that closes in on a point (pulling); dashed, in the given palette.
func pull_ring(x: float, y: float, r0: float, life: float, cols: Array):
	pulls.append([x, y, r0, 0.0, life, cols])

## Short coloured streak (push / pull lines, foam): fades through cols.
func streak(x0: float, y0: float, x1: float, y1: float, life: float, cols: Array):
	if streaks.size() < 200:
		streaks.append([x0, y0, x1, y1, 0.0, life, cols])

## Earth dust: a falling-up mote in dust tones (sandbox dust).
func dust(x: float, y: float, vx: float, vy: float):
	mote(x, y, vx, vy, EARTH.dust, 0.6 + randf() * 0.4, -2.0, 2.0)

func droplet(x: float, y: float, vx: float, vy: float, vz: float):
	vfx.chunk(x, y, vx, vy, vz, WATER.foam, 0.5 + randf() * 0.5, 1)

func ripple(x: float, y: float, max_r: float, delay: float = 0.0):
	var go := func(): vfx.ring(x, y, max_r, 0.5, [WATER.foam[0], WATER.foam[1], WATER.foam[2], WATER.rim[0]])
	if delay > 0.0:
		later.append([delay, go])
	else:
		go.call()

func foam_streak(x: float, y: float, vx: float, vy: float, len: float):
	var L := maxf(0.001, Vector2(vx, vy).length())
	if streaks.size() < 200:
		streaks.append([x, y, x - vx / L * len, y - vy / L * len, 0.0, 0.12, [WATER.hi, WATER.foam[1], WATER.foam[2]]])

func ray(x: float, y: float, ang: float, len: float, life: float, cols: Array, r0: float = 0.0):
	if rays.size() < 200:
		rays.append([x, y, ang, len, 0.0, life, cols, r0])

## Goo for the shaders (sandbox accumulateElements): blobs splat into the air
## layer, or the ground once a sticking blob has landed.
func accumulate_water():
	for b in blobs:
		var k: float = b[5] / b[6]
		vfx.gsplat(b[9] + (1 if b[8] and k > 0.35 else 0), b[0], b[1], b[4] * (1.0 - k * 0.5))

# --- life (sandbox FX.life helpers)
func leaf(x: float, y: float, vx: float, vy: float, cols: Array, life: float):
	if leaves.size() < (120 if vfx.reduced_effects else 400):
		leaves.append([x, y, vx, vy, cols, 0.0, life, randf() * 6.0])

func blade(x: float, y: float, h: int, delay: float, life: float, flower: bool = false):
	if blades.size() < (200 if vfx.reduced_effects else 600):
		blades.append([x, y, h, delay, 0.0, life, randi() % 3, randf() * 6.0, flower])

func vine(x: float, y: float, ang: float, len: float, grow_t: float, life: float, curl: float = 0.5):
	if vines.size() < 60:
		vines.append([x, y, ang, len, grow_t, 0.0, life, curl, randf() * 6.0])

func grass_tuft(x: float, y: float, r: float, life: float = 6.0):
	for i in 14:
		var a := randf() * TAU
		var d := randf() * r
		tufts.append([x + cos(a) * d, y + sin(a) * d * 0.7, randi() % 3, 0.0, life])
	while tufts.size() > 400:
		tufts.pop_front()

# --- arcane / slice
func glyph(x: float, y: float, vy: float, life: float, cols: Array = ARCANE.spark):
	if glyphs.size() < 120:
		glyphs.append([x, y, vy, 0.0, life, randi() % 4, cols])

func rune(x: float, y: float, r: float, life: float = 4.0):
	if runes.size() < 30:
		runes.append([x, y, r, 0.0, life, randf() * 6.0])

## Crescent smear (sandbox eSlash): sweeps across the swing, thick in the middle,
## tapered at the ends; the trailing part dithers out. emit(x, y, fx, fy) is
## called along the leading edge while it sweeps.
func slash(cx: float, cy: float, a0: float, span: float, dir: int, rin: float, rout: float, cols: Array, emit: Callable, dur: float = 0.13, sharp: bool = false):
	slashes.append({"cx": cx, "cy": cy, "a0": a0, "span": span, "dir": dir, "t": 0.0, "dur": dur, "linger": 0.14, "rin": rin, "rout": rout, "cols": cols, "emit": emit, "sharp": sharp})

func draw_glyph(buf: PackedByteArray, x: float, y: float, k: int, c: Color):
	var P: Array = GLYPH[k]
	for j in 5:
		for i in 5:
			if P[j][i] == "x":
				spx(buf, roundi(x) - 2 + i, roundi(y) - 2 + j, c)

func crystal(x: float, y: float, h: float, life: float, pal: Array = ICE.body):
	if crystals.size() < (40 if vfx.reduced_effects else 120):
		crystals.append([x, y, h, (randf() - 0.5) * 0.6, 0.0, life, pal])

## Jagged arc (sandbox jag + arcs). The path is fixed for its short life, like
## the sandbox; only `regen` arcs (sky strikes) re-roll every step and crackle.
## Re-rolling every arc every frame read as noise on ones. c = arc palette
## index; thick doubles it in the darker tone; branch forks from the midpoint.
func arc(x0: float, y0: float, x1: float, y1: float, amp: float, life: float, c: int = 1, thick: bool = false, branch: bool = false, regen: bool = false):
	if arcs.size() < (80 if vfx.reduced_effects else 300):
		var pts = null if regen else jag(x0, y0, x1, y1, amp)
		var fork = null
		if branch and not regen:
			var m: Vector2 = pts[pts.size() / 2]
			fork = jag(m.x, m.y, m.x + (randf() - 0.5) * 16.0, m.y + 6.0 + randf() * 8.0, 3.0)
		arcs.append([x0, y0, x1, y1, amp, 0.0, life, c, thick, branch, pts, fork])

func hop(x: float, y: float, life: float):
	if hops.size() < (120 if vfx.reduced_effects else 400):
		hops.append([x, y, 0.0, 0.0, 0.0, life, 0.0])

static func jag(x0: float, y0: float, x1: float, y1: float, amp: float) -> PackedVector2Array:
	var dx := x1 - x0
	var dy := y1 - y0
	var L := maxf(0.001, sqrt(dx * dx + dy * dy))
	var n := maxi(2, ceili(L / 4.0))
	var nx := -dy / L
	var ny := dx / L
	var pts := PackedVector2Array([Vector2(x0, y0)])
	for i in range(1, n):
		var t := float(i) / n
		var o := (randf() - 0.5) * 2.0 * amp * sin(t * PI)
		pts.append(Vector2(x0 + dx * t + nx * o, y0 + dy * t + ny * o))
	pts.append(Vector2(x1, y1))
	return pts

# ------------------------------------------------------------------ step

func step(dt: float):
	var t: float = vfx._t
	var keep: Array = []
	for s in shards:
		s[9] += dt
		if s[9] > s[10]:
			continue
		s[5] -= 170.0 * dt
		s[2] += s[5] * dt
		s[0] += s[3] * dt
		s[1] += s[4] * dt
		s[6] += s[7] * dt
		if s[2] <= 0.0:
			s[2] = 0.0
			if not s[12]:
				s[5] = -s[5] * 0.3; s[3] *= 0.5; s[4] *= 0.5; s[7] *= 0.4; s[12] = true
			else:
				s[5] = 0.0; s[3] = vfx._drag(s[3], dt, 0.8); s[4] = vfx._drag(s[4], dt, 0.8); s[7] = 0.0
		keep.append(s)
	shards = keep
	keep = []
	for c in crystals:
		c[4] += dt
		if c[4] > c[5]:
			# shatter, don't fade (principle 5)
			var pal: Array = c[6]
			for i in 3:
				var a := randf() * TAU
				shard(c[0], c[1] - c[2] * 0.5, cos(a) * 18.0, sin(a) * 12.0, 25.0 + randf() * 25.0, 1.6, 0.6 + randf() * 0.4, pal)
			for i in 4:
				mote(c[0], c[1] - c[2] * 0.5, (randf() - 0.5) * 20.0, (randf() - 0.5) * 12.0, [pal[0], pal[1], pal[2], pal[3]], 0.5, 6.0, 3.0)
			continue
		keep.append(c)
	crystals = keep
	keep = []
	for m in motes:
		m[5] += dt
		if m[5] > m[6]:
			continue
		m[2] = vfx._drag(m[2], dt, 0.92)
		m[3] = vfx._drag(m[3], dt, 0.95) + m[7] * dt
		m[0] += (m[2] + sin(m[9] + t * 4.0) * m[8] + vfx.wind * 0.4) * dt
		m[1] += m[3] * dt
		keep.append(m)
	motes = keep
	keep = []
	for b in blobs:
		b[5] += dt
		if b[5] > b[6]:
			continue
		b[2] = vfx._drag(b[2], dt, 0.88)
		b[3] = vfx._drag(b[3], dt, 0.88) + b[7] * dt
		b[0] += b[2] * dt
		b[1] += b[3] * dt
		keep.append(b)
	blobs = keep
	keep = []
	for m in mists:
		m[6] += dt
		if m[6] > m[7]:
			continue
		m[2] = vfx._drag(m[2] + vfx.wind * 2.4 * dt, dt, 0.95)
		m[3] = vfx._drag(m[3], dt, 0.97)
		m[0] += m[2] * dt
		m[1] += m[3] * dt
		m[4] += m[5] * dt
		m[5] *= pow(0.97, dt * 60.0)
		keep.append(m)
	mists = keep
	for q in pulls:
		q[3] += dt
	pulls = pulls.filter(func(q): return q[3] < q[4])
	keep = []
	for q in bubbles:
		q[4] += dt
		q[1] += q[2] * dt
		q[0] += sin(q[4] * 9.0 + q[1]) * 3.0 * dt
		if q[4] > q[5]:
			if q.size() > 6 and q[6] < 1.0:
				continue   # a status bubble just vanishes: no pop spray on a crowded enemy
			for i in 3:
				var a := randf() * TAU
				mote(q[0], q[1], cos(a) * 14.0, sin(a) * 14.0, [PLAGUE.hi, PLAGUE.light], 0.15)
			continue
		keep.append(q)
	bubbles = keep
	for arr in [streaks, rays]:
		var k2: Array = []
		for q in arr:
			q[4] += dt
			if q[4] < q[5]:
				k2.append(q)
		arr.clear()
		arr.append_array(k2)
	var due := []
	for l in later:
		l[0] -= dt
		if l[0] <= 0.0:
			due.append(l)
	for l in due:
		later.erase(l)
		l[1].call()
	for g in glyphs:
		g[3] += dt
		g[1] += g[2] * dt
	glyphs = glyphs.filter(func(g): return g[3] < g[4])
	for r in runes:
		r[3] += dt
	runes = runes.filter(func(r): return r[3] < r[4])
	for sl in slashes:
		sl.t += dt
		var k: float = minf(1.0, sl.t / sl.dur)
		if k < 1.0 and sl.emit.is_valid():
			var cur: float = sl.a0 + sl.span * k * sl.dir
			for i in 4:
				var inner: float = lerpf(sl.rin, sl.rout, 0.85) if sl.get("sharp", false) else sl.rin
				var rr: float = inner + randf() * (sl.rout - inner)
				sl.emit.call(sl.cx + cos(cur) * rr, sl.cy + sin(cur) * rr, cos(cur), sin(cur))
	slashes = slashes.filter(func(sl): return sl.t < sl.dur + sl.linger)
	keep = []
	for l in leaves:
		l[5] += dt
		if l[5] > l[6]:
			continue
		l[2] = vfx._drag(l[2], dt, 0.9)
		l[3] = vfx._drag(l[3], dt, 0.92) + 16.0 * dt
		l[0] += (l[2] + sin(l[7] + t * 5.0) * 9.0 + vfx.wind * 0.8) * dt
		l[1] += l[3] * dt
		keep.append(l)
	leaves = keep
	for spec in [[blades, 4, 5], [vines, 5, 6], [tufts, 3, 4]]:
		var arr: Array = spec[0]
		var ai: int = spec[1]
		var li: int = spec[2]
		var k3: Array = []
		for q in arr:
			q[ai] += dt
			if q[ai] < q[li]:
				k3.append(q)
		arr.clear()
		arr.append_array(k3)
	keep = []
	for f in flakes:
		f[4] += dt
		if f[4] > f[5]:
			continue
		f[2] = vfx._drag(f[2], dt, 0.93)
		f[3] = vfx._drag(f[3], dt, 0.93) + f[9] * dt
		f[0] += (f[2] + sin(f[8] + t * 2.2) * 4.0 + vfx.wind * 0.6) * dt
		f[1] += f[3] * dt
		keep.append(f)
	flakes = keep
	keep = []
	for a in arcs:
		a[5] += dt
		if a[5] < a[6]:
			keep.append(a)
	arcs = keep
	keep = []
	for h in hops:
		h[4] += dt
		if h[4] > h[5]:
			continue
		h[6] -= dt
		if h[6] <= 0.0:
			h[6] = 0.04
			var an := randf() * TAU
			h[2] = cos(an) * 70.0
			h[3] = sin(an) * 70.0
		h[0] += h[2] * dt
		h[1] += h[3] * dt
		keep.append(h)
	hops = keep

# ------------------------------------------------------------------ draw

## Crystals stand on the ground (sandbox drawGround): under actors.
func draw_ground(buf: PackedByteArray):
	var K: float = vfx.K
	_draw_growth(buf)
	for c in crystals:
		var age: float = c[4]
		var g := minf(1.0, age / 0.1)
		# snap up with overshoot: 125% then settle (principle 6)
		var s := g * 1.25 if g < 1.0 else 1.0 + maxf(0.0, 0.15 - (age - 0.1) * 1.5)
		var h: float = c[2] * s
		var x: float = c[0]
		var y: float = c[1]
		for q in [-1, 0, 1]:
			vfx._put(buf, roundi((x + q) * K), roundi((y + 1.0) * K), SHADOW)
		body(buf, Vector2(x + c[3] * h * 0.5, y - h * 0.5), Vector2(c[3], -1.0).normalized(),
			{"t": "diamond", "a": maxf(1.5, h * 0.5), "b": maxf(1.2, h * 0.22)}, c[6], null, true)

## Grass tufts, blades with flowers, vines (sandbox drawEDecals 'grass' + drawGround).
func _draw_growth(buf: PackedByteArray):
	var t: float = vfx._t
	# rune decal (sandbox DECAL.rune): dashed ellipse dithering away, 4 dots
	for q in runes:
		var f: float = 1.0 - q[3] / q[4]
		var r: float = q[2]
		var steps := ceili(TAU * r * 1.3)
		for i in steps:
			var a := TAU * i / steps
			var X := roundi(q[0] + cos(a) * r)
			var Y := roundi(q[1] + sin(a) * r * 0.7)
			if (i & 1) and vfx._bayer(X, Y) < f:
				spx(buf, X, Y, ARCANE.floor2)
		if f > 0.3:
			for i in 4:
				var a2: float = float(i) / 4.0 * TAU + q[5]
				spx(buf, roundi(q[0] + cos(a2) * r), roundi(q[1] + sin(a2) * r * 0.7), ARCANE.spark[3])
	var L: Dictionary = LIFE
	for q in tufts:
		var k: float = q[3] / q[4]
		var X := roundi(q[0])
		var Y := roundi(q[1])
		if vfx._bayer(X, Y) >= 1.0 - k:
			continue
		spx(buf, X, Y, L.leaf[2 + (q[2] & 1)])
		if q[2] == 0:
			spx(buf, X, Y - 1, L.leaf[1])
	for b in blades:
		var age: float = b[4]
		if age < b[3]:
			continue
		var h: int = mini(b[2], ceili((age - b[3]) * 18.0))
		var k2: float = age / b[5]
		var X2 := roundi(b[0])
		var Y2 := roundi(b[1])
		if k2 > 0.85 and vfx._bayer(X2, Y2) < (k2 - 0.85) * 6.6:
			continue
		var sway := roundi(sin(t * 2.2 + b[7]) * 0.7)
		for j in h:
			spx(buf, X2 + (sway if j == h - 1 else 0), Y2 - j, L.leaf[1] if j == h - 1 else L.leaf[2 + (b[6] & 1)])
		if b[8] and age - b[3] > (0.15 if b[5] < 3.5 else 0.8):
			var c: Color = L.petal[b[6] % 2]
			spx(buf, X2 + sway, Y2 - h, L.petal[1])
			spx(buf, X2 + sway - 1, Y2 - h, c)
			spx(buf, X2 + sway + 1, Y2 - h, c)
			spx(buf, X2 + sway, Y2 - h - 1, c)
	for v in vines:
		var Lg: float = v[3] * minf(1.0, v[5] / v[4])
		var k3: float = v[5] / v[6]
		var x: float = v[0]
		var y: float = v[1]
		var sgo := 0.0
		while sgo < Lg:
			var a: float = v[2] + sin(sgo * 0.22 + v[8]) * v[7]
			x += cos(a) * 0.8
			y += sin(a) * 0.8 * 0.8
			sgo += 0.8
			if k3 > 0.8 and vfx._bayer(roundi(x), roundi(y)) < (k3 - 0.8) * 5.0:
				continue
			spx(buf, roundi(x), roundi(y), L.vine[1])
			if int(sgo * 10.0) % 60 < 8:
				spx(buf, roundi(x + sin(a) * 1.5), roundi(y - cos(a) * 1.5), L.leaf[1])
		spx(buf, roundi(x), roundi(y), L.vine[0])

func draw_over(buf: PackedByteArray):
	var K: float = vfx.K
	for s in shards:
		var k: float = s[9] / s[10]
		if vfx.dissolved(s[10], k, 0.75):
			continue
		var x: float = s[0]
		var y: float = s[1] - s[2]
		if s[2] > 1.0:
			vfx._put(buf, roundi(s[0] * K), roundi(s[1] * K), SHADOW)
		var pal: Array = s[11]
		var vx := cos(s[6])
		var vy := sin(s[6])
		var L: float = s[8]
		var tt := -L
		while tt <= L:
			var c: Color = pal[0] if absf(tt) < 0.6 else (pal[1] if tt > 0.0 else pal[3])
			var X := roundi((x + vx * tt) * K)
			var Y := roundi((y + vy * tt * 0.7) * K)
			vfx._put(buf, X, Y, c)
			vfx._put(buf, X + 1, Y, c)
			tt += 0.4
	draw_paths(buf)
	for g in glyphs:
		var kg: float = g[3] / g[4]
		if vfx.dissolved(g[4], kg, 0.7):
			continue
		var cols: Array = g[6]
		draw_glyph(buf, g[0], g[1], g[5], cols[mini(cols.size() - 1, int(kg * cols.size()))])
	for sl in slashes:
		_draw_slash(buf, sl)
	# steam: dithered puffs (sandbox drawSoft, per puff): dense core light, edges thin out
	var grid_size: Vector2i = vfx._size
	var grid_origin: Vector2i = vfx._origin
	var bayer_values: Array = vfx.BAYER
	for m in mists:
		var km: float = m[6] / m[7]
		var dens: float = 1.05 * pow(1.0 - km, 0.8)
		var rc: float = m[4] * K
		var R := ceili(rc)
		var cx := roundi(m[0] * K)
		var cy := roundi(m[1] * K)
		var mc: Array = m[8]
		var colors := PackedByteArray()
		for color: Color in mc:
			colors.append_array(PackedByteArray([color.r8, color.g8, color.b8]))
		for oy in range(maxi(-R, grid_origin.y - cy), mini(R + 1, grid_origin.y + grid_size.y - cy)):
			var row_offset := ((cy + oy - grid_origin.y) * grid_size.x + cx - grid_origin.x) * 4
			var bayer_row := ((cy + oy) & 3) << 2
			for ox in range(maxi(-R, grid_origin.x - cx), mini(R + 1, grid_origin.x + grid_size.x - cx)):
				var d := sqrt(float(ox * ox + oy * oy))
				if d >= rc:
					continue
				var w := 1.0 - d / rc
				var v := dens * w * w * 2.2
				var b: float = float(bayer_values[bayer_row | ((cx + ox) & 3)]) / 16.0
				var L := v + (b - 0.5) * 0.35
				var color_index := 0 if L > 1.15 else (3 if L > 0.7 else 6)
				if L <= 0.7 and not (v > 0.25 and b < v * 1.4):
					continue
				var pixel := row_offset + ox * 4
				buf[pixel] = colors[color_index]
				buf[pixel + 1] = colors[color_index + 1]
				buf[pixel + 2] = colors[color_index + 2]
				buf[pixel + 3] = 255
	for q in pulls:
		var kp: float = q[3] / q[4]
		var r: float = q[2] * (1.0 - kp * kp)
		var cols: Array = q[5]
		var steps := maxi(10, ceili(TAU * r * 1.2))
		for i in steps:
			if (i + (vfx._steps >> 1)) % 3 == 0:
				continue
			var a := TAU * i / steps
			spx(buf, roundi(q[0] + cos(a) * r), roundi(q[1] + sin(a) * r), cols[mini(cols.size() - 1, int(kp * cols.size()))])
	# bubbles: dark rim, light body, one specular pixel; swell before popping
	for q in bubbles:
		if q.size() > 7 and q[7]:
			if poison_status_visible:
				_draw_poison_status_bubble(buf, q)
			continue
		var kb: float = q[4] / q[5]
		var r: float = q[3] + (0.6 if kb > 0.75 else 0.0)
		var X0 := roundi(q[0])
		var Y0 := roundi(q[1])
		var al: float = q[6] if q.size() > 6 else 1.0
		for e in _bubble_px(r):
			spx(buf, X0 + e[0], Y0 + e[1], Color(PLAGUE.outline if e[2] else PLAGUE.light, al))
		spx(buf, X0 - roundi(r * 0.5), Y0 - roundi(r * 0.5), Color(PLAGUE.hi, al))
	for q in rays:
		var k: float = q[4] / q[5]
		var len: float = q[3] * (k / 0.3 if k < 0.3 else 1.0)
		var cols: Array = q[6]
		var c: Color = cols[mini(cols.size() - 1, int(k * cols.size()))]
		var a: float = q[2]
		var p0 := Vector2(q[0] + cos(a) * q[7], q[1] + sin(a) * q[7] * 0.8)
		var p1 := Vector2(q[0] + cos(a) * (q[7] + len), q[1] + sin(a) * (q[7] + len) * 0.8)
		if k > 0.6 and vfx._bayer(roundi(p1.x), roundi(p1.y)) < (k - 0.6) * 2.5:
			continue
		line(buf, p0, p1, c)
	for q in streaks:
		var k2: float = q[4] / q[5]
		var cols2: Array = q[6]
		line(buf, Vector2(q[0], q[1]), Vector2(q[2], q[3]), cols2[mini(cols2.size() - 1, int(k2 * cols2.size()))])
	var t: float = vfx._t
	for l in leaves:
		var kl: float = l[5] / l[6]
		if vfx.dissolved(l[7], kl, 0.8):
			continue
		var flip := sin(l[7] + t * 7.0) > 0.0
		var cols: Array = l[4]
		spx(buf, roundi(l[0]), roundi(l[1]), cols[0 if flip else 1])
		spx(buf, roundi(l[0]) + (1 if flip else 0), roundi(l[1]) + (0 if flip else 1), cols[2 if cols.size() > 3 else 1])
	var pal: Array = ICE.mote
	for f in flakes:
		var k: float = f[4] / f[5]
		if vfx.dissolved(f[8], k, 0.75):
			continue
		var size: int = f[6]
		# shrink a size as it ages: break up, don't fade
		if k > 0.55 and size > 0:
			size -= 1
		var pose: int = int(f[8] + t * f[7]) & 1
		var X := roundi(f[0] * K)
		var Y := roundi(f[1] * K)
		for q in FLAKES[size][pose]:
			vfx._put(buf, X + q[0], Y + q[1], pal[q[2]] if k < 0.4 else pal[mini(3, q[2] + 1)])
	for m in motes:
		var k: float = m[5] / m[6]
		if vfx.dissolved(m[9], k, 0.7):
			continue
		var cols: Array = m[4]
		var c: Color = cols[mini(cols.size() - 1, int(k * cols.size()))]
		var X := roundi(m[0] * K)
		var Y := roundi(m[1] * K)
		# one sandbox pixel = a 2x2 block; young swaying motes are a plus of
		# blocks (sandbox snowflake); old ones shrink to one cell before vanishing
		if k > 0.6:
			vfx._put(buf, X, Y, c)
			continue
		_block(buf, X, Y, c)
		if k < 0.2 and m[8] > 5.0:
			_block(buf, X + 2, Y, c); _block(buf, X - 2, Y, c); _block(buf, X, Y + 2, c); _block(buf, X, Y - 2, c)

func _draw_poison_status_bubble(buf: PackedByteArray, q: Array) -> void:
	var phase: float = clampf(q[4] / q[5], 0.0, 1.0)
	var radius: float = q[3] * (0.72 + sin(phase * PI) * 0.10) * vfx.K
	var center: Vector2 = Vector2(q[0], q[1]) * vfx.K
	var extent := ceili(radius + 1.0)
	var fade := smoothstep(0.0, 0.16, phase) * (1.0 - smoothstep(0.72, 1.0, phase))
	for y in range(floori(center.y) - extent, floori(center.y) + extent + 1):
		for x in range(floori(center.x) - extent, floori(center.x) + extent + 1):
			var offset: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / radius
			var distance: float = offset.length()
			var coverage := 1.0 - smoothstep(0.65, 1.15, distance)
			if coverage <= 0.0:
				continue
			var highlight := maxf(0.0, 1.0 - (offset - Vector2(-0.3, -0.4)).length() * 1.4)
			var color: Color = Color("#70bd38").lerp(PLAGUE.hi, highlight * 0.7)
			color.a = float(q[6]) * 1.2 * coverage * fade * (0.55 + 0.45 * smoothstep(0.2, 0.7, distance))
			_rect(buf, x, y, x + 1, y + 1, color)

var _bubble_cache := {}
## Sandbox-pixel offsets of a bubble of radius r: [ox, oy, is_rim], cached.
func _bubble_px(r: float) -> Array:
	var key := roundi(r * 10.0)
	if _bubble_cache.has(key):
		return _bubble_cache[key]
	var out := []
	var R := ceili(r + 1.0)
	for oy in range(-R, R + 1):
		for ox in range(-R, R + 1):
			var d := Vector2(ox, oy).length()
			if d <= r + 0.5:
				out.append([ox, oy, d > r - 0.5])
	_bubble_cache[key] = out
	return out

func _block(buf: PackedByteArray, x: int, y: int, c: Color):
	_rect(buf, x, y, x + 2, y + 2, c)

## Fill cells [x0, x1) x [y0, y1) straight into the buffer (clipped once).
func _rect(buf: PackedByteArray, x0: int, y0: int, x1: int, y1: int, c: Color):
	var o: Vector2i = vfx._origin
	var sz: Vector2i = vfx._size
	x0 = maxi(x0 - o.x, 0); x1 = mini(x1 - o.x, sz.x)
	y0 = maxi(y0 - o.y, 0); y1 = mini(y1 - o.y, sz.y)
	if x0 >= x1 or y0 >= y1:
		return
	var r := c.r8
	var g := c.g8
	var b := c.b8
	if c.a < 0.99:
		# See-through pixel (status marks on enemies): blend over what is drawn, keep the stronger alpha.
		var a8 := c.a8
		var k := c.a
		for y in range(y0, y1):
			var i := (y * sz.x + x0) * 4
			for x in range(x0, x1):
				if buf[i + 3] == 0:
					buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = a8
				else:
					buf[i] = roundi(lerpf(buf[i], r, k)); buf[i + 1] = roundi(lerpf(buf[i + 1], g, k)); buf[i + 2] = roundi(lerpf(buf[i + 2], b, k))
				i += 4
		return
	for y in range(y0, y1):
		var i := (y * sz.x + x0) * 4
		for x in range(x0, x1):
			buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = 255
			i += 4

## Sandbox put(): one sandbox pixel = the cells it covers (1-2 per axis, K ~ 1.67),
## so lines keep the sandbox's exact pixel staircase.
func spx(buf: PackedByteArray, X: int, Y: int, c: Color):
	var K: float = vfx.K
	var x0 := floori(X * K)
	var y0 := floori(Y * K)
	_rect(buf, x0, y0, maxi(floori((X + 1) * K), x0 + 1), maxi(floori((Y + 1) * K), y0 + 1), c)

## Sandbox line(): Bresenham on the sandbox pixel grid (su), drawn with spx.
func line(buf: PackedByteArray, a: Vector2, b: Vector2, c: Color):
	var x0 := roundi(a.x)
	var y0 := roundi(a.y)
	var x1 := roundi(b.x)
	var y1 := roundi(b.y)
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var e := dx + dy
	for i in 400:
		spx(buf, x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * e
		if e2 >= dy:
			e += dy
			x0 += sx
		if e2 <= dx:
			e += dx
			y0 += sy

func path(buf: PackedByteArray, pts: PackedVector2Array, c: Color):
	for i in range(1, pts.size()):
		line(buf, pts[i - 1], pts[i], c)

func draw_paths(buf: PackedByteArray):
	var A: Array = LIGHTNING.arc
	for a in arcs:
		var pts: PackedVector2Array = a[10] if a[10] != null else jag(a[0], a[1], a[2], a[3], a[4])
		if a[8]:
			var sh := PackedVector2Array()
			for q in pts:
				sh.append(q + Vector2(1.0, 0.0))
			path(buf, sh, A[2])
		path(buf, pts, A[a[7]])
		if a[9]:
			if a[11] != null:
				path(buf, a[11], A[a[7]])
			else:
				var m := pts[pts.size() / 2]
				path(buf, jag(m.x, m.y, m.x + (randf() - 0.5) * 16.0, m.y + 6.0 + randf() * 8.0, 3.0), A[a[7]])
	for h in hops:
		var k: float = h[4] / h[5]
		var c: Color = A[0] if k < 0.3 else (A[1] if k < 0.6 else A[2])
		spx(buf, roundi(h[0]), roundi(h[1]), c)
		spx(buf, roundi(h[0] - h[2] * 0.012), roundi(h[1] - h[3] * 0.012), A[2])

func _draw_slash(buf: PackedByteArray, sl: Dictionary):
	var k: float = minf(1.0, sl.t / sl.dur)
	var cur: float = sl.span * k
	var cols: Array = sl.cols
	var steps := ceili(sl.span * sl.rout * 1.6)
	for i in steps + 1:
		var rel: float = float(i) / steps * sl.span
		if rel > cur:
			break
		var age: float = (cur - rel) / sl.span * sl.dur + maxf(0.0, sl.t - sl.dur)
		var fade: float = 1.0 - age / (sl.dur * 0.9 + sl.linger * 0.6)
		if fade <= 0.0:
			continue
		var a: float = sl.a0 + rel * sl.dir
		var ca := cos(a)
		var sa := sin(a)
		var thick: float = (sl.rout - sl.rin) * (0.3 + 0.7 * sin(rel / sl.span * PI))
		var sharp: bool = sl.get("sharp", false)
		if sharp:
			thick *= 0.22 * sqrt(fade)
		var r: float = sl.rout - thick
		while r <= sl.rout:
			var X := roundi(sl.cx + ca * r)
			var Y := roundi(sl.cy + sa * r)
			if sharp or vfx._bayer(X, Y) <= fade:
				var band: float = (sl.rout - r) / thick
				var color: Color = cols[0] if band < 0.2 else (cols[1] if band < 0.55 else cols[2])
				if sharp and fade < 0.5:
					color = cols[1] if fade > 0.25 else cols[2]
				spx(buf, X, Y, color)
			r += 0.7
	if k < 1.0 and not sl.get("sharp", false):
		var a3: float = sl.a0 + cur * sl.dir
		line(buf, Vector2(sl.cx + cos(a3) * sl.rin, sl.cy + sin(a3) * sl.rin), Vector2(sl.cx + cos(a3) * (sl.rout + 1.0), sl.cy + sin(a3) * (sl.rout + 1.0)), cols[0])

## Nova front rim (sandbox drawElementTop, enovas): dashed bright band at the
## live radius, marching. Radius from the gameplay part, so it is the hitbox.
func draw_nova(buf: PackedByteArray, x: float, y: float, r: float, rim: Array):
	var K: float = vfx.K
	var frame: int = vfx._steps
	var steps := ceili(TAU * r * 1.2)
	var i := 0
	while i < steps:
		var a := TAU * i / steps
		var c: Color = rim[0] if ((i + (frame >> 1)) & 3) != 0 else rim[1]
		var X := roundi((x + cos(a) * r) * K)
		var Y := roundi((y + sin(a) * r) * K)
		vfx._put(buf, X, Y, c); vfx._put(buf, X + 1, Y, c); vfx._put(buf, X, Y + 1, c); vfx._put(buf, X + 1, Y + 1, c)
		i += 2

## Shaded body (sandbox drawBody): diamond oriented along dir, or orb.
## pal = [core, light, mid, dark, outline]; rim replaces the outline colour;
## ink draws a dark outer outline so the body reads over busy ground.
## The inside test runs once per pixel into a mask; edges are mask lookups.
func body(buf: PackedByteArray, pos: Vector2, dir: Vector2, b: Dictionary, pal: Array, rim = null, ink: bool = true, scale: float = 1.0):
	var K: float = vfx.K
	var orb: bool = b.t == "orb"
	var ra: float = (float(b.get("r", 0.0)) if orb else float(b.a)) * K * scale
	var rb: float = (float(b.get("r", 0.0)) if orb else float(b.b)) * K * scale
	var rb2 := maxf(rb, 0.75)
	var cx := roundi(pos.x * K)
	var cy := roundi(pos.y * K)
	var R := ceili(maxf(ra, rb) + 1.0)
	var W := 2 * R + 5                        # mask covers -R-2 .. R+2
	var mask := PackedByteArray()
	mask.resize(W * W)
	var r2 := ra * ra + 0.5
	for my in W:
		var oy := my - R - 2
		for mx in W:
			var ox := mx - R - 2
			var inside: bool
			if orb:
				inside = ox * ox + oy * oy <= r2
			else:
				var u := ox * dir.x + oy * dir.y
				var v := -ox * dir.y + oy * dir.x
				inside = absf(u) / ra + absf(v) / rb2 <= 1.0
			mask[my * W + mx] = 1 if inside else 0
	for my in range(1, W - 1):
		var oy2 := my - R - 2
		for mx in range(1, W - 1):
			var ox2 := mx - R - 2
			var m := my * W + mx
			var c = null
			if mask[m] == 1:
				if mask[m + 1] == 0 or mask[m - 1] == 0 or mask[m + W] == 0 or mask[m - W] == 0:
					c = rim if rim != null else pal[4]
				elif not orb and ox2 * dir.x + oy2 * dir.y > ra * 0.45:
					c = pal[0]
				else:
					var sh: float = -(ox2 + oy2) / maxf(ra, 1.0) if orb else -(ox2 * 0.35 + oy2) / maxf(rb, 1.0)
					c = pal[1] if sh > 0.5 else (pal[3] if sh < -0.5 else pal[2])
					if orb and ox2 == -1 and oy2 == -1:
						c = pal[0]
			elif ink and (mask[m + 1] == 1 or mask[m - 1] == 1 or mask[m + W] == 1 or mask[m - W] == 1):
				c = INK
			if c != null:
				vfx._put(buf, cx + ox2, cy + oy2, c)
