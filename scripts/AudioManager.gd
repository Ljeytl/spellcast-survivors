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
	
	# Spell impact sounds
	SPELL_IMPACT_FIRE,
	SPELL_IMPACT_ICE,
	SPELL_IMPACT_LIGHTNING,
	SPELL_IMPACT_EARTH,
	SPELL_CHARGING,
	
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
var music_volume: float = 1.0  # Temporarily set to max volume for debugging

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
	print("DEBUG: Setting up audio buses...")
	
	# Ensure all required buses exist
	var master_idx = AudioServer.get_bus_index(MASTER_BUS)
	if master_idx == -1:
		print("WARNING: Master bus not found")
		return
	else:
		print("DEBUG: Master bus found at index: ", master_idx)
	
	# Check if SFX bus exists, create if needed
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_idx == -1:
		print("Creating SFX bus...")
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, SFX_BUS)
		AudioServer.set_bus_send(1, MASTER_BUS)
		sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	
	# Check if Music bus exists, create if needed  
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx == -1:
		print("Creating Music bus...")
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, MUSIC_BUS)
		AudioServer.set_bus_send(2, MASTER_BUS)
		music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	
	# Set initial volumes
	set_master_volume(master_volume)
	set_sfx_volume(sfx_volume)
	set_music_volume(music_volume)
	
	print("DEBUG: Audio buses setup complete")

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
	
	# Spell sounds - using generated WAV files with more variations
	audio_resources[SoundType.SPELL_BOLT] = [SFX_PATH + "spell_bolt_1.wav", SFX_PATH + "spell_bolt_2.wav"]
	audio_resources[SoundType.SPELL_LIFE] = [SFX_PATH + "spell_life_1.wav", SFX_PATH + "spell_life_2.wav"]
	audio_resources[SoundType.SPELL_ICE_BLAST] = [SFX_PATH + "spell_ice_blast_1.wav", SFX_PATH + "spell_ice_blast_2.wav"]
	audio_resources[SoundType.SPELL_EARTHSHIELD] = [SFX_PATH + "spell_earthshield_1.wav", SFX_PATH + "spell_earthshield_2.wav"]
	audio_resources[SoundType.SPELL_LIGHTNING_ARC] = [SFX_PATH + "spell_lightning_arc_1.wav", SFX_PATH + "spell_lightning_arc_2.wav"]
	audio_resources[SoundType.SPELL_METEOR_SHOWER] = [SFX_PATH + "spell_meteor_shower_1.wav", SFX_PATH + "spell_meteor_shower_2.wav"]
	audio_resources[SoundType.SPELL_MANA_BOLT] = [SFX_PATH + "spell_mana_bolt_1.wav", SFX_PATH + "spell_mana_bolt_2.wav"]
	
	# Spell impact and charging sounds (reuse existing sounds with different processing)
	audio_resources[SoundType.SPELL_IMPACT_FIRE] = [SFX_PATH + "spell_bolt_1.wav", SFX_PATH + "spell_meteor_shower_1.wav"]
	audio_resources[SoundType.SPELL_IMPACT_ICE] = [SFX_PATH + "spell_ice_blast_1.wav", SFX_PATH + "spell_ice_blast_2.wav"]
	audio_resources[SoundType.SPELL_IMPACT_LIGHTNING] = [SFX_PATH + "spell_lightning_arc_1.wav", SFX_PATH + "spell_lightning_arc_2.wav"]
	audio_resources[SoundType.SPELL_IMPACT_EARTH] = [SFX_PATH + "spell_earthshield_1.wav", SFX_PATH + "spell_earthshield_2.wav"]
	audio_resources[SoundType.SPELL_CHARGING] = [SFX_PATH + "spell_life_1.wav"]  # Soft charging sound
	
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
	current_music_player.bus = SFX_BUS  # Use working SFX bus
	current_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(current_music_player)

# PUBLIC API FUNCTIONS

func play_sound(sound_type: SoundType, volume_override: float = -1.0, pitch_override: float = -1.0):
	"""Play a sound effect with optional volume and pitch override"""
	if active_audio_players.size() >= MAX_CONCURRENT_SOUNDS:
		# Limit concurrent sounds to prevent audio overload
		return
	
	var player = get_available_player(sound_type)
	if not player:
		return
	
	var audio_files = audio_resources.get(sound_type, [])
	if audio_files.is_empty():
		return
	
	# Pick random variation
	var audio_file = audio_files[randi() % audio_files.size()]
	var audio_stream = load_audio_file(audio_file)
	
	if not audio_stream:
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
	player.play()
	active_audio_players.append(player)
	
	# Emit signal for debugging/analytics
	audio_event_triggered.emit(str(sound_type))

func play_music(music_type: SoundType, loop: bool = true, fade_in_duration: float = 0.0):
	"""Play background music using the same system as SFX"""
	# Just use the regular SFX system for music
	play_sound(music_type, 1.0, 1.0)  # Full volume, normal pitch

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

