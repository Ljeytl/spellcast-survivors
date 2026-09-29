extends SceneTree

var checks = 0
var failures = 0
const Status = preload("res://scripts/SpellDurationStatus.gd")

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

func effects(id):
	return get_nodes_in_group("build_spell_effects").filter(func(e): return e.info.id == id and not e.is_queued_for_deletion())

func run():
	root.get_node("AudioManager").quitting = true
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	manager.spells.clear()
	manager.acquired_spells.clear()
	for id in ["arcane_orbit", "ember_trail", "regeneration", "earth_shield", "focus_ray", "rune_trap"]:
		check(manager.learn_spell(id), "Learn " + id)
	manager.cast_spell_by_type(1)
	var orbit = effects("arcane_orbit")[0]
	orbit.set_physics_process(false)
	orbit.advance(2)
	var angle = orbit.angle
	var before = orbit.remaining
	manager.cast_spell_by_type(1)
	check(effects("arcane_orbit").size() == 1, "Orbit stays one instance")
	check(is_equal_approx(orbit.remaining, before + 6), "Orbit adds full incoming duration")
	check(orbit.angle == angle, "Orbit recast preserves phase")
	var prior_damage = orbit.damage
	manager.upgrade_spell("arcane_orbit")
	manager.cast_spell_by_type(1)
	check(orbit.damage > prior_damage and effects("arcane_orbit").size() == 1, "Recast applies earned rank without stacking effects")
	manager.cast_spell_by_type(2)
	var trail = effects("ember_trail")[0]
	trail.set_physics_process(false)
	trail.advance(2)
	var patch_age = trail.trail_points[0].age
	manager.cast_spell_by_type(2)
	check(trail.emission_deadline == 10, "Firewalk extends laying fire by five seconds")
	check(trail.trail_points[0].age == patch_age and trail.info.patch_duration == 6, "Existing fire age and linger stay unchanged")
	trail.advance(7.5)
	game.player.position += Vector2(40, 0)
	trail.advance(0.1)
	var old_fire = game.player.global_position
	trail.advance(0.6)
	game.player.position += Vector2(1000, 0)
	check(Status.collect(manager).ember_trail.phase == "ground", "Emission expiry distinguishes lingering ground")
	manager.cast_spell_by_type(2)
	check(is_equal_approx(trail.emission_deadline - trail.age, 5), "Tail recast restores five seconds of emission")
	check(trail.last_trail_position == game.player.global_position, "Recast does not bridge travel gap")
	game.player.position += Vector2(40, 0)
	trail.advance(0.1)
	check(not trail.trail_contains(old_fire + Vector2(500, 0)), "Resumed trail cannot damage across unburned gap")
	check(trail.trail_contains(old_fire), "Old patch still burns without extending its lifetime")
	check(effects("ember_trail").size() == 1, "Firewalk remains one emitter")
	manager.cast_spell_by_type(3)
	manager.process_healing_effects(2)
	manager.add_healing_effect(4, 2)
	var rate = manager.active_healing_effects[0].heal_per_second
	manager.cast_spell_by_type(3)
	check(manager.active_healing_effects.size() == 2, "Regeneration extends without merging independent seed healing")
	check(manager.active_healing_effects[0].remaining_time == 8, "Regeneration remaining duration extended")
	check(manager.active_healing_effects[0].heal_per_second == rate, "Regeneration rate not stacked")
	manager.cast_spell_by_type(4)
	game.player.earth_shield.advance(3)
	manager.cast_spell_by_type(4)
	check(game.player.earth_shield.charges.size() == 2 and game.player.earth_shield.charges[0].remaining == 13 and game.player.earth_shield.charges[1].remaining == 16, "Earth Shield stacks independent charges")
	game.player.earth_shield.charges.clear()
	check(not Status.collect(manager).has("earth_shield"), "Depleted shield hides stale timer")
	manager.cast_spell_by_type(4)
	manager.cast_spell_by_type(5)
	manager.cast_spell_by_type(5)
	check(effects("focus_ray").size() == 2, "Beam recasts remain independent")
	manager.cast_spell_by_type(6)
	var trap = effects("rune_trap")[0]
	trap.set_physics_process(false)
	trap.age = 2
	check(Status.caption(Status.collect(manager).rune_trap) == "armed", "Trap shows armed instead of invented duration")
	for effect in get_nodes_in_group("build_spell_effects"):
		effect.set_physics_process(false)
	var reference = game.hud.get_node("CastingReference")
	for geometry in [Vector2i(1280, 720), Vector2i(640, 480), Vector2i(480, 640)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		for i in range(15):
			await process_frame
		check("s" in reference.entries.arcane_orbit.text and "\n" in reference.entries.arcane_orbit.text, "Live duration visible under incantation")
		for entry in reference.entries.values():
			check(game.hud.get_global_rect().encloses(entry.get_global_rect()), "Duration chip inside HUD")
			for card in game.hud.get_node("RunInventory").cards.values():
				check(not entry.get_global_rect().intersects(card.get_global_rect()), "Duration HUD clears inventory")
		if DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute("res://builds/duration-evidence")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://builds/duration-evidence/" + str(geometry.x) + ".png")
	trail.emission_deadline = trail.age - 1
	trail.trail_points.clear()
	check(not Status.collect(manager).has("ember_trail"), "No ground timer after last patch expires")
	orbit.remaining = 0
	check(not Status.collect(manager).has("arcane_orbit"), "Expired timer removed")
	check(preload("res://scripts/BuildVersion.gd").text() == "v0.1.36 · Playtest", "Requested version")
	game.queue_free()
	await process_frame
	print("LASTING_RECASTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
