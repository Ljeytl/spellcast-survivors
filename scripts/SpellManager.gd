extends Node

signal style_input_changed(text: String)
signal manual_spell_released(family: String, canonical: String, typed: String)
signal style_clock_advanced(seconds: float)

signal spell_queued(spell_name: String, slot: int)
signal spell_cast(spell_name: String)
signal spell_extended(spell_id: String, seconds: float)
signal typing_started
signal typing_ended
signal spell_locked_error(spell_name: String, required_level: int, current_level: int)

# Constants for spell system
const TIME_SCALE_DURING_TYPING = 0.2
const SPELL_DAMAGE_MULTIPLIER = 0.15
const MANA_BOLT_COOLDOWN = 1.5
const CHAIN_LIGHTNING_RANGE = 200.0
const CHAIN_DAMAGE_REDUCTION = 0.8
const PLAYER_TRANSPARENCY_TYPING = 1.0
const METEOR_DELAY_INTERVAL = 0.5
const METEOR_SPREAD_RANGE = 300.0
const AOE_RADIUS_METEOR = 100.0
const SLOW_EFFECT_STRENGTH = 0.5
const SLOW_EFFECT_DURATION = 3.0
const SPELL_CAST_COOLDOWN = 0.1  # Minimum time between spell casts

const CombinationScaling = preload("res://scripts/CombinationScaling.gd")
const Keywords = preload("res://scripts/KeywordRules.gd")
const MEGA_MULTIPLIER = Keywords.DEFINITIONS.mega.power
var pending_keyword_casts: Array[Dictionary] = []
var release_snapshot: Dictionary = {}
var release_style_receipt: Dictionary = {}
const SNAPSHOT_STATS = ["spell_damage_multiplier", "spell_size_multiplier", "spell_duration_multiplier", "projectile_speed_multiplier", "cast_speed_multiplier", "level"]
var cast_keyword_multiplier = 1.0

const Geometry = preload("res://scripts/SpellGeometry.gd")

const Targeting = preload("res://scripts/SpellTargeting.gd")

var spell_projectile_scene = preload("res://scenes/SpellProjectile.tscn")

const Synergies = preload("res://scripts/SynergyCatalog.gd")
@export_range(0.1, 30.0, 0.1) var typing_slowdown_capacity: float = 1.5
@export_range(0.1, 60.0, 0.1) var typing_slowdown_refill_seconds: float = 10.0
var typing_slowdown_remaining: float = 1.5
var _scale_change_frame: int = -1
var _scale_before_change: float = 1.0
var space_casting = false
var last_cast_failure: String = ""

const MAX_EQUIPPED_SPELLS = 6
## How many base spells learn_spell accepts. Training Grounds raises it to equip everything.
var slot_limit: int = MAX_EQUIPPED_SPELLS
const BASE_SPELL_IDS = ["bolt", "life", "regeneration", "ice_blast", "earth_shield", "lightning", "meteor_shower", "ember_spear", "infestation", "cinder_field", "arcane_orbit", "focus_ray", "rune_trap", "seeker", "firewalk", "cross_blade"]
var spell_catalog: Dictionary = {}
var evolved_ingredients: Dictionary = {}
var bonus_spells: Dictionary = {}
var acquired_spells: Dictionary = {"bolt": true}

var spell_queue: Array = []
var current_typing_text: String = ""
var is_typing: bool = false
var target_spell: String = ""
var casting_clock: float = 0.0
var last_spell_cast_time: float = -1.0

# Freeform casting system
var freeform_mode: bool = false

# Data-driven spell definitions loaded from DataManager
var spells = {}

# Freeform spell library loaded from DataManager
var freeform_spells: Dictionary = {}

# Magic Missile is the auto-attack spell
var mana_bolt_damage = 15.0
var mana_bolt_level = 1
var mana_bolt_cooldown = MANA_BOLT_COOLDOWN
var mana_bolt_timer = 0.0

# Player states
var active_healing_effects = []

# Visual effects
var spell_effects_scene = preload("res://scenes/SpellProjectile.tscn")
var aoe_effect_scene = preload("res://scenes/SpellProjectile.tscn")

@onready var game_manager = get_parent()
@onready var player = get_parent().get_node("Player")
@onready var player_sprite: Sprite2D = null

# Signals
signal healing_applied(amount: float)

func _ready():
	typing_slowdown_remaining = typing_slowdown_capacity
	# Clear any existing queue
	spell_queue.clear()
	
	# Load spell data from DataManager
	load_spells_from_data()
	rebuild_freeform_library()
	
	# Find player sprite for transparency effect
	if player:
		player_sprite = player.get_node("Sprite2D")
	
	# Connect to typing signals for player transparency
	typing_started.connect(_on_typing_started)
	typing_ended.connect(_on_typing_ended)

# Load spells from DataManager
func load_spells_from_data():
	spells.clear()
	bonus_spells.clear()
	acquired_spells = {"bolt": true}
	evolved_ingredients.clear()
	spell_catalog.clear()
	var data = DataManager.get_all_spells()
	for id in BASE_SPELL_IDS:
		if not data.has(id):
			continue
		var info = data[id].duplicate(true)
		info.id = id
		info.display_name = info.get("incantation", id.replace("_", " "))
		info.chars = info.display_name.length()
		info.level = 1
		info.damage = info.get("damage", 0)
		spell_catalog[id] = info
	spells[1] = spell_catalog.bolt.duplicate(true)

## Prepared spellbook for this run (see Preparation.gd). Empty means the legacy level-up learning flow.
var prepared_order: Array = []

## Starts a preparation run: the first prepared spell replaces Bolt in slot 1; the rest arrive by level.
func begin_prepared_run(order: Array):
	var starter = str(order[0]) if not order.is_empty() else ""
	if not spell_catalog.has(starter):
		return
	prepared_order = order.duplicate()
	spells.clear()
	acquired_spells = {starter: true}
	spells[1] = spell_catalog[starter].duplicate(true)
	rebuild_freeform_library()

func _process(delta):
	var frame_scale = _scale_before_change if _scale_change_frame == Engine.get_process_frames() else Engine.time_scale
	var unscaled_delta = delta / maxf(frame_scale, 0.01)
	casting_clock += unscaled_delta
	style_clock_advanced.emit(unscaled_delta)
	advance_typing_slowdown(unscaled_delta)
	advance_pending_casts(unscaled_delta)
	# Handle auto-attack Magic Missile
	handle_auto_attack(delta)
	
	# Process healing over time effects
	process_healing_effects(delta)

func _input(event):
	if event is InputEventKey and event.pressed:
		if is_typing and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
		handle_key_input(event)

func handle_key_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
	if space_casting:
		handle_freeform_typing_input(event)
		return
	if event.keycode == KEY_SPACE and not is_typing and not event.echo:
		if not pending_keyword_casts.is_empty() or casting_clock - last_spell_cast_time >= SPELL_CAST_COOLDOWN:
			space_casting = true
			start_freeform_typing()
		return
	# Handle freeform mode input
	if freeform_mode:
		handle_freeform_input(event)
		return
	
	# Handle normal slot-based input
	var key_code = event.keycode
	
	if key_code >= KEY_1 and key_code <= KEY_6:
		activate_spell_slot(key_code - KEY_0)
		return

	if is_typing:
		handle_typing_input(event)

func activate_spell_slot(slot: int) -> bool:
	if not game_manager or game_manager.current_state != game_manager.GameState.PLAYING or is_typing:
		return false
	if not is_spell_unlocked(slot):
		game_manager.show_gameplay_feedback("Empty slot · Learn a spell when you level up")
		return false
	if pending_keyword_casts.is_empty() and casting_clock - last_spell_cast_time < SPELL_CAST_COOLDOWN:
		game_manager.show_gameplay_feedback("Spell recovering · Try again in a moment")
		return false
	spell_queue.clear()
	queue_spell(slot)
	start_typing()
	return is_typing

func queue_spell(slot: int):
	if not is_spell_unlocked(slot):
		return
	var info = get_spell_info(slot)
	if not is_spell_unlocked(slot):
		spell_locked_error.emit(info.name, 0, player.level)
		return
	spell_queue.append({"slot": slot, "name": info.name, "display_name": info.display_name})
	spell_queued.emit(info.name, slot)

func start_typing():
	if spell_queue.size() == 0:
		return
	
	# Prevent starting typing if already typing
	if is_typing:
		return
	
	is_typing = true
	typing_slowdown_remaining = typing_slowdown_capacity
	current_typing_text = ""
	target_spell = spell_queue[0].get("display_name", spell_queue[0]["name"].to_lower())
	
	_apply_typing_slowdown()

	typing_started.emit()
	update_typing_display()

func advance_typing_slowdown(unscaled_delta: float):
	if is_typing:
		typing_slowdown_remaining = maxf(0.0, typing_slowdown_remaining - maxf(unscaled_delta, 0.0))
		_apply_typing_slowdown()

