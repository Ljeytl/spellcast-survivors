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

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	var widths = {"pursuer":44,"sprinter":32,"flanker":48,"skirmisher":50,"swarmer":24,"juggernaut":78,"charger":40,"shieldbearer":84,"slammer":90,"marksman":26,"fan_caster":30,"mortar":58}
	for id in manager.encounter_config.variants:
		var definition = manager.encounter_config.variants[id].duplicate(true)
		definition.id = id
		var enemy = manager.spawn_monster(definition, false, true)
		enemy.set_physics_process(false)
		var sprite = enemy.get_node("Sprite2D")
		var used = sprite.texture.get_image().get_used_rect()
		check(absf(used.size.x * sprite.scale.x * enemy.scale.x - widths[id]) < 0.1, "Authored body width: " + id)
		check(is_equal_approx(enemy.scale.x, definition.size) and enemy.get_node("CollisionShape2D").shape.size == Vector2(40,40), "Variant collision scale unchanged: " + id)
		check(enemy.current_health == definition.health and enemy.speed == definition.speed and enemy.damage == definition.damage, "Variant gameplay stats unchanged: " + id)
		var top = (used.position.y - sprite.texture.get_height() / 2.0) * sprite.scale.y
		check(enemy.get_node("HealthBar").offset_bottom < top, "Healthbar clears artwork: " + id)
		enemy.queue_free()
	for id in ["juggernaut","charger","shieldbearer"]:
		var definition = manager.encounter_config.variants[id].duplicate(true)
		definition.id = id
		var enemy = manager.spawn_monster(definition, true, true)
		var sprite = enemy.get_node("Sprite2D")
		var width = sprite.texture.get_image().get_used_rect().size.x * sprite.scale.x * enemy.scale.x
		check(absf(width - {"juggernaut":140,"charger":125,"shieldbearer":155}[id]) < 0.1, "Boss has deliberate silhouette: " + id)
		check(is_equal_approx(enemy.scale.x, definition.size * 1.7) and enemy.current_health == definition.health * 12, "Boss gameplay size/HP unchanged: " + id)
		enemy.queue_free()
	var particles = game.particle_manager
	var hit = particles.create_spell_impact_effect(Vector2.ZERO)
	var death = particles.create_enemy_death_effect(Vector2.ZERO)
	var xp = particles.create_xp_collect_effect(Vector2.ZERO)
	var boss_death = particles.create_boss_death_effect(Vector2.ZERO)
	check(xp.particle_size < hit.particle_size and hit.particle_size <= death.particle_size and death.particle_size < boss_death.particle_size, "Effect importance has readable size hierarchy")
	check(xp.radius == 12 and xp.duration == 0.25, "XP sparkle remains restrained")
	check(hit.get_child_count() == 0 and death.get_child_count() == 0, "Cosmetic bursts have no collision nodes")
	check(game.camera.zoom == Vector2.ONE * 1.5 and game.player.get_node("Sprite2D").scale == Vector2.ONE * 2, "Reviewed camera and wizard proportions")
	check(game.player.get_node("CollisionShape2D").shape.size == Vector2(64,64), "Player navigation shape preserved")
	game.queue_free()
	await process_frame
	print("Visual proportions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
