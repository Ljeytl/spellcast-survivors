extends SceneTree

var checks = 0
var failures = 0
var heard: Array[String] = []
var audio
var game

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Audio Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, label: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func reset_audio():
	for voice in audio.active_audio_players:
		voice.stop()
	audio.active_audio_players.clear()
	audio.last_played_ms.clear()
	heard.clear()

func count_cue(kind: int) -> int:
	return heard.count(str(kind))

func run():
	audio = root.get_node("AudioManager")
	audio.audio_event_triggered.connect(func(event): heard.append(event))
	for kind in audio.audio_resources:
		for path in audio.audio_resources[kind]:
			check(path.begins_with("res://audio/tactile/"), "SFX uses replacement library: " + path)
			var stream = audio.load_audio_file(path)
			check(stream != null and stream.get_length() > 0, "Sample loads with duration: " + path)
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.player.set_physics_process(false)
	game.spell_manager.set_process(false)
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	reset_audio()
	check(not audio.is_music_playing, "Placeholder music does not autoplay")
	check(not game.spell_manager.cast_spell_by_type(99), "Locked spell rejected")
	check(heard.is_empty(), "Rejected cast emits no audio")
	check(game.spell_manager.cast_spell_by_type(1), "Direct Bolt cast succeeds")
	check(count_cue(audio.SoundType.SPELL_BOLT) == 1, "Direct cast emits one Bolt cue")
	reset_audio()
	game.spell_manager.spell_queue = [{"slot": 1, "name": "Bolt"}]
	check(game.spell_manager.cast_spell(), "Typed cast succeeds")
	check(count_cue(audio.SoundType.SPELL_BOLT) == 1, "Typed cast has no duplicate cue")
	reset_audio()
	game.spell_manager.learn_spell("infestation")
	check(not game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("infestation")), "Targetless plague fails")
	check(heard.is_empty(), "Failed targeted build spell remains silent")
	var enemy = load("res://scenes/Enemy.tscn").instantiate()
	game.add_child(enemy)
	enemy.position = game.player.position + Vector2(100, 0)
	enemy.set_physics_process(false)
	enemy.current_health = 1000
	enemy.max_health = 1000
	reset_audio()
	game.spell_manager.learn_spell("seeker")
	check(game.spell_manager.cast_spell_by_type(game.spell_manager.find_spell_slot("seeker")), "Build spell succeeds")
	check(count_cue(audio.SoundType.SPELL_LIFE) == 1, "Successful Seeker emits cue")
	reset_audio()
	check(game.spell_manager.cast_freeform_spell("bolt"), "Freeform owned cast succeeds")
	check(count_cue(audio.SoundType.SPELL_BOLT) == 1, "Freeform has one cue")
	reset_audio()
	game.spell_manager.fire_mana_bolt()
	check(count_cue(audio.SoundType.SPELL_MANA_BOLT) == 1, "Actual passive fire emits its cue")
	reset_audio()
	enemy.take_damage(0)
	check(heard.is_empty(), "Zero enemy damage is silent")
	enemy.take_damage(10)
	check(count_cue(audio.SoundType.ENEMY_HIT) == 1, "Actual enemy damage emits hit cue")
	for i in range(100):
		enemy.take_damage(1)
	check(count_cue(audio.SoundType.ENEMY_HIT) == 1, "Horde hit burst throttled")
	enemy.take_damage(10000)
	await process_frame
	check(count_cue(audio.SoundType.ENEMY_DEATH) == 1, "Actual enemy death emits death cue")
	reset_audio()
	var orb = load("res://scenes/XPOrb.tscn").instantiate()
	game.add_child(orb)
	orb.xp_value = 1
	orb.collect_xp()
	orb.collect_xp()
	check(count_cue(audio.SoundType.XP_COLLECT) == 1, "Real XP collection sounds once")
	reset_audio()
	game.player.take_damage(0)
	check(heard.is_empty(), "Zero player damage is silent")
	game.player.take_damage(1)
	check(count_cue(audio.SoundType.DAMAGE_TAKEN) == 1, "Actual player damage emits priority cue")
	reset_audio()
	game.player.do_level_up()
	check(count_cue(audio.SoundType.LEVEL_UP) == 1, "Player level-up and shown menu produce one cue")
	paused = false
	reset_audio()
	for kind in audio.audio_resources:
		if not audio.is_priority_sound(kind):
			audio.play_sound(kind)
	check(audio.active_audio_players.size() == audio.MAX_CONCURRENT_SOUNDS, "Stress setup reaches voice budget")
	audio.on_damage_taken()
	check(count_cue(audio.SoundType.DAMAGE_TAKEN) == 1, "Player damage survives saturated ambient voices")
	check(audio.active_audio_players.size() == audio.MAX_CONCURRENT_SOUNDS, "Priority eviction preserves budget")
	reset_audio()
	for i in range(12):
		audio.last_played_ms.clear()
		audio.play_sound(audio.SoundType.SPELL_BOLT)
	check(audio.active_audio_players.size() <= audio.MAX_POOL_SIZE_PER_TYPE, "Pool reuse never duplicates active voice")
	reset_audio()
	game.free()
	await process_frame
	print("TACTILE AUDIO: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
