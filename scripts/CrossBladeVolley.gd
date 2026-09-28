extends Node2D

const Blade = preload("res://scripts/TacticalSpellEffect.gd")

func configure(info: Dictionary, damage: float, player: Node2D):
	add_to_group("cross_blade_volleys")
	var count = maxi(1, int(info.get("blade_count", 3)))
	var rotation_offset = PI / 4.0 if count == 4 else -PI / 2.0
	for index in range(count):
		var blade = Blade.new()
		blade.configure(info, damage, player, null)
		blade.direction = Vector2.from_angle(rotation_offset + TAU * float(index) / count)
		add_child(blade)

func _process(_delta):
	if get_child_count() == 0:
		queue_free()
