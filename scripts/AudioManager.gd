extends Node

# AudioManager handles all sound effects and music for SpellCast Survivors
# Features: Sound pooling, volume control, randomized audio, bus management

signal audio_event_triggered(event_name: String)

# Audio bus indices
const MASTER_BUS = "Master"
const SFX_BUS = "SFX"  
const MUSIC_BUS = "Music"

# Audio pool settings
const MAX_CONCURRENT_SOUNDS = 20
const MAX_POOL_SIZE_PER_TYPE = 10
const PITCH_VARIATION_RANGE = 0.15  # ±15% pitch variation
const VOLUME_VARIATION_RANGE = 0.1  # ±10% volume variation
const FADE_START_VOLUME = 0.01  # Starting volume for fade-in
const MUTED_VOLUME_DB = -80.0  # Volume for muted audio

# Audio file paths
const AUDIO_PATH = "res://audio/"
const SFX_PATH = AUDIO_PATH + "sfx/"
const MUSIC_PATH = AUDIO_PATH + "music/"

# Sound categories
enum SoundType {
	# Spell sounds
	SPELL_BOLT,
	SPELL_LIFE,
	SPELL_ICE_BLAST,
	SPELL_EARTHSHIELD,
	SPELL_LIGHTNING_ARC,
	SPELL_METEOR_SHOWER,
	SPELL_MANA_BOLT,
	
	# UI sounds
	UI_BUTTON_CLICK,
	UI_BUTTON_HOVER,
	UI_MENU_OPEN,
	UI_MENU_CLOSE,
	UI_LEVEL_SELECT,
	
	# Game sounds
	ENEMY_DEATH,
	XP_COLLECT,
	LEVEL_UP,
	DAMAGE_TAKEN,
	CHEST_OPEN,
	PICKUP_ITEM,
	
	# Typing sounds
	TYPING_KEYSTROKE,
	TYPING_BACKSPACE,
	TYPING_COMPLETE,
	TYPING_ERROR,
	
	# Environment
	MUSIC_GAMEPLAY,
	MUSIC_MENU
}

# Audio pools - grouped by type for performance
var audio_pools: Dictionary = {}
var active_audio_players: Array[AudioStreamPlayer] = []
var audio_resources: Dictionary = {}

# Current music player
var current_music_player: AudioStreamPlayer
var is_music_playing: bool = false

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.7

func _ready():
	# Make AudioManager process independently from Engine.time_scale
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Add to audio group for easy access
	add_to_group("audio_manager")
	
	# Setup audio buses
	setup_audio_buses()
	
	# Initialize audio pools
	initialize_audio_pools()
	
	# Load audio resources
	load_audio_resources()
	
	# Setup music player
	setup_music_player()
	
	print("AudioManager initialized with ", audio_resources.size(), " audio resources")

func setup_audio_buses():
	"""Configure the audio bus system"""
	# Ensure all required buses exist
	var master_idx = AudioServer.get_bus_index(MASTER_BUS)
	if master_idx == -1:
		print("WARNING: Master bus not found")
		return
	
	# Check if SFX bus exists, create if needed
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_idx == -1:
		print("Creating SFX bus...")
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, SFX_BUS)
		AudioServer.set_bus_send(1, MASTER_BUS)
	
	# Check if Music bus exists, create if needed  
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx == -1:
		print("Creating Music bus...")
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, MUSIC_BUS)
		AudioServer.set_bus_send(2, MASTER_BUS)
	
	# Set initial volumes
	set_master_volume(master_volume)
	set_sfx_volume(sfx_volume)
	set_music_volume(music_volume)

func initialize_audio_pools():
	"""Create audio player pools for each sound type"""
	for sound_type in SoundType.values():
		audio_pools[sound_type] = []
		
		# Create initial pool of AudioStreamPlayers
		for i in range(MAX_POOL_SIZE_PER_TYPE):
			var player = AudioStreamPlayer.new()
			# Make each audio player process independently from Engine.time_scale
			player.process_mode = Node.PROCESS_MODE_ALWAYS
			player.finished.connect(_on_audio_finished.bind(player))
			add_child(player)
			audio_pools[sound_type].append(player)

