extends SceneTree

var checks := 0
var failures := 0
var game
var manager
var interface
var interactive = "--interactive" in OS.get_cmdline_user_args()
var baseline = "--baseline" in OS.get_cmdline_user_args()
var known_bad = "--known-bad" in OS.get_cmdline_user_args()

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle():
	for i in 4:
		await process_frame

func capture(name: String):
	if DisplayServer.get_name() == "headless" or known_bad:
		return
	await RenderingServer.frame_post_draw
	var directory = "res://builds/hud-feedback-evidence"
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory.path_join(name + ".png"))

func run():
	root.get_node("AudioManager").quitting = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640, 720) if "--narrow" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	if not interactive:
		root.set_flag(Window.FLAG_NO_FOCUS, true)
		root.position = Vector2i(5000, 5000)
	if "--menu" in OS.get_cmdline_user_args():
		root.get_node("SceneManager").goto_scene("res://scenes/MainMenu.tscn")
		return
	game = load("res://scenes/Game.tscn").instantiate()
	game.set_meta("bot_run", true)
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	interface = game.get_node("GameplayReadability")
	game.player.is_invincible = true
	for id in ["firewalk", "arcane_orbit", "earth_shield", "focus_ray", "regeneration"]:
		manager.learn_spell(id)
	game.style_session.score.combo = 95.0
	game.style_session.score.grace_remaining = 3600.0
	game.style_session.score.run_score = 12345
	game.style_session.updated.emit()
	await settle()
	if interactive:
		manager.mana_bolt_timer = 1000000.0
		game.player.xp_to_next_level = 1000000.0
		game.style_session.score.grace_remaining = 3600.0
		var encounters = game.get_node("MonsterManager")
		encounters.set_process(false)
		encounters.spawn_timer.stop()
		var definition = encounters.encounter_config.variants.pursuer.duplicate(true)
		definition.id = "pursuer"
		for index in 8:
			var enemy = encounters.spawn_monster(definition, false, true)
			if enemy:
				enemy.current_health = 1000000.0
				enemy.max_health = 1000000.0
				enemy.position = game.player.position + Vector2.from_angle(index * TAU / 8) * 250.0
				enemy.set_physics_process(false)
		print("Assisted HUD QA fixture ready: Bolt, Firewalk, Arcane Orbit, Earth Shield, Focus Ray, Regeneration; invincible, stationary high-HP targets, auto attack disabled, initial grace extended; normal manual controls/scoring.")
		return
	for family in ["spell_damage", "spell_area", "projectile_speed", "spell_duration", "slowdown_duration", "mana_bolt_mastery"]:
		game.player.passive_ranks[family] = 1
	manager.set_process(false)
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.player.set_physics_process(false)
	if not baseline:
		await verify_feedback()
	for geometry in [Vector2i(1280, 720), Vector2i(640, 720), Vector2i(480, 800)]:
		root.size = geometry
		interface.layout()
		game.style_session.updated.emit()
		await settle()
		await capture(("baseline-" if baseline else "final-") + str(geometry.x))
		if not baseline:
			var style = game.hud.get_node("StyleHUD")
			var inventory = game.hud.get_node("RunInventory")
			if known_bad:
				style.score_label.position = style.position
				style.note.text = "100/800"
			check(not style.score_label.get_global_rect().intersects(style.get_global_rect()), "score separated from style meter")
			check(style.score_label.get_rect().end.y < inventory.position.y, "score does not overlap inventory")
			check(game.hud.get_global_rect().encloses(style.get_global_rect()), "style stays within HUD")
			check(style.note.text == "COMBO %s" % style.format_score(game.style_session.score.combo_score), "combo score shows under the bar")
			check(not "/" in style.note.text and not "/" in style.label.text, "no rank fraction")
			check(not interface.guidance.is_visible_in_tree(), "normal HUD has no tutorial instructions")
	game.free()
	await process_frame
	print("Baseline HUD captures complete (not a regression pass)" if baseline else "HUD feedback: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func prepare_cast(text: String):
	if manager.is_typing:
		manager.cancel_typing()
	manager.casting_clock += 2.0
	manager.start_freeform_typing()
	manager.current_typing_text = text
	game.style_session.observe_text(text)
	game.update_typing_display(text)
	game.typing_keycaps.sync(text, "")

func verify_feedback():
	var keys = game.typing_keycaps
	var style = game.hud.get_node("StyleHUD")
	var session = game.style_session
	var reference = game.hud.get_node("CastingReference")
	prepare_cast("bolt")
	var focus_status = game.hud.get_node("TypingPanel/SlowdownStatus")
	check(focus_status.visible, "focus visible during incantation")
	var completion = keys.completion_count
	check(manager.cast_freeform_spell("bolt"), "owned bolt casts")
	check(keys.completion_count == completion + 1 and not keys.completed_mega, "successful ordinary incantation cue")
	check(keys.visible_caption().is_empty(), "no success toast")
	check(not focus_status.visible, "no stale focus during cast completion")
	check(style.pulse_kind == "gain", "cast award gives gain cue")
	game.hud.get_node("RunInventory")._process(0)
	var typing_panel = game.hud.get_node("TypingPanel")
	var inventory = game.hud.get_node("RunInventory")
	check(not inventory.visible or not typing_panel.get_global_rect().intersects(inventory.get_global_rect()), "completion panel does not cover inventory")
	await capture("cast-normal")
	await capture("combo-promotion")
	prepare_cast("mega bolt")
	for i in keys.letters.length():
		check(keys.typed_letter_tint(i) != Color("ff8175"), "valid freeform MEGA not mismatch")
	check(manager.cast_freeform_spell("mega bolt"), "MEGA cast accepted")
	manager.advance_pending_casts(0.351)
	check(keys.completed_mega and keys.completion_duration > 0.28, "MEGA distinct emphasis")
	await capture("cast-mega")
	prepare_cast("mega bolt")
	manager.target_spell = "bolt"
	for i in keys.letters.length():
		check(keys.typed_letter_tint(i) != Color("ff8175"), "valid numbered MEGA not mismatch")
	keys.letters = "mega bolx"
	check(keys.typed_letter_tint(8) == Color("ff8175"), "actual numbered typo marked")
	keys.letters = "me"
	check(keys.typed_letter_tint(1) != Color("ff8175"), "partial MEGA prefix valid")
	completion = keys.completion_count
	manager.cancel_typing()
	check(keys.completion_count == completion, "cancel no success cue")
	prepare_cast("not a spell")
	check(not manager.cast_freeform_spell("not a spell"), "unknown spell rejected")
	check(keys.completion_count == completion, "unknown no success cue")
	prepare_cast("meteor shower")
	check(not manager.cast_freeform_spell("meteor shower"), "unowned spell rejected")
	check(keys.completion_count == completion, "unowned no success cue")
	manager.cancel_typing()
	var pulse = style.pulse_count
	session.on_release("bolt", "bolt", "bolt")
	check(style.pulse_count == pulse, "invalid score receipt no gain pulse")
	session.score.combo = session.Score.CAP
	prepare_cast("bolt")
	pulse = style.pulse_count
	check(manager.cast_freeform_spell("bolt"), "spell casts at style cap")
	check(style.pulse_count == pulse, "zero actual combo gain does not pulse")
	check(keys.completion_count == completion + 1, "cast success independent of combo award")
	session.score.combo = 10000
	session.score.atomic_charges = 1
	prepare_cast("atomic")
	check(manager.cast_freeform_spell("atomic"), "Atomic accepted")
	check(style.pulse_kind == "atomic" and keys.completion_count == completion + 2, "Atomic cue distinct from damage")
	for blast in game.get_children():
		if blast.get_script() == load("res://scripts/AtomicBlast.gd"):
			blast.queue_free()
	prepare_cast("bolt")
	check(keys.completion_remaining == 0, "new typing clears prior completion")
	check(focus_status.visible, "new incantation restores focus status")
	await settle()
	check(not inventory.visible or not typing_panel.get_global_rect().intersects(inventory.get_global_rect()), "active typing does not cover inventory")
	manager.cancel_typing()
	session.score.combo = 900
	session.score.grace_remaining = 0
	pulse = style.pulse_count
	session.advance(1.0)
	check(session.score.combo < 900 and style.pulse_count == pulse, "decay drains without damage pulse")
	game.player.is_invincible = false
	game.player.overheal = 10
	game.player.take_damage(1)
	check(style.pulse_count == pulse, "overheal loss no combo hit cue")
	game.player.overheal = 0
	game.player.take_damage(1)
	check(style.pulse_kind == "hit" and style.pulse_count == pulse + 1, "health loss distinct hit cue")
	await capture("combo-hit")
	game.player.is_invincible = true
	game.particle_manager.reduced_effects = true
	style.badge.scale = Vector2.ONE
	style.on_style_event("gain", 10, true)
	check(style.badge.scale == Vector2.ONE and style.meter.modulate != Color.WHITE, "reduced effects preserves color without movement")
	game.particle_manager.reduced_effects = false
	var policy = load("res://scripts/CastingReference.gd")
	for id in ["bolt", "ice_blast", "lightning", "focus_ray", "seeker", "meteor_shower"]:
		check(not policy.shows_status(root.get_node("DataManager").get_spell_data(id)), "no unnecessary timer: " + id)
	for id in ["firewalk", "arcane_orbit", "earth_shield", "regeneration", "rune_trap"]:
		check(policy.shows_status(root.get_node("DataManager").get_spell_data(id)), "useful maintained status: " + id)
	check(policy.shows_status({"type":"beam","recast_behavior":"extend"}), "extendable lifecycle exposes useful status")
	var status = load("res://scripts/SpellDurationStatus.gd")
	for first in ["ground", "active"]:
		var states = {}
		status.add(states, "firewalk", 6 if first == "ground" else 1, first)
		status.add(states, "firewalk", 1 if first == "ground" else 6, "active" if first == "ground" else "ground")
		check(states.firewalk.phase == "active" and states.firewalk.seconds == 1 and states.firewalk.count == 1, "mixed trail phase has honest remaining emission and count")
	for id in ["firewalk", "arcane_orbit", "earth_shield", "regeneration"]:
		manager.cast_spell_by_type(manager.find_spell_slot(id))
	await settle()
	reference._process(0)
	check(reference.status_bars.firewalk.visible and "active" in reference.entries.firewalk.text, "Firewalk shows active drain")
	check(reference.status_bars.arcane_orbit.visible, "orbit shows active drain")
	check("charge" in reference.entries.earth_shield.text and not reference.status_bars.earth_shield.visible, "shield charges not cooldown")
	check(not reference.status_bars.bolt.visible and not "\n" in reference.entries.bolt.text, "Bolt stays name only")
	manager.cast_spell_by_type(manager.find_spell_slot("firewalk"))
	reference._process(0)
	check("+" in reference.entries.firewalk.text, "recast extension remains observable")
	var recipe = manager.Synergies.RECIPES.frost_sigil
	var bonus = manager.spell_catalog.rune_trap.duplicate(true)
	bonus.merge(recipe.overrides, true)
	bonus.id = "frost_sigil"
	bonus.name = recipe.name
	bonus.display_name = recipe.incantation
	manager.bonus_spells[7] = bonus
	manager.acquired_spells.frost_sigil = true
	manager.cast_spell_by_type(7)
	await settle()
	reference._process(0)
	check("arming" in reference.entries.frost_sigil.text or "armed" in reference.entries.frost_sigil.text, "combination trap uses equipped recipe status")
	pulse = style.pulse_count
	game.player.is_invincible = false
	game.player.take_damage(1, {"position":game.player.position + Vector2(10,0)})
	check(style.pulse_count == pulse, "shield block no hit cue")
	game.player.is_invincible = true
	check(not "Enter casts" in game.hud.get_node("TypingPanel/SlowdownStatus").text, "focus line no tutorial prose")
