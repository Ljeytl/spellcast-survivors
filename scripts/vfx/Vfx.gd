extends Node2D
## Chunky-magic VFX service (autoload "Vfx"). See docs/VFX_PORT_BRIEF.md.
##
## Effects live on a world-anchored grid: 1 VFX cell = CELL world px = 4x4 art px.
## Two layers are drawn in world space, so the camera transform keeps them
## world-locked and z_index places them relative to actors:
##   ground (z GROUND_Z): decals, floors, rims, warnings   -> under actors
##   air    (z AIR_Z):    flames, embers, smoke, bodies     -> over actors, under UI
##
## Simulation runs in cell units (sandbox px * SANDBOX_SCALE), so numbers ported
## from tools/vfx-reference/spell_vfx_sandbox.html keep their meaning.
## VFX never change gameplay: hit-stop here freezes only this simulation.

const CELL := 8.0
const MARGIN := 2
const GROUND_Z := -1
const AIR_Z := 50
const SANDBOX_SCALE := 160.0 / 192.0
const MAX_FLAMES := 1000          # web budget: ~4 ms VFX on an M-series Mac in a late-game horde
const MAX_FLAMES_REDUCED := 400

const HEAT_SHADER := preload("res://shaders/vfx_heat.gdshader")
const DECAL_SHADER := preload("res://shaders/vfx_decal.gdshader")

# Fire material (sandbox MAT_SRC.fire). Thresholds descending.
const FIRE_HEAT := [[1.6, Color("#fff7d6")], [1.1, Color("#ffd54a")], [0.7, Color("#ff8a1f")], [0.35, Color("#e0401c")], [0.12, Color("#7a1f14")]]
const FIRE_GLOW := Color("#3a1a12")
const FIRE_EMBER := [Color("#fff7d6"), Color("#ffd54a"), Color("#ff8a1f"), Color("#e0401c")]
const FIRE_SMOKE := [Color("#4a4452"), Color("#332e3b")]
const FIRE_SCORCH := [Color("#141010"), Color("#211715")]
# Splat footprints for flame radius 0, 1, 2 (sandbox: ox*ox + oy*oy <= r*r + 1).
static var DISK_XY: Array = _make_disks()
var _disks: Array = []
var _disk_w := -1

static func _make_disks() -> Array:
	var out := []
	for r in 3:
		var offs := PackedInt32Array()
		for qy in range(-r, r + 1):
			for qx in range(-r, r + 1):
				if qx * qx + qy * qy <= r * r + 1:
					offs.append_array([qx, qy])
		out.append(offs)
	return out

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var reduced_effects := false
var wind := 0.0                 # sandbox units; visual only
var stats := {"flames": 0, "sim_ms": 0.0, "draw_ms": 0.0, "cells": 0}

var _t := 0.0
var _bench := {}                # active benchmark accumulator, see bench()
var _frame := 0
var _stop := 0                  # VFX-only hit-stop frames
var _active := false

# Grid placement this frame (in cells, world-anchored).
var _origin := Vector2i.ZERO
var _size := Vector2i.ZERO

# Flames: one interleaved PackedFloat32Array, stride FS. Positions in cell units,
# velocities in sandbox units (scaled by SANDBOX_SCALE when integrated).
enum { AX, AY, LX, LY, WX, WY, VX, VY, DVX, DX, DY, RISE, AGE, LIFE, HEAT, GX, SMALL, FS }
var _fd := PackedFloat32Array()
var _f_anchor: Array = []       # Node2D, or null for static
var _f_count := 0

var _embers: Array = []         # [x, y, vx, vy, age, life]
var _smoke: Array = []          # [x, y, vx, rise, age, life, s]
var _decals: Array = []         # [sprite, material, age, life]
var _emitters: Array = []       # debug/test emitters

var _heat := PackedFloat32Array()
var _under := PackedByteArray()  # air layer, drawn under heat (smoke)
var _over := PackedByteArray()   # air layer, drawn over heat (embers)
var _ground := PackedByteArray()

var _ground_layer: Sprite2D
var _decal_root: Node2D
var _air_layer: Sprite2D
var _tex := {}

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_ground_layer = _make_layer(GROUND_Z, null)
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
	_fd.resize(0)
	_f_anchor.clear()
	_f_count = 0
	_embers.clear(); _smoke.clear(); _emitters.clear()
	for d in _decals:
		d[0].queue_free()
	_decals.clear()

# ------------------------------------------------------------------ coords

static func world_to_cell(p: Vector2) -> Vector2:
	return p / CELL

static func cell_to_world(c: Vector2) -> Vector2:
	return c * CELL