func load_audio_resources():
	"""Load all audio files into memory for quick access"""
	# NOTE: For a complete implementation, you would load actual audio files
	# For now, we'll create placeholder entries that can be replaced with real audio
	
	# Spell sounds - using generated WAV files
	audio_resources[SoundType.SPELL_BOLT] = [SFX_PATH + "spell_bolt_1.wav", SFX_PATH + "spell_bolt_2.wav"]
	audio_resources[SoundType.SPELL_LIFE] = [SFX_PATH + "spell_life_1.wav", SFX_PATH + "spell_life_2.wav"]
	audio_resources[SoundType.SPELL_ICE_BLAST] = [SFX_PATH + "spell_ice_blast_1.wav", SFX_PATH + "spell_ice_blast_2.wav"]
	audio_resources[SoundType.SPELL_EARTHSHIELD] = [SFX_PATH + "spell_earthshield_1.wav", SFX_PATH + "spell_earthshield_2.wav"]
	audio_resources[SoundType.SPELL_LIGHTNING_ARC] = [SFX_PATH + "spell_lightning_arc_1.wav", SFX_PATH + "spell_lightning_arc_2.wav"]
	audio_resources[SoundType.SPELL_METEOR_SHOWER] = [SFX_PATH + "spell_meteor_shower_1.wav", SFX_PATH + "spell_meteor_shower_2.wav"]
	audio_resources[SoundType.SPELL_MANA_BOLT] = [SFX_PATH + "spell_mana_bolt_1.wav", SFX_PATH + "spell_mana_bolt_2.wav"]
	
	# UI sounds
	audio_resources[SoundType.UI_BUTTON_CLICK] = [SFX_PATH + "ui_button_click_1.wav", SFX_PATH + "ui_button_click_2.wav"]
	audio_resources[SoundType.UI_BUTTON_HOVER] = [SFX_PATH + "ui_button_hover.wav"]
	audio_resources[SoundType.UI_MENU_OPEN] = [SFX_PATH + "ui_menu_open.wav"]
	audio_resources[SoundType.UI_MENU_CLOSE] = [SFX_PATH + "ui_menu_close.wav"]
	audio_resources[SoundType.UI_LEVEL_SELECT] = [SFX_PATH + "ui_level_select.wav"]
	
	# Game sounds
	audio_resources[SoundType.ENEMY_DEATH] = [SFX_PATH + "enemy_death_1.wav", SFX_PATH + "enemy_death_2.wav", SFX_PATH + "enemy_death_3.wav"]
	audio_resources[SoundType.XP_COLLECT] = [SFX_PATH + "xp_collect_1.wav", SFX_PATH + "xp_collect_2.wav"]
	audio_resources[SoundType.LEVEL_UP] = [SFX_PATH + "level_up.wav"]
	audio_resources[SoundType.DAMAGE_TAKEN] = [SFX_PATH + "damage_taken_1.wav", SFX_PATH + "damage_taken_2.wav"]
	audio_resources[SoundType.CHEST_OPEN] = [SFX_PATH + "chest_open.wav"]
	audio_resources[SoundType.PICKUP_ITEM] = [SFX_PATH + "pickup_item.wav"]
	
	# Typing sounds
	audio_resources[SoundType.TYPING_KEYSTROKE] = [SFX_PATH + "typing_keystroke_1.wav", SFX_PATH + "typing_keystroke_2.wav", SFX_PATH + "typing_keystroke_3.wav"]
	audio_resources[SoundType.TYPING_BACKSPACE] = [SFX_PATH + "typing_backspace.wav"]
	audio_resources[SoundType.TYPING_COMPLETE] = [SFX_PATH + "typing_complete.wav"]
	audio_resources[SoundType.TYPING_ERROR] = [SFX_PATH + "typing_error.wav"]
	
	# Music
	audio_resources[SoundType.MUSIC_GAMEPLAY] = [MUSIC_PATH + "gameplay_music.wav"]
	audio_resources[SoundType.MUSIC_MENU] = [MUSIC_PATH + "menu_music.wav"]

func setup_music_player():
	"""Setup dedicated music player"""
	current_music_player = AudioStreamPlayer.new()
	current_music_player.bus = MUSIC_BUS
	# Make music player process independently from Engine.time_scale
	current_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(current_music_player)