func _set_typing_time_scale(value: float):
	var frame = Engine.get_process_frames()
	if _scale_change_frame != frame:
		_scale_change_frame = frame
		_scale_before_change = Engine.time_scale
	Engine.time_scale = value

func _apply_typing_slowdown():
	if typing_slowdown_remaining <= 0.0:
		_set_typing_time_scale(1.0)
	else:
		_set_typing_time_scale(TIME_SCALE_DURING_TYPING)
	if game_manager and game_manager.has_method("update_typing_slowdown"):
		game_manager.update_typing_slowdown(typing_slowdown_remaining, typing_slowdown_capacity)

func handle_typing_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
	if not is_typing:
		return
	
	if event.keycode == KEY_BACKSPACE:
		if current_typing_text.length() > 0:
			current_typing_text = current_typing_text.substr(0, current_typing_text.length() - 1)
			style_input_changed.emit(current_typing_text)
			update_typing_display()
			# Play backspace sound
			if AudioManager:
				AudioManager.play_sound(AudioManager.SoundType.TYPING_BACKSPACE)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		attempt_cast()
	elif event.keycode == KEY_ESCAPE:
		cancel_typing()
		# Play error sound for cancellation
		if AudioManager:
			AudioManager.on_typing_error()
	else:
		# Add character to typing text
		var char = char(event.unicode)
		if char.length() > 0 and char.is_valid_identifier() or char == " ":
			current_typing_text += char.to_lower()
			style_input_changed.emit(current_typing_text)
			update_typing_display()
			
			# Play typing sound for each character
			if AudioManager:
				AudioManager.play_typing_sound(char)
			
			# Auto-cast if we typed the complete spell name
			if current_typing_text == target_spell or current_typing_text == "mega " + target_spell:
				attempt_cast()

func attempt_cast():
	if current_typing_text == target_spell or current_typing_text == "mega " + target_spell:
		if cast_spell() and AudioManager:
			AudioManager.on_typing_complete()
	else:
		var feedback = "Keep typing" if (target_spell.begins_with(current_typing_text) or ("mega " + target_spell).begins_with(current_typing_text)) else "Mismatch"
		game_manager.update_typing_display(target_spell + " › " + current_typing_text + " · " + feedback)
		# Play error sound for mistyped spell
		if AudioManager:
			AudioManager.on_typing_error()

func cast_spell() -> bool:
	last_cast_failure = ""
	if spell_queue.is_empty():
		return false
	var spell_data = spell_queue[0]
	var spell_name = spell_data["name"]
	var mega = spell_data.get("mega", current_typing_text.strip_edges().to_lower().begins_with("mega "))
	if mega:
		var slot = int(spell_data["slot"])
		if not is_spell_unlocked(slot):
			return false
		var info = get_spell_info(slot)
		if info.type == "plague" and get_visible_plague_host(info) == null:
			last_cast_failure = "No target in range"
			game_manager.update_typing_display(current_typing_text + " · " + last_cast_failure)
			return false
		var stats: Dictionary = {}
		for key in SNAPSHOT_STATS:
			stats[key] = player.get(key)
		var charge = preload("res://scripts/KeywordCharge.gd").new()
		charge.caster = player
		charge.tint = Keywords.cast_color(info)
		get_parent().add_child(charge)
		var payload = {"slot": slot, "info": info.duplicate(true), "ranks": get_combination_ingredient_ranks(str(info.id)).duplicate(true), "stats": stats, "canonical": "mega " + str(info.display_name), "typed": current_typing_text, "name": spell_name, "remaining": Keywords.DEFINITIONS.mega.charge_seconds, "charge": charge, "receipt": game_manager.style_session.snapshot_attempt()}
		pending_keyword_casts.append(payload)
		spell_queue.pop_front()
		last_spell_cast_time = casting_clock
		end_typing()
		return true
	if not cast_spell_by_type(spell_data["slot"]):
		if not last_cast_failure.is_empty() and game_manager:
			game_manager.update_typing_display(current_typing_text + " · " + last_cast_failure)
		return false
	var released_info = get_spell_info(spell_data["slot"])
	manual_spell_released.emit(str(released_info.id), ("mega " if mega else "") + str(released_info.display_name), current_typing_text)
	spell_queue.pop_front()
	last_spell_cast_time = casting_clock
	spell_cast.emit(spell_name)
	if game_manager and game_manager.has_method("increment_spells_cast"):
		game_manager.increment_spells_cast()
	end_typing()
	return true

func cast_stat(key: String) -> float:
	var value = float(release_snapshot.stats[key]) if not release_snapshot.is_empty() and release_snapshot.stats.has(key) else float(player.get(key))
	return value * spell_property_multiplier(key)

## Per-spell layer over the four spell passives, bought with level-ups past rank 8.
## Applies to whichever spell is casting (DamageSource.current), and records which
## properties each spell reads so its level-up cards match what it actually uses.
const SPELL_PROPERTIES = {"spell_damage_multiplier": "power", "spell_size_multiplier": "size", "spell_duration_multiplier": "duration", "projectile_speed_multiplier": "velocity"}
var property_reads: Dictionary = {}

func spell_property_multiplier(key: String) -> float:
	var ley = get_tree().get_first_node_in_group("ley_lines") if key == "spell_damage_multiplier" else null
	return (ley.power_multiplier() if ley else 1.0) * spell_own_multiplier(key)

func spell_own_multiplier(key: String) -> float:
	var property = SPELL_PROPERTIES.get(key, "")
	var spell = str(DamageSource.current.get("spell", ""))
	if property == "" or spell == "":
		return 1.0
	if not property_reads.has(spell):
		property_reads[spell] = {}
	property_reads[spell][property] = true
	for info in spells.values():
		if str(info.get("id", "")) == spell:
			return 1.0 + preload("res://scripts/SpellProgression.gd").OVERFLOW_STEP * int(info.get("overflow", {}).get(property, 0))
	return 1.0

## Properties a spell has read while casting, in passive order. Power if it has never been cast.
func spell_properties(spell_id: String) -> Array:
	var read = property_reads.get(spell_id, {})
	var result = SPELL_PROPERTIES.values().filter(func(property): return read.has(property))
	return result if not result.is_empty() else ["power"]

func discard_pending_casts():
	for payload in pending_keyword_casts:
		if is_instance_valid(payload.charge):
			payload.charge.queue_free()
	pending_keyword_casts.clear()

func advance_pending_casts(seconds: float):
	if not is_instance_valid(player) or player.health <= 0 or game_manager.current_state in [game_manager.GameState.GAME_OVER, game_manager.GameState.EXTRACTION]:
		discard_pending_casts()
		return
	if get_tree().paused or game_manager.current_state != game_manager.GameState.PLAYING:
		return
	var ready: Array[Dictionary] = []
	for payload in pending_keyword_casts:
		payload.remaining -= maxf(0, seconds)
		if is_instance_valid(payload.charge):
			payload.charge.remaining = payload.remaining
		if payload.remaining <= 0:
			ready.append(payload)
	for payload in ready:
		pending_keyword_casts.erase(payload)
		if is_instance_valid(payload.charge):
			payload.charge.queue_free()
		release_snapshot = payload
		var accepted = cast_spell_by_type(payload.slot, MEGA_MULTIPLIER)
		release_snapshot = {}
		if accepted:
			if is_instance_valid(payload.charge):
				payload.charge.release_burst()
			release_style_receipt = payload.receipt
			manual_spell_released.emit(str(payload.info.id), payload.canonical, payload.typed)
			release_style_receipt = {}
			spell_cast.emit(payload.name)
			game_manager.increment_spells_cast()
		else:
			game_manager.hud.get_node("StyleHUD").show_cast_fizzle()

func _exit_tree():
	discard_pending_casts()

func cancel_typing():
	spell_queue.clear()
	end_typing()

func end_typing():
	space_casting = false
	is_typing = false
	current_typing_text = ""
	target_spell = ""
	
	# Force time scale back to normal - this is critical
	_set_typing_time_scale(1.0)
	
	# Also try the time dilation system
	var scene_tree = get_tree()
	if scene_tree:
		var game_node = scene_tree.get_first_node_in_group("game")
		if game_node and game_node.has_method("end_time_dilation"):
			game_node.end_time_dilation()
	
	typing_ended.emit()
	update_typing_display()

func update_typing_display():
	if game_manager and game_manager.has_method("update_typing_display"):
		var display_text = ""
		if is_typing:
			display_text = target_spell + "  ›  " + (current_typing_text if not current_typing_text.is_empty() else "Start typing…")
			if not (target_spell.begins_with(current_typing_text) or ("mega " + target_spell).begins_with(current_typing_text)):
				display_text += " · Mismatch"
		game_manager.update_typing_display(display_text)

