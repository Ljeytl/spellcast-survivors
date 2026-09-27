extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	run.call_deferred()

func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ", label)

func run():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		quit(2)
		return
	root.get_node("AudioManager").quitting = true
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	await fixture.setup(root, "regeneration")
	var player = fixture.game.player
	var particles = fixture.game.particle_manager
	var manager = fixture.game.spell_manager
	var leaves = particles.get_children().filter(func(effect): return effect.mode == "regeneration")
	check(leaves.size() == 1, "Regeneration has one ongoing leaf indicator")
	var indicator = leaves[0]
	indicator.set_process(false)
	check(indicator.followed.get_ref() == player and indicator.duration > 1, "Leaves track caster and spell lifetime")
	player.health = player.max_health
	var before = particles.get_child_count()
	player.heal(4)
	if "--known-bad-full-health" in OS.get_cmdline_user_args():
		particles.create_heal_effect(player.global_position)
	check(particles.get_child_count() == before, "Full health never emits healing pluses")
	check(not indicator.is_queued_for_deletion(), "Leaves remain at full health")
	var chest = load("res://scenes/Chest.tscn").instantiate()
	fixture.game.add_child(chest)
	chest.chest_type = 0
	chest.create_collection_effects()
	check(particles.get_child_count() == before, "Health chest does not fake healing at full health")
	chest.free()
	player.health -= 10
	player.next_heal_feedback_msec = 0
	player.heal(4)
	check(is_equal_approx(player.health, player.max_health - 6), "Life restores actual health")
	check(particles.get_children().filter(func(effect): return effect.mode == "healing").size() == 1, "Actual healing emits one plus burst")
	indicator.age = 1
	manager.cast_life_spell(manager.find_spell_slot("regeneration"))
	check(particles.get_children().filter(func(effect): return effect.mode == "regeneration").size() == 1, "Overlapping regeneration does not stack visual clutter")
	check(indicator.duration > 1 + indicator.age, "Recast extends active indicator")
	indicator._process(indicator.duration)
	check(indicator.is_queued_for_deletion(), "Leaves expire")
	for id in ["bolt", "mana_bolt", "life_bolt", "lightning_bolt"]:
		await fixture.setup(root, id)
		var projectiles = get_nodes_in_group("spell_projectiles").filter(func(node): return node.projectile_type == id)
		check(not projectiles.is_empty(), id + " has projectile")
		if not projectiles.is_empty():
			var shot = projectiles[0]
			var factor = 0.75 if id == "bolt" else 1.0
			check(is_equal_approx(shot.spell_size, factor), id + " baseline is isolated")
			check(is_equal_approx(shot.get_node("CollisionShape2D").shape.radius, 17 * factor), id + " collision matches visible body")
	var workshop = load("res://tools/workshop/VisualWorkshop.gd").new()
	fixture.game.free()
	root.add_child(workshop)
	await settled(workshop)
	workshop.command([JSON.stringify({"action":"settings", "values":{"spell_size":0.8, "projectile":1.2, "particle":1.3}})])
	await settled(workshop)
	workshop.command([JSON.stringify({"action":"select", "id":"regeneration"})])
	await settled(workshop)
	check(workshop.fixture.settings.spell_size == 1, "Bolt adjustment never leaks into regeneration")
	workshop.command([JSON.stringify({"action":"settings", "values":{"spell_size":1.4}})])
	await settled(workshop)
	workshop.command([JSON.stringify({"action":"select", "id":"bolt"})])
	await settled(workshop)
	if "--known-bad-selection" in OS.get_cmdline_user_args():
		workshop.fixture.settings.spell_size = 1.4
	check(is_equal_approx(workshop.fixture.settings.spell_size, 0.8), "Selecting Bolt restores its gameplay size")
	check(is_equal_approx(workshop.fixture.settings.projectile, 1.2) and is_equal_approx(workshop.fixture.settings.particle, 1.3), "Selecting Bolt restores its decorative sizes")
	check(is_equal_approx(workshop.fixture.settings.effect_settings.regeneration.spell_size, 1.4), "Export state retains other spell settings")
	workshop.command([JSON.stringify({"action":"settings", "values":{"effect_settings":{}, "spell_size":1, "projectile":1, "particle":1}})])
	await settled(workshop)
	workshop.command([JSON.stringify({"action":"select", "id":"regeneration"})])
	await settled(workshop)
	check(workshop.fixture.settings.spell_size == 1, "Reset clears all effect overrides")
	check(is_equal_approx(workshop.fixture.game.camera.zoom.x, 1.3875), "Workshop camera matches game default")
	workshop.command([JSON.stringify({"action":"select", "id":"regeneration"})])
	workshop.command([JSON.stringify({"action":"select", "id":"ice_blast"})])
	await settled(workshop)
	check(workshop.selected == "ice_blast" and workshop.fixture.selected == "ice_blast", "Rapid selection settles on latest effect")
	check(not get_nodes_in_group("ice_blasts").is_empty(), "Latest selection renders actual Ice Blast")
	workshop.free()
	print("HEALING READABILITY CHECKS ", checks, " FAILURES ", failures)
	quit(1 if failures else 0)

func settled(workshop):
	for frame in range(80):
		await process_frame
		if not workshop.busy:
			return
	check(false, "Workshop settled")