func _visible_world_rect() -> Rect2:
	var vp := get_viewport()
	var inv := vp.get_canvas_transform().affine_inverse()
	var r := vp.get_visible_rect()
	var a := inv * r.position
	var b := inv * r.end
	return Rect2(a, b - a).abs()

# ------------------------------------------------------------------ juice

## Freezes the VFX simulation only. Gameplay time is never touched.
func hitstop(frames: int):
	_stop = max(_stop, frames)

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

# Lattice of hs() values (256x256, wraps) so the hot per-particle turbulence
# avoids hashing. Same value noise as vn(), periodic every 256 lattice cells.
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

# ------------------------------------------------------------------ particles (cell units)

## Spawns one flame particle. anchor: Node2D to follow (attach point) or null.
## o keys match the sandbox flame(): lx, ly, vx, vy, inh, grip, rise, life, heat, small.
func flame(anchor, at: Vector2, o: Dictionary = {}):
	var cap := MAX_FLAMES_REDUCED if reduced_effects else MAX_FLAMES
	if _f_count >= cap:
		return
	var ax := at.x
	var ay := at.y
	var avx := 0.0
	var avy := 0.0
	if anchor is Node2D:
		var c := world_to_cell((anchor as Node2D).global_position)
		ax = c.x; ay = c.y
		if "velocity" in anchor:
			var vel: Vector2 = anchor.velocity / CELL / SANDBOX_SCALE
			avx = vel.x; avy = vel.y
	var lx: float = o.get("lx", 0.0)
	var ly: float = o.get("ly", 0.0)
	var inh: float = o.get("inh", 0.0)
	_fd.append_array(PackedFloat32Array([
		ax, ay, lx, ly, ax + lx, ay + ly,
		o.get("vx", 0.0) + avx * inh, o.get("vy", 0.0) + avy * inh,
		0.0, 0.0, 0.0,
		o.get("rise", 20.0) * SANDBOX_SCALE, 0.0, o.get("life", 0.6),
		o.get("heat", 1.2), 0.2 + o.get("grip", 0.0) * 2.8, o.get("small", 0.0),
	]))
	_f_anchor.append(anchor if anchor is Node2D else null)
	_f_count += 1

func ember(x: float, y: float, vx: float, vy: float, life: float):
	if _embers.size() < (150 if reduced_effects else 400):
		_embers.append([x, y, vx, vy, 0.0, life])

func puff(x: float, y: float, s: int = 0):
	if _smoke.size() < (60 if reduced_effects else 160):
		_smoke.append([x, y, 0.0, (6.0 + randf() * 5.0) * SANDBOX_SCALE, 0.0, 1.6 + randf() * 1.2, s if s > 0 else 2 + randi() % 2])

## Scorch decal: rasterized once into a small world-locked sprite on the ground
## layer; the dissolve runs in vfx_decal.gdshader, so it costs no CPU per frame.
func scorch(x: float, y: float, r: float, life: float = 6.0):
	if _decals.size() >= 40:
		var old = _decals.pop_front()
		old[0].queue_free()
	var seed := randf() * 100.0
	var R := ceili(r + 3.0)
	var cx := roundi(x)
	var cy := roundi(y)
	var img := Image.create_empty(2 * R + 1, 2 * R + 1, false, Image.FORMAT_RGBA8)
	for qy in range(-R, R + 1):
		for qx in range(-R, R + 1):
			var X := cx + qx
			var Y := cy + qy
			var dist := Vector2(qx, qy * 1.25).length()
			var edge := r * (0.7 + 0.55 * vn(X * 0.3 + seed, Y * 0.3))
			if dist < edge:
				var c: Color = FIRE_SCORCH[0] if dist < edge * 0.55 else FIRE_SCORCH[1]
				c.a = (BAYER[((Y & 3) << 2) | (X & 3)] + 1) / 17.0
				img.set_pixel(qx + R, qy + R, c)
	var mat := ShaderMaterial.new()
	mat.shader = DECAL_SHADER
	mat.set_shader_parameter("limit", 0.95)
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

# ------------------------------------------------------------------ test effects (Milestone 0)

## Debug test flame: a small field of fire (sandbox Cinder Field) at a world point.
## Default radius = sandbox Cinder Field (20 sandbox px).
func add_test_flame(world_pos: Vector2, radius_world: float = 20.0 * SANDBOX_SCALE * CELL, life: float = -1.0) -> Dictionary:
	var c := world_to_cell(world_pos)
	var e := {"x": c.x, "y": c.y, "r": radius_world / CELL, "age": 0.0, "life": life, "acc": 0.0}
	_emitters.append(e)
	scorch(c.x, c.y + 0.5, e.r * 0.9, 1e9 if life < 0 else life + 4.0)
	return e

func clear_test_flames():
	_emitters.clear()

