extends SceneTree

var checks = 0
var failures = 0
var game
var visual = false
var known_bad = false

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	visual = "--visual" in OS.get_cmdline_user_args()
	known_bad = "--known-bad-dark-tint" in OS.get_cmdline_user_args()
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func capture(name):
	for effect in get_nodes_in_group("effect_bursts"):
		effect.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	var suffix = "-negative" if known_bad and not name.ends_with("-negative") else ""
	image.save_png("res://builds/evidence/damage-flash-" + name + suffix + ".png")
	return image

func red_pixels(image: Image, center: Vector2):
	var count = 0
	for y in range(maxi(0, int(center.y) - 45), mini(image.get_height(), int(center.y) + 45)):
		for x in range(maxi(0, int(center.x) - 45), mini(image.get_width(), int(center.x) + 45)):
			var color = image.get_pixel(x, y)
			if color.r > 0.45 and color.r > color.g * 2 and color.r > color.b * 2:
				count += 1
	return count

func run():
	root.get_node("AudioManager").quitting = true
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	var manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	var enemy = manager.spawn_monster(manager.get_available_variants(0)[0])
	enemy.position = game.player.position + Vector2(120, 0)
	enemy.set_physics_process(false)
	enemy.max_health = 1000
	enemy.current_health = 1000
	var player = game.player
	var player_sprite = player.get_node("Sprite2D")
	var enemy_sprite = enemy.get_node("Sprite2D")
	player.health = 100
	player.overheal = 0
	player.take_damage(0)
	enemy.take_damage(0)
	check(player_sprite.get_node_or_null("DamageFlash") == null, "Zero player damage does not flash")
	check(enemy_sprite.get_node_or_null("DamageFlash") == null, "Zero enemy damage does not flash")
	player.is_invincible = true
	player.take_damage(10)
	check(player.health == 100 and player_sprite.get_node_or_null("DamageFlash") == null, "Invincible hit does not flash")
	player.is_invincible = false
	player.overheal = 10
	player.take_damage(5)
	check(player.health == 100 and player_sprite.get_node_or_null("DamageFlash") == null, "Shield absorption retains distinct shield feedback")
	player.overheal = 0
	enemy.apply_slow(0.6, 2)
	var slow_color = enemy_sprite.modulate
	player_sprite.modulate.a = 0.7
	var player_color = player_sprite.modulate
	var before: Image
	var player_center: Vector2
	var enemy_center: Vector2
	if visual:
		DirAccess.make_dir_recursive_absolute("res://builds/evidence")
		before = await capture("before")
		player_center = root.get_final_transform() * (player.get_global_transform_with_canvas() * Vector2.ZERO)
		enemy_center = root.get_final_transform() * (enemy.get_global_transform_with_canvas() * Vector2.ZERO)
	player.take_damage(1)
	enemy.take_damage(1)
	var player_flash = player_sprite.get_node("DamageFlash")
	var enemy_flash = enemy_sprite.get_node("DamageFlash")
	player_flash.set_process(false)
	enemy_flash.set_process(false)
	check(player_flash.visible and enemy_flash.visible, "Actual damage shows both overlays immediately")
	check(player_sprite.modulate == player_color and enemy_sprite.modulate == slow_color, "Hit preserves player alpha and enemy slow color")
	check(is_equal_approx(player_flash.remaining, 0.1), "Flash uses the requested tenth-second duration")
	check(player_flash.texture.get_image().get_pixel(0, 0).a == player_sprite.texture.get_image().get_pixel(0, 0).a, "Flash mask preserves transparent sprite pixels")
	if visual:
		if known_bad:
			player_flash.hide()
			enemy_flash.hide()
			player_sprite.modulate = Color.RED
			enemy_sprite.modulate = Color.RED
		var hit = await capture("hit-negative" if known_bad else "hit")
		print("Native red pixels: wizard=%d enemy=%d" % [red_pixels(hit, player_center) - red_pixels(before, player_center), red_pixels(hit, enemy_center) - red_pixels(before, enemy_center)])
		check(red_pixels(hit, player_center) > red_pixels(before, player_center) + 250, "Native wizard damage is visibly red instead of dark cyan")
		check(red_pixels(hit, enemy_center) > red_pixels(before, enemy_center) + 25, "Native enemy damage is visibly red")
		player_sprite.modulate = player_color
		enemy_sprite.modulate = slow_color
	player_flash.advance(0.06)
	enemy_flash.advance(0.06)
	player.take_damage(1)
	enemy.take_damage(1)
	check(player_sprite.get_node("DamageFlash") == player_flash and enemy_sprite.get_node("DamageFlash") == enemy_flash, "Repeated hits reuse one overlay per actor")
	player_flash.advance(0.05)
	enemy_flash.advance(0.05)
	check(player_flash.visible and enemy_flash.visible, "Repeated hit restarts full flash window")
	player.toggle_invincibility()
	var invincible_color = player_sprite.modulate
	enemy_sprite.modulate = Color(0.8, 1.4, 0.8, 0.65)
	var elite_color = enemy_sprite.modulate
	player_flash.advance(0.06)
	enemy_flash.advance(0.06)
	check(not player_flash.visible and not enemy_flash.visible, "Overlays clear after their last hit")
	check(player_sprite.modulate == invincible_color and enemy_sprite.modulate == elite_color, "Expiry preserves colors changed during flash")
	player.toggle_invincibility()
	player_sprite.modulate = player_color
	enemy_sprite.modulate = slow_color
	if visual:
		var restored = await capture("restored")
		check(red_pixels(restored, player_center) <= red_pixels(before, player_center) + 5, "Wizard leaves no persistent red pixels")
		check(red_pixels(restored, enemy_center) <= red_pixels(before, enemy_center) + 5, "Enemy leaves no persistent red pixels")
	player_flash.set_process(true)
	player.take_damage(1)
	paused = true
	await create_timer(0.15, true).timeout
	check(not player_flash.visible, "Flash expires while death or pause freezes gameplay")
	paused = false
	enemy.take_damage(5000)
	var flash_reference = weakref(enemy_flash)
	await process_frame
	await process_frame
	check(flash_reference.get_ref() == null, "Enemy death frees its flash with the actor")
	game.queue_free()
	await process_frame
	await process_frame
	check(not is_instance_valid(player_flash), "Run teardown frees player flash")
	print("Damage flash regression: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
