extends "res://scripts/Enemy.gd"

const Hazard = preload("res://scripts/EnemyProjectile.gd")
var variant: String = "pursuer"
var family: String = "grunt"
var boss: bool = false
var encounter_name: String = "Pursuer"
var facing: Vector2 = Vector2.DOWN
var behavior_time: float = 0.0
var action_time: float = 2.0
var warning: float = 0.0
var action_direction: Vector2 = Vector2.ZERO
var charge_remaining: float = 0.0
var recoil_remaining = 0.0
var recoil_velocity = Vector2.ZERO
var spawn_data: Dictionary = {}

func configure(definition: Dictionary, stats: Dictionary, is_boss: bool = false):
	spawn_data = definition
	variant = definition.id
	family = definition.family
	boss = is_boss
	encounter_name = definition.name
	set_monster_stats(stats)
	scale = Vector2.ONE * definition.get("size", 1.0) * (1.7 if boss else 1.0)
	enemy_type = {"grunt": EnemyType.CHASER, "runner": EnemyType.SWARM, "brute": EnemyType.TANK, "shooter": EnemyType.SHOOTER}[family]

func _ready():
	player = get_tree().get_first_node_in_group("player")
	health_bar_fill = $HealthBar/Fill
	$Sprite2D.texture = load(spawn_data.get("boss_sprite", spawn_data.sprite) if boss else spawn_data.sprite)
	update_health_bar()
	add_to_group("enemies")
	if boss:
		add_to_group("bosses")
		var label = Label.new()
		label.text = encounter_name
		label.position = Vector2(-70, -65)
		label.add_theme_font_size_override("font_size", 16)
		add_child(label)

func _physics_process(delta):
	if dying or not is_instance_valid(player):
		return
	process_status_effects(delta)
	if recoil_remaining > 0.0:
		recoil_remaining = maxf(0.0, recoil_remaining - delta)
		velocity = recoil_velocity
		move_and_slide()
		return
	behavior_time += delta
	action_time -= delta
	var offset = player.global_position - global_position
	var toward = offset.normalized()
	facing = facing.rotated(clampf(facing.angle_to(toward), -1.8 * delta, 1.8 * delta))
	velocity = toward * speed * slow_multiplier
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
	var terrain = get_parent().get_node_or_null("Background")
	if terrain and terrain.has_method("steer") and charge_remaining <= 0.0:
		velocity = terrain.steer(global_position, velocity, 29.0 * scale.x)
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity *= pow(knockback_decay, delta * 60.0)
	queue_redraw()

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
		velocity = action_direction * speed * float(settings.get("speed_multiplier", 2.5)) * slow_multiplier
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
	get_parent().add_child(hazard)

func take_damage(damage_amount: float, source_position: Vector2 = Vector2.INF):
	var amount = damage_amount
	if variant == "shieldbearer" and source_position != Vector2.INF:
		var incoming = (source_position - global_position).normalized()
		if incoming.dot(facing) > 0.5:
			amount *= 0.65
	super.take_damage(amount, source_position)

func _draw():
	var debug_archetypes = OS.get_cmdline_user_args().has("--debug-enemies")
	var colors = {"grunt": Color(0.8, 0.85, 0.65), "runner": Color(1, 0.8, 0.2), "brute": Color(0.9, 0.5, 0.25), "shooter": Color(1, 0.25, 0.3)}
	if debug_archetypes:
		draw_arc(Vector2.ZERO, 25, 0, TAU, 24, Color("0b1320"), 6.0)
		draw_arc(Vector2.ZERO, 25, 0, TAU, 24, colors.get(family, Color.WHITE), 2.5)
	if boss and debug_archetypes:
		draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color.GOLD, 3.0)
	if variant == "shieldbearer":
		draw_arc(Vector2.ZERO, 32, facing.angle() - 0.95, facing.angle() + 0.95, 16, Color(0.7, 0.85, 1), 5.0)
	if warning > 0.0:
		var line_direction = action_direction if variant != "mortar" else (action_direction - global_position).normalized()
		draw_line(Vector2.ZERO, line_direction * 100.0, Color(1, 0.2, 0.1, 0.8), 4.0)
