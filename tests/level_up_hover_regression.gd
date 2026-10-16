extends SceneTree
## Playtest 0.3.4: sweeping the mouse back and forth over the upgrade cards faded them out. Hover
## must only ever brighten a card and restore it, however fast the mouse moves.

var checks = 0
var failures = 0

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var screen = load("res://scenes/LevelUpScreen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var button = Button.new()
	var panel = Panel.new()
	screen.add_child(panel)
	panel.add_child(button)
	for i in 40:   # enter and leave every couple of frames, interrupting each tween
		screen._on_upgrade_button_mouse_entered(button, panel)
		await process_frame
		screen._on_upgrade_button_mouse_exited(button, panel)
		await process_frame
	await create_timer(0.3).timeout
	check(button.modulate.is_equal_approx(Color.WHITE), "card returns to full colour after rapid hovering (%s)" % button.modulate)
	screen._on_upgrade_button_mouse_entered(button, panel)
	await create_timer(0.3).timeout
	check(button.modulate.a >= 1.0 and button.modulate.r > 1.0, "hover brightens without fading (%s)" % button.modulate)
	print("level up hover: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