# Auto-attack system
func handle_auto_attack(delta):
	mana_bolt_timer -= delta
	if mana_bolt_timer <= 0.0:
		var previous_source = DamageSource.current
		DamageSource.current = DamageSource.make("mana_bolt", style_clock())
		fire_mana_bolt()
		DamageSource.current = previous_source
		# Apply cast speed to Magic Missile cooldown (faster auto-attacks)
		var cast_speed_bonus = cast_stat("cast_speed_multiplier") if player else 1.0
		var adjusted_cooldown = mana_bolt_cooldown / cast_speed_bonus
		mana_bolt_timer = adjusted_cooldown

func fire_mana_bolt():
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0 or not player:
		return
	
	# Calculate damage
	var level_multiplier = 1.0 + SPELL_DAMAGE_MULTIPLIER * (mana_bolt_level - 1)
	var damage = mana_bolt_damage * level_multiplier * cast_stat("spell_damage_multiplier")
	
	# Determine number of projectiles based on Magic Missile level
	var projectile_count = 1
	if mana_bolt_level >= 3:
		projectile_count = 2  # Level 3+: 2 Magic Missiles
	if mana_bolt_level >= 6:
		projectile_count = 3  # Level 6+: 3 Magic Missiles
	if mana_bolt_level >= 10:
		projectile_count = 4  # Level 10+: 4 Magic Missiles
	
	# Get multiple targets for higher levels
	var targets = get_multiple_enemies(projectile_count)
	if targets.size() == 0:
		return
	
	# Play Magic Missile sound
	if AudioManager:
		AudioManager.play_spell_sound("mana_bolt")
	
	# Create Magic Missile visual effect (simple flash)
	create_simple_spell_flash(player.global_position, Color.CYAN)
	
	# Fire multiple Magic Missiles with slight timing offset
	for i in range(projectile_count):
		var delay = i * 0.05  # 50ms delay between each Magic Missile for smoother effect
		var target = targets[i % targets.size()]  # Cycle through available targets
		
		if delay > 0:
			scene_tree.create_timer(delay).timeout.connect(
				DamageSource.wrap(_delayed_mana_bolt.bind(weakref(target), damage, i))
			)
		else:
			create_mana_bolt_projectile(target, damage, i)

# Helper function to create individual Magic Missile projectiles
func create_mana_bolt_projectile(target: Node2D, damage: float, projectile_index: int):
	target = Targeting.select(get_tree(), player.global_position)
	if not target or not is_instance_valid(target):
		return
	
	var scene_tree = get_tree()
	if not scene_tree:
		return
	
	var game_node = scene_tree.get_first_node_in_group("game")
	var projectile = null
	
	# Try to get from object pool first
	if game_node and game_node.has_method("get_pooled_object"):
		projectile = game_node.get_pooled_object("SpellProjectile")
	
	if not projectile:
		projectile = spell_projectile_scene.instantiate()
	
	if not projectile or not is_instance_valid(projectile):
		return
	
	# Vary color slightly for multiple Magic Missiles
	var base_color = Color.CYAN
	var hue_shift = fmod(projectile_index * 0.1, 1.0)
	var color_variation = Color.from_hsv(0.5 + hue_shift * 0.15, 0.8, 1.0)  # Cyan to blue range
	var projectile_color = base_color.lerp(color_variation, 0.3)
	
	# Slightly vary speed
	var speed_variation = 450.0 + (projectile_index * 25.0)
	projectile.speed = speed_variation * cast_stat("projectile_speed_multiplier")
	
	# Strong homing for Magic Missiles
	projectile.homing_strength = 6.0
	
	projectile.setup_homing(player.global_position, target, damage, projectile_color, "mana_bolt")
	var parent = get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		projectile.queue_free()  # Clean up if we can't add it

# Main spell casting dispatcher
func cast_spell_by_type(slot: int, keyword_multiplier: float = 1.0) -> bool:
	var previous = cast_keyword_multiplier
	cast_keyword_multiplier = keyword_multiplier
	var previous_source = DamageSource.current
	DamageSource.current = DamageSource.make(str(get_spell_info(slot).get("id", "")), style_clock())
	var success = _dispatch_spell(slot)
	DamageSource.current = previous_source
	cast_keyword_multiplier = previous
	return success

## Active play time used to age casts; matches the style meter's clock.
func style_clock() -> float:
	var session = game_manager.get("style_session") if game_manager else null
	return float(session.clock) if is_instance_valid(session) else 0.0

func _dispatch_spell(slot: int) -> bool:
	last_cast_failure = ""
	if not player or not is_spell_unlocked(slot):
		return false
	
	var spell_info = get_spell_info(slot)
	var spell_type = spell_info["type"]
	if LegacyBridge.handles(spell_info):
		if not cast_ported(slot):
			return false
		AudioManager.play_spell_sound(str(spell_info.id))
		return true
	
	match spell_type:
		"plague":
			if not cast_build_spell(slot):
				return false
		"heal_over_time":
			cast_life_spell(slot)
		"shield":
			cast_earthshield_spell(slot)
	AudioManager.play_spell_sound(str(spell_info.id))
	return true

# Helper function to get multiple enemy targets for multi-projectile spells
func get_multiple_enemies(count: int) -> Array:
	var scene_tree = get_tree()
	if not scene_tree:
		return []
	
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return []
	
	# Sort enemies by distance from player
	var sorted_enemies = []
	for enemy in enemies:
		if not _live_spell_target(enemy):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		sorted_enemies.append({"enemy": enemy, "distance": distance})
	
	# Sort by distance (closest first)
	sorted_enemies.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Return up to 'count' closest enemies
	var targets = []
	for i in range(min(count, sorted_enemies.size())):
		targets.append(sorted_enemies[i].enemy)
	
	return targets

func cast_life_spell(slot: int):
	var spell_info = get_spell_info(slot)
	var level_multiplier = 1.0 + 0.15 * (spell_info["level"] - 1)
	var heal_per_second = spell_info["heal_amount"] * level_multiplier * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier)
	var duration = float(spell_info["duration"]) * maxf(1.0, cast_stat("spell_duration_multiplier"))
	
	var total_remaining = float(duration)
	var visual_size = cast_keyword_multiplier
	var extended = false
	if spell_info.get("recast_behavior", "stack") == "extend":
		for effect in active_healing_effects:
			if effect.get("spell_id", "") == spell_info.id and effect.remaining_time > 0:
				if not effect.has("segments"):
					effect.segments = [{"remaining": effect.remaining_time, "rate": effect.heal_per_second, "size": effect.get("keyword_multiplier", 1.0)}]
				effect.segments.append({"remaining": duration, "rate": heal_per_second, "size": cast_keyword_multiplier})
				effect.remaining_time += duration
				total_remaining = effect.remaining_time
				visual_size = float(effect.segments[0].size)
				extended = true
				spell_extended.emit(spell_info.id, duration)
				break
	if not extended:
		active_healing_effects.append({"spell_id": spell_info.id, "keyword_multiplier": cast_keyword_multiplier, "heal_per_second": heal_per_second, "remaining_time": duration})
	var particles = get_parent().get("particle_manager")
	if is_instance_valid(particles):
		var visual = particles.create_persistent_life_circle(player, total_remaining, visual_size)
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE * visual_size


func cast_earthshield_spell(slot: int):
	var info = get_spell_info(slot)
	var rank_multiplier = 1.0 + 0.15 * (int(info.get("level", 1)) - 1)
	player.add_earth_shield_charge({
		"remaining": float(info.get("duration", 16.0)) * maxf(1.0, cast_stat("spell_duration_multiplier")),
		"damage": float(info.get("retaliation_damage", 60.0)) * rank_multiplier * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier),
		"reach": float(info.get("retaliation_reach", 160.0)) * (float(cast_stat("spell_size_multiplier")) * cast_keyword_multiplier),
		"half_angle": deg_to_rad(float(info.get("retaliation_angle", 100.0)) * 0.5),
		"knockback": float(info.get("retaliation_knockback", 500.0)),
		"travel_time": float(info.get("retaliation_travel_time", 0.22)),
		"damage_source": DamageSource.current
	})

# Helper functions
func get_closest_enemy():
	var scene_tree = get_tree()
	if not scene_tree:
		return null
	var enemies = scene_tree.get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var closest_enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		if not _live_spell_target(enemy):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	return closest_enemy

func calculate_spell_damage(spell_info: Dictionary) -> float:
	# Spells with damage in rank_growth use that curve instead of the flat +15% per rank.
	var grows_damage = spell_info.get("rank_growth", {}).has("damage")
	if grows_damage and not spell_info.get("rank_resolved", false):
		spell_info = preload("res://scripts/SpellProgression.gd").resolve(spell_info)
	var base_damage = spell_info["damage"]
	var spell_level = spell_info["level"]
	var damage_ranks = 0.0 if spell_info.has("rank_steps") or grows_damage else float(mini(spell_level, 8) - 1)
	var level_multiplier = 1.0 + 0.15 * damage_ranks
	if Synergies.RECIPES.has(str(spell_info.get("id", ""))):
		var resolved = spell_info if spell_info.get("combination_scaled", false) else CombinationScaling.resolve(spell_info, get_combination_ingredient_ranks(str(spell_info.id)))
		return float(resolved.damage) * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier)
	return float(base_damage) * level_multiplier * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier)

