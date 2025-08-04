extends CanvasLayer
class_name TimeDilationEffect

@onready var screen_overlay: ColorRect
var is_time_dilated: bool = false
var normal_time_scale: float = 1.0
var dilation_time_scale: float = 0.2

func _ready():
	# Create screen overlay for time dilation effect
	screen_overlay = ColorRect.new()
	screen_overlay.size = get_viewport().size
	screen_overlay.color = Color(0.3, 0.3, 0.8, 0.0)  # Blue tint, transparent initially
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_overlay)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	if screen_overlay:
		screen_overlay.size = get_viewport().size

func start_time_dilation():
	# Start time dilation effect with visual feedback
	if is_time_dilated:
		return
	
	is_time_dilated = true
	Engine.time_scale = dilation_time_scale
	
	# Animate screen overlay
	var tween = create_tween()
	tween.tween_property(screen_overlay, "color:a", 0.15, 0.2)

func end_time_dilation():
	# End time dilation effect and return to normal
	if not is_time_dilated:
		return
	
	is_time_dilated = false
	Engine.time_scale = normal_time_scale
	
	# Animate screen overlay fade out
	var tween = create_tween()
	tween.tween_property(screen_overlay, "color:a", 0.0, 0.3)

func is_active() -> bool:
	return is_time_dilated

func get_time_scale() -> float:
	return Engine.time_scale