extends "res://scripts/Enemy.gd"

static var sprite_bounds: Dictionary = {}

const Hazard = preload("res://scripts/EnemyProjectile.gd")
var variant: String = "pursuer"
var family: String = "grunt"
var boss: bool = false
var encounter_name: String = "Pursuer"
## Shieldbearer shield: turns toward the player at this rate (rad/s) and blocks 35% within this half-angle of its facing.
const SHIELD_TURN_SPEED = 0.9
const SHIELD_HALF_ARC = PI / 3.0
var facing: Vector2 = Vector2.DOWN
var behavior_time: float = 0.0
var action_time: float = 2.0
var warning: float = 0.0
var action_direction: Vector2 = Vector2.ZERO
var charge_remaining: float = 0.0
var recoil_remaining = 0.0
var recoil_velocity = Vector2.ZERO
var spawn_data: Dictionary = {}
var normal_collision_mask = 34
## Training dummies walk back to this point instead of chasing; INF means a normal enemy.
var training_anchor := Vector2.INF
## Elite words and traits (scripts/Elites.gd, data/elites.json); empty for a normal monster.
var elite: Dictionary = {}
var cast_timers: Array = []
const TRAINING_PULL = 6.0
const TRAINING_MAX_SPEED = 260.0

func configure(definition: Dictionary, stats: Dictionary, is_boss: bool = false, elite_traits: Dictionary = {}):
	spawn_data = definition
	variant = definition.id
	family = definition.family
	boss = is_boss
	encounter_name = definition.name
	elite = elite_traits
	if not elite.is_empty():
		stats = stats.duplicate()
		for key in ["health", "damage", "speed", "xp"]:
			if stats.has(key):
				stats[key] = float(stats[key]) * float(elite.get(key + "_mult", 1.0))
		encounter_name = str(elite.get("name", encounter_name))
		if str(elite.get("element", "")) != "":
			element = str(elite.element)   # the type chart gives it its resistance and weakness
		if str(elite.get("resist_profile", "")) != "":
			resistances = preload("res://scripts/engine/SpellDamage.gd").resistance_profile(str(elite.resist_profile))
		cast_timers.clear()
		for c in elite.get("casts", []):
			cast_timers.append(float(c.get("every", 4.0)) * 0.5)   # first cast comes sooner
	set_monster_stats(stats)
	scale = Vector2.ONE * definition.get("size", 1.0) * (1.7 if boss else 1.0) * float(elite.get("size_mult", 1.0))
	enemy_type = {"grunt": EnemyType.CHASER, "runner": EnemyType.SWARM, "brute": EnemyType.TANK, "shooter": EnemyType.SHOOTER}[family]

var terrain: Node = null   # the Background's tree steering, looked up once

func _ready():
	register_spawn_telemetry()
	normal_collision_mask = collision_mask
	update_crowd_collision(false)
	# Top-down bodies: floating motion (no floor logic) and one slide per step. In a dense crowd the
	# extra slide iterations were most of the movement cost (measured 16 October 2026: 400 enemies
	# 14 ms -> 7-8 ms of physics per frame on an M4 Pro); crowds still block each other.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_slides = 1
	var bg = get_parent().get_node_or_null("Background") if get_parent() else null
	terrain = bg if bg and bg.has_method("steer") else null
	player = get_tree().get_first_node_in_group("player")
	health_bar_fill = $HealthBar/Fill
	$Sprite2D.texture = load(spawn_data.get("boss_sprite", spawn_data.sprite) if boss else spawn_data.sprite)
	var sprite = $Sprite2D
	sprite.scale = Vector2.ONE * float(spawn_data.get("boss_visual_scale", spawn_data.get("visual_scale", 2.0)) if boss else spawn_data.get("visual_scale", 2.0))
	var texture_path = sprite.texture.resource_path
	if not sprite_bounds.has(texture_path):
		sprite_bounds[texture_path] = sprite.texture.get_image().get_used_rect()
	var body_bounds: Rect2i = sprite_bounds[texture_path]
	var body_top = (body_bounds.position.y - sprite.texture.get_height() / 2.0) * sprite.scale.y
	var bar = $HealthBar
	bar.offset_left = -body_bounds.size.x * sprite.scale.x / 2.0
	bar.offset_right = -bar.offset_left
	bar.offset_bottom = body_top - 5.0
	bar.offset_top = bar.offset_bottom - 5.0
	update_health_bar()
	add_to_group("enemies")
	if not elite.is_empty():
		add_to_group("elites")
		var tint: Array = elite.get("tint", [1, 1, 1])
		sprite.self_modulate = Color(float(tint[0]), float(tint[1]), float(tint[2]))   # darker, never a status colour
		var words = Label.new()
		words.name = "EliteWords"
		words.text = str(elite.get("label", ""))
		words.add_theme_font_size_override("font_size", 13)
		# Keyword gold, or the element word's own colour (FIERY orange, ICY cyan, SHOCKING yellow)
		# so you know what it will throw before it throws it.
		var word_color := str(elite.get("color", ""))
		words.add_theme_color_override("font_color", Color(word_color) if word_color != "" else Color("f2c96b"))
		words.add_theme_color_override("font_outline_color", Color("1a1420"))
		words.add_theme_constant_override("outline_size", 4)
		words.scale = Vector2.ONE / scale
		var words_size = words.get_minimum_size()
		words.position = Vector2(-words_size.x * words.scale.x / 2.0, bar.offset_top - (words_size.y + 2.0) * words.scale.y)
		add_child(words)
	if boss:
		add_to_group("bosses")
		var label = Label.new()
		label.text = encounter_name
		label.name = "BossLabel"
		label.add_theme_font_size_override("font_size", 16)
		label.scale = Vector2.ONE / scale
		var label_size = label.get_minimum_size()
		label.position = Vector2(-label_size.x * label.scale.x / 2.0, bar.offset_top - (label_size.y + 6.0) * label.scale.y)
		add_child(label)

