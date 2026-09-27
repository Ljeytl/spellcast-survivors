extends Node2D

var kind = "impact"
var radius = 24.0
var duration = 0.35
var age = 0.0
var direction = Vector2.RIGHT
var half_angle = 0.0
var endpoint = Vector2.ZERO
var followed: WeakRef
var mode = "burst"
var tint = Color.WHITE
var particle_size = 18.0

func _ready():
	add_to_group("effect_bursts")
	z_index = 6

func _process(delta):
	age += delta
	if followed:
		var target = followed.get_ref()
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			queue_free()
			return
		if kind == "stone" and target.get("overheal") != null and float(target.overheal) <= 0:
			queue_free()
			return
		global_position = target.global_position
	if age >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	var progress = clampf(age / maxf(duration, 0.01), 0, 1)
	var opacity = minf(1, (1 - progress) * 4)
	match mode:
		"area":
			preload("res://scripts/AreaArt.gd").circle(self, Vector2.ZERO, radius, tint, opacity)
		"link":
			draw_line(Vector2.ZERO, endpoint, Color(art.INK, opacity), 4)
			draw_line(Vector2.ZERO, endpoint, Color(art.PALETTE.get(kind, art.PALETTE.plague), opacity), 2)
			art.stamp(self, kind, endpoint * progress, Vector2.ONE * particle_size)
		"directional":
			if half_angle > 0:
				preload("res://scripts/AreaArt.gd").cone(self, radius, direction.angle(), half_angle, Color("9fe9ee"), opacity)
				for i in range(9):
					var heading = direction.rotated(lerpf(-half_angle, half_angle, i / 8.0))
					art.stamp(self, kind, heading * radius * progress, Vector2.ONE * 20, Color(1, 1, 1, opacity), heading.angle())
			else:
				art.beam(self, Vector2.ZERO, direction * radius, 3, opacity)
		"follow":
			art.wreath(self, kind, Vector2.ZERO, radius, 0, opacity, 6, particle_size)
		"warning":
			preload("res://scripts/AreaArt.gd").circle(self, Vector2.ZERO, radius, Color("ee6257"), 1, progress)

		_:
			art.wreath(self, kind, Vector2.ZERO, radius * progress, 0, opacity, 5, particle_size)