func process_healing_effects(delta):
	for i in range(active_healing_effects.size() - 1, -1, -1):
		var effect = active_healing_effects[i]
		var elapsed = min(delta, max(0.0, effect["remaining_time"]))
		effect["remaining_time"] -= elapsed
		if player:
			var previous_health = player.health
			var budget = elapsed
			if effect.has("segments"):
				while budget > 0 and not effect.segments.is_empty():
					var segment = effect.segments[0]
					var step = minf(budget, segment.remaining)
					player.heal(segment.rate * step, segment.size)
					var particles = get_parent().get("particle_manager")
					if is_instance_valid(particles):
						for visual in particles.get_children():
							if visual.get("mode") == "regeneration":
								visual.scale = Vector2.ONE * segment.size
					segment.remaining -= step
					budget -= step
					if segment.remaining <= 0:
						effect.segments.pop_front()
				if not effect.segments.is_empty():
					var particles = get_parent().get("particle_manager")
					if is_instance_valid(particles):
						for visual in particles.get_children():
							if visual.get("mode") == "regeneration":
								visual.scale = Vector2.ONE * effect.segments[0].size
			else:
				player.heal(effect["heal_per_second"] * elapsed, effect.get("keyword_multiplier", 1.0))
			healing_applied.emit(player.health - previous_health)
		if effect["remaining_time"] <= 0:
			active_healing_effects.remove_at(i)

# Visual effect functions
func create_simple_spell_flash(pos: Vector2, color: Color):
	# Create a simple visual flash effect without circles
	var flash = spell_projectile_scene.instantiate()
	if flash:
		flash.setup_effect(pos, color, "flash", 0.3)
		flash.scale = Vector2(0.5, 0.5)  # Make it smaller than AoE effects
		get_parent().add_child(flash)

func create_shield_effect():
	var particles = get_parent().get("particle_manager")
	if is_instance_valid(particles) and particles.has_method("create_persistent_shield_circle"):
		particles.create_persistent_shield_circle(player, player.overheal_timer)

func create_aoe_explosion(pos: Vector2, radius: float, damage: float, color: Color, effect_type: String, duration_snapshot: float = -1.0):
	var effect = load("res://scripts/LingeringArea.gd").new()
	var slow_factor = 0.5 if effect_type == "ice" else 1.0
	var slow_time = 3.0 if effect_type == "ice" else 0.0
	effect.configure(pos, radius, damage, 0.2 * (duration_snapshot if duration_snapshot > 0 else maxf(1.0, cast_stat("spell_duration_multiplier"))), color, effect_type, {}, slow_factor, slow_time)
	get_parent().add_child(effect)

func create_meteor_strike(pos: Vector2, damage: float, radius: float = 220.0, duration_snapshot: float = -1.0):
	# Larger radius and higher damage for meteors with big explosion
	create_aoe_explosion(pos, radius, damage, Color.RED, "meteor", duration_snapshot)

func create_meteor_warning(pos: Vector2, delay: float, radius: float = 180.0):
	# Create a warning indicator at the target position showing the impact radius
	var warning = spell_projectile_scene.instantiate()
	warning.setup_aoe_effect(pos, radius, Color.ORANGE_RED, "warning")
	warning.lifetime = delay
	get_parent().add_child(warning)

## Ice Blast shard count: one shard per degrees_per_shard of cone when the spell sets it, so wider cones stay just as dense.
func chain_lightning(target, damage: float, remaining_chains: int, hit_enemies: Array):
	if not _live_spell_target(target) or remaining_chains <= 0:
		return
	
	# Damage current target
	target.take_damage(damage, Vector2.INF, DamageSource.current)
	hit_enemies.append(target.get_instance_id())
	
	# Find next target
	var scene_tree = get_tree()
	if not scene_tree:
		return
	var enemies = scene_tree.get_nodes_in_group("enemies")
	var next_target = null
	var closest_distance = INF
	
	for enemy in enemies:
		if not _live_spell_target(enemy) or enemy.get_instance_id() in hit_enemies:
			continue
		
		var distance = target.global_position.distance_to(enemy.global_position)
		if distance <= CHAIN_LIGHTNING_RANGE and distance < closest_distance:
			closest_distance = distance
			next_target = enemy
	
	# Create lightning visual effect with position validation
	if next_target and is_instance_valid(next_target):
		var from_pos = target.global_position
		var to_pos = next_target.global_position
		
		# Validate positions before creating arc
		if from_pos.length() > 5.0 and to_pos.length() > 5.0:
			create_lightning_arc_visual(from_pos, to_pos, next_target, target)
		else:
			print("Warning: Invalid chain lightning positions - skipping visual")
		
		# Chain to next target with reduced damage (with validation in callback)
		var tree = get_tree()
		if tree:
			tree.create_timer(0.1).timeout.connect(
				DamageSource.wrap(_delayed_chain.bind(weakref(next_target), damage * CHAIN_DAMAGE_REDUCTION, remaining_chains - 1, hit_enemies.duplicate()))
			)

func create_lightning_arc_visual(from_pos: Vector2, to_pos: Vector2, target_enemy: Node2D = null, from_target: Node2D = null):
	# Validate positions to prevent top-left corner bugs
	if from_pos.length() < 5.0 or to_pos.length() < 5.0:
		print("Warning: Invalid lightning arc positions - from:", from_pos, " to:", to_pos)
		return
	
	# Create lightning arc visual effect
	var lightning = spell_projectile_scene.instantiate()
	lightning.setup_lightning_arc(from_pos, to_pos, Color.YELLOW)
	get_parent().add_child(lightning)

# Player transparency effects
func _on_typing_started():
	if player_sprite:
		player_sprite.modulate.a = PLAYER_TRANSPARENCY_TYPING

func _on_typing_ended():
	if player_sprite:
		player_sprite.modulate.a = 1.0  # Full opacity


# Function to upgrade spells
func enemies_within(center: Vector2, radius: float) -> int:
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if _live_spell_target(enemy) and enemy.global_position.distance_to(center) <= radius:
			count += 1
	return count

func upgrade_spell(spell_name: String):
	if spell_name == "mana_bolt":
		mana_bolt_level += 1
		return
	var slot = find_spell_slot(spell_name)
	if is_spell_unlocked(slot) and can_rank_up(spell_name):
		get_spell_info(slot).level += 1

## Ranks stop at 8 until every spell slot is filled and every equipped spell is rank 8.
## After that, any equipped spell can keep ranking up for percentage damage.
func overflow_unlocked() -> bool:
	if spells.size() < MAX_EQUIPPED_SPELLS:
		return false
	for info in spells.values():
		if int(info.get("level", 1)) < preload("res://scripts/SpellProgression.gd").RANK_CAP:
			return false
	return true

func can_rank_up(spell_name: String) -> bool:
	var info = get_spell_info(find_spell_slot(spell_name))
	if info.is_empty():
		return false
	if preload("res://scripts/SpellProgression.gd").can_upgrade(info):
		return true
	return int(info.get("level", 1)) >= preload("res://scripts/SpellProgression.gd").RANK_CAP and spells.values().has(info) and overflow_unlocked()

func get_mana_bolt_damage() -> float:
	var level_multiplier = 1.0 + SPELL_DAMAGE_MULTIPLIER * (mana_bolt_level - 1)
	var damage = mana_bolt_damage * level_multiplier
	
	# Apply player's spell damage multiplier
	if player:
		damage *= cast_stat("spell_damage_multiplier")
	
	return damage


# Get list of available spells for current player level
func get_available_spells() -> Array:
	var available: Array = []
	for slot in get_all_spells():
		if is_spell_unlocked(slot):
			available.append({"slot": slot, "name": get_spell_info(slot).name, "unlock_level": 1})
	return available

func get_unlocked_spell_names() -> Array:
	var owned: Array = ["mana_bolt"]
	for id in acquired_spells:
		owned.append(id)
	return owned

func is_spell_unlocked(slot: int) -> bool:
	var info = get_spell_info(slot)
	return not info.is_empty() and acquired_spells.has(info.id)

func unlock_all_spells():
	for id in BASE_SPELL_IDS:
		if spells.size() >= MAX_EQUIPPED_SPELLS:
			break
		learn_spell(id)
	game_manager.update_spell_slot_lock_status()


func toggle_freeform_mode(action: String):
	match action:
		"on":
			freeform_mode = true
		"off":
			freeform_mode = false
		"toggle", _:
			freeform_mode = not freeform_mode
	
	# Clear any current typing state when switching modes
	if is_typing:
		cancel_typing()
	