func _physics_process(delta):
	if dying or not is_instance_valid(player):
		return
	process_status_effects(delta)
	if training_anchor != Vector2.INF:
		training_step(delta)
		return
	if recoil_remaining > 0.0:
		recoil_remaining = maxf(0.0, recoil_remaining - delta)
		velocity = recoil_velocity
		update_crowd_collision(false)
		move_and_slide()
		return
	behavior_time += delta
	action_time -= delta
	var offset = player.global_position - global_position
	var toward = offset.normalized()
	facing = facing.rotated(clampf(facing.angle_to(toward), -SHIELD_TURN_SPEED * delta, SHIELD_TURN_SPEED * delta))
	velocity = toward * speed * slow_multiplier
	var charging_this_step = charge_remaining > 0.0
	match variant:
		"flanker":
			var side = 1.0 if get_instance_id() % 2 == 0 else -1.0
			var target_position = player.global_position + toward.orthogonal() * side * minf(160.0, offset.length() * 0.5)
			velocity = (target_position - global_position).normalized() * speed * slow_multiplier
		"skirmisher":
			if offset.length() < 140.0 and fmod(behavior_time, 3.5) > 2.0:
				velocity = -toward * speed * slow_multiplier
		"charger":
			update_charge(delta, toward, offset.length())
		"slammer":
			if action_time <= 0.0 and offset.length() < 140.0:
				place_hazard(global_position, 115.0, 1.2, damage * 1.5)
				action_time = 4.0
			if action_time > 2.8:
				velocity = Vector2.ZERO
		"marksman", "fan_caster", "mortar":
			update_ranged(delta, toward, offset.length())
	charging_this_step = charging_this_step or charge_remaining > 0.0
	if not elite.is_empty():
		update_elite_casts(delta, offset.length())
	update_crowd_collision(charging_this_step)
	if terrain and is_instance_valid(terrain) and not charging_this_step:
		velocity = terrain.steer(global_position, velocity, 29.0 * scale.x)
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity *= pow(knockback_decay, delta * 60.0)
	_redraw_if_needed()

## Slows cap how fast a dummy can get back home; knockback shoves it off its spot.
func training_step(delta: float):
	velocity = ((training_anchor - global_position) * TRAINING_PULL).limit_length(TRAINING_MAX_SPEED * slow_multiplier)
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity *= pow(knockback_decay, delta * 60.0)
	_redraw_if_needed()

func update_crowd_collision(charging: bool):
	collision_mask = normal_collision_mask & ~2 if boss or charging else normal_collision_mask

func recoil_from_contact(source: Vector2):
	if dying or recoil_remaining > 0.0:
		return
	var manager = get_tree().get_first_node_in_group("monster_manager")
	var settings = manager.encounter_config.get("contact_recoil", {}) if manager else {}
	var weight = float(settings.get("boss_multiplier", 0.35)) if boss else (float(settings.get("heavy_multiplier", 0.6)) if family == "brute" else 1.0)
	var away = source.direction_to(global_position)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	recoil_remaining = float(settings.get("duration", 0.24))
	recoil_velocity = away * float(settings.get("speed", 320.0)) * weight
	charge_remaining = 0.0
	warning = 0.0
	action_time = maxf(action_time, 0.7)

func update_charge(delta: float, toward: Vector2, distance: float):
	var settings = spawn_data.get("boss_charge", {}) if boss else {}
	if charge_remaining > 0.0:
		velocity = action_direction * float(settings.get("speed", speed * float(settings.get("speed_multiplier", 2.5)))) * slow_multiplier
		charge_remaining -= delta
	elif warning > 0.0:
		velocity = Vector2.ZERO
		warning -= delta
		if warning <= 0.0:
			charge_remaining = float(settings.get("duration", 0.65))
			action_time = float(settings.get("cooldown", 3.5))
	elif action_time <= 0.0 and distance < float(settings.get("trigger_range", 450.0)):
		warning = float(settings.get("warning", 0.9))
		action_direction = toward
		velocity = Vector2.ZERO
	elif action_time > 2.8:
		velocity = Vector2.ZERO