func play_spell_sound(spell_name: String, level: int = 1):
	"""Play sound for a specific spell by name with level-based variations"""
	var pitch_variation = 1.0 + (level - 1) * 0.05  # Higher levels sound slightly higher pitched
	var volume_variation = 1.0 + min(level - 1, 5) * 0.1  # Higher levels slightly louder (cap at level 6)
	
	match spell_name.to_lower():
		"bolt":
			play_sound(SoundType.SPELL_BOLT, volume_variation, pitch_variation)
		"life":
			# Life spell gets softer, more ethereal sound at higher levels
			play_sound(SoundType.SPELL_LIFE, volume_variation, max(0.8, 1.0 - (level - 1) * 0.03))
		"ice blast":
			# Ice blast gets deeper/more menacing at higher levels
			play_sound(SoundType.SPELL_ICE_BLAST, volume_variation, max(0.7, 1.0 - (level - 1) * 0.04))
		"earth shield":
			# Earth shield gets more resonant at higher levels
			play_sound(SoundType.SPELL_EARTHSHIELD, volume_variation, max(0.8, 1.0 - (level - 1) * 0.02))
		"lightning arc":
			# Lightning gets more crackling/higher pitched at higher levels
			play_sound(SoundType.SPELL_LIGHTNING_ARC, volume_variation, min(1.3, 1.0 + (level - 1) * 0.06))
		"meteor shower":
			# Meteor shower gets more dramatic at higher levels
			play_sound(SoundType.SPELL_METEOR_SHOWER, volume_variation, max(0.9, 1.0 - (level - 1) * 0.01))
		"mana_bolt":
			play_sound(SoundType.SPELL_MANA_BOLT, volume_variation, pitch_variation)
		_:
			print("Unknown spell sound: ", spell_name)

func play_spell_impact_sound(spell_name: String, level: int = 1):
	"""Play impact sound when spells hit enemies"""
	var volume_variation = 0.8 + min(level - 1, 4) * 0.1  # Slightly quieter but still level-based
	var pitch_variation = 0.9 + randf() * 0.3  # More random pitch for impacts
	
	match spell_name.to_lower():
		"bolt", "mana_bolt":
			play_sound(SoundType.SPELL_IMPACT_FIRE, volume_variation, pitch_variation)
		"ice blast":
			play_sound(SoundType.SPELL_IMPACT_ICE, volume_variation, max(0.7, pitch_variation - 0.2))
		"lightning arc":
			play_sound(SoundType.SPELL_IMPACT_LIGHTNING, volume_variation, min(1.4, pitch_variation + 0.3))
		"earth shield":
			play_sound(SoundType.SPELL_IMPACT_EARTH, volume_variation, max(0.6, pitch_variation - 0.3))
		"meteor shower":
			play_sound(SoundType.SPELL_IMPACT_FIRE, volume_variation * 1.2, max(0.8, pitch_variation - 0.1))
		"life":
			# Life spell doesn't have impact sound (it's healing)
			pass

func play_spell_charging_sound():
	"""Play charging sound when player starts typing a spell"""
	play_sound(SoundType.SPELL_CHARGING, 0.6, 1.1)

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
	print("DEBUG: Attempting to load audio file: ", file_path)
	
	# Try to load the actual file first
	if ResourceLoader.exists(file_path):
		var stream = load(file_path)
		if stream:
			return stream
		else:
			print("ERROR: Failed to load existing audio file: ", file_path)
	else:
		print("ERROR: Audio file does not exist: ", file_path)
	
	# If file doesn't exist, generate a simple procedural sound
	return generate_procedural_audio(file_path)

func generate_procedural_audio(file_path: String) -> AudioStream:
	"""Generate simple procedural audio as fallback"""
	print("WARNING: Audio file not found, generating procedural audio for: ", file_path)
	
	# For music, create a longer stream or return null to avoid short audio
	if "music" in file_path:
		print("ERROR: Music file missing! Cannot generate procedural music.")
		return null
	
	# Create a simple sine wave audio stream for SFX only
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 0.1  # 100ms samples
	
	return audio_stream

func _on_audio_finished(player: AudioStreamPlayer):
	"""Handle audio player finishing playback"""
	active_audio_players.erase(player)

func _on_music_finished():
	"""Handle music player finishing playback"""
	is_music_playing = false
	
	# Try to restart the music regardless of loop mode since looping isn't working
	if current_music_player and current_music_player.stream:
		current_music_player.play()
		is_music_playing = true

# CONVENIENCE FUNCTIONS FOR COMMON GAME EVENTS

func on_enemy_death():
	play_sound(SoundType.ENEMY_DEATH)

func on_xp_collected():
	play_sound(SoundType.XP_COLLECT)

func on_level_up():
	play_sound(SoundType.LEVEL_UP)

func on_damage_taken():
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
