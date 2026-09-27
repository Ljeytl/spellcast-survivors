extends SceneTree

var checks = 0
var failures = 0
const SETTINGS = preload("res://scripts/EffectPreferences.gd")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func settle():
	for i in range(15):
		await process_frame

func run():
	SETTINGS.save_reduced(false)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.change_state(game.GameState.PAUSED)
	game._on_pause_options_pressed()
	await settle()
	var options = game.get_node("UI/Options")
	var toggle = options.get_node("OptionsPanel/VBoxContainer/ReducedEffectsCheckBox")
	check(not toggle.button_pressed, "Options reflects stored default")
	game.camera_shake.shake_heavy()
	toggle.button_pressed = true
	check(game.camera_shake.reduced_effects and game.particle_manager.reduced_effects, "Paused toggle immediately updates both effect systems")
	check(game.camera_shake.shake_timer == 0 and game.camera_shake.camera.offset == game.camera_shake.original_offset, "Toggle cancels current screen shake immediately")
	check(SETTINGS.reduced(), "Preference survives config reload")
	for geometry in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(960, 540)]:
		root.size = geometry
		options._layout_readable_menu()
		await settle()
		check(options.get_global_rect().encloses(options.get_node("OptionsPanel").get_global_rect()), "Options panel fits window")
		check(options.get_node("OptionsPanel").get_global_rect().encloses(toggle.get_global_rect()), "Reduced effects control is visible")
	options._on_back_button_pressed()
	await settle()
	check(game.current_state == game.GameState.PAUSED and game.pause_overlay.visible, "Options returns to pause")
	game.queue_free()
	paused = false
	await settle()
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	check(game.camera_shake.reduced_effects and game.particle_manager.reduced_effects, "New run applies persisted preference")
	game.camera_shake.shake_heavy()
	check(game.camera_shake.shake_intensity == 0, "Reduced setting suppresses future shake")
	game.change_state(game.GameState.PAUSED)
	game._on_pause_options_pressed()
	await settle()
	options = game.get_node("UI/Options")
	toggle = options.get_node("OptionsPanel/VBoxContainer/ReducedEffectsCheckBox")
	check(toggle.button_pressed, "Reopened options shows persisted setting")
	toggle.button_pressed = false
	game.camera_shake.shake_heavy()
	check(not SETTINGS.reduced() and game.camera_shake.shake_intensity > 0, "Turning reduction off restores bounded shake")
	game.queue_free()
	paused = false
	await settle()
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.25, true, false, true).timeout
	print("Effect preferences: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
