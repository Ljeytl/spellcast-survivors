extends Node2D
class_name CameraShake

@export var camera: Camera2D
@export var follow_target: Node2D

var original_offset: Vector2
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

# Smooth camera following parameters
@export var follow_speed: float = 5.0
@export var follow_offset: Vector2 = Vector2.ZERO

func _ready():
	if camera:
		original_offset = camera.offset

func _process(delta):
	# Handle smooth camera following
	if camera and follow_target:
		var target_pos = follow_target.global_position + follow_offset
		camera.global_position = camera.global_position.lerp(target_pos, follow_speed * delta)
	
	# Handle screen shake
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculate shake offset using noise
		var shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		# Apply shake with decay
		var shake_progress = shake_timer / shake_duration
		shake_offset *= shake_progress
		
		if camera:
			camera.offset = original_offset + shake_offset
	else:
		# Reset camera offset when shake is done
		if camera:
			camera.offset = original_offset

func shake(intensity: float, duration: float):
	# Trigger a screen shake with specified intensity and duration
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func shake_light(duration: float = 0.2):
	# Light shake for minor hits
	shake(5.0, duration)

func shake_medium(duration: float = 0.3):
	# Medium shake for enemy deaths
	shake(10.0, duration)

func shake_heavy(duration: float = 0.5):
	# Heavy shake for powerful spells and player damage
	shake(20.0, duration)

func set_follow_target(target: Node2D):
	# Set the target for the camera to follow
	follow_target = target

func set_camera(cam: Camera2D):
	# Set the camera to control
	camera = cam
	if camera:
		original_offset = camera.offset