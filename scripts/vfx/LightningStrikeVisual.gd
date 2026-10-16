extends Node2D

var mark_ref: WeakRef
var caster_ref: WeakRef
var world_ref: WeakRef
var vfx
var radius := 100.0
var duration := 0.55
var charge := 0.0
var struck := false
var age := 0.0
var branch_paths: Array[PackedVector2Array] = []
var sky := PackedVector2Array()
var rng := RandomNumberGenerator.new()
var slam_emitted := false
var has_charge := true

func setup(part, owner_vfx) -> void:
	vfx = owner_vfx
	has_charge = part.part_name == "mark"
	mark_ref = weakref(part)
	caster_ref = weakref(part.cast.caster) if is_instance_valid(part.cast.caster) else null
	world_ref = weakref(part.cast.world) if is_instance_valid(part.cast.world) else null
	position = part.global_position
	radius = maxf(10.0, part.geo("radius", 100.0))
	duration = maxf(0.01, part.total_life()) if part.part_name == "mark" else 0.55
	rng.seed = part.get_instance_id()

func _ready() -> void:
	add_to_group("lightning_visuals")
	top_level = true
	z_index = 8
	for i in 9:
		var angle := float(i) * TAU / 9.0 + rng.randf_range(-0.24, 0.24)
		var reach := radius * rng.randf_range(0.65, 1.0)
		var path := PackedVector2Array([Vector2.ZERO])
		for j in range(1, 10):
			var r := reach * float(j) / 9.0
			path.append(Vector2.from_angle(angle + rng.randf_range(-0.24, 0.24)) * r)
		branch_paths.append(path)
		var fork := PackedVector2Array([path[4]])
		var fork_angle := angle + rng.randf_range(-0.8, 0.8)
		for j in range(1, 5):
			fork.append(path[4] + Vector2.from_angle(fork_angle + rng.randf_range(-0.25, 0.25)) * reach * float(j) * 0.09)
		branch_paths.append(fork)
	_make_sky()
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null and has_charge:
		audio.play_sound(audio.SoundType.SPELL_LIGHTNING, 0.5, 1.0)

func _make_sky() -> void:
	sky.clear()
	var height := maxf(700.0, get_viewport_rect().size.y)
	for i in 15:
		var k := float(i) / 14.0
		sky.append(Vector2(rng.randf_range(-55.0, 55.0) * (1.0 - k), -height * (1.0 - k)))