func update_ranged(delta: float, toward: Vector2, distance: float):
	if distance < 260.0:
		velocity = -toward * speed * slow_multiplier
	elif distance < 450.0:
		velocity = Vector2.ZERO
	if warning > 0.0:
		velocity = Vector2.ZERO
		warning -= delta
		if warning <= 0.0:
			if variant == "mortar":
				place_hazard(action_direction, 95.0, 1.4, damage)
			else:
				for angle in ([-0.32, 0.0, 0.32] if variant == "fan_caster" else [0.0]):
					var shot = Hazard.new()
					shot.position = global_position
					shot.direction = action_direction.rotated(angle)
					shot.damage = damage
					shot.damage_source = encounter_name
					shot.attacker = weakref(self)
					shot.source_position = global_position
					get_parent().add_child(shot)
			action_time = 3.8 if variant == "mortar" else 2.8
	elif action_time <= 0.0 and distance < 650.0:
		warning = 0.9
		action_direction = player.global_position if variant == "mortar" else toward

func place_hazard(location: Vector2, radius: float, delay: float, amount: float):
	var hazard = Hazard.new()
	hazard.position = location
	hazard.blast_radius = radius
	hazard.warning_time = delay
	hazard.damage = amount
	hazard.damage_source = encounter_name
	hazard.attacker = weakref(self)
	hazard.source_position = global_position
	get_parent().add_child(hazard)

func take_damage(damage_amount: float, source_position: Vector2 = Vector2.INF, source: Dictionary = {}):
	var amount = damage_amount
	if variant == "shieldbearer" and source_position != Vector2.INF:
		var incoming = (source_position - global_position).normalized()
		if incoming.dot(facing) > cos(SHIELD_HALF_ARC):
			amount *= 0.65
	super.take_damage(amount, source_position, source)

## Only enemies with something on their canvas (a shield arc, an attack warning, debug rings) are
## redrawn each step; one more redraw clears a warning that just ended. Redrawing every enemy every
## step was a large share of crowd cost.
static var _debug_archetypes = null
var _drew_something := false
func _redraw_if_needed() -> void:
	if _debug_archetypes == null:
		_debug_archetypes = OS.get_cmdline_user_args().has("--debug-enemies")
	var wants: bool = _debug_archetypes or variant == "shieldbearer" or warning > 0.0
	if wants or _drew_something:
		queue_redraw()
	_drew_something = wants

const ARCHETYPE_COLORS = {"grunt": Color(0.8, 0.85, 0.65), "runner": Color(1, 0.8, 0.2), "brute": Color(0.9, 0.5, 0.25), "shooter": Color(1, 0.25, 0.3)}
func _draw():
	if _debug_archetypes == null:
		_debug_archetypes = OS.get_cmdline_user_args().has("--debug-enemies")
	var debug_archetypes: bool = _debug_archetypes
	var colors = ARCHETYPE_COLORS
	if debug_archetypes:
		draw_arc(Vector2.ZERO, 25, 0, TAU, 24, Color("0b1320"), 6.0)
		draw_arc(Vector2.ZERO, 25, 0, TAU, 24, colors.get(family, Color.WHITE), 2.5)
	if boss and debug_archetypes:
		draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color.GOLD, 3.0)
	if variant == "shieldbearer":
		draw_arc(Vector2.ZERO, 32, facing.angle() - SHIELD_HALF_ARC, facing.angle() + SHIELD_HALF_ARC, 16, Color(0.7, 0.85, 1), 5.0)
	if warning > 0.0:
		var line_direction = action_direction if variant != "mortar" else (action_direction - global_position).normalized()
		var reach = 100.0
		if variant == "charger" and boss:
			var settings = spawn_data.get("boss_charge", {})
			reach = float(settings.get("speed", speed * float(settings.get("speed_multiplier", 2.5)))) * float(settings.get("duration", 0.65)) * slow_multiplier / scale.x
		draw_line(Vector2.ZERO, line_direction * reach, Color(1, 0.2, 0.1, 0.8), 4.0)

## Elite word spells (FIERY fireball, ICY frost burst, SHOCKING strike): each on its own timer, cast
## when the player is within its range.
func update_elite_casts(delta: float, distance: float):
	var casts: Array = elite.get("casts", [])
	for i in casts.size():
		cast_timers[i] = float(cast_timers[i]) - delta
		if cast_timers[i] <= 0.0 and distance <= float(casts[i].get("range", 500.0)):
			cast_timers[i] = float(casts[i].get("every", 4.0))
			preload("res://scripts/Elites.gd").cast(self, casts[i], player)

## LEECHING: its contact damage heals it (a fraction of its max health per hit that lands).
## Element words: its touch puts their status on the player.
func on_dealt_contact(_amount: float):
	for status in elite.get("contact_statuses", []):
		if is_instance_valid(player) and player.has_method("apply_status"):
			player.apply_status(str(status))
	var heal = float(elite.get("heal_per_hit", 0.0))
	if heal > 0.0 and not dying:
		current_health = minf(max_health, current_health + max_health * heal)
		update_health_bar()
