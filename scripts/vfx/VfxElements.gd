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
const SHADOW := Color("#16141b")
const INK := Color("#120e14")

var vfx
var motes: Array = []       # [x, y, vx, vy, cols, age, life, g, sway, ph, big]
var shards: Array = []      # [x, y, z, vx, vy, vz, ang, spin, len, age, life, pal, bounced]
var crystals: Array = []    # [x, y, h, tilt, age, life, pal]
var arcs: Array = []        # [x0, y0, x1, y1, amp, age, life, c, thick, branch, pts]  pts null = regenerate every step
var hops: Array = []        # [x, y, vx, vy, age, life, next]  hopping spark
var flakes: Array = []      # [x, y, vx, vy, age, life, size, spin, ph, g]
var blobs: Array = []       # [x, y, vx, vy, r, age, life, g, stick]   water goo blobs (sandbox wblob)
var streaks: Array = []     # [x0, y0, x1, y1, age, life, cols]        foam streaks
var rays: Array = []        # [x, y, ang, len, age, life, cols, r0]    spray rays
var later: Array = []       # [t, Callable]                            delayed spawns (ripples)

func _init(owner):
	vfx = owner

func clear():
	motes.clear(); shards.clear(); crystals.clear(); arcs.clear(); hops.clear(); flakes.clear()
	blobs.clear(); streaks.clear(); rays.clear(); later.clear()

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
		blobs.append([x, y, vx, vy, r, 0.0, life, g, stick])

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
		vfx.gsplat(1 if b[8] and k > 0.35 else 0, b[0], b[1], b[4] * (1.0 - k * 0.5))

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
	var pal: Array = ICE.mote
	var t: float = vfx._t
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

func _block(buf: PackedByteArray, x: int, y: int, c: Color):
	vfx._put(buf, x, y, c); vfx._put(buf, x + 1, y, c); vfx._put(buf, x, y + 1, c); vfx._put(buf, x + 1, y + 1, c)

## Sandbox put(): one sandbox pixel = the cells it covers (1-2 per axis, K ~ 1.67),
## so lines keep the sandbox's exact pixel staircase.
func spx(buf: PackedByteArray, X: int, Y: int, c: Color):
	var K: float = vfx.K
	var x0 := floori(X * K)
	var x1 := floori((X + 1) * K)
	var y0 := floori(Y * K)
	var y1 := floori((Y + 1) * K)
	for cy in range(y0, maxi(y1, y0 + 1)):
		for cx in range(x0, maxi(x1, x0 + 1)):
			vfx._put(buf, cx, cy, c)

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
func body(buf: PackedByteArray, pos: Vector2, dir: Vector2, b: Dictionary, pal: Array, rim = null, ink: bool = true, scale: float = 1.0):
	var K: float = vfx.K
	var orb: bool = b.t == "orb"
	var ra: float = (float(b.get("r", 0.0)) if orb else float(b.a)) * K * scale
	var rb: float = (float(b.get("r", 0.0)) if orb else float(b.b)) * K * scale
	var cx := roundi(pos.x * K)
	var cy := roundi(pos.y * K)
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
			elif ink and (inside.call(ox + 1, oy) or inside.call(ox - 1, oy) or inside.call(ox, oy + 1) or inside.call(ox, oy - 1)):
				c = INK
			if c != null:
				vfx._put(buf, cx + ox, cy + oy, c)
