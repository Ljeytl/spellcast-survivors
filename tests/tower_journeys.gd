extends SceneTree

var checks = 0
var failures = 0
var output = "res://builds/tower-evidence"
func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()
func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func key(code: int, pressed: bool):
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func tap(code: int):
	key(code,true)
	await process_frame
	key(code,false)
	await process_frame
func walk(code: int, distance: float):
	var tower = current_scene
	var start = tower.wizard.position
	key(code,true)
	var frames = 0
	while is_instance_valid(tower) and tower.wizard.position.distance_to(start) < distance and frames < 180:
		await physics_frame
		frames += 1
	key(code,false)
	await process_frame
	return is_instance_valid(tower) and tower.wizard.position.distance_to(start) >= distance
func screenshot(name: String):
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "/" + name + ".png")
func settle():
	await create_timer(0.4).timeout
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.get_node("AudioManager").quitting = true
	root.size = Vector2i(1280,800)
	root.get_node("SceneManager").goto_scene("res://scenes/MainMenu.tscn")
	await settle()
	await tap(KEY_ENTER)
	await settle()
	check(current_scene.scene_file_path.ends_with("Tower.tscn"), "Title Enter activates Play")
	var tower = current_scene
	await screenshot("journey-arrival")
	check(await walk(KEY_W,42), "W physically walks toward orb")
	await tap(KEY_E)
	check(tower.orb_active, "E reaches orb interaction from spawn")
	await tap(KEY_LEFT)
	await screenshot("journey-rotating")
	await settle()
	check(tower.selected == 11, "Left selects blank destination")
	await tap(KEY_RIGHT)
	await settle()
	check(tower.selected == 0, "Right restores Woodland")
	root.size = Vector2i(480,720)
	await settle()
	await screenshot("journey-orb-narrow")
	check(tower.label.get_global_rect().end.y <= tower.ui.size.y * tower.ui.scale.y + 1, "Orb instructions fit narrow window")
	await tap(KEY_ESCAPE)
	check(not tower.orb_active and current_scene == tower, "Escape leaves orb without leaving tower")
	check(await walk(KEY_A,155), "A walks to tome lane")
	await tap(KEY_E)
	check(is_instance_valid(tower.archive), "E opens tome by walking")
	await screenshot("journey-necronomicon")
	var position = tower.wizard.position
	key(KEY_D,true)
	await settle()
	key(KEY_D,false)
	check(tower.wizard.position == position, "Movement keys cannot move player behind archive")
	await tap(KEY_ESCAPE)
	await settle()
	check(not is_instance_valid(tower.archive), "Escape closes Necronomicon")
	check(await walk(KEY_D,230), "Walk around pedestal to clear lane")
	check(await walk(KEY_W,250), "Walk north past center furnishings")
	check(await walk(KEY_A,75), "Align with selected top arch")
	await screenshot("journey-doorway")
	key(KEY_W,true)
	await create_timer(1.0).timeout
	key(KEY_W,false)
	check(current_scene.scene_file_path.ends_with("Game.tscn"), "Actual walking crosses doorway into run")
	if not current_scene.scene_file_path.ends_with("Game.tscn"):
		print("TOWER JOURNEYS: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var game = current_scene
	game.finish_run(false)
	await create_timer(0.6).timeout
	await screenshot("journey-results")
	await tap(KEY_ENTER)
	await settle()
	check(current_scene.scene_file_path.ends_with("Tower.tscn") and not paused, "Results Enter returns to tower")
	await screenshot("journey-returned")
	await tap(KEY_ESCAPE)
	await settle()
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn"), "Escape from room returns title")
	print("TOWER JOURNEYS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
