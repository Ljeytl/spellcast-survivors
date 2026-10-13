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
	for id in ["arcane_orbit", "firewalk", "regeneration", "earth_shield", "focus_ray", "rune_trap"]:
		check(manager.learn_spell(id), "Learn " + id)
	# Arcane Orbit and Rune Trap run on the generic engine (doc 18 phase 2).
	manager.cast_spell_by_type(1)
	var orbit_cast = manager.last_generic_cast
	orbit_cast.manual = true
	orbit_cast.run(2)
	var orbit = orbit_cast.root_parts()[0]
	var angle = orbit.orbit_angle
	var before = orbit.remaining_life()
	manager.cast_spell_by_type(1)
	check(manager.ported_casts("arcane_orbit").size() == 1, "Orbit stays one instance")
	check(is_equal_approx(orbit.remaining_life(), before + 6), "Orbit adds full incoming duration")
	check(orbit.orbit_angle == angle, "Orbit recast preserves phase")
	var prior_damage = float(orbit.def.payload[0].hit)
	manager.upgrade_spell("arcane_orbit")
	manager.cast_spell_by_type(1)
	# Extend recasts queue a segment with its own numbers; the earned rank applies when that segment starts.
	check(not orbit.segments.is_empty() and float(orbit.segments.back().def.payload[0].hit) > prior_damage and manager.ported_casts("arcane_orbit").size() == 1, "Recast applies earned rank without stacking effects")
	# Fire Walk runs on the generic engine (doc 18 phase 2): an emitter lays patches along the path.
	manager.cast_spell_by_type(2)
	var walk = manager.last_generic_cast
	walk.manual = true
	walk.run(2)
	var emitter = walk.root_parts()[0]
	var first_patch = walk.parts.filter(func(p): return is_instance_valid(p) and p.part_name.begins_with("patch"))[0]
	var patch_age = first_patch.age
	manager.cast_spell_by_type(2)
	check(is_equal_approx(emitter.total_life(), 10.0), "Firewalk extends laying fire by five seconds")
	check(first_patch.age == patch_age and is_equal_approx(first_patch.total_life(), float(manager.spell_catalog["firewalk"].patch_duration)), "Existing fire age and linger stay unchanged")
	walk.run(7.5)
	game.player.position += Vector2(40, 0)
	walk.run(0.1)
	var old_fire = game.player.global_position
	walk.run(0.6)
	game.player.position += Vector2(1000, 0)
	check(Status.collect(manager).firewalk.phase == "ground", "Emission expiry distinguishes lingering ground")
	manager.cast_spell_by_type(2)
	var walk2 = manager.last_generic_cast
	walk2.manual = true
	check(is_equal_approx(walk2.root_parts()[0].remaining_life(), 5), "Tail recast restores five seconds of emission")
	check(walk2.root_parts()[0].emit_last == game.player.global_position, "Recast does not bridge travel gap")
	game.player.position += Vector2(40, 0)
	walk2.run(0.1)
	var burning = func(point: Vector2) -> bool:
		for c in [walk, walk2]:
			for p in c.parts:
				if is_instance_valid(p) and not p.done and p.part_name.begins_with("patch") and p.contains(point, 0.0):
					return true
		return false
	check(not burning.call(old_fire + Vector2(500, 0)), "Resumed trail cannot damage across unburned gap")
	check(burning.call(old_fire), "Old patch still burns without extending its lifetime")
	var emitters = [walk, walk2].filter(func(c): return not c.root_parts().is_empty())
	check(emitters.size() == 1, "Firewalk remains one emitter")
	manager.cast_spell_by_type(3)
	var regen = manager.ported_casts("regeneration")[0]   # generic life aura
	regen.manual = true
	regen.run(2.0)
	manager.add_healing_effect(4, 2)
	var aura = regen.root_parts()[0]
	var rate = float(aura.def.heal_rate)
	manager.cast_spell_by_type(3)
	check(manager.ported_casts("regeneration").size() == 1 and manager.active_healing_effects.size() == 1, "Regeneration extends without merging independent seed healing")
	check(is_equal_approx(aura.remaining_life(), 8), "Regeneration remaining duration extended")
	check(aura.segments.size() == 1 and is_equal_approx(float(aura.segments[0].def.heal_rate), rate), "Regeneration rate not stacked")
	manager.cast_spell_by_type(4)
	game.player.earth_shield.advance(3)
	manager.cast_spell_by_type(4)
	check(game.player.earth_shield.charges.size() == 2 and game.player.earth_shield.charges[0].remaining == 13 and game.player.earth_shield.charges[1].remaining == 16, "Earth Shield stacks independent charges")
	game.player.earth_shield.charges.clear()
	check(not Status.collect(manager).has("earth_shield"), "Depleted shield hides stale timer")
	manager.cast_spell_by_type(4)
	manager.cast_spell_by_type(5)
	manager.cast_spell_by_type(5)
	check(manager.ported_casts("focus_ray").size() == 2, "Beam recasts remain independent")
	manager.cast_spell_by_type(6)
	var trap_cast = manager.last_generic_cast
	trap_cast.manual = true
	trap_cast.root_parts()[0].armed = true
	check(Status.caption(Status.collect(manager).rune_trap) == "armed", "Trap shows armed instead of invented duration")
	for cast in get_nodes_in_group("generic_casts"):
		cast.manual = true
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
	for c in [walk, walk2]:
		for p in c.parts:
			if is_instance_valid(p):
				p.finish(true)
	check(not Status.collect(manager).has("firewalk"), "No ground timer after last patch expires")
	for part in orbit_cast.root_parts():
		part.finish(true)
	check(not Status.collect(manager).has("arcane_orbit"), "Expired timer removed")
	check(preload("res://scripts/BuildVersion.gd").text() == "v%s · Playtest" % ProjectSettings.get_setting("application/config/version"), "Requested version")
	game.queue_free()
	await process_frame
	print("LASTING_RECASTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
