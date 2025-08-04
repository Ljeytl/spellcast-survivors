extends Control

@onready var label = $Label

func setup(damage_amount: float, pos: Vector2):
	global_position = pos
	
	# Get label reference if not already set
	if not label:
		label = get_node_or_null("Label")
	
	# Set damage text with null check
	if label:
		label.text = str(int(damage_amount))
		
		# Different colors for different damage amounts
		if damage_amount >= 50:
			label.add_theme_color_override("font_color", Color.RED)
		elif damage_amount >= 25:
			label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
	else:
		print("ERROR: label is null in DamageNumber.setup() - Label node not found!")
		print("Available children: ", get_children())
	
	# Animate the damage number
	animate_damage_number()

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
	await tween.finished
	queue_free()
