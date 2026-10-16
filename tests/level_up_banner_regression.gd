extends SceneTree
## Playtest 0.3.4: the "New spell" banner on level up sat bottom right over the minimap. It must
## sit centred above the wizard at every window size.

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
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	for geometry in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(800, 600)]:
		root.size = geometry
		await process_frame
		await process_frame
		game.celebrate_spell(1, "New spell: Bolt", "Press 1, then type BOLT")
		await process_frame
		var banner: Control = game.hud.get_node("SpellCelebration")
		var hud_rect := Rect2(Vector2.ZERO, game.hud.size)   # layout rect; the pop-in tween scales it
		var rect := Rect2(banner.position, banner.size)
		check(absf(rect.get_center().x - hud_rect.get_center().x) < 2.0, "banner is centred horizontally at %s (%s)" % [geometry, rect])
		check(rect.get_center().y < hud_rect.get_center().y, "banner sits above the wizard at %s (%s)" % [geometry, rect])
		check(hud_rect.encloses(rect), "banner stays on screen at %s" % geometry)
		banner.free()
	print("level up banner: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
