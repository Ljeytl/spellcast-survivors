extends Node2D

func _init():
	DamageSource.stamp(self)

const Visual = preload("res://scripts/ProjectileVisual.gd")
var shards: Array = []
var hit_ids: Dictionary = {}
var damage = 0.0
var reach = 400.0
var speed = 620.0
var distance = 0.0
var knockback = 200.0
var slow_duration = 2.0
var slow_strength = 0.6
var shard_radius = 12.0

func configure(origin: Vector2, heading: Vector2, radius: float, amount: float, push: float, slow_time: float, slow: float, speed_multiplier: float, size_multiplier: float = 1.0):
	shard_radius = 12.0 * size_multiplier
	position = origin
	reach = radius * size_multiplier
	damage = amount
	knockback = push
	slow_duration = slow_time
	slow_strength = slow
	speed *= speed_multiplier
	for index in range(13):
		shards.append({"direction": heading.rotated(lerpf(-PI / 4, PI / 4, index / 12.0)), "position": Vector2.ZERO, "active": true})

func _ready():
	add_to_group("ice_blasts")
	Visual.register(self)
	z_index = 6

func _physics_process(delta: float):
	advance(delta)

func advance(delta: float):
	var travel = minf(maxf(delta, 0) * speed, maxf(0, reach - distance))
	var enemies = get_tree().get_nodes_in_group("enemies")
	for shard in shards:
		if not shard.active:
			continue
		var start: Vector2 = global_position + shard.position
		var end: Vector2 = start + shard.direction * travel
		var candidates: Array = []
		for enemy in enemies:
			if not preload("res://scripts/SpellTargeting.gd").alive(enemy):
				continue
			var fraction = contact_fraction(enemy, start, end)
			if fraction >= 0:
				candidates.append({"enemy": enemy, "fraction": fraction})
		candidates.sort_custom(func(a, b): return a.fraction < b.fraction)
		shard.position += shard.direction * travel
		if not candidates.is_empty():
			var enemy = candidates[0].enemy
			shard.active = false
			if hit_ids.has(enemy.get_instance_id()):
				continue
			hit_ids[enemy.get_instance_id()] = true
			var impact: Vector2 = start.lerp(end, candidates[0].fraction)
			enemy.take_damage(damage, impact, DamageSource.of(self))
			if is_instance_valid(enemy):
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(shard.direction, knockback * (1.2 + (1.0 - distance / reach) * 0.8))
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(slow_strength, slow_duration)
			var burst = preload("res://scripts/EffectBurst.gd").new()
			burst.kind = "ice"
			burst.radius = 24
			burst.particle_size = 14
			get_parent().add_child(burst)
			burst.global_position = impact
	distance += travel
	queue_redraw()
	if distance >= reach:
		queue_free()

func contact_fraction(enemy: Node2D, start: Vector2, end: Vector2) -> float:
	var hurtbox = enemy.get_node_or_null("HurtBox/HurtBoxShape") as CollisionShape2D
	if hurtbox and hurtbox.shape is RectangleShape2D and not hurtbox.disabled:
		var inverse = hurtbox.global_transform.affine_inverse()
		var local_start = inverse * start
		var local_end = inverse * end
		var padding = Vector2(shard_radius / hurtbox.global_transform.x.length(), shard_radius / hurtbox.global_transform.y.length())
		var half = hurtbox.shape.size / 2 + padding
		var entry = 0.0
		var exit_time = 1.0
		for axis in range(2):
			var movement = local_end[axis] - local_start[axis]
			if absf(movement) < 0.000001:
				if absf(local_start[axis]) > half[axis]:
					return -1.0
			else:
				var first = (-half[axis] - local_start[axis]) / movement
				var last = (half[axis] - local_start[axis]) / movement
				entry = maxf(entry, minf(first, last))
				exit_time = minf(exit_time, maxf(first, last))
				if entry > exit_time:
					return -1.0
		return entry
	var closest = Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
	if closest.distance_to(enemy.global_position) > shard_radius:
		return -1.0
	return start.distance_to(closest) / maxf(start.distance_to(end), 0.000001)

func _draw():
	for shard in shards:
		if shard.active:
			preload("res://scripts/EffectArt.gd").stamp(self, "ice", shard.position, Visual.size(self, Vector2(32, 24) * shard_radius / 12.0), Color.WHITE, shard.direction.angle())
