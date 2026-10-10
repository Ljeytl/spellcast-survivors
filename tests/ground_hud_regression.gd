extends SceneTree

var checks = 0
var failures = 0

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

func settle():
	for i in range(15):
		await process_frame

func capture(name):
	if DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute("res://builds/ground-hud-evidence")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/ground-hud-evidence/" + name + ".png")

func run():
	root.get_node("AudioManager").quitting = true
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.player.set_physics_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	var interface = game.get_node("GameplayReadability")
	check(not interface.guidance.is_visible_in_tree(), "Startup instructions hidden in normal game")
	manager.learn_spell("firewalk")
	manager.learn_spell("cinder_field")
	manager.learn_spell("rune_trap")
	game.show_gameplay_feedback("Fire Walk learned · Press 2, then type fire walk")
	await settle()
	check(not interface.guidance.is_visible_in_tree(), "Learned-spell instruction hidden")
	var reference = game.hud.get_node("CastingReference")
	check(reference.is_visible_in_tree() and reference.entries.firewalk.text == "2  fire walk", "Exact spell names and numbers remain")
	manager.cast_spell_by_type(manager.find_spell_slot("firewalk"))
	var trail = get_nodes_in_group("build_spell_effects")[0]
	trail.set_physics_process(false)
	game.player.position += Vector2(50, 0)
	trail.advance(0.2)
	game.player.position -= Vector2(50, 0)
	check(trail.z_index < game.player.z_index and not trail.z_as_relative, "Firewalk draws below wizard independently of insertion order")
	trail.z_index = 1
	check(not (trail.z_index < game.player.z_index), "Known-bad foreground fire fails ordering invariant")
	await settle()
	await capture("before-foreground-fire")
	trail.z_index = -2
	trail.advance(0.1)
	manager.cast_spell_by_type(manager.find_spell_slot("firewalk"))
	await settle()
	check("s" in reference.entries.firewalk.text and "+5s" in reference.entries.firewalk.text, "Duration and recast confirmation remain visible without instructions")
	await capture("after-ground-fire")
	for id in ["cinder_field", "rune_trap"]:
		manager.cast_spell_by_type(manager.find_spell_slot(id))
	for effect in get_nodes_in_group("build_spell_effects"):
		effect.set_physics_process(false)
		check(effect.z_index < game.player.z_index, "Sibling ground effect below wizard: " + str(effect.info.id))
	for geometry in [Vector2i(1280, 720), Vector2i(640, 480), Vector2i(480, 640)]:
		root.size = geometry
		interface.layout()
		await settle()
		check(not interface.guidance.is_visible_in_tree(), "No instructional text after resize")
		check(reference.is_visible_in_tree(), "Casting reference visible after resize")
		for entry in reference.entries.values():
			check(game.hud.get_global_rect().encloses(entry.get_global_rect()), "Spell reference inside HUD")
		await capture(str(geometry.x))
	game.set_interface_debug(true)
	await settle()
	check(interface.guidance.is_visible_in_tree(), "Diagnostics retain instructional text")
	game.set_interface_debug(false)
	await settle()
	check(not interface.guidance.is_visible_in_tree(), "Normal HUD restored without instructions")
	game.queue_free()
	await process_frame
	print("GROUND_HUD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
