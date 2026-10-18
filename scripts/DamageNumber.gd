extends Control

@onready var label = $Label
var damage_total := 0.0

func setup(damage_amount: float, pos: Vector2):
	damage_total = damage_amount
	global_position = pos
	
	_refresh_label()
	animate_damage_number()

func add_damage(amount: float):
	damage_total += amount
	_refresh_label()

func _refresh_label():
	# Get label reference if not already set
	if not label:
		label = get_node_or_null("Label")
	
	# Set damage text with null check
	if label:
		label.text = str(int(damage_total))
		
		# Different colors for different damage amounts
		if damage_total >= 50:
			label.add_theme_color_override("font_color", Color.RED)
		elif damage_total >= 25:
			label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
	else:
		print("ERROR: label is null in DamageNumber.setup() - Label node not found!")
		print("Available children: ", get_children())
	

func animate_damage_number():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move up and fade out
	tween.tween_property(self, "global_position", global_position + Vector2(0, -50), 1.0)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	
	# Scale effect
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Remove after animation
	tween.finished.connect(queue_free)