func handle_freeform_input(event: InputEventKey):
	var key_code = event.keycode
	
	# Start typing on any alphabetic key
	if not is_typing:
		# Check if it's a letter key
		if (key_code >= KEY_A and key_code <= KEY_Z) or key_code == KEY_SPACE:
			# Check spell cast cooldown to prevent rapid casting
			var current_time = casting_clock
			if pending_keyword_casts.is_empty() and current_time - last_spell_cast_time < SPELL_CAST_COOLDOWN:
				return
			
			start_freeform_typing()
			# Process this first character
			handle_freeform_typing_input(event)
		return
	
	# Handle typing input
	if is_typing:
		handle_freeform_typing_input(event)

func start_freeform_typing():
	if is_typing:
		return
	
	is_typing = true
	typing_slowdown_remaining = typing_slowdown_capacity
	current_typing_text = ""
	target_spell = ""  # No target in freeform mode, we'll match dynamically
	
	_apply_typing_slowdown()

	typing_started.emit()
	update_freeform_typing_display()

func handle_freeform_typing_input(event: InputEventKey):
	if event.echo and event.keycode != KEY_BACKSPACE:
		return
	if not is_typing:
		return
	
	if event.keycode == KEY_BACKSPACE:
		if current_typing_text.length() > 0:
			current_typing_text = current_typing_text.substr(0, current_typing_text.length() - 1)
			style_input_changed.emit(current_typing_text)
			update_freeform_typing_display()
			# Play backspace sound
			if AudioManager:
				AudioManager.play_sound(AudioManager.SoundType.TYPING_BACKSPACE)
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		attempt_freeform_cast()
	elif event.keycode == KEY_ESCAPE:
		cancel_typing()
		# Play error sound for cancellation
		if AudioManager:
			AudioManager.on_typing_error()
	else:
		# Add character to typing text
		var char = char(event.unicode)
		if char.length() > 0 and (char.is_valid_identifier() or char == " "):
			current_typing_text += char.to_lower()
			style_input_changed.emit(current_typing_text)
			update_freeform_typing_display()
			
			# Play typing sound for each character
			if AudioManager:
				AudioManager.play_typing_sound(char)
			
			# A finished ley word binds at once, like a finished spell name.
			if current_typing_text.strip_edges() in ley_words():
				attempt_freeform_cast()
				return
			# Check if we have a perfect match with any spell
			if not space_casting and (find_cast_spell_slot(current_typing_text) != 0 or current_typing_text == "atomic" or generic_autocast_ready(current_typing_text)):
				attempt_freeform_cast()

func attempt_freeform_cast():
	var spell_name = current_typing_text.strip_edges().to_lower()
	if cast_freeform_spell(spell_name):
		if AudioManager:
			AudioManager.on_typing_complete()
	elif is_typing:
		game_manager.update_typing_display(current_typing_text + " · " + (last_cast_failure if not last_cast_failure.is_empty() else "Spell unavailable in this run"))

func cast_freeform_spell(spell_name: String) -> bool:
	last_cast_failure = ""
	var ley = get_tree().get_first_node_in_group("ley_lines")
	if ley and ley.try_word(spell_name):
		end_typing()
		return true
	if spell_name == "atomic" and is_instance_valid(game_manager.style_session):
		if not game_manager.style_session.cast_atomic():
			last_cast_failure = "Atomic requires S rank and 10,000 combo"
			return false
		last_spell_cast_time = casting_clock
		spell_cast.emit("atomic")
		game_manager.increment_spells_cast()
		end_typing()
		return true
	var slot = find_cast_spell_slot(spell_name)
	if not is_spell_unlocked(slot):
		if slot in spells:
			spell_locked_error.emit(get_spell_info(slot).name, 0, player.level)
			return false
		return cast_keyword_spell(spell_name)
	spell_queue.clear()
	queue_spell(slot)
	spell_queue[0].mega = spell_name.strip_edges().to_lower().begins_with("mega ")
	return cast_spell()

# --- Generic spell engine (doc 18) ---------------------------------------------------------
# Old spells keep their own code paths (and MEGA's charge). Generic spells come from data and take
# any keyword that changes them. An old spell with a keyword it does not support yet fails with a reason.
const KeywordParser = preload("res://scripts/engine/KeywordParser.gd")
const SpellDefs = preload("res://scripts/engine/SpellDefs.gd")
const CastPlanner = preload("res://scripts/engine/CastPlanner.gd")
const GenericCast = preload("res://scripts/engine/GenericCast.gd")
const LegacyBridge = preload("res://scripts/engine/LegacyBridge.gd")
var learned_generic_spells: Array = []
var last_generic_cast = null
var last_parse: Dictionary = {}
var last_cracked: Array = []
signal keyword_cracked(word: String, reason: String)

## Generic spells this player can cast now: bare forms plus learned ones. incantation -> definition.
func castable_generic_spells() -> Dictionary:
	var out := {}
	var by_incantation = SpellDefs.by_incantation()
	for incantation in by_incantation:
		var def: Dictionary = SpellDefs.get_def(str(by_incantation[incantation]))
		if str(def.get("acquire", "")) == "bare" or learned_generic_spells.has(str(def.id)):
			out[incantation] = def
	return out

## Unlocked old spells by lowercase incantation -> slot.
func legacy_incantations() -> Dictionary:
	var out := {}
	for slot in get_all_spells():
		if is_spell_unlocked(slot):
			var info = get_spell_info(slot)
			out[str(info.display_name).to_lower()] = slot
			out[str(info.name).to_lower()] = slot
	return out

func parse_incantation(text: String) -> Dictionary:
	var names: Array = legacy_incantations().keys()
	names.append_array(castable_generic_spells().keys())
	return KeywordParser.parse(text, names)

func cast_keyword_spell(text: String) -> bool:
	var parsed = parse_incantation(text)
	last_parse = parsed
	if not parsed.ok:
		# No spell name at all keeps the existing "Spell unavailable in this run" feedback.
		if parsed.error == "no spell":
			last_cast_failure = ""
		elif not parsed.unknown.is_empty():
			last_cast_failure = "Unknown word: " + str(parsed.unknown[0])
		else:
			last_cast_failure = str(parsed.error).capitalize()
		return false
	var legacy = legacy_incantations()
	if legacy.has(parsed.spell):
		var slot = int(legacy[parsed.spell])
		var spell_label = str(get_spell_info(slot).name)
		if parsed.quick:
			last_cast_failure = "Quick cast doesn't work on %s yet" % spell_label
			return false
		var words: Array = parsed.keywords.filter(func(w): return w != "mega")
		if LegacyBridge.handles(get_spell_info(slot)) and (not words.is_empty() or not parsed.rejected.is_empty()):
			# Ported spells take every keyword (doc 18 phase 2); rejected words crack and the cast goes on.
			ported_bundle = parsed.bundle
			for r in parsed.rejected:
				keyword_cracked.emit(str(r.word), str(r.reason))
			spell_queue.clear()
			queue_spell(slot)
			spell_queue[0].mega = false
			var ok = cast_spell()
			ported_bundle = {}
			return ok
		if not parsed.rejected.is_empty():
			last_cast_failure = "%s: %s" % [str(parsed.rejected[0].word).to_upper(), parsed.rejected[0].reason]
			return false
		for word in parsed.keywords:
			if word != "mega":
				last_cast_failure = "%s doesn't work on %s yet" % [str(word).to_upper(), spell_label]
				return false
		spell_queue.clear()
		queue_spell(slot)
		spell_queue[0].mega = parsed.keywords.has("mega")
		return cast_spell()
	var generic = castable_generic_spells()
	if not generic.has(parsed.spell):
		last_cast_failure = "No matching spell"
		return false
	return cast_generic(generic[parsed.spell], parsed)

func generic_plan_options(quick: bool) -> Dictionary:
	return {"rank_power": cast_stat("spell_damage_multiplier"), "size_stat": maxf(0.1, cast_stat("spell_size_multiplier")),
		"duration_stat": maxf(1.0, cast_stat("spell_duration_multiplier")), "speed_stat": maxf(0.1, cast_stat("projectile_speed_multiplier")), "quick": quick}

func cast_generic(def: Dictionary, parsed: Dictionary) -> bool:
	if not is_instance_valid(player):
		return false
	var previous = DamageSource.current
	var source = DamageSource.make(str(def.id), casting_clock)
	DamageSource.current = source
	var plan = CastPlanner.plan(def, parsed.bundle, generic_plan_options(bool(parsed.quick)))
	DamageSource.current = previous
	# A rejected word cracks its rune red and the spell casts without it (doc 18 principle 1).
	last_cracked = parsed.rejected + plan.rejected
	for r in last_cracked:
		keyword_cracked.emit(str(r.word), str(r.reason))
	var cast = GenericCast.new()
	cast.name = "GenericCast_" + str(def.id)
	cast.setup(plan, player, get_parent(), source)
	get_parent().add_child(cast)
	last_generic_cast = cast
	var canonical = current_typing_text.strip_edges().to_lower() if not current_typing_text.strip_edges().is_empty() else str(def.incantation)
	manual_spell_released.emit(str(def.id), canonical, current_typing_text)
	last_spell_cast_time = casting_clock
	spell_cast.emit(str(def.id))
	if game_manager and game_manager.has_method("increment_spells_cast"):
		game_manager.increment_spells_cast()
	end_typing()
	return true