func _update_emitters(dt: float):
	var keep: Array = []
	for e in _emitters:
		e.age += dt
		if e.life >= 0 and e.age > e.life:
			continue
		keep.append(e)
		var r: float = e.r
		# Sandbox spawns max(1, n/3) flame tongues per 60 fps frame; made frame-rate independent.
		var per_frame := r * r * 0.0042 / (SANDBOX_SCALE * SANDBOX_SCALE) / 3.0
		e.acc += maxf(1.0, per_frame) * dt * 60.0
		while e.acc >= 1.0:
			e.acc -= 1.0
			var ang := randf() * TAU
			var d := sqrt(randf()) * r * 0.9
			var at := Vector2(e.x + cos(ang) * d, e.y + sin(ang) * d)
			var rise := 20.0 + randf() * 12.0
			var lf := 0.45 + randf() * 0.35
			for j in 3:
				flame(null, at, {"lx": (randf() - 0.5) * 1.5, "ly": randf() - 0.5, "heat": 0.8 * 0.46, "rise": rise * (0.9 + j * 0.18), "life": lf * (1.0 - j * 0.15), "small": 1.0 if j > 0 else 0.0})
		if randf() < r / SANDBOX_SCALE * 0.004 * dt * 60.0:
			ember(e.x + (randf() - 0.5) * r, e.y + (randf() - 0.5) * r * 0.6, (randf() - 0.5) * 8.0, -(14.0 + randf() * 14.0) * SANDBOX_SCALE, 0.8 + randf())
		if randf() < r / SANDBOX_SCALE * 0.003 * dt * 60.0:
			puff(e.x + (randf() - 0.5) * r, e.y - 5.0 + (randf() - 0.5) * r * 0.4)
	_emitters = keep

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
	_frame += 1
	var t0 := Time.get_ticks_usec()
	if _stop > 0:
		_stop -= 1
	else:
		_step(min(delta, 0.05))
	var t1 := Time.get_ticks_usec()
	_render()
	var t2 := Time.get_ticks_usec()
	stats.flames = _f_count
	stats.sim_ms = (t1 - t0) / 1000.0
	stats.draw_ms = (t2 - t1) / 1000.0
	if not _bench.is_empty():
		_bench_frame(delta)

## Measures frame time and VFX cost over `frames` frames; prints and emits the summary.
signal bench_done(summary: String)
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
		var summary := "VFX bench [%s]: %d frames, avg frame %.2f ms (%.0f fps), worst %.2f ms, vfx sim %.2f ms + draw %.2f ms, peak %d flames, %d cells" % [
			OS.get_name(), n, _bench.frame * 1000.0 / n, n / maxf(_bench.frame, 0.0001), _bench.worst * 1000.0,
			_bench.sim / n, _bench.draw / n, _bench.flames, stats.cells]
		_bench = {}
		print(summary)
		bench_done.emit(summary)

func _step(dt: float):
	_t += dt
	_update_emitters(dt)
	var k93 := pow(0.93, dt * 60.0)
	var k92 := pow(0.92, dt * 60.0)
	var j := 0                     # compaction write index
	for i in _f_count:
		var b := i * FS
		var age := _fd[b + AGE] + dt
		if age > _fd[b + LIFE]:
			continue
		_fd[b + AGE] = age
		var a = _f_anchor[i]
		if a != null:
			if is_instance_valid(a):
				var c := world_to_cell(a.global_position)
				_fd[b + AX] = c.x; _fd[b + AY] = c.y
			else:
				a = null
		var wx := _fd[b + WX]
		var wy := _fd[b + WY]
		var dvx := (_fd[b + DVX] + (_turb(wx + _fd[b + DX], wy + _fd[b + DY], 80.0) + wind * 1.5) * dt) * k92
		_fd[b + DVX] = dvx
		_fd[b + DX] += dvx * dt * SANDBOX_SCALE
		_fd[b + DY] -= _fd[b + RISE] * dt
		_fd[b + WX] = wx + _fd[b + VX] * dt * SANDBOX_SCALE
		_fd[b + WY] = wy + _fd[b + VY] * dt * SANDBOX_SCALE
		_fd[b + VX] *= k93
		_fd[b + VY] *= k93
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
		e[0] += e[2] * dt * SANDBOX_SCALE
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
		s[0] += (s[2] + _turb(s[0], s[1], 20.0)) * dt * SANDBOX_SCALE
		s[1] -= s[3] * dt
		keep.append(s)
	_smoke = keep
	keep = []
	for d in _decals:
		d[2] += dt
		if d[2] < d[3]:
			d[1].set_shader_parameter("limit", (1.0 - d[2] / d[3]) * 0.95)
			keep.append(d)
		else:
			d[0].queue_free()
	_decals = keep

# ------------------------------------------------------------------ render

