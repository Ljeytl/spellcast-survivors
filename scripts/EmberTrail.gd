extends Node2D
## The burning line an Ember Lance leaves behind: enemies standing in or walking into it
## burn for a short while. Anchored in the world; grows with the lance while it flies.

const MAX_ACTIVE = 3

var a = Vector2.ZERO          # throw start (global)
var b = Vector2.ZERO          # current lance tip (global)
var radius = 24.0
var tick_damage = 0.0
var tick_interval = 0.5
var linger = 1.5
var flight = 1.5
var age = 0.0
var next_hits: Dictionary = {}

func _init():
	DamageSource.stamp(self)

func _ready():
	add_to_group("ember_trails")
	z_as_relative = false
	z_index = -1
	# Cap on screen: the oldest burning line goes out first.
	var trails = get_tree().get_nodes_in_group("ember_trails").filter(func(t): return t != self and not t.is_queued_for_deletion())
	while trails.size() >= MAX_ACTIVE:
		var oldest = trails[0]
		for t in trails:
			if t.age > oldest.age:
				oldest = t
		oldest.queue_free()
		trails.erase(oldest)

func _physics_process(delta):
	advance(delta)

func lifetime() -> float:
	return flight + linger

func advance(delta: float):
	age += maxf(0.0, delta)
	if age >= lifetime():
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not preload("res://scripts/SpellTargeting.gd").alive(enemy):
			continue
		var id = enemy.get_instance_id()
		if age < float(next_hits.get(id, -INF)):
			continue
		if Geometry2D.get_closest_point_to_segment(enemy.global_position, a, b).distance_to(enemy.global_position) > radius:
			continue
		next_hits[id] = age + tick_interval
		enemy.take_damage(tick_damage, enemy.global_position, DamageSource.of(self))
	queue_redraw()

func _draw():
	var fade = clampf((lifetime() - age) / 0.6, 0.0, 1.0)
	var from = to_local(a)
	var to = to_local(b)
	if from.distance_to(to) < 1.0:
		return
	var length = from.distance_to(to)
	var dir = (to - from) / length
	var side = dir.orthogonal()
	var flicker = int(age * 12.0)
	# Broken, flickering bands of flame rather than one solid beam.
	var step = 22.0
	for s in int(length / step) + 1:
		var h0 = hash(s * 17 + flicker)
		var heat = 0.55 + float(h0 % 45) / 100.0
		var p0 = from + dir * (s * step)
		var p1 = from + dir * minf(length, s * step + step * 0.85)
		draw_line(p0, p1, Color(0.85, 0.2, 0.05, 0.28 * fade * heat), radius * 1.15, true)
		draw_line(p0, p1, Color(1.0, 0.6, 0.15, 0.45 * fade * heat), radius * 0.35, true)
	var count = int(length / 12.0)
	for i in count:
		var h = hash(i * 31 + flicker)
		var p = from + dir * (i * 12.0 + float(h % 9)) + side * (float((h >> 4) % 17) - 8.0) * radius / 12.0
		var rise = float((h >> 8) % 7)
		draw_rect(Rect2(p - Vector2(1.5, 1.5 + rise), Vector2(3, 3)), Color(1.0, 0.85 if h % 2 == 0 else 0.45, 0.2, 0.7 * fade))