## Auto-cast for generic incantations: the text parses completely and no castable name continues it.
func generic_autocast_ready(text: String) -> bool:
	var normalized = text.strip_edges().to_lower()
	if normalized.is_empty() or text.ends_with(" "):
		return false
	var parsed = parse_incantation(normalized)
	if not parsed.ok or not castable_generic_spells().has(parsed.spell):
		return false
	var last_word = normalized.split(" ", false)[-1]
	var names: Array = legacy_incantations().keys()
	names.append_array(castable_generic_spells().keys())
	for name in names:
		for part in str(name).split(" ", false):
			if part != last_word and part.begins_with(last_word):
				return false
	for word in KeywordParser.data().get("words", {}):
		if word != last_word and str(word).begins_with(last_word):
			return false
	return true

func add_healing_effect(amount: float, duration: float):
	if amount <= 0.0 or duration <= 0.0 or not is_instance_valid(player):
		return
	active_healing_effects.append({"heal_per_second": amount / duration, "remaining_time": duration})

func get_owned_incantations() -> Array:
	var names: Array = []
	for slot in get_all_spells():
		if is_spell_unlocked(slot):
			names.append(get_spell_info(slot).display_name)
			names.append("mega " + str(get_spell_info(slot).display_name))
	names.append_array(castable_generic_spells().keys())
	return names

func cast_freeform_spell_by_type(spell_name: String, _spell_data: Dictionary):
	var slot = find_spell_slot(spell_name)
	if is_spell_unlocked(slot):
		cast_spell_by_type(slot)

## Ley words typable here, from the ley site the player is standing in.
func ley_words() -> Array:
	var ley = get_tree().get_first_node_in_group("ley_lines")
	return ley.available_words() if ley and ley.has_method("available_words") else []

func update_freeform_typing_display():
	if game_manager and game_manager.has_method("update_typing_display"):
		var display_text = ""
		if is_typing:
			var potential_matches = []
			var normalized = current_typing_text.strip_edges().to_lower()
			# Leading keywords (adjectives) do not stop the spell name from matching.
			var name_words = Array(normalized.split(" ", false))
			while name_words.size() > 1 and KeywordParser.is_keyword(str(name_words[0])):
				name_words.pop_front()
			var stripped = " ".join(name_words)
			for incantation in get_owned_incantations():
				if (str(incantation).begins_with(normalized) or str(incantation).begins_with(stripped)) and not normalized.is_empty():
					potential_matches.append(incantation)

			if is_instance_valid(game_manager.style_session) and game_manager.style_session.atomic_available() and "atomic".begins_with(current_typing_text):
				potential_matches.append("atomic")
			# Ley words in reach match like spells do.
			for word in ley_words():
				if not normalized.is_empty() and str(word).begins_with(normalized):
					potential_matches.append(word)
			display_text = current_typing_text if not current_typing_text.is_empty() else "Type an equipped spell…"
			if not current_typing_text.is_empty() and potential_matches.is_empty():
				display_text += " · No matching spell"
			if potential_matches.size() > 0:
				display_text += " · Ready to cast" if find_cast_spell_slot(current_typing_text) != 0 or current_typing_text == "atomic" or castable_generic_spells().has(str(parse_incantation(normalized).spell)) else " · Matches: " + potential_matches[0]
				if potential_matches.size() > 1 and find_cast_spell_slot(current_typing_text) == 0:
					display_text += " (+%d)" % (potential_matches.size() - 1)
		game_manager.update_typing_display(display_text)

func get_all_spells() -> Dictionary:
	var all = spells.duplicate()
	all.merge(bonus_spells)
	return all

func get_spell_info(slot: int) -> Dictionary:
	if not release_snapshot.is_empty() and slot == release_snapshot.slot:
		return release_snapshot.info
	return spells.get(slot, bonus_spells.get(slot, {}))

func find_spell_slot(spell_name: String) -> int:
	var normalized = spell_name.strip_edges().to_lower().replace("_", " ")
	for slot in get_all_spells():
		var info = get_spell_info(slot)
		for alias in [info.id, info.name, info.display_name]:
			if str(alias).to_lower().replace("_", " ") == normalized:
				return slot
	return 0

func find_cast_spell_slot(spell_name: String) -> int:
	var normalized = spell_name.strip_edges().to_lower()
	if normalized.begins_with("mega "):
		normalized = normalized.substr(5)
	for slot in get_all_spells():
		var info = get_spell_info(slot)
		if is_spell_unlocked(slot) and (normalized == info.display_name or normalized == str(info.name).to_lower()):
			return slot
	return 0

## record_discovery=false is for Training Grounds, which must not unlock Necronomicon entries.
func learn_spell(spell_id: String, record_discovery: bool = true) -> bool:
	if acquired_spells.has(spell_id):
		return false
	if spell_id in Synergies.RECIPES:
		if not synergy_eligible(spell_id):
			return false
		var recipe = Synergies.RECIPES[spell_id]
		var ingredient = spell_catalog.get(recipe.ingredients[0], {})
		if ingredient.is_empty():
			return false
		var bonus = ingredient.duplicate(true)
		bonus.merge(recipe.overrides, true)
		bonus.erase("rank_steps")
		# Combinations need rank-8 ingredients, so they start at the ingredient's full size.
		var growth = bonus.get("rank_growth", {})
		for key in growth:
			if growth[key].has("max"):
				bonus[key] = growth[key].max
		bonus.erase("rank_growth")
		bonus.erase("growth_description")
		bonus.id = spell_id
		bonus.name = recipe.name
		bonus.display_name = recipe.incantation
		bonus.chars = recipe.incantation.length()
		bonus.level = 1
		bonus_spells[slot_limit + bonus_spells.size() + 1] = bonus
		acquired_spells[spell_id] = true
		if record_discovery:
			CharacterManager.discover_synergy(spell_id)
	else:
		if not spell_catalog.has(spell_id) or spells.size() >= slot_limit:
			return false
		spells[spells.size() + 1] = spell_catalog[spell_id].duplicate(true)
		acquired_spells[spell_id] = true
	rebuild_freeform_library()
	return true

func get_spell_rank(spell_id: String) -> int:
	if spell_id == "mana_bolt":
		return mana_bolt_level
	var slot = find_spell_slot(spell_id)
	return int(get_spell_info(slot).level) if is_spell_unlocked(slot) else 0

func get_combination_ingredient_ranks(spell_id: String) -> Dictionary:
	var ranks: Dictionary = {}
	if Synergies.RECIPES.has(spell_id):
		for ingredient in Synergies.RECIPES[spell_id].ingredients:
			ranks[ingredient] = get_spell_rank(ingredient)
	return ranks

func resolve_cast_info(slot: int) -> Dictionary:
	var info = preload("res://scripts/SpellProgression.gd").resolve(get_spell_info(slot))
	info = CombinationScaling.resolve(info, release_snapshot.ranks if not release_snapshot.is_empty() else get_combination_ingredient_ranks(str(info.get("id", ""))))
	info.keyword_size_multiplier = cast_keyword_multiplier
	if not release_snapshot.is_empty():
		info.keyword_stats = release_snapshot.stats.duplicate(true)
	for key in ["splash_damage", "explosion_damage", "healing_seed_amount", "healing_bloom_amount"]:
		if info.has(key):
			info[key] = float(info[key]) * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier)
	return info

func rebuild_freeform_library():
	freeform_spells.clear()
	for info in get_all_spells().values():
		for alias in [str(info.name).to_lower(), info.display_name]:
			freeform_spells[alias] = info

func get_learnable_spell_cards() -> Array:
	var cards: Array = []
	# Preparation runs get base spells from the spellbook, not cards; combinations are still cards.
	if spells.size() < MAX_EQUIPPED_SPELLS and prepared_order.is_empty():
		for id in spell_catalog:
			if acquired_spells.has(id):
				continue
			var info = spell_catalog[id]
			cards.append({"key": "learn:" + id, "name": "Learn " + info.name,
				"description": info.get("role", "Learn a new spell.") + "\nSlot %d of 6 · Type: %s" % [spells.size() + 1, info.display_name],
				"icon": "+", "effect": {"type": "learn_spell", "spell": id}})
	for id in Synergies.RECIPES:
		if acquired_spells.has(id) or not synergy_ready(id):
			continue
		var recipe = Synergies.RECIPES[id]
		cards.append({"key": "learn:" + id, "name": "Learn " + recipe.name,
			"description": recipe.card_description + "\nBonus spell; keeps both ingredients, takes no active slot and starts at rank 1.",
			"icon": "+", "effect": {"type": "learn_spell", "spell": id}})
	return cards

