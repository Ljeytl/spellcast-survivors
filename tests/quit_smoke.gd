extends SceneTree

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func run():
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for i in range(8):
		await process_frame
	if "--window-close" in OS.get_cmdline_user_args():
		root.get_node("AudioManager").notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	else:
		menu._on_quit_button_pressed()
	var audio = root.get_node("AudioManager")
	assert(audio.quitting and paused)
	assert(audio.active_audio_players.is_empty())
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			assert(not child.playing and child.stream == null)
	audio.request_quit()
	print("Quit smoke: 3 invariants and every audio player checked")
