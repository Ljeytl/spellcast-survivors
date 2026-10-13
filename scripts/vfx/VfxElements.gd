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
const SHADOW := Color("#16141b")
const INK := Color("#120e14")

var vfx
var motes: Array = []       # [x, y, vx, vy, cols, age, life, g, sway, ph, big]
var shards: Array = []      # [x, y, z, vx, vy, vz, ang, spin, len, age, life, pal, bounced]
var crystals: Array = []    # [x, y, h, tilt, age, life, pal]
var arcs: Array = []        # [x0, y0, x1, y1, amp, age, life, c, thick, branch]  jag path, regenerated each step
var hops: Array = []        # [x, y, vx, vy, age, life, next]  hopping spark

func _init(owner):
	vfx = owner

func clear():
	motes.clear(); shards.clear(); crystals.clear(); arcs.clear(); hops.clear()

# ------------------------------------------------------------------ spawners (sandbox signatures)

func mote(x: float, y: float, vx: float, vy: float, cols: Array, life: float, g: float = 0.0, sway: float = 0.0):
	if motes.size() < (200 if vfx.reduced_effects else 700):
		motes.append([x, y, vx, vy, cols, 0.0, life, g, sway, randf() * 6.0])

func shard(x: float, y: float, vx: float, vy: float, vz: float, len: float, life: float, pal: Array = ICE.body):
	if shards.size() < (80 if vfx.reduced_effects else 260):
		shards.append([x, y, 3.0, vx, vy, vz, randf() * TAU, (randf() - 0.5) * 20.0, len, 0.0, life, pal, false])

func crystal(x: float, y: float, h: float, life: float, pal: Array = ICE.body):
	if crystals.size() < (40 if vfx.reduced_effects else 120):
		crystals.append([x, y, h, (randf() - 0.5) * 0.6, 0.0, life, pal])

## Jagged arc (sandbox jag + arcs). Regenerated every step while it lives, so
## it crackles. c = arc palette index; thick doubles it in the darker tone;
## branch adds a side fork from the midpoint (sky strikes).
func arc(x0: float, y0: float, x1: float, y1: float, amp: float, life: float, c: int = 1, thick: bool = false, branch: bool = false):
	if arcs.size() < (80 if vfx.reduced_effects else 300):
		arcs.append([x0, y0, x1, y1, amp, 0.0, life, c, thick, branch])

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

## Sandbox line(): one sandbox pixel thick = a 2x2 block every half su.
func line(buf: PackedByteArray, a: Vector2, b: Vector2, c: Color):
	var K: float = vfx.K
	var d := b - a
	var n := maxi(1, ceili(d.length() * 2.0))
	for i in n + 1:
		var p := a + d * (float(i) / n)
		_block(buf, roundi(p.x * K), roundi(p.y * K), c)

func path(buf: PackedByteArray, pts: PackedVector2Array, c: Color):
	for i in range(1, pts.size()):
		line(buf, pts[i - 1], pts[i], c)

func draw_paths(buf: PackedByteArray):
	var A: Array = LIGHTNING.arc
	for a in arcs:
		var pts := jag(a[0], a[1], a[2], a[3], a[4])
		if a[8]:
			var sh := PackedVector2Array()
			for q in pts:
				sh.append(q + Vector2(1.0, 0.0))
			path(buf, sh, A[2])
		path(buf, pts, A[a[7]])
		if a[9]:
			var m := pts[pts.size() / 2]
			path(buf, jag(m.x, m.y, m.x + (randf() - 0.5) * 16.0, m.y + 6.0 + randf() * 8.0, 3.0), A[a[7]])
	var K: float = vfx.K
	for h in hops:
		var k: float = h[4] / h[5]
		var c: Color = A[0] if k < 0.3 else (A[1] if k < 0.6 else A[2])
		_block(buf, roundi(h[0] * K), roundi(h[1] * K), c)
		_block(buf, roundi((h[0] - h[2] * 0.012) * K), roundi((h[1] - h[3] * 0.012) * K), A[2])

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
