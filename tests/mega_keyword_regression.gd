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
	# Bolt runs on the generic engine (doc 18 phase 2): the MEGA snapshot lives in the cast plan.
	var mega_cast = manager.last_generic_cast
	var mega_part: Dictionary = mega_cast.plan.parts.bolt
	check(is_equal_approx(float(mega_part.payload[0].hit), base_damage * 1.5), "MEGA damage snapshot")
	var mega_size = float(mega_part.geometry.radius)
	check(is_equal_approx(manager.cast_keyword_multiplier, 1), "Dispatcher restores cast context")
	check(is_equal_approx(game.player.spell_size_multiplier, 1), "Player size untouched")
	check(is_equal_approx(game.player.spell_damage_multiplier, 1), "Player power untouched")
	for i in 9:   # 0.15 s of game time: the second bolt leaves 0.12 s after the first
		await physics_frame
	check(mega_cast.spawned == 2, "Delayed second Bolt emitted")
	check(mega_cast.parts.all(func(p): return not is_instance_valid(p) or is_equal_approx(p.geo("radius"), mega_size)), "Delayed Bolt retains MEGA snapshot")
	manager.cast_spell_by_type(1)
	var normal_part: Dictionary = manager.last_generic_cast.plan.parts.bolt
	check(is_equal_approx(mega_size, float(normal_part.geometry.radius) * 1.5), "Normal cast remains ordinary sized")
	check(is_equal_approx(float(normal_part.payload[0].hit), base_damage), "Normal cast remains ordinary power")
	check(float(normal_part.geometry.get("pad", 14.0)) == float(mega_part.geometry.get("pad", 14.0)), "Collision matches visible growth (one radius drives hit and look)")
	manager.fire_mana_bolt()
	# Magic Missile runs on the generic engine; a MEGA cast's size never leaks into it.
	var automatic: Dictionary = manager.last_generic_cast.plan.parts.missile
	var plain_missile = preload("res://scripts/SpellGeometry.gd").BOLT_RADIUS * preload("res://scripts/SpellGeometry.gd").multiplier(game.player) * 0.8
	check(is_equal_approx(float(automatic.geometry.radius), plain_missile), "Magic Missile unaffected (%s vs %s)" % [automatic.geometry.radius, plain_missile])
	# Fields run on the generic engine (doc 18 phase 2): an extend recast queues a segment.
	var field_data = {"id": "test", "type": "field", "duration": 1.0, "radius": 100, "tick_interval": 0.5, "recast_behavior": "extend"}
	var boosted_field = field_data.duplicate(true)
	boosted_field.keyword_size_multiplier = 1.5
	var before_health = target.current_health
	var field = manager.spawn_ported(field_data, 10, {}, target)
	field.manual = true
	check(manager.spawn_ported(boosted_field, 15, {}, target) == field, "MEGA recast extends the live field")
	field.run(2.0, 0.1)
	var large_step_damage = before_health - target.current_health
	field.free()
	before_health = target.current_health
	field = manager.spawn_ported(field_data, 10, {}, target)
	field.manual = true
	manager.spawn_ported(boosted_field, 15, {}, target)
	field.run(1.0, 1.0 / 60.0)
	field.run(1.0, 1.0 / 60.0)
	check(is_equal_approx(large_step_damage, before_health - target.current_health), "Segment boundary is independent of frame delta (%s vs %s)" % [large_step_damage, before_health - target.current_health])
	check(is_equal_approx(large_step_damage, 50), "Normal and MEGA field duration retain distinct power (%s)" % large_step_damage)
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
	# With the VFX layer up the heal burst is drawn there (sized by the same value); check the
	# particle fallback the layer replaces.
	var vfx = root.get_node("Vfx")
	game.player.health = 10
	game.player.next_heal_feedback_msec = 0
	vfx.presenter.enabled = false
	manager.cast_spell_by_type(life, 1.5)
	vfx.presenter.enabled = true
	check(game.particle_manager.get_children().any(func(v): return v is Node2D and is_equal_approx(v.scale.x, 1.5)), "MEGA healing is visibly larger")
	for id in ["regeneration", "arcane_orbit", "firewalk"]:
		var owned_slot = manager.find_spell_slot(id)
		manager.cast_spell_by_type(owned_slot)
		manager.cast_spell_by_type(owned_slot, 1.5)
		if id == "regeneration":
			var regen = manager.ported_casts(id)
			check(regen.size() == 1, "Mixed regeneration uses one stream")
			var aura = regen[0].root_parts()[0] if not regen.is_empty() else null
			check(aura != null and not aura.segments.is_empty() and is_equal_approx(float(aura.segments[0].def.heal_rate), float(aura.def.heal_rate) * 1.5), "MEGA regeneration potency")
		elif id == "arcane_orbit":
			# Ported to the generic engine: the MEGA recast is a queued segment on the live sparks.
			var casts = manager.ported_casts(id)
			check(casts.size() == 1, id + " mixed casts preserve one effect")
			var spark = casts[0].root_parts()[0]
			check(not spark.segments.is_empty() and is_equal_approx(float(spark.segments[0].def.payload[0].hit), float(spark.def.payload[0].hit) * 1.5), id + " power")
			check(not spark.segments.is_empty() and is_equal_approx(float(spark.segments[0].def.geometry.radius), float(spark.def.geometry.radius) * 1.5), id + " size")
		else:
			# Fire Walk: the MEGA recast queues an emitter segment whose patches carry the MEGA numbers.
			var casts = manager.ported_casts(id)
			check(casts.size() == 1, id + " mixed casts preserve one effect")
			var walker = casts[0].root_parts()[0]
			var plan_parts: Dictionary = casts[0].plan.parts
			var queued = plan_parts.get(str(walker.segments[0].def.emit.part), {}) if not walker.segments.is_empty() else {}
			check(not queued.is_empty() and is_equal_approx(float(queued.payload[0].hit), float(plan_parts.patch.payload[0].hit) * 1.5), id + " power")
			check(not queued.is_empty() and is_equal_approx(float(queued.geometry.radius), float(plan_parts.patch.geometry.radius) * 1.5), id + " size")
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
	# Meteor Shower runs on the generic engine: marks warn, then each lands an impact of the same size.
	var meteor_casts = manager.ported_casts("meteor_shower")
	check(not meteor_casts.is_empty(), "MEGA meteor warning exists")
	var landed = 0
	var footprint_kept = false
	if not meteor_casts.is_empty():
		var meteor = meteor_casts.back()
		meteor.manual = true
		var marks = meteor.root_parts().size()
		meteor.run(1.5)
		landed = meteor.spawned - marks
		# Impacts take the mark's size scale; their own radius matches the mark's in the plan.
		footprint_kept = is_equal_approx(float(meteor.plan.parts.impact.geometry.radius), float(meteor.plan.parts.mark.geometry.radius))
	check(landed > 0, "Delayed meteor impact exists")
	check(footprint_kept, "Delayed meteor retains warning footprint")
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
