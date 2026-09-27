extends SceneTree

var checks = 0
var failures = 0
const COPY = preload("res://scripts/UpgradeCopy.gd")

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func settle():
	for i in range(15):
		await process_frame

func minimal(text: String) -> bool:
	return not ("\n" in text or "Currently" in text or "Rank" in text or "Slot" in text or "→" in text or "PASSIVE" in text)

func run():
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.is_invincible = true
	var manager = game.spell_manager
	var choices = game.level_up_screen
	check(not game.interface_debug, "Each run starts with minimal player interface")
	game.update_difficulty_display()
	check(not game.difficulty_label.visible, "Boss schedule and tier hidden before encounter")
	game._on_timer_panel_mouse_entered()
	check(not game.difficulty_tooltip.visible, "Normal clock hover cannot reveal boss schedule")
	check(not game.get_node("GameplayReadability").passive_label.visible, "Automatic attack telemetry hidden")
	check(not game.get_node("GameplayReadability").focus_label.visible, "Slowdown telemetry hidden outside typing")
	check(game.spell_slots.filter(func(slot): return slot.visible).size() == manager.spells.size(), "Only equipped spell cards shown")
	for id in manager.spell_catalog:
		check(COPY.SPELLS.has(id), "Every learnable base spell has authored short copy: " + id)
		check(minimal(COPY.description({"effect": {"type": "learn_spell", "spell": id}}, manager)), "Base spell copy is concise: " + id)
	for id in COPY.EVOLUTIONS:
		var text = COPY.description({"effect": {"type": "learn_spell", "spell": id}}, manager)
		check(minimal(text) and not "Replace " in text, "Bonus describes its effect without replacing ingredients: " + id)
	for geometry in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = geometry
		game.get_node("GameplayReadability").layout()
		choices.show_level_up(2, {})
		await settle()
		for button in choices.upgrade_buttons:
			check(minimal(button.get_node("CardText").text), "Normal choice contains one short description")
			check(button.get_global_rect().encloses(button.get_node("CardText").get_global_rect()), "Short card body fits")
			check(button.get_global_rect().encloses(button.get_node("KeyTitle").get_global_rect()), "Stone title fits")
		var f3 = InputEventKey.new()
		f3.keycode = KEY_F3
		f3.pressed = true
		game.console_instance._input(f3)
		await settle()
		check(game.interface_debug, "F3 activates diagnostics even with a choice open")
		check(game.difficulty_label.visible, "Debug restores tier and schedule")
		for i in range(choices.available_upgrades.size()):
			check(str(choices.available_upgrades[i].description) in choices.upgrade_buttons[i].get_node("CardText").text, "Debug preserves complete original description")
		game.console_instance.execute_command("ui_debug off")
		await settle()
		check(not game.difficulty_label.visible, "Console command returns to minimal view")
		choices.lock_upgrade(0)
		check(choices.upgrade_buttons[0].get_node("CardText").text.begins_with("LOCKED\n"), "Lock state remains legible")
		choices._on_reroll_pressed()
		check(0 in choices.locked_upgrades, "Lock survives reroll under minimal presentation")
	check(not minimal("PASSIVE UPGRADE\n+10% (Currently: +20%)"), "Known-bad verbose card fails concise invariant")
	check(COPY.description({"effect": {"type": "spell_damage", "value": 0.05}}, manager) == "Gain 5% spell power.", "Exact percentage comes from actual effect value")
	check(COPY.description({"effect": {"type": "movement_speed", "value": 0.08}}, manager) == "Gain 8% movement speed.", "No percentage ranges")
	check(COPY.rank_description("bolt", manager) == "Deal 6 more damage per hit and fire one extra bolt.", "Rank card describes actual damage increment and additional projectile")
	var report = game.interface_debug_report()
	check("Bosses arrive" in report and "UPGRADE DETAILS" in report and "SYNERGY DETAILS" in report and "bonus" in report.to_lower(), "Full diagnostic report retains schedules, cards and recipe mechanics")
	var monster_manager = game.get_node("MonsterManager")
	monster_manager.game_time = 300
	monster_manager.check_boss_milestones()
	game.update_difficulty_display()
	check(game.difficulty_label.visible and "HP" in game.difficulty_label.text and not "05:00" in game.difficulty_label.text, "Arrived boss shows health without advance schedule")
	game.game_over_screen.display_stats({"won": false, "survival_time": 42, "final_kit": ["Bolt"], "final_hit": {"kind": "contact", "damage": 10}})
	check(not game.game_over_screen.kit_label.visible and not game.game_over_screen.defeat_label.visible, "Run ending hides technical summary by default")
	game.set_interface_debug(true)
	check(game.game_over_screen.kit_label.visible and game.game_over_screen.defeat_label.visible, "Debug can restore retained run details")
	game.queue_free()
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	await create_timer(0.25, true, false, true).timeout
	print("Minimal interface: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