# PUBLIC API FUNCTIONS

func play_sound(sound_type: SoundType, volume_override: float = -1.0, pitch_override: float = -1.0):
	"""Play a sound effect with optional volume and pitch override"""
	print("DEBUG: play_sound called with type: ", sound_type, " (", SoundType.keys()[sound_type], ")")
	
	if active_audio_players.size() >= MAX_CONCURRENT_SOUNDS:
		# Limit concurrent sounds to prevent audio overload
		print("DEBUG: Max concurrent sounds reached (", active_audio_players.size(), ")")
		return
	
	var player = get_available_player(sound_type)
	if not player:
		print("DEBUG: No available audio player for sound type: ", sound_type)
		return
	
	var audio_files = audio_resources.get(sound_type, [])
	if audio_files.is_empty():
		print("DEBUG: No audio files found for sound type: ", sound_type)
		return
	
	# Pick random variation
	var audio_file = audio_files[randi() % audio_files.size()]
	print("DEBUG: Selected audio file: ", audio_file)
	var audio_stream = load_audio_file(audio_file)
	
	if not audio_stream:
		print("DEBUG: Failed to load audio file: ", audio_file)
		return
	
	# Configure player
	player.stream = audio_stream
	player.bus = get_bus_for_sound_type(sound_type)
	
	# Apply volume (with optional randomization)
	var final_volume = volume_override if volume_override >= 0 else 1.0
	if volume_override < 0:
		final_volume += randf_range(-VOLUME_VARIATION_RANGE, VOLUME_VARIATION_RANGE)
	player.volume_db = linear_to_db(clamp(final_volume, 0.1, 1.0))
	
	# Apply pitch (with optional randomization)
	var final_pitch = pitch_override if pitch_override >= 0 else 1.0
	if pitch_override < 0:
		final_pitch += randf_range(-PITCH_VARIATION_RANGE, PITCH_VARIATION_RANGE)
	player.pitch_scale = clamp(final_pitch, 0.5, 2.0)
	
	# Play sound
	print("DEBUG: Playing audio file: ", audio_file, " with volume: ", player.volume_db, " pitch: ", player.pitch_scale)
	player.play()
	active_audio_players.append(player)
	
	# Emit signal for debugging/analytics
	audio_event_triggered.emit(str(sound_type))

func play_music(music_type: SoundType, loop: bool = true, fade_in_duration: float = 0.0):
	"""Play background music with optional fade-in"""
	if not current_music_player:
		return
	
	var audio_files = audio_resources.get(music_type, [])
	if audio_files.is_empty():
		return
	
	var audio_file = audio_files[0]  # Use first music file
	var audio_stream = load_audio_file(audio_file)
	
	if not audio_stream:
		return
	
	# Stop current music
	if is_music_playing:
		current_music_player.stop()
	
	# Setup new music
	current_music_player.stream = audio_stream
	
	# Enable looping if the stream supports it
	if audio_stream.has_method("set_loop"):
		audio_stream.set_loop(loop)
	elif audio_stream.has_method("loop"):
		audio_stream.loop = loop
	
	# Play music
	current_music_player.play()
	is_music_playing = true
	
	# Handle fade-in
	if fade_in_duration > 0:
		current_music_player.volume_db = linear_to_db(FADE_START_VOLUME)
		var tween = create_tween()
		tween.tween_method(
			func(vol): current_music_player.volume_db = linear_to_db(vol * music_volume),
			FADE_START_VOLUME, 1.0, fade_in_duration
		)

func stop_music(fade_out_duration: float = 0.0):
	"""Stop background music with optional fade-out"""
	if not current_music_player or not is_music_playing:
		return
	
	if fade_out_duration > 0:
		var tween = create_tween()
		tween.tween_method(
			func(vol): current_music_player.volume_db = linear_to_db(vol),
			music_volume, 0.01, fade_out_duration
		)
		tween.tween_callback(func(): 
			current_music_player.stop()
			is_music_playing = false
		)
	else:
		current_music_player.stop()
		is_music_playing = false

# VOLUME CONTROL FUNCTIONS

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(master_volume) if master_volume > 0 else -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), db)

