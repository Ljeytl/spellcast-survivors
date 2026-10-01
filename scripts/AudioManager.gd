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
const MAX_POOL_SIZE_PER_TYPE = 3
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
	SPELL_LIGHTNING,
	SPELL_METEOR_SHOWER,
	SPELL_METEOR,
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
	ELITE_SPAWN,
	
	# Typing sounds
	TYPING_KEYSTROKE,
	TYPING_BACKSPACE,
	TYPING_COMPLETE,
	TYPING_ERROR,
	
	# Environment
	MUSIC_GAMEPLAY,
	MUSIC_MENU,
	ENEMY_HIT,
	MEGA_CHARGE,
	MEGA_RELEASE
}

# Audio pools - grouped by type for performance
var audio_pools: Dictionary = {}
var active_audio_players: Array[AudioStreamPlayer] = []
var audio_resources: Dictionary = {}
var last_played_ms: Dictionary = {}
const PLACEHOLDER_MUSIC_ENABLED = false

# Current music player
var current_music_player: AudioStreamPlayer
var is_music_playing: bool = false
var quitting = false

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0  # Temporarily set to max volume for debugging

func _ready():
	# Make AudioManager process independently from Engine.time_scale
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	
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
	audio_resources.clear()
	audio_resources[SoundType.SPELL_BOLT] = ["res://audio/tactile/blade_01.wav", "res://audio/tactile/blade_02.wav"]
	audio_resources[SoundType.SPELL_MANA_BOLT] = ["res://audio/tactile/blade_01.wav", "res://audio/tactile/blade_02.wav"]
	audio_resources[SoundType.SPELL_LIFE] = ["res://audio/tactile/spell_02.wav"]
	audio_resources[SoundType.SPELL_ICE_BLAST] = ["res://audio/tactile/stones_02.wav", "res://audio/tactile/stones_03.wav"]
	audio_resources[SoundType.SPELL_EARTHSHIELD] = ["res://audio/tactile/stones_01.wav"]
	audio_resources[SoundType.SPELL_LIGHTNING_ARC] = ["res://audio/tactile/spell_01.wav"]
	audio_resources[SoundType.SPELL_LIGHTNING] = ["res://audio/tactile/spell_01.wav"]
	audio_resources[SoundType.SPELL_METEOR_SHOWER] = ["res://audio/tactile/spell_fire_07.wav"]
	audio_resources[SoundType.SPELL_METEOR] = ["res://audio/tactile/spell_fire_07.wav"]
	audio_resources[SoundType.SPELL_IMPACT_FIRE] = ["res://audio/tactile/spell_fire_01.wav", "res://audio/tactile/spell_fire_04.wav"]
	audio_resources[SoundType.SPELL_IMPACT_ICE] = ["res://audio/tactile/stones_02.wav"]
	audio_resources[SoundType.SPELL_IMPACT_LIGHTNING] = ["res://audio/tactile/spell_01.wav"]
	audio_resources[SoundType.SPELL_IMPACT_EARTH] = ["res://audio/tactile/stones_01.wav"]
	audio_resources[SoundType.SPELL_CHARGING] = ["res://audio/tactile/book_01.wav"]
	audio_resources[SoundType.MEGA_CHARGE] = ["res://audio/tactile/spell_02.wav"]
	audio_resources[SoundType.MEGA_RELEASE] = ["res://audio/tactile/spell_fire_07.wav", "res://audio/tactile/stones_03.wav"]
	audio_resources[SoundType.UI_BUTTON_CLICK] = ["res://audio/tactile/item_stone_01.wav"]
	audio_resources[SoundType.UI_BUTTON_HOVER] = ["res://audio/tactile/book_02.wav"]
	audio_resources[SoundType.UI_MENU_OPEN] = ["res://audio/tactile/book_01.wav"]
	audio_resources[SoundType.UI_MENU_CLOSE] = ["res://audio/tactile/book_02.wav"]
	audio_resources[SoundType.UI_LEVEL_SELECT] = ["res://audio/tactile/item_gem_03.wav"]
	audio_resources[SoundType.ENEMY_DEATH] = ["res://audio/tactile/creature_slime_02.wav", "res://audio/tactile/creature_slime_03.wav"]
	audio_resources[SoundType.ENEMY_HIT] = ["res://audio/tactile/creature_slime_01.wav"]
	audio_resources[SoundType.XP_COLLECT] = ["res://audio/tactile/item_gem_01.wav", "res://audio/tactile/item_gem_02.wav"]
	audio_resources[SoundType.LEVEL_UP] = ["res://audio/tactile/item_gem_03.wav"]
	audio_resources[SoundType.DAMAGE_TAKEN] = ["res://audio/tactile/creature_hurt_01.wav"]
	audio_resources[SoundType.CHEST_OPEN] = ["res://audio/tactile/lock_01.wav"]
	audio_resources[SoundType.PICKUP_ITEM] = ["res://audio/tactile/item_gem_02.wav"]
	audio_resources[SoundType.ELITE_SPAWN] = ["res://audio/tactile/stones_01.wav"]
	audio_resources[SoundType.TYPING_KEYSTROKE] = ["res://audio/tactile/item_stone_01.wav", "res://audio/tactile/item_stone_02.wav"]
	audio_resources[SoundType.TYPING_BACKSPACE] = ["res://audio/tactile/stones_03.wav"]
	audio_resources[SoundType.TYPING_COMPLETE] = ["res://audio/tactile/book_01.wav"]
	audio_resources[SoundType.TYPING_ERROR] = ["res://audio/tactile/wood_01.wav"]

