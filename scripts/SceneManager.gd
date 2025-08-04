# Scene management system for smooth transitions between game screens
# Handles loading MainMenu, Game, Options, etc. without memory leaks
extends Node

# Reference to the currently active scene
var current_scene = null

# Called when SceneManager autoload is initialized
func _ready():
	# Get reference to the initial scene (usually MainMenu)
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

# Switch to a different scene by file path
func goto_scene(path):
	print("DEBUG: SceneManager.goto_scene() called with path: ", path)
	
	# Critical: Ensure game is not paused before scene transition
	print("DEBUG: Ensuring game is not paused")
	get_tree().paused = false
	Engine.time_scale = 1.0
	
	# Use Godot's built-in scene changing which is more reliable
	print("DEBUG: Using get_tree().change_scene_to_file()")
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		print("ERROR: Failed to change scene to: ", path, " Error code: ", error)
	else:
		print("DEBUG: Scene change initiated successfully")

# Internal function that actually performs the scene transition
func _deferred_goto_scene(path):
	print("DEBUG: _deferred_goto_scene() starting with path: ", path)
	
	# Critical: Ensure game is not paused before scene transition
	print("DEBUG: Ensuring game is not paused - setting paused = false and time_scale = 1.0")
	get_tree().paused = false
	Engine.time_scale = 1.0
	
	# Free the current scene from memory to prevent leaks
	if current_scene:
		print("DEBUG: Freeing current scene: ", current_scene.name)
		current_scene.queue_free()
		# Wait a frame to ensure cleanup is complete
		await get_tree().process_frame
	
	# Load the new scene resource
	print("DEBUG: Loading scene resource from: ", path)
	var s = ResourceLoader.load(path)
	if not s:
		print("ERROR: Failed to load scene from path: ", path)
		return
	
	# Create an instance of the new scene
	print("DEBUG: Instantiating new scene")
	current_scene = s.instantiate()
	if not current_scene:
		print("ERROR: Failed to instantiate scene")
		return
	
	# Add it to the scene tree
	print("DEBUG: Adding scene to tree")
	get_tree().root.add_child(current_scene)
	
	# Update the engine's current_scene reference
	get_tree().current_scene = current_scene
	print("DEBUG: Scene transition completed successfully")

# Restart the current scene (useful for "Play Again" functionality)
func restart_current_scene():
	print("DEBUG: restart_current_scene() called")
	
	# Critical: Ensure game is not paused before restart
	get_tree().paused = false
	Engine.time_scale = 1.0
	
	# Use Godot's built-in reload which is most reliable
	print("DEBUG: Using get_tree().reload_current_scene()")
	var error = get_tree().reload_current_scene()
	if error != OK:
		print("ERROR: Failed to reload scene, error code: ", error)
		# Fallback to manual reload
		goto_scene("res://scenes/Game.tscn")
	else:
		print("DEBUG: Scene reload initiated successfully")