func impact(part) -> void:
	if struck:
		return
	struck = true
	age = 0.0
	radius = maxf(10.0, part.geo("radius", radius))
	vfx.shake(0.7)
	var p := global_position / (1280.0 / 192.0)
	for i in (8 if vfx.reduced_effects else 20):
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(12.0, 30.0)
		vfx.spark(p.x, p.y, cos(angle) * speed, sin(angle) * speed, rng.randf_range(0.2, 0.5), [Color("#f4ffff"), Color("#69cdff"), Color("#4873f0")])
	var audio = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sound(audio.SoundType.SPELL_IMPACT_LIGHTNING, 0.9, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	if not vfx.presenter.enabled or (world_ref != null and not is_instance_valid(world_ref.get_ref())):
		queue_free()
		return
	if struck:
		age += delta
		if age > 1.3:
			queue_free()
			return
		if age < 0.14 and not vfx.reduced_effects:
			_make_sky()
	else:
		var mark = mark_ref.get_ref()
		if not is_instance_valid(mark) or mark.done:
			queue_free()
			return
		charge = clampf(float(mark.age) / duration, 0.0, 1.0)
		var caster = caster_ref.get_ref() if caster_ref else null
		var staff = caster.get_node_or_null("OrbitingStaff") if is_instance_valid(caster) else null
		if staff != null:
			staff.set_lightning_pose(charge)
		if charge >= 0.48 and not slam_emitted:
			slam_emitted = true
			if staff != null:
				var p: Vector2 = staff.global_position / (1280.0 / 192.0)
				vfx.ring(p.x, p.y, 3.5, 0.18, [Color("#d9f8ff"), Color("#65bcff")])
	queue_redraw()

func _draw_path(path: PackedVector2Array, color: Color, width: float, progress: float = 1.0) -> void:
	var count := clampi(ceili(progress * (path.size() - 1)) + 1, 2, path.size())
	draw_polyline(path.slice(0, count), color, width, true)

func _draw() -> void:
	var blue := Color("#4caaff")
	if not struck:
		var caster = caster_ref.get_ref() if caster_ref else null
		var staff = caster.get_node_or_null("OrbitingStaff") if is_instance_valid(caster) else null
		if staff != null:
			var tip: Vector2 = staff.staff.to_global(Vector2(0, -staff.staff.texture.get_height() * 0.32)) - global_position
			var gather := minf(charge / 0.4, 1.0)
			for i in 9:
				var angle := float(i) * TAU / 9.0 + charge * 4.0
				var r := lerpf(36.0, 5.0, fmod(gather + float(i) * 0.13, 1.0))
				var p := tip + Vector2.from_angle(angle) * r
				draw_line(p, p + (tip - p).normalized() * 6.0, Color(0.4, 0.8, 1.0, 0.85), 2.0, true)
			draw_circle(tip, 4.0 + gather * 3.0, Color(0.7, 0.95, 1.0, 0.9))
		var k := smoothstep(0.38, 0.7, charge)
		if k > 0.0:
			draw_circle(Vector2.ZERO, radius, Color(0.12, 0.4, 1.0, 0.08 * k))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.2, 0.65, 1.0, k), 3.0, true)
			draw_arc(Vector2.ZERO, radius * lerpf(1.1, 0.88, charge), -PI * 0.5, -PI * 0.5 + TAU * charge, 80, Color(0.65, 0.92, 1.0, k), 2.0, true)
			for i in 8:
				var a := float(i) * TAU / 8.0
				draw_line(Vector2.from_angle(a) * radius * 0.92, Vector2.from_angle(a) * radius, Color(0.7, 0.95, 1.0, k), 2.0, true)
		return
	var fade := 1.0 - smoothstep(0.35, 1.3, age)
	for i in branch_paths.size():
		if vfx.reduced_effects and i % 2 == 1:
			continue
		var path := branch_paths[i]
		_draw_path(path, Color(0.06, 0.10, 0.15, fade * 0.65), 5.0, clampf(age / 0.2, 0.0, 1.0))
		var flicker := 0.7 if vfx.reduced_effects else 0.6 + 0.4 * sin(age * 23.0 + float(i) * 2.7)
		_draw_path(path, Color(blue, fade * flicker * 0.35), 8.0, clampf(age / 0.18, 0.0, 1.0))
		_draw_path(path, Color(0.45, 0.85, 1.0, fade * flicker), 1.5, clampf(age / 0.18, 0.0, 1.0))
		if age < 0.28:
			var index := mini(path.size() - 1, int(age / 0.2 * (path.size() - 1)))
			draw_circle(path[index], 3.0, Color(0.85, 0.98, 1.0, fade))
	if age < 0.18:
		var bolt_alpha := 1.0 - smoothstep(0.08, 0.18, age)
		_draw_path(sky, Color(0.2, 0.5, 1.0, bolt_alpha * 0.25), 24.0)
		_draw_path(sky, Color(0.35, 0.7, 1.0, bolt_alpha), 10.0)
		_draw_path(sky, Color(0.93, 0.99, 1.0, bolt_alpha), 3.0)
		var fork := PackedVector2Array([sky[9], sky[10] + Vector2(radius * 0.4, 0), Vector2(radius * 0.6, -10)])
		_draw_path(fork, Color(0.5, 0.8, 1.0, bolt_alpha), 2.0)
	if age < 0.3:
		draw_arc(Vector2.ZERO, radius * clampf(age / 0.16, 0.05, 1.0), 0.0, TAU, 96, Color(0.6, 0.9, 1.0, 1.0 - age / 0.3), 3.0, true)
	if age < 0.08 and not vfx.reduced_effects:
		draw_circle(Vector2.ZERO, radius * 0.7, Color(0.8, 0.95, 1.0, (1.0 - age / 0.08) * 0.4))