func setup_music_player():
	"""Setup dedicated music player"""
	current_music_player = AudioStreamPlayer.new()
	current_music_player.bus = MUSIC_BUS
	current_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(current_music_player)

# PUBLIC API FUNCTIONS

func sound_profile(sound_type: SoundType) -> Dictionary:
	match sound_type:
		SoundType.ENEMY_HIT: return {"gain": 0.20, "interval": 100}
		SoundType.ENEMY_DEATH: return {"gain": 0.30, "interval": 100}
		SoundType.XP_COLLECT: return {"gain": 0.22, "interval": 90}
		SoundType.SPELL_MANA_BOLT: return {"gain": 0.20, "interval": 110}
		SoundType.TYPING_KEYSTROKE: return {"gain": 0.20, "interval": 35}
		SoundType.UI_BUTTON_HOVER: return {"gain": 0.12, "interval": 100}
		SoundType.DAMAGE_TAKEN: return {"gain": 0.55, "interval": 100}
		SoundType.LEVEL_UP, SoundType.CHEST_OPEN: return {"gain": 0.55, "interval": 150}
		SoundType.MEGA_CHARGE: return {"gain": 0.50, "interval": 40}
		SoundType.MEGA_RELEASE: return {"gain": 0.75, "interval": 40}
		_: return {"gain": 0.40, "interval": 60}

func is_priority_sound(sound_type: SoundType) -> bool:
	return sound_type in [SoundType.DAMAGE_TAKEN, SoundType.LEVEL_UP, SoundType.CHEST_OPEN, SoundType.UI_BUTTON_CLICK, SoundType.TYPING_ERROR, SoundType.MEGA_CHARGE, SoundType.MEGA_RELEASE]

