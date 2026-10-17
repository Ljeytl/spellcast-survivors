extends SceneTree

const Visual = preload("res://scripts/vfx/FirewalkVisual.gd")
var checks := 0
var failures := 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run():
	root.get_node("AudioManager").quitting = true
	var args := OS.get_cmdline_user_args()
	for radius in [25.0, 50.0, 85.0]:
		var img := Visual.material(Vector2(37, -19), radius * (1.3 if args.has("known-bad-bounds") else 1.0), 0.1, 5.0)
		var half := img.get_width() / 2
		var count := 0
		var outside := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0:
					count += 1
					if (Vector2(x - half, y - half).abs() * Visual.CELL + Vector2.ONE * Visual.CELL * 0.5).length() > radius + 0.01:
						outside += 1
		check(count > 0 and outside == 0, "Nonempty material remains within actual patch radius %s" % radius)
	var fresh := Visual.material(Vector2.ZERO, 25, 0.1, 5)
	var old := Visual.material(Vector2.ZERO, 25, 4.8, 5)
	var expired := Visual.material(Vector2.ZERO, 25, 5, 5)
	check(fresh.get_pixel(7, 7).r > old.get_pixel(7, 7).r, "Real material cools before expiry")
	check(expired.get_used_rect().size == Vector2i.ZERO, "Expired material is empty")
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.player.set_physics_process(false)
	root.get_node("Vfx").set_process(false)
	root.get_node("Vfx")._active = true
	var manager = game.spell_manager
	manager.set_process(false)
	check(manager.learn_spell("firewalk"), "Learn Fire Walk")
	var slot = manager.find_spell_slot("firewalk")
	check(manager.cast_spell_by_type(slot), "Cast Fire Walk")
	var cast = manager.last_generic_cast
	cast.manual = true
	cast.run(4.4)
	var patches = cast.parts.filter(func(p): return is_instance_valid(p) and p.part_name == "patch")
	check(not patches.is_empty(), "Actual emitter creates patch")
	var patch = patches[0]
	var state = root.get_node("Vfx").presenter._parts[patch.get_instance_id()]
	var visual = state.ground
	visual.update_material()
	var age: float = patch.age
	var pixel_before: Color = visual.texture.get_image().get_pixel(7, 7)
	manager.cast_spell_by_type(slot)
	if args.has("known-bad-rejuvenation"):
		patch.age = 0
	visual.update_material()
	check(is_equal_approx(patch.age, age) and visual.texture.get_image().get_pixel(7, 7) == pixel_before, "Recast does not rejuvenate existing ground material")
	check(visual.z_index < game.player.z_index and not visual.z_as_relative, "Ground heat remains below wizard")
	var vfx = root.get_node("Vfx")
	vfx.presenter.enabled = false
	visual._process(0.1)
	check(not visual.visible, "Presenter off hides ground material")
	vfx.presenter.enabled = true
	visual._process(0.1)
	check(visual.visible, "Presenter on restores ground material")
	vfx._set_visible(false)
	visual._process(0.1)
	check(not visual.visible, "Inactive VFX hides ground material")
	vfx._set_visible(true)
	visual._process(0.1)
	check(visual.visible, "Active VFX restores ground material")
	patch.geo_override.radius = 50.0
	visual.update_material()
	check(visual.texture.get_width() == 27, "Geometry resize recreates matching texture")
	vfx.clear()
	await process_frame
	check(not is_instance_valid(visual), "Scene clear releases old ground material")
	vfx.presenter.step(0.01)
	visual = state.ground
	check(is_instance_valid(visual), "Live patch resumes ground after clear")
	cast.run(2)
	await process_frame
	check(not is_instance_valid(visual), "Finished patch releases ground visual")
	root.get_node("Vfx").clear()
	game.queue_free()
	await process_frame
	await process_frame
	print("Fire Walk visual: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
