extends Node2D

var part_ref: WeakRef
var state: Dictionary
var owner_vfx
const WPS := 1280.0 / 192.0

func setup(part, presentation: Dictionary, vfx) -> void:
	part_ref = weakref(part)
	state = presentation
	owner_vfx = vfx
	add_to_group("infection_visuals")
	top_level = true
	z_index = 8

func _process(_dt: float) -> void:
	var part = part_ref.get_ref()
	if not is_instance_valid(part) or part.done or not owner_vfx.presenter.enabled:
		queue_free()
		return
	queue_redraw()

func _seed(point: Vector2, radius: float, alpha: float) -> void:
	draw_circle(point, radius * 1.6, Color(0.22, 0.48, 0.08, alpha * 0.12), true, -1, true)
	draw_circle(point, radius, Color(0.28, 0.48, 0.10, alpha * 0.85), true, -1, true)
	draw_circle(point + Vector2(-radius * 0.15, -radius * 0.16), radius * 0.72, Color(0.65, 0.82, 0.26, alpha), true, -1, true)
	draw_circle(point + Vector2(-radius * 0.20, -radius * 0.26), radius * 0.32, Color(0.87, 0.95, 0.57, alpha * 0.85), true, -1, true)

func _draw() -> void:
	var part = part_ref.get_ref()
	if not is_instance_valid(part) or part.done or part.infection == null:
		return
	var inf = part.infection
	var time := float(inf.elapsed)
	for link in inf.links:
		var point: Vector2 = Vector2(link.position) + Vector2(0, -10)
		var wake: Array = state.get("infection_wakes", {}).get(link.id, [])
		for i in range(1, wake.size()):
			var fade := clampf(1.0 - float(wake[i].age) / 0.16, 0.0, 1.0)
			var a: Vector2 = Vector2(wake[i - 1].pos) * WPS + Vector2(0, 10)
			var b: Vector2 = Vector2(wake[i].pos) * WPS + Vector2(0, 10)
			draw_line(a, b, Color(0.57, 0.76, 0.21, fade * 0.55), 1.0 + fade * 4.0, true)
		_seed(point, 4.2 + sin(time * 11.0) * 0.3, 1.0)
	for host in inf.hosts:
		var enemy = host.ref.get_ref()
		if not is_instance_valid(enemy):
			continue
		var sprite = enemy.get_node_or_null("Sprite2D")
		var center: Vector2 = sprite.global_position if sprite != null else Vector2(host.pos)
		var grow := clampf((time - float(host.at)) / 0.2, 0.0, 1.0) * clampf((float(host.expires) - time) / 0.35, 0.0, 1.0)
		var pulse := float(state.get("infection_pulses", {}).get(host.id, 0.0)) / 0.18
		for i in 3:
			var angle := float(i) * TAU / 3.0 + float(int(host.id) % 13) * 0.25
			var point := center + Vector2(cos(angle) * 8.0, sin(angle) * 4.0)
			_seed(point, (2.4 + pulse * 0.8 + sin(time * 3.0 + angle) * 0.2) * grow, 0.85)
	for spore in inf.spores:
		var fade := clampf((float(spore.expires) - time) / 0.35, 0.0, 1.0)
		_seed(spore.position, (4.0 + sin(time * 4.0) * 0.4) * fade, fade)
