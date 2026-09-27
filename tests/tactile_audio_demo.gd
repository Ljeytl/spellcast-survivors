extends SceneTree

var game
var audio
var events = []

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Audio Test"):
		quit(2)
		return
	run.call_deferred()

func enemy(offset: Vector2):
	var actor = load("res://scenes/Enemy.tscn").instantiate()
	game.add_child(actor)
	actor.position = game.player.position + offset
	actor.set_physics_process(false)
	actor.current_health = 400
	actor.max_health = 400
	return actor

func run():
	audio = root.get_node("AudioManager")
	audio.audio_event_triggered.connect(func(event): events.append({"ms": Time.get_ticks_msec(), "type": event}))
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.spell_manager.learn_spell("seeking_spirit")
	var record = AudioEffectRecord.new()
	record.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, record)
	record.set_recording_active(true)
	var target = enemy(Vector2(200, 0))
	await create_timer(0.5).timeout
	game.spell_manager.cast_spell_by_type(1)
	await create_timer(1.0).timeout
	game.spell_manager.fire_mana_bolt()
	await create_timer(1.0).timeout
	game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("seeking_spirit"))
	await create_timer(1.5).timeout
	if is_instance_valid(target):
		target.take_damage(10000)
	await create_timer(0.5).timeout
	for orb in get_nodes_in_group("xp_orbs"):
		orb.collect_xp()
	await create_timer(0.5).timeout
	game.player.take_damage(1)
	await create_timer(1.0).timeout
	audio.on_chest_open()
	await create_timer(1.5).timeout
	record.set_recording_active(false)
	var recording = record.get_recording()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/audio-evidence"))
	var error = recording.save_to_wav("res://builds/audio-evidence/gameplay-audio.wav")
	var log = FileAccess.open("res://builds/audio-evidence/events.json", FileAccess.WRITE)
	log.store_string(JSON.stringify(events, "\t"))
	print("AUDIO DEMO: ", recording.get_length(), " seconds, ", events.size(), " actual audio events; save=", error)
	quit(0 if error == OK and recording.get_length() > 5 and events.size() > 5 else 1)