func synergy_eligible(id: String) -> bool:
	if id not in Synergies.RECIPES or not Synergies.RECIPES[id].get("enabled", true):
		return false
	for ingredient in Synergies.RECIPES[id].ingredients:
		if not acquired_spells.has(ingredient):
			return false
	return true

const COMBINATION_RANK = 8

## Combination cards are offered only once both ingredients reach COMBINATION_RANK.
func synergy_ready(id: String) -> bool:
	if not synergy_eligible(id):
		return false
	for ingredient in Synergies.RECIPES[id].ingredients:
		if get_spell_rank(ingredient) < COMBINATION_RANK:
			return false
	return true

func get_rank_upgrade_description(spell_id: String) -> String:
	var rank = get_spell_rank(spell_id)
	return "Rank %d → %d: " % [rank, rank + 1] + rank_change_summary(spell_id)

## Short rank-card text listing what the next rank changes, e.g. "+1 meteor, +damage, +area". No numbers.
const RANK_COUNT_WORDS = {"shard_pierce": "pierce", "projectile_count": "projectile", "blade_count": "blade", "meteor_count": "meteor", "shard_count": "shard", "orb_count": "orb", "chain_count": "chain"}
const RANK_AREA_KEYS = ["radius", "trail_radius", "trap_radius", "trigger_radius", "orbit_radius", "blade_radius", "cone_degrees", "spread_radius", "travel_distance", "beam_radius", "spear_radius"]
const RANK_DURATION_KEYS = ["duration", "patch_duration", "spore_linger"]
func rank_change_summary(spell_id: String) -> String:
	var rank = get_spell_rank(spell_id)
	if rank >= preload("res://scripts/SpellProgression.gd").RANK_CAP and spell_id != "mana_bolt":
		return "+10% damage"
	var combination_description = CombinationScaling.next_description(spell_id, rank)
	if not combination_description.is_empty():
		return combination_description
	var raw = get_spell_info(find_spell_slot(spell_id)).duplicate(true)
	raw.erase("rank_resolved")
	var now_info = raw.duplicate(true)
	now_info.level = rank
	var next_info = raw.duplicate(true)
	next_info.level = rank + 1
	now_info = preload("res://scripts/SpellProgression.gd").resolve(now_info)
	next_info = preload("res://scripts/SpellProgression.gd").resolve(next_info)
	var parts: Array = []
	var extra_projectiles = {"bolt": [3, 6], "mana_bolt": [3, 6, 10]}
	if extra_projectiles.has(spell_id) and rank + 1 in extra_projectiles[spell_id]:
		parts.append("+1 projectile")
	for key in RANK_COUNT_WORDS:
		var gained = int(next_info.get(key, 0)) - int(now_info.get(key, 0))
		if gained > 0:
			parts.append("+%d %s%s" % [gained, RANK_COUNT_WORDS[key], "s" if gained > 1 else ""])
	if int(next_info.get("active_limit", 0)) > int(now_info.get("active_limit", 0)):
		parts.append("+1 at once")
	match spell_id:
		"life", "regeneration":
			parts.append("+healing")
		"earth_shield":
			parts.append("+damage")
		_:
			if float(next_info.get("damage", 0.0)) > float(now_info.get("damage", 0.0)) or not (raw.has("rank_steps") or raw.get("rank_growth", {}).has("damage")):
				parts.append("+damage")
	if RANK_AREA_KEYS.any(func(key): return float(next_info.get(key, 0.0)) > float(now_info.get(key, 0.0))):
		parts.append("+area")
	if RANK_DURATION_KEYS.any(func(key): return float(next_info.get(key, 0.0)) > float(now_info.get(key, 0.0))):
		parts.append("+duration")
	if spell_id == "ice_blast":
		parts.append("+push")
	return ", ".join(parts) if not parts.is_empty() else "+damage"

func cast_build_spell(slot: int) -> bool:
	var info = resolve_cast_info(slot)
	var target = get_visible_plague_host(info) if info.type == "plague" else get_closest_enemy()
	if info.type == "field":
		target = Targeting.select_area(get_tree(), player.global_position, float(info.get("radius", 150)), INF, {}, get_viewport().get_visible_rect())
	if info.type == "plague" and target == null:
		last_cast_failure = "No target in range"
		return false
	info.projectile_speed_multiplier = cast_stat("projectile_speed_multiplier")
	var tactical = info.type in ["beam", "trap", "spirit", "trail", "returning"]
	var active = get_tree().get_nodes_in_group("build_spell_effects").filter(func(effect): return effect.info.id == info.id and not effect.is_queued_for_deletion())
	if info.get("recast_behavior", "stack") == "extend":
		for existing in active:
			if existing.remaining > 0 and existing.caster and existing.caster.get_ref() == player:
				var added = existing.queue_cast_extension(info, calculate_spell_damage(info))
				DamageSource.stamp(existing)
				spell_extended.emit(info.id, added)
				return true
	if active.size() >= int(info.get("active_limit", 3)):
		if info.get("extend_at_cap", false):
			# At the cap a recast goes where the horde is: extend the field already covering the
			# target, otherwise move the emptiest field there. Fields never sit extended on empty ground.
			var covering = null
			if target != null and is_instance_valid(target):
				for existing in active:
					if existing.global_position.distance_to(target.global_position) <= float(existing.info.get("radius", 150.0)):
						covering = existing
						break
			if covering == null and (target == null or not is_instance_valid(target)):
				covering = active[0]
				for existing in active:
					if existing.remaining < covering.remaining:
						covering = existing
			if covering != null:
				var added = covering.queue_cast_extension(info, calculate_spell_damage(info))
				DamageSource.stamp(covering)
				spell_extended.emit(info.id, added)
				return true
			var emptiest = active[0]
			var fewest = INF
			for existing in active:
				var inside = enemies_within(existing.global_position, float(existing.info.get("radius", 150.0)))
				if inside < fewest or (inside == fewest and existing.remaining < emptiest.remaining):
					fewest = inside
					emptiest = existing
			emptiest.queue_free()
		else:
			active[0].queue_free()
	if tactical:
		target = null
		var distance = INF
		var occupied_targets: Array = []
		if info.type == "beam":
			for beam in get_tree().get_nodes_in_group("active_spell_channels"):
				if beam.is_style_channel_active() and beam.target_ref and is_instance_valid(beam.target_ref.get_ref()):
					occupied_targets.append(beam.target_ref.get_ref())
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not _live_spell_target(enemy):
				continue
			if info.type == "beam" and player.global_position.distance_to(enemy.global_position) > 450.0:
				continue
			var target_distance = player.global_position.distance_squared_to(enemy.global_position) + (1000000.0 if enemy in occupied_targets else 0.0)
			if target_distance < distance:
				distance = target_distance
				target = enemy
	if info.type == "spirit":
		target = Targeting.select_spirit(get_tree(), player)
	if info.type == "beam":
		var beam_direction = player.global_position.direction_to(target.global_position) if target else Vector2.RIGHT
		var occupied_lanes: Array = []
		for beam in active:
			if not beam.is_queued_for_deletion():
				occupied_lanes.append(int(beam.info.get("beam_lane", 0)))
		for lane in [-1, 0, 1]:
			if lane not in occupied_lanes:
				info.beam_lane = lane
				info.beam_origin_offset = beam_direction.orthogonal() * float(lane) * 18.0
				break
	var effect = preload("res://scripts/TacticalSpellEffect.gd").new() if tactical else preload("res://scripts/BuildSpellEffect.gd").new()
	effect.configure(info, calculate_spell_damage(info), player, target)
	get_parent().add_child(effect)
	return true

## Doc 18 phase 2: a shipping spell rebuilt on the generic engine (scripts/engine/LegacyBridge.gd).
## Same numbers and targeting as before; the generic runner moves and hits, and the VFX present it.
var ported_bundle: Dictionary = {}

