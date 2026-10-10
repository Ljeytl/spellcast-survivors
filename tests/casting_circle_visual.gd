extends SceneTree
## Rendered evidence for the casting circle. Run windowed:
## Godot --path . --script res://tests/casting_circle_visual.gd

const OUT = "res://builds/casting-circle/"
var game: Node

func _initialize():
	run.call_deferred()

func wait(seconds: float):
	await create_timer(seconds, true, false, true).timeout

func shot(name: String):
	var c = game.player.get_node_or_null("CastingCircle")
	if c:
		print("SHOT ", name, " text='", game.spell_manager.current_typing_text, "' typing=", game.spell_manager.is_typing, " fade=", c.fade, " runes=", c.runes.size(), " good=", c.good_runes, " state=", c.state, " table=", c.spell_table())
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func press(ch: String):
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE if ch == " " else KEY_A + (ch.unicode_at(0) - "a".unicode_at(0))
	event.unicode = ch.unicode_at(0)
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var up = event.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()

func type_text(text: String, gap: float = 0.07):
	for i in text.length():
		press(text[i])
		await wait(gap)

func key(code: int):
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var up = event.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await wait(0.06)

func backspace(times: int):
	for i in times:
		var event = InputEventKey.new()
		event.keycode = KEY_BACKSPACE
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await wait(0.04)

func run():
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await wait(0.8)
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	game.player.is_invincible = true
	var def = monsters.encounter_config.variants.pursuer.duplicate(true)
	def.id = "pursuer"
	for i in 10:
		var enemy = monsters.spawn_monster(def, true)
		enemy.global_position = game.player.global_position + Vector2.from_angle(i * TAU / 10.0) * (190 + (i % 3) * 40)
		enemy.set_physics_process(false)
	var spells = game.spell_manager
	for id in ["meteor_shower", "cinder_field", "cross_blade", "lightning", "ice_blast"]:
		spells.learn_spell(id)
	await wait(2.5)  # the opening cast cooldown ignores keys right after load
	await key(KEY_SPACE)
	await type_text("c")
	await wait(0.25)
	await shot("01-c-neutral")
	await type_text("i")
	await wait(0.35)
	await shot("02-ci-fire-locked")
	await type_text("nder f")
	await wait(0.4)
	await shot("03-cinder-f-two-rings")
	await type_text("ield", 0.07)
	await key(KEY_ENTER)
	await shot("04-cinder-field-cast")
	await wait(0.45)
	await shot("04b-scorch")
	await wait(1.2)
	await key(KEY_SPACE)
	await type_text("meg")
	await wait(0.3)
	await shot("05a-meg-forming-satellite")
	await type_text("x")
	await wait(0.08)
	await shot("05b-megx-typo-in-satellite")
	await backspace(1)
	await type_text("a ")
	await wait(0.12)
	await shot("05c-mega-seals")
	await wait(0.4)
	await shot("05-mega-satellite")
	await type_text("meteor sho")
	await wait(0.4)
	await shot("06-mega-meteor-sho")
	await type_text("wer", 0.07)
	await key(KEY_ENTER)
	await wait(0.12)
	await shot("07a-mega-charging")
	await wait(0.3)
	await shot("07b-mega-burst")
	await wait(1.2)
	await key(KEY_SPACE)
	await type_text("bx")
	await wait(0.1)
	await shot("08-typo")
	await backspace(2)
	await type_text("bol")
	await wait(0.35)
	await shot("09-bol")
	await type_text("t")
	await key(KEY_ENTER)
	await wait(0.1)
	await shot("10-bolt-cast")
	await wait(1.0)
	await key(KEY_SPACE)
	await type_text("ice blast")
	await key(KEY_ENTER)
	await wait(0.1)
	await shot("11-ice-cast")
	await wait(1.0)
	await key(KEY_SPACE)
	await type_text("lightning")
	await key(KEY_ENTER)
	await wait(0.1)
	await shot("12-lightning-cast")
	await wait(1.0)
	game.queue_free()
	await process_frame
	quit()
