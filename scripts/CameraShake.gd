extends Node2D
class_name CameraShake

@export var camera: Camera2D
@export var follow_target: Node2D

var reduced_effects = false
## The live game camera's shaker, for the VFX layer's landings (no scene lookups: co-op rule 2).
static var active: CameraShake = null
var original_offset: Vector2
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

# Smooth camera following parameters
@export var follow_speed: float = 5.0
@export var follow_offset: Vector2 = Vector2.ZERO

func _ready():
	active = self
	if camera:
		original_offset = camera.offset

func _exit_tree():
	if active == self:
		active = null

func _process(delta):
	# Handle smooth camera following
	if camera and follow_target:
		var target_pos = follow_target.global_position + follow_offset
		camera.global_position = camera.global_position.lerp(target_pos, follow_speed * delta)
	
	# Handle screen shake
	if shake_timer > 0:
		shake_timer = maxf(0, shake_timer - delta)
		
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
	var requested := 0.0 if reduced_effects else clampf(intensity, 0.0, 6.0)
	if shake_timer > 0.0 and requested < shake_intensity * shake_timer / maxf(shake_duration, 0.001):
		return
	shake_intensity = requested
	shake_duration = clampf(duration, 0.0, 0.3)
	shake_timer = shake_duration

## A spell landing (Meteor Shower, Lightning…): stronger than the 6 px cap on other shakes,
## always short (playtest: landings had no shake you could feel).
func shake_impact(intensity: float, duration: float = 0.25):
	if reduced_effects:
		return
	if intensity >= shake_intensity or shake_timer <= 0.0:
		shake_intensity = clampf(intensity, 0.0, 12.0)
		shake_duration = clampf(duration, 0.0, 0.35)
		shake_timer = shake_duration

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