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
	for i in 4: await process_frame
func run():
	root.get_node("AudioManager").quitting = true
	root.get_node("SceneManager").goto_scene("res://scenes/MainMenu.tscn")
	await settle()
	current_scene._on_play_button_pressed()
	await settle()
	var tower = current_scene
	check(tower.scene_file_path.ends_with("Tower.tscn"), "Play enters tower")
	check(tower.arches.size() == 12 and tower.selected == 0, "Twelve destinations, Woodland initially selected")
	check(tower.wizard.position == Vector2(0,115), "Wizard begins away from pedestal")
	tower.set_physics_process(false)
	tower.wizard.position = Vector2(0,65)
	await physics_frame
	var hit = tower.wizard.move_and_collide(Vector2(0,-90), true)
	check(hit != null, "Orb pedestal physically blocks walking")
	tower.wizard.collision_mask = 0
	check(tower.wizard.move_and_collide(Vector2(0,-90), true) == null, "Known-bad disabled collision control discriminates")
	tower.wizard.collision_mask = 32
	tower.interact()
	check(tower.orb_active, "Nearby orb activates")
	var initial = tower.arches[0].position
	var wizard_position = tower.wizard.position
	tower.turn(1)
	tower.turn(1)
	check(is_equal_approx(tower.target_angle, tower.STEP), "Rapid presses cannot queue accidental turns")
	for i in 40: tower._physics_process(0.02)
	check(tower.selected == 11 and tower.settled(), "Turn settles precisely on adjacent doorway")
	check(tower.arches[0].position != initial and tower.wizard.position == wizard_position, "Outer ring moves while wizard remains fixed")
	check(tower.arches[2].has_node("Blocker") and not tower.arches[0].has_node("Blocker"), "Locked door clutter belongs to rotating sector")
	check(tower.TRAINING_PORTAL == 11 and not tower.arches[11].has_node("Blocker") and tower.is_open(11) and not tower.is_open(1), "Training Grounds sits left of Woodland; other blank doorways stay sealed")
	tower.turn(1)
	for i in 40: tower._physics_process(0.02)
	check(tower.selected == 10, "Second left turn reaches a sealed doorway")
	tower.interact()
	tower.wizard.position = Vector2(0,-301)
	tower.interact()
	tower._physics_process(0)
	check(not tower.transitioning, "Blank doorway cannot launch")
	tower.wizard.position = tower.tome_position + Vector2(0,60)
	tower.interact()
	check(is_instance_valid(tower.archive), "Tome opens archive")
	check(tower.archive.find_child("CollectionTitle",true,false).text == "NECRONOMICON", "Tome uses existing Necronomicon")
	var still = tower.wizard.position
	tower._physics_process(1)
	check(tower.wizard.position == still, "Archive stops hub simulation")
	tower.archive.close_collection()
	await settle()
	check(not is_instance_valid(tower.archive), "Archive close restores interaction")
	tower.wizard.position = Vector2(0,65)
	tower.interact()
	tower.turn(-1)
	for i in 40: tower._physics_process(0.02)
	tower.turn(-1)
	for i in 40: tower._physics_process(0.02)
	tower.interact()
	check(tower.selected == 0, "Can return to Woodland")
	tower.wizard.position = Vector2(47,-270)
	await physics_frame
	tower.move_wizard(Vector2.RIGHT, 0.02)
	check(tower.wizard.position.x < 48 and is_equal_approx(tower.wizard.position.y,-270), "Exit corridor blocks sideways without snapping south")
	tower.wizard.position = Vector2(0,-301)
	tower._physics_process(0)
	await settle()
	check(current_scene.scene_file_path.ends_with("Game.tscn"), "Walking through top Woodland starts run")
	var game = current_scene
	check(game.game_time < 2 and game.spell_manager.spells.size() == 1 and not paused, "First run fresh")
	var progression = root.get_node("CharacterManager")
	var games_before = progression.total_games_played
	var discoveries_before = progression.discovered_synergies.duplicate()
	game.finish_run(false)
	var xp_after = progression.persistent_xp
	game.finish_run(false)
	check(progression.total_games_played == games_before + 1 and progression.persistent_xp == xp_after, "Duplicate finalization cannot award progression twice")
	await settle()
	check(game.game_over_screen.visible, "Death displays results")
	game.game_over_screen.restart_game.emit()
	await settle()
	check(current_scene.scene_file_path.ends_with("Tower.tscn") and not paused and Engine.time_scale == 1, "Death results return home unpaused")
	check(progression.persistent_xp == xp_after, "Home preserves awarded progression")
	current_scene.depart()
	await settle()
	game = current_scene
	check(game.game_time < 2 and game.player.health == game.player.max_health, "Second run resets clock and health")
	check(progression.persistent_xp == xp_after and progression.discovered_synergies == discoveries_before, "Second startup retains XP and discoveries")
	game.finish_run(true)
	await settle()
	check(game.game_over_screen.title_label.text == "VICTORY!", "Extraction still shows victory")
	game.game_over_screen.return_to_menu.emit()
	await settle()
	check(current_scene.scene_file_path.ends_with("Tower.tscn") and not paused, "Extraction returns home")
	print("TOWER: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