func cast_ported(slot: int, bundle: Dictionary = {}) -> bool:
	if bundle.is_empty():
		bundle = ported_bundle
	ported_bundle = {}
	var info = resolve_cast_info(slot)
	var scaled = Geometry.scaled_data(info, player)
	var speed_mult = float(cast_stat("projectile_speed_multiplier"))
	var ctx = {"speed_mult": speed_mult}
	if str(info.get("type", "")) == "heal":
		ctx.heal = float(info.heal_amount) * (1.0 + 0.15 * (int(info.level) - 1)) * (maxf(0.0, cast_stat("spell_damage_multiplier")) * cast_keyword_multiplier)
	var def = LegacyBridge.build(scaled, calculate_spell_damage(info), ctx)
	if def.is_empty():
		return false
	var plan = CastPlanner.plan(def, bundle, {})
	last_cracked = plan.rejected
	for r in plan.rejected:
		keyword_cracked.emit(str(r.word), str(r.reason))
	if def.has("recast") and _apply_recast(def, plan, ported_target.bind(scaled, speed_mult)):
		return true
	var cast = GenericCast.new()
	cast.name = "GenericCast_" + str(def.id)
	cast.target_picker = ported_target.bind(scaled, speed_mult)
	if str(info.get("type", "")) == "multi_aoe":
		cast.point_picker = meteor_points.bind(float(scaled.get("radius", 220.0)))
	if str(info.get("type", "")) == "life_bolt":
		cast.target_picker = life_bolt_picker()
	cast.setup(plan, player, get_parent(), DamageSource.current if not DamageSource.current.is_empty() else DamageSource.make(str(def.id), style_clock()))
	get_parent().add_child(cast)
	last_generic_cast = cast
	# Old spells left the caster the moment they were cast; so do ported ones (and targeting sees them).
	cast.step(0.0)
	if str(info.get("type", "")) == "beam":
		_beam_lane(cast)
	return true

## Old Focus Ray lanes: up to three beams sit side by side (18 px apart) instead of on top of each other.
func _beam_lane(cast) -> void:
	var roots: Array = cast.root_parts()
	if roots.is_empty():
		return
	var taken: Array = []
	for other in ported_casts(str(cast.plan.id)):
		if other != cast:
			taken.append(int(other.get_meta("beam_lane", 0)))
	for lane in [-1, 0, 1]:
		if lane not in taken:
			cast.set_meta("beam_lane", lane)
			for part in roots:
				part.beam_offset = part.direction.orthogonal() * float(lane) * 18.0
				part.global_position = cast.caster_position() + part.beam_offset
			return

## Live casts of a ported spell owned by the player, oldest first.
func ported_casts(id: String) -> Array:
	return get_tree().get_nodes_in_group("generic_casts").filter(func(c):
		return not c.is_queued_for_deletion() and c.caster == player and str(c.plan.get("id", "")) == id and not c.root_parts().is_empty())

## Old recast rules for ported spells. True when the recast was absorbed (an existing cast was
## extended) and no new cast should start.
##  extend: a recast adds one cast's duration to the live one; its numbers take over when the
##          current ones run out.
##  stack + active_limit: at the cap the oldest goes; with extend_at_cap the recast instead extends
##          the field already covering the target, or moves the emptiest field to it.
func _apply_recast(def: Dictionary, plan: Dictionary, picker: Callable) -> bool:
	var rule: Dictionary = def.recast
	var live = ported_casts(str(def.id))
	if str(rule.behavior) == "extend" and not live.is_empty():
		_extend_ported(live[0], plan, rule)
		return true
	if live.size() < int(rule.cap):
		return false
	if bool(rule.extend_at_cap):
		var target = picker.call()
		var covering = null
		if target != null and is_instance_valid(target):
			for c in live:
				var root = c.root_parts()[0]
				if root.global_position.distance_to(target.global_position) <= root.geo("radius", 150.0):
					covering = c
					break
		if covering == null and (target == null or not is_instance_valid(target)):
			covering = live[0]
			for c in live:
				if c.root_parts()[0].remaining_life() < covering.root_parts()[0].remaining_life():
					covering = c
		if covering != null:
			_extend_ported(covering, plan, rule)
			return true
		var emptiest = live[0]
		var fewest = INF
		for c in live:
			var root = c.root_parts()[0]
			var inside = enemies_within(root.global_position, root.geo("radius", 150.0))
			if inside < fewest or (inside == fewest and root.remaining_life() < emptiest.root_parts()[0].remaining_life()):
				fewest = inside
				emptiest = c
		for part in emptiest.root_parts():
			part.finish(false)
		return false
	for part in live[0].root_parts():
		part.finish(false)
	return false

func _extend_ported(cast, plan: Dictionary, rule: Dictionary) -> void:
	var new_root: Dictionary = plan.parts[str(plan.root)]
	var one = float(new_root.get("timing", {}).get("duration", new_root.get("limits", {}).get("lifetime", 0.0)))
	var roots: Array = cast.root_parts()
	var added = one
	if rule.has("max_banked"):
		added = clampf(one * float(rule.max_banked) - roots[0].remaining_life(), 0.0, one)
	if added <= 0.0:
		return
	for part in roots:
		part.extend_with(new_root, added)
	if not DamageSource.current.is_empty():
		cast.source = DamageSource.current   # later hits count toward the newest cast (style meter)
	spell_extended.emit(str(plan.id), added)

## Old Life Bolt aim: each bolt goes to a different on-screen enemy first, then any on-screen one.
func life_bolt_picker() -> Callable:
	var offscreen: Dictionary = {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_visible_in_tree() or not get_viewport().get_visible_rect().has_point(enemy.get_global_transform_with_canvas().origin):
			offscreen[enemy.get_instance_id()] = true
	var coverage: Dictionary = {}
	return func():
		var excluded = offscreen.duplicate()
		excluded.merge(coverage)
		var target = Targeting.select(get_tree(), player.global_position, INF, excluded)
		if not _live_spell_target(target):
			target = Targeting.select(get_tree(), player.global_position, INF, offscreen)
		if _live_spell_target(target):
			coverage[target.get_instance_id()] = true
			return target
		return null

## Old Meteor Shower aim: weighted picks over visible enemies, spread by what earlier meteors cover.
func meteor_points(count: int, radius: float) -> Array:
	var coverage: Dictionary = {}
	var points: Array = []
	for index in range(count):
		var target = Targeting.select_meteor(get_tree(), player.global_position, get_viewport().get_visible_rect(), coverage)
		if not _live_spell_target(target):
			break
		var center = target.global_position
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if _live_spell_target(enemy) and center.distance_to(enemy.global_position) <= radius:
				coverage[enemy.get_instance_id()] = float(coverage.get(enemy.get_instance_id(), 0)) + 1.0
		points.append(center)
	return points

## The target each ported spell aimed at before the port.
func ported_target(info: Dictionary, speed_mult: float):
	match str(info.get("type", "")):
		"piercing":
			var reach = 700.0 * 1.5 * speed_mult
			var line_target = Targeting.select_line(get_tree(), player.global_position, float(info.get("spear_radius", 24.0)), reach, get_viewport().get_visible_rect())
			return line_target if line_target != null else get_closest_enemy()
		"projectile":
			return Targeting.select(get_tree(), player.global_position) if is_instance_valid(player) else null
		"bouncing_projectile":
			var first = Targeting.select(get_tree(), player.global_position) if is_instance_valid(player) else null
			return first if _live_spell_target(first) else null
		"direct_strike", "chain":
			var area = Targeting.select_area(get_tree(), player.global_position, float(info.get("radius", 160)), INF, {}, get_viewport().get_visible_rect())
			return area if _live_spell_target(area) else null
		"heal":
			return null
		"field":
			var spot = Targeting.select_area(get_tree(), player.global_position, float(info.get("radius", 150)), INF, {}, get_viewport().get_visible_rect())
			return spot if _live_spell_target(spot) else null
		"orbit", "spirit", "trail":
			return null
		"returning":
			return Targeting.select(get_tree(), player.global_position, 600.0)
		"beam":
			# nearest within reach, preferring enemies no live beam is already on
			var occupied: Array = []
			for beam in get_tree().get_nodes_in_group("active_spell_channels"):
				if beam.has_method("is_style_channel_active") and beam.is_style_channel_active() and beam.get("target_ref") and is_instance_valid(beam.target_ref.get_ref()):
					occupied.append(beam.target_ref.get_ref())
			var best = null
			var distance = INF
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not _live_spell_target(enemy) or player.global_position.distance_to(enemy.global_position) > 450.0:
					continue
				var score = player.global_position.distance_squared_to(enemy.global_position) + (1000000.0 if enemy in occupied else 0.0)
				if score < distance:
					distance = score
					best = enemy
			return best
	return get_closest_enemy()

func get_visible_plague_host(info: Dictionary):
	var nearest = null
	var nearest_distance = INF
	var maximum_distance = maxf(0.0, float(info.get("cast_range", INF)))
	var viewport = get_viewport().get_visible_rect()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _live_spell_target(enemy) or not enemy.is_visible_in_tree():
			continue
		if not viewport.has_point(enemy.get_global_transform_with_canvas().origin):
			continue
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance <= maximum_distance and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _live_spell_target(target) -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and not target.get("dying") and float(target.get("current_health")) > 0.0

func _delayed_mana_bolt(reference: WeakRef, damage: float, index: int):
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var target = reference.get_ref()
	create_mana_bolt_projectile(target, damage, index)

func _delayed_chain(reference: WeakRef, damage: float, remaining: int, hit_ids: Array):
	if not is_inside_tree() or not is_instance_valid(player):
		return
	var target = reference.get_ref()
	if _live_spell_target(target):
		chain_lightning(target, damage, remaining, hit_ids)
