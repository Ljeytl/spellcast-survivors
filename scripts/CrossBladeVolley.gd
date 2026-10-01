extends Node2D

const Blade = preload("res://scripts/TacticalSpellEffect.gd")

func configure(info: Dictionary, damage: float, player: Node2D):
	add_to_group("cross_blade_volleys")
	var count = maxi(1, int(info.get("blade_count", 3)))
	# Aim the volley at the nearest enemy so a single rank-1 blade is useful; four blades still form an X.
	var aim = -PI / 2.0
	var target = preload("res://scripts/SpellTargeting.gd").select(get_tree(), player.global_position, 600.0) if is_inside_tree() else null
	if target:
		aim = player.global_position.direction_to(target.global_position).angle()
	var rotation_offset = aim + PI / 4.0 if count == 4 else aim
	for index in range(count):
		var blade = Blade.new()
		blade.configure(info, damage, player, null)
		blade.direction = Vector2.from_angle(rotation_offset + TAU * float(index) / count)
		add_child(blade)

func _process(_delta):
	if get_child_count() == 0:
		queue_free()
