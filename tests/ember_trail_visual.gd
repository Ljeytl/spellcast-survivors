extends SceneTree
## Rendered evidence for the Ember Spear fire trail. Run windowed:
## Godot --path . --script res://tests/ember_trail_visual.gd

const OUT = "res://builds/ember-trail/"

func _initialize():
	run.call_deferred()

func wait(seconds: float):
	await create_timer(seconds, true, false, true).timeout

func shot(name: String):
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run():
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await wait(1.0)
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	game.player.is_invincible = true
	var def = monsters.encounter_config.variants.pursuer.duplicate(true)
	def.id = "pursuer"
	# A loose column of slimes walking in from the right.
	for i in 12:
		var enemy = monsters.spawn_monster(def, true)
		enemy.global_position = game.player.global_position + Vector2(140 + i * 45, (i % 3 - 1) * 30)
	game.spell_manager.mana_bolt_timer = 999.0
	game.spell_manager.learn_spell("ember_lance")
	game.spell_manager.cast_freeform_spell("ember spear")
	await wait(0.25)
	await shot("01-throw")
	await wait(0.8)
	await shot("02-line-burning")
	await wait(1.2)
	await shot("03-burnt-out")
	game.queue_free()
	await process_frame
	quit()
