extends SceneTree

const PREFS = preload("res://scripts/EffectPreferences.gd")
var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func press(control: Control):
	await process_frame
	control.grab_focus()
	for down in [true, false]:
		var event = InputEventAction.new()
		event.action = "ui_accept"
		event.pressed = down
		root.push_input(event)
		await process_frame

func run():
	if not root.is_node_ready():
		await root.ready
	await process_frame
	var vfx = root.get_node("Vfx")
	var original = PREFS.reduced()
	PREFS.save_reduced(false)
	var menu = load("res://scenes/Options.tscn").instantiate()
	root.add_child.call_deferred(menu)
	await menu.ready
	current_scene = menu
	PREFS.apply(menu, false)
	await process_frame
	await press(menu.get_node("OptionsPanel/VBoxContainer/ReducedEffectsCheckBox"))
	check(vfx.reduced_effects and PREFS.reduced(), "Menu toggle applies and saves spell renderer preference")
	menu.free()
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
	await game.ready
	current_scene = game
	await process_frame
	check(vfx.reduced_effects and game.particle_manager.reduced_effects and game.camera_shake.reduced_effects, "New game inherits saved preference in all renderers")
	for geometry in [Vector2i(1280, 720), Vector2i(640, 720)]:
		root.size = geometry
		game.toggle_pause()
		await press(game.get_node("UI/PauseOverlay/PauseMenu/VBoxContainer/OptionsButton"))
		var options = game.get_node_or_null("UI/Options")
		check(options != null, "Pause Options button opens options")
		if options == null:
			quit(1)
			return
		var toggle = options.get_node("OptionsPanel/VBoxContainer/ReducedEffectsCheckBox")
		check(toggle.button_pressed, "Reopened pause options agrees with saved preference")
		await press(toggle)
		check(not vfx.reduced_effects and not game.particle_manager.reduced_effects and not game.camera_shake.reduced_effects, "Disable applies to all renderers while paused")
		game.camera_shake.shake_timer = 1.0
		game.camera_shake.shake_intensity = 4.0
		await press(toggle)
		check(vfx.reduced_effects and game.particle_manager.reduced_effects and game.camera_shake.reduced_effects, "Enable applies to all renderers while paused")
		check(game.camera_shake.shake_timer == 0.0 and game.camera_shake.shake_intensity == 0.0, "Enabling cancels existing camera shake")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://builds/reduced-effects")
			check(root.get_texture().get_image().save_png("res://builds/reduced-effects/options-%d.png" % geometry.x) == OK, "Capture operated settings")
		vfx.clear()
		for i in 900:
			vfx.ember(0, 0, 0, 0, 1.0)
		check(vfx._embers.size() == 250, "Reduced renderer enforces lower ember budget")
		vfx.reduced_effects = false
		vfx.clear()
		for i in 900:
			vfx.ember(0, 0, 0, 0, 1.0)
		check(vfx._embers.size() == 800, "Known-bad propagation control restores full ember budget")
		PREFS.apply(game, true)
		await press(options.get_node("OptionsPanel/VBoxContainer/BackButton"))
		check(game.pause_overlay.visible, "Back returns to pause menu")
		game.toggle_pause()
		await process_frame
		check(vfx.reduced_effects and not paused, "Preference survives resume")
	game.free()
	vfx.clear()
	PREFS.save_reduced(original)
	vfx.reduced_effects = original
	print("Reduced effects: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