func play_sound(sound_type: SoundType, volume_override: float = -1.0, pitch_override: float = -1.0):
	if quitting:
		return
	var profile = sound_profile(sound_type)
	var now = Time.get_ticks_msec()
	if now - int(last_played_ms.get(sound_type, -100000)) < int(profile.interval):
		return
	var audio_files = audio_resources.get(sound_type, [])
	if audio_files.is_empty():
		return
	active_audio_players = active_audio_players.filter(func(voice): return is_instance_valid(voice) and voice.playing)
	if active_audio_players.size() >= MAX_CONCURRENT_SOUNDS:
		if not is_priority_sound(sound_type):
			return
		var victim = active_audio_players.filter(func(voice): return not voice.get_meta("priority", false))
		if victim.is_empty():
			return
		victim[0].stop()
		active_audio_players.erase(victim[0])
	var player = get_available_player(sound_type)
	if not player:
		return
	var stream = load_audio_file(audio_files.pick_random())
	if not stream:
		return
	active_audio_players.erase(player)
	player.stream = stream
	player.bus = get_bus_for_sound_type(sound_type)
	var gain = float(profile.gain) * (volume_override if volume_override >= 0 else randf_range(0.94, 1.0))
	player.volume_db = linear_to_db(clampf(gain, 0.001, 1.0))
	player.pitch_scale = clampf(pitch_override if pitch_override >= 0 else randf_range(0.96, 1.04), 0.75, 1.25)
	player.set_meta("priority", is_priority_sound(sound_type))
	player.play()
	active_audio_players.append(player)
	last_played_ms[sound_type] = now
	audio_event_triggered.emit(str(sound_type))

func play_music(music_type: SoundType, loop: bool = true, fade_in_duration: float = 0.0):
	if not PLACEHOLDER_MUSIC_ENABLED or quitting:
		return
	var paths = audio_resources.get(music_type, [])
	if paths.is_empty():
		return
	current_music_player.stop()
	current_music_player.stream = load_audio_file(paths[0])
	current_music_player.bus = MUSIC_BUS
	current_music_player.play()
	is_music_playing = true

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
	

# SPELL-SPECIFIC FUNCTIONS

func spell_sound_type(spell_name: String) -> SoundType:
	match spell_name.to_lower().replace(" ", "_"):
		"mana_bolt": return SoundType.SPELL_MANA_BOLT
		"life", "regeneration", "life_bolt", "soul_bloom": return SoundType.SPELL_LIFE
		"ice_blast", "frost_sigil": return SoundType.SPELL_ICE_BLAST
		"earth_shield", "earthshield", "rune_trap": return SoundType.SPELL_EARTHSHIELD
		"lightning_arc", "lightning", "lightning_bolt", "focus_ray", "prism_ray": return SoundType.SPELL_LIGHTNING
		"meteor_shower", "meteor_lance": return SoundType.SPELL_METEOR
		"ember_lance", "ember_trail", "firewalk", "cinder_field", "steam_field": return SoundType.SPELL_IMPACT_FIRE
		"plague_seed", "seeking_spirit", "seeker", "arcane_orbit": return SoundType.SPELL_LIFE
		_: return SoundType.SPELL_BOLT

func play_spell_sound(spell_name: String, _level: int = 1):
	play_sound(spell_sound_type(spell_name))

func play_spell_impact_sound(spell_name: String, level: int = 1):
	"""Play impact sound when spells hit enemies"""
	var volume_variation = 0.8 + min(level - 1, 4) * 0.1  # Slightly quieter but still level-based
	var pitch_variation = 0.9 + randf() * 0.3  # More random pitch for impacts
	
	match spell_name.to_lower():
		"bolt", "mana_bolt":
			play_sound(SoundType.SPELL_IMPACT_FIRE, volume_variation, pitch_variation)
		"ice blast":
			play_sound(SoundType.SPELL_IMPACT_ICE, volume_variation, max(0.7, pitch_variation - 0.2))
		"lightning arc", "lightning":
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
	if ResourceLoader.exists(file_path):
		return load(file_path) as AudioStream
	push_error("Missing audio asset: " + file_path)
	return null

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

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

func request_quit():
	if quitting:
		return
	quitting = true
	get_tree().paused = true
	for tween in get_tree().get_processed_tweens():
		tween.kill()
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	current_music_player = null
	is_music_playing = false
	active_audio_players.clear()
	audio_pools.clear()
	audio_resources.clear()
	await get_tree().create_timer(0.25, true, false, true).timeout
	get_tree().quit()