func set_sfx_volume(volume: float):
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(sfx_volume) if sfx_volume > 0 else -80
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, db)

func set_music_volume(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(music_volume) if music_volume > 0 else -80
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, db)
	
	# Update current music player volume if playing
	if current_music_player and is_music_playing:
		current_music_player.volume_db = db

# SPELL-SPECIFIC FUNCTIONS

func play_spell_sound(spell_name: String):
	"""Play sound for a specific spell by name"""
	match spell_name.to_lower():
		"bolt":
			play_sound(SoundType.SPELL_BOLT)
		"life":
			play_sound(SoundType.SPELL_LIFE)
		"ice blast":
			play_sound(SoundType.SPELL_ICE_BLAST)
		"earth shield":
			play_sound(SoundType.SPELL_EARTHSHIELD)
		"lightning arc":
			play_sound(SoundType.SPELL_LIGHTNING_ARC)
		"meteor shower":
			play_sound(SoundType.SPELL_METEOR_SHOWER)
		"mana_bolt":
			play_sound(SoundType.SPELL_MANA_BOLT)
		_:
			print("Unknown spell sound: ", spell_name)

func play_typing_sound(character: String = ""):
	"""Play typing sound with variation based on character"""
	if character == "":
		play_sound(SoundType.TYPING_KEYSTROKE)
	elif character in [" ", "\t"]:
		# Different sound for space/tab
		play_sound(SoundType.TYPING_KEYSTROKE, 0.7, 0.8)
	else:
		# Regular keystroke
		play_sound(SoundType.TYPING_KEYSTROKE)

# HELPER FUNCTIONS

func get_available_player(sound_type: SoundType) -> AudioStreamPlayer:
	"""Get an available audio player from the pool"""
	var pool = audio_pools.get(sound_type, [])
	
	for player in pool:
		if not player.playing:
			return player
	
	# If no available players, return the first one (will interrupt current sound)
	if pool.size() > 0:
		return pool[0]
	
	return null

func get_bus_for_sound_type(sound_type: SoundType) -> String:
	"""Determine which audio bus to use for a sound type"""
	match sound_type:
		SoundType.MUSIC_GAMEPLAY, SoundType.MUSIC_MENU:
			return MUSIC_BUS
		_:
			return SFX_BUS

func load_audio_file(file_path: String) -> AudioStream:
	"""Load an audio file, with fallback to procedural generation"""
	# Try to load the actual file first
	if ResourceLoader.exists(file_path):
		return load(file_path)
	
	# If file doesn't exist, generate a simple procedural sound
	return generate_procedural_audio(file_path)

func generate_procedural_audio(file_path: String) -> AudioStream:
	"""Generate simple procedural audio as fallback"""
	# Create a simple sine wave audio stream
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 0.1  # 100ms samples
	
	return audio_stream

func _on_audio_finished(player: AudioStreamPlayer):
	"""Handle audio player finishing playback"""
	active_audio_players.erase(player)

# CONVENIENCE FUNCTIONS FOR COMMON GAME EVENTS

func on_enemy_death():
	play_sound(SoundType.ENEMY_DEATH)

func on_xp_collected():
	play_sound(SoundType.XP_COLLECT)

func on_level_up():
	play_sound(SoundType.LEVEL_UP)

func on_damage_taken():
	print("DEBUG: AudioManager.on_damage_taken() called")
	play_sound(SoundType.DAMAGE_TAKEN)

func on_button_click():
	play_sound(SoundType.UI_BUTTON_CLICK)

func on_button_hover():
	play_sound(SoundType.UI_BUTTON_HOVER, 0.5)  # Quieter hover sound

func on_typing_complete():
	play_sound(SoundType.TYPING_COMPLETE)

func on_typing_error():
	play_sound(SoundType.TYPING_ERROR)

func on_chest_open():
	play_sound(SoundType.CHEST_OPEN)

# DEBUG FUNCTIONS

func get_audio_debug_info() -> Dictionary:
	"""Get debug information about audio system state"""
	return {
		"active_players": active_audio_players.size(),
		"max_concurrent": MAX_CONCURRENT_SOUNDS,
		"music_playing": is_music_playing,
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"total_audio_resources": audio_resources.size()
	}