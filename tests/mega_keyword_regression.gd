extends SceneTree

var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 100000.0
	var dying = false
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health -= amount
	func apply_slow(_amount, _duration):
		pass

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func projectiles(game, kind = "bolt"):
	return game.get_children().filter(func(node): return node is Area2D and node.get("projectile_type") == kind)

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	var target = Target.new()
	game.add_child(target)
	target.global_position = game.player.global_position + Vector2(240, 0)
	target.add_to_group("enemies")
	check(manager.find_cast_spell_slot("mega bolt") == 1, "MEGA resolves owned Bolt")
	for invalid in ["mega mega bolt", "big bolt", "mega lightning", "mega atomic", "mega mana bolt", "mega magic missile"]:
		check(manager.find_cast_spell_slot(invalid) == 0, "Reject " + invalid)
	check(manager.get_owned_incantations().has("mega bolt"), "Owned incantations include MEGA")
	var base_damage = manager.calculate_spell_damage(manager.get_spell_info(1))
	manager.spells[1].level = 2
	base_damage = manager.calculate_spell_damage(manager.get_spell_info(1))
	manager.current_typing_text = "mega bolt"
	check(manager.cast_freeform_spell("mega bolt"), "Freeform commits MEGA")
	manager.advance_pending_casts(0.351)
	var mega = projectiles(game)[0]
	check(is_equal_approx(mega.damage, base_damage * 1.5), "MEGA damage snapshot")
	var mega_size = mega.spell_size
	mega.set_process(false)
	check(is_equal_approx(manager.cast_keyword_multiplier, 1), "Dispatcher restores cast context")
	check(is_equal_approx(game.player.spell_size_multiplier, 1), "Player size untouched")
	check(is_equal_approx(game.player.spell_damage_multiplier, 1), "Player power untouched")
	await create_timer(0.14).timeout
	var bolts = projectiles(game)
	check(bolts.size() == 2, "Delayed second Bolt emitted")
	check(bolts.all(func(b): return is_equal_approx(b.spell_size, mega_size) and is_equal_approx(b.damage, base_damage * 1.5)), "Delayed Bolt retains MEGA snapshot")
	manager.cast_spell_by_type(1)
	var normal = projectiles(game).back()
	normal.set_process(false)
	check(is_equal_approx(mega_size, normal.spell_size * 1.5), "Normal cast remains ordinary sized")
	check(is_equal_approx(normal.damage, base_damage), "Normal cast remains ordinary power")
	check(is_equal_approx(mega.get_node("CollisionShape2D").shape.radius, normal.get_node("CollisionShape2D").shape.radius * 1.5), "Collision matches visible growth")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 720)
		for projectile in projectiles(game):
			if projectile != mega and projectile != normal:
				projectile.hide()
		mega.global_position = game.player.global_position + Vector2(-120, -100)
		normal.global_position = game.player.global_position + Vector2(120, -100)
		var labels: Array = []
		for pair in [[mega, "MEGA BOLT"], [normal, "BOLT"]]:
			var label = Label.new()
			label.text = pair[1]
			label.add_theme_font_size_override("font_size", 18)
			game.add_child(label)
			label.global_position = pair[0].global_position + Vector2(-50, -45)
			labels.append(label)
		DirAccess.make_dir_recursive_absolute("res://builds/mega-evidence")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/mega-evidence/bolt-size.png")
		for label in labels:
			label.queue_free()
	manager.fire_mana_bolt()
	var automatic = projectiles(game, "mana_bolt")[0]
	check(not automatic.has_meta("cast_size_snapshot"), "Magic Missile unaffected")
	mega.reset_for_pool()
	check(not mega.has_meta("cast_size_snapshot"), "Pool clears MEGA geometry")
	mega.set_meta("cast_size_snapshot", mega_size / preload("res://scripts/VisualDefaults.gd").PROJECTILE_SCALES.get("bolt", 1.0))
	mega.setup(mega.global_position, Vector2.RIGHT, base_damage * 1.5, Color.WHITE, "bolt")
	var field_data = {"id": "test", "type": "field", "duration": 1.0, "radius": 100, "tick_interval": 0.5}
	var field = preload("res://scripts/BuildSpellEffect.gd").new()
	field.configure(field_data, 10, game.player, target)
	game.add_child(field)
	field.set_physics_process(false)
	var boosted_field = field_data.duplicate(true)
	boosted_field.keyword_size_multiplier = 1.5
	field.queue_cast_extension(boosted_field, 15)
	var before_health = target.current_health
	field.advance(2)
	var large_step_damage = before_health - target.current_health
	field.free()
	field = preload("res://scripts/BuildSpellEffect.gd").new()
	field.configure(field_data, 10, game.player, target)
	game.add_child(field)
	field.set_physics_process(false)
	field.queue_cast_extension(boosted_field, 15)
	before_health = target.current_health
	field.advance(1)
	field.advance(1)
	check(is_equal_approx(large_step_damage, before_health - target.current_health), "Segment boundary is independent of frame delta")
	check(is_equal_approx(large_step_damage, 50), "Normal and MEGA field duration retain distinct power")
	field.free()
	var slot = 2
	for id in manager.spell_catalog:
		if id == "bolt":
			continue
		manager.spells[slot] = manager.spell_catalog[id].duplicate(true)
		manager.spells[slot].level = 1
		manager.acquired_spells[id] = true
		slot += 1
	var life = manager.find_spell_slot("life")
	game.player.health = 10
	manager.cast_spell_by_type(life)
	var ordinary_heal = game.player.health - 10
	game.player.health = 10
	game.player.next_heal_feedback_msec = 0
	manager.cast_spell_by_type(life, 1.5)
	check(is_equal_approx(game.player.health - 10, ordinary_heal * 1.5), "MEGA Life heals more")
	check(game.particle_manager.get_children().any(func(v): return v is Node2D and is_equal_approx(v.scale.x, 1.5)), "MEGA healing is visibly larger")
	for id in ["regeneration", "arcane_orbit", "firewalk"]:
		var owned_slot = manager.find_spell_slot(id)
		manager.cast_spell_by_type(owned_slot)
		manager.cast_spell_by_type(owned_slot, 1.5)
		if id == "regeneration":
			check(manager.active_healing_effects.size() == 1, "Mixed regeneration uses one stream")
			check(is_equal_approx(manager.active_healing_effects[0].segments[1].rate, manager.active_healing_effects[0].segments[0].rate * 1.5), "MEGA regeneration potency")
		else:
			var effects = get_nodes_in_group("build_spell_effects").filter(func(v): return v.info.id == id)
			check(effects.size() == 1, id + " mixed casts preserve one effect")
			check(is_equal_approx(effects[0].queued_casts[0].damage, effects[0].damage * 1.5), id + " power")
			check(is_equal_approx(effects[0].queued_casts[0].info.spell_size_multiplier, effects[0].info.spell_size_multiplier * 1.5), id + " size")
	for id in preload("res://scripts/SynergyCatalog.gd").RECIPES:
		if not preload("res://scripts/SynergyCatalog.gd").RECIPES[id].get("enabled", true):
			continue
		check(manager.learn_spell(id), "Learn combination " + id)
		var added_slot = manager.bonus_spells.keys().back()
		var entry = manager.bonus_spells[added_slot]
		manager.bonus_spells.erase(added_slot)
		manager.bonus_spells[100 + manager.bonus_spells.size()] = entry
		var combo_slot = manager.find_spell_slot(id)
		var ordinary = manager.resolve_cast_info(combo_slot)
		manager.cast_keyword_multiplier = manager.MEGA_MULTIPLIER
		var boosted = manager.resolve_cast_info(combo_slot)
		for property in ["splash_damage", "explosion_damage", "healing_seed_amount", "healing_bloom_amount"]:
			if ordinary.has(property):
				check(is_equal_approx(boosted[property], ordinary[property] * 1.5), id + " " + property + " scales")
		manager.cast_keyword_multiplier = 1
	var meteor_slot = manager.find_spell_slot("meteor_shower")
	manager.cast_spell_by_type(meteor_slot, 1.5)
	var warnings = projectiles(game, "warning")
	check(not warnings.is_empty(), "MEGA meteor warning exists")
	var warning_radius = warnings[0].effect_radius
	manager.cast_spell_by_type(1)
	await create_timer(0.7).timeout
	var impacts = game.get_children().filter(func(v): return v.get_script() == preload("res://scripts/LingeringArea.gd"))
	check(not impacts.is_empty(), "Delayed meteor impact exists")
	check(impacts.any(func(v): return is_equal_approx(v.radius, warning_radius)), "Delayed meteor retains warning footprint")
	manager.last_spell_cast_time = -100
	check(manager.activate_spell_slot(1), "Numbered cast begins")
	var style = game.style_session
	for text in ["m", "me", "mega", "mega b", "mega bolt"]:
		manager.current_typing_text = text
		style.observe_text(text)
		style.clock += 0.1
	check(style.mistakes == 0, "MEGA prefixes are not typos")
	manager.attempt_cast()
	manager.advance_pending_casts(0.351)
	check(not manager.is_typing, "Numbered MEGA cast completes")
	check(style.score.run_score > 0, "MEGA receives style credit")
	check(style.score.freshness.has("bolt") and not style.score.freshness.has("mega bolt"), "Same base repetition identity")
	if DisplayServer.get_name() != "headless":
		game.change_state(game.GameState.PAUSED)
		game.get_node("PauseInput").open_spellbook()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/mega-evidence/spellbook.png")
		game.get_node("PauseInput").spellbook.close()
		game.change_state(game.GameState.PLAYING)
	game.queue_free()
	await process_frame
	await create_timer(1.0).timeout
	for audio_player in root.get_node("AudioManager").get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
			audio_player.stream = null
	print("MEGA: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
