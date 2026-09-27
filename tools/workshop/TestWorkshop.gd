extends SceneTree

var checks = 0
var failures = 0

func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ", label)

func _initialize():
	run.call_deferred()

func run():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		quit(2)
		return
	root.get_node("AudioManager").quitting = true
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	await fixture.setup(root, "bolt")
	check(fixture.catalog().size() == 52, "complete 24 spell and 28 factory catalog")
	var wizard = fixture.game.player.get_node("Sprite2D")
	var original = wizard.scale
	var enemy = fixture.targets[0]
	var enemy_original = enemy.get_node("Sprite2D").scale
	var collision_original = enemy.scale
	fixture.settings.wizard = 1.8
	fixture.settings.enemy = 1.4
	fixture.settings.zoom = 2.0
	fixture.apply_sizes()
	check(wizard.scale.is_equal_approx(original * 1.8), "wizard multiplier")
	check(enemy.get_node("Sprite2D").scale.is_equal_approx(enemy_original * 1.4), "enemy artwork multiplier")
	check(enemy.scale == collision_original, "enemy collision root unchanged")
	fixture.apply_sizes()
	check(wizard.scale.is_equal_approx(original * 1.8), "scaling does not compound")
	check(fixture.game.camera.zoom == Vector2.ONE * 2, "camera preview")
	fixture.settings.wizard = 1.0
	fixture.settings.enemy = 1.0
	fixture.apply_sizes()
	check(wizard.scale == original, "reset wizard")
	check(enemy.get_node("Sprite2D").scale == enemy_original, "reset enemy")
	fixture.settings.comparison = true
	await fixture.setup(root, "steam_field")
	check(fixture.targets.size() == 12, "all twelve normal variants compared")
	fixture.settings.enemy_sizes = {"swarmer": 1.8}
	fixture.apply_sizes()
	for target in fixture.targets:
		var multiplier = 1.8 if target.variant == "swarmer" else 1.0
		var sprite = target.get_node("Sprite2D")
		check(sprite.scale.is_equal_approx(sprite.get_meta("preview_original_scale") * multiplier), "independent variant size " + target.variant)
	check(fixture.game.spell_manager.find_spell_slot("steam_field") > 0, "combination cast in isolated fixture")
	fixture.settings.comparison = false
	await fixture.setup(root, "create_enemy_death_effect")
	check(fixture.game.particle_manager.get_child_count() > 0, "real particle factory")
	fixture.settings.particle = 2.0
	fixture.apply_sizes()
	var effect = fixture.game.particle_manager.get_children()[-1]
	check(is_equal_approx(effect.particle_size, float(effect.get_meta("preview_original_particle")) * 2), "particle stamp multiplier")
	if "--known-bad-compounding" in OS.get_cmdline_user_args():
		fixture.settings.wizard = 2.0
		fixture.apply_sizes()
		fixture.game.player.get_node("Sprite2D").scale *= 2
		check(fixture.game.player.get_node("Sprite2D").scale == Vector2.ONE * 4, "scaling does not compound negative control")
	print("WORKSHOP CHECKS ", checks, " FAILURES ", failures)
	quit(1 if failures else 0)