func _bayer(x: int, y: int) -> float:
	return BAYER[((y & 3) << 2) | (x & 3)] / 16.0

func _put(buf: PackedByteArray, x: int, y: int, c: Color):
	x -= _origin.x
	y -= _origin.y
	if x < 0 or y < 0 or x >= _size.x or y >= _size.y:
		return
	var i := (y * _size.x + x) * 4
	buf[i] = c.r8; buf[i + 1] = c.g8; buf[i + 2] = c.b8; buf[i + 3] = 255

func _render():
	var vis := _visible_world_rect()
	var tl := Vector2i(floori(vis.position.x / CELL) - MARGIN, floori(vis.position.y / CELL) - MARGIN)
	var br := Vector2i(ceili(vis.end.x / CELL) + MARGIN, ceili(vis.end.y / CELL) + MARGIN)
	var size := br - tl
	if size.x <= 0 or size.y <= 0 or size.x * size.y > 200000:
		return
	_origin = tl
	var n := size.x * size.y
	if size != _size:
		_size = size
		_heat.resize(n)
		_under.resize(n * 4)
		_over.resize(n * 4)
		_ground.resize(n * 4)
	_heat.fill(0.0)
	_under.fill(0)
	_over.fill(0)
	_ground.fill(0)
	stats.cells = n
	# heat splats (sandbox accumulateHeat)
	var w := _size.x
	var hgt := _size.y
	var ox := _origin.x
	var oy := _origin.y
	if _disk_w != w:
		_disk_w = w
		_disks = []
		for offs in DISK_XY:
			var lin := PackedInt32Array()
			for q in range(0, offs.size(), 2):
				lin.append(offs[q + 1] * w + offs[q])
			_disks.append(lin)
	var disks := _disks
	for i in _f_count:
		var fb := i * FS
		var k := _fd[fb + AGE] / _fd[fb + LIFE]
		var b := pow(k, _fd[fb + GX])
		var x := (_fd[fb + AX] + _fd[fb + LX] + _fd[fb + DX]) * (1.0 - b) + (_fd[fb + WX] + _fd[fb + DX]) * b
		var y := (_fd[fb + AY] + _fd[fb + LY] + _fd[fb + DY]) * (1.0 - b) + (_fd[fb + WY] + _fd[fb + DY]) * b
		var r := maxi(0, (2 if k < 0.3 else (1 if k < 0.65 else 0)) - int(_fd[fb + SMALL]))
		var h := pow(1.0 - k, 0.7) * _fd[fb + HEAT]
		var cx := roundi(x) - ox
		var cy := roundi(y) - oy
		if cx >= 2 and cy >= 2 and cx < w - 2 and cy < hgt - 2:
			var base := cy * w + cx
			for o in disks[r]:
				_heat[base + o] += h
		else:
			var offs: PackedInt32Array = DISK_XY[r]
			for q in range(0, offs.size(), 2):
				var xx := cx + offs[q]
				var yy := cy + offs[q + 1]
				if xx >= 0 and yy >= 0 and xx < w and yy < hgt:
					_heat[yy * w + xx] += h
	# smoke under heat (sandbox drawSmoke)
	for s in _smoke:
		var k: float = s[4] / s[5]
		var c: Color = FIRE_SMOKE[0] if k < 0.5 else FIRE_SMOKE[1]
		var x0 := roundi(s[0])
		var y0 := roundi(s[1])
		for qy in s[6]:
			for qx in s[6]:
				if _bayer(x0 + qx, y0 + qy) < (1.0 - k) * 0.85:
					_put(_under, x0 + qx, y0 + qy, c)
	# embers over heat (sandbox drawTop)
	for e in _embers:
		var k: float = e[4] / e[5]
		if k > 0.7 and (_frame & 2):
			continue
		_put(_over, roundi(e[0]), roundi(e[1]), FIRE_EMBER[mini(3, int(k * 4.0))])
	_upload("heat", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RF, _heat.to_byte_array()))
	_upload("under", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _under))
	_upload("over", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _over))
	_upload("ground", Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_RGBA8, _ground))
	var world_origin := Vector2(_origin) * CELL
	_ground_layer.texture = _tex.ground
	_ground_layer.position = world_origin
	_air_layer.texture = _tex.over
	_air_layer.position = world_origin
	var mat: ShaderMaterial = _air_layer.material
	mat.set_shader_parameter("heat_tex", _tex.heat)
	mat.set_shader_parameter("under_tex", _tex.under)
	mat.set_shader_parameter("origin", _origin)

func _upload(key: String, img: Image):
	var t: ImageTexture = _tex.get(key)
	if t == null or t.get_size() != Vector2(img.get_size()):
		_tex[key] = ImageTexture.create_from_image(img)
	else:
		t.update(img)
