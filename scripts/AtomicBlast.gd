extends Node2D

func _init():
	DamageSource.stamp(self)

const GameData = preload("res://scripts/core/GameData.gd")
## Numbers from data/abilities.json (atomic).
static var WARNING_SECONDS: float = float(GameData.file("abilities").abilities.atomic.warning)
static var AFTERGLOW_SECONDS: float = float(GameData.file("abilities").abilities.atomic.afterglow)
static var BOSS_HEALTH_FRACTION: float = float(GameData.file("abilities").abilities.atomic.boss_health_fraction)

var footprint := Rect2()
var origin := Vector2.ZERO
var reach := 0.0
var game: Node
var elapsed := 0.0
var impacted := false
var configured := false
var reduced_effects := false
var pulse: ColorRect
var pulse_material: ShaderMaterial

func configure(source_game: Node) -> void:
	game = source_game
	var viewport := game.get_viewport()
	footprint = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	origin = game.player.global_position
	for corner in [footprint.position, footprint.end, Vector2(footprint.end.x, footprint.position.y), Vector2(footprint.position.x, footprint.end.y)]:
		reach = maxf(reach, origin.distance_to(corner))
	configured = true
	_read_reduced_effects()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 90
	if not configured:
		queue_free()
	else:
		pulse = ColorRect.new()
		var visual_radius := reach + 160.0
		pulse.position = origin - Vector2.ONE * visual_radius
		pulse.size = Vector2.ONE * visual_radius * 2.0
		pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pulse_material = ShaderMaterial.new()
		pulse_material.shader = preload("res://scripts/vfx/atomic_pulse.gdshader")
		pulse_material.set_shader_parameter("extent", pulse.size)
		pulse_material.set_shader_parameter("center", origin - pulse.position)
		pulse_material.set_shader_parameter("warning", WARNING_SECONDS)
		pulse_material.set_shader_parameter("reach", reach)
		pulse.material = pulse_material
		add_child(pulse)
		get_node("/root/AudioManager").play_sound(load("res://scripts/AudioManager.gd").SoundType.MEGA_CHARGE, 0.4, 0.75)

func _read_reduced_effects() -> void:
	if not is_instance_valid(game):
		return
	var manager = game.get("particle_manager")
	if is_instance_valid(manager):
		reduced_effects = bool(manager.get("reduced_effects"))

func _process(delta: float) -> void:
	elapsed += delta
	_read_reduced_effects()
	if elapsed >= WARNING_SECONDS and not impacted:
		_impact()
	if elapsed >= WARNING_SECONDS + AFTERGLOW_SECONDS:
		queue_free()
	if pulse_material:
		pulse_material.set_shader_parameter("age", elapsed)
		pulse_material.set_shader_parameter("strength", 0.35 if reduced_effects else 1.0)
	queue_redraw()

func _impact() -> void:
	if impacted:
		return
	impacted = true
	get_node("/root/AudioManager").play_sound(load("res://scripts/AudioManager.gd").SoundType.MEGA_RELEASE, 0.85, 0.75)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
			continue
		if not footprint.has_point(enemy.global_position) or not enemy.has_method("take_damage"):
			continue
		var health = enemy.get("current_health")
		if health == null or float(health) <= 0.0:
			continue
		var damage := float(health)
		if enemy.is_in_group("bosses"):
			damage = float(enemy.get("max_health")) * BOSS_HEALTH_FRACTION
		else:
			# Atomic deals pure damage (data/spell_damage.json), which no resistance reduces.
			damage += 1.0
		var source = DamageSource.of(self).duplicate()
		source.spell = "atomic"  # always pure damage, even when the blast was made without a cast source
		enemy.take_damage(damage, Vector2.INF, source)
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(projectile) and projectile is Node2D and footprint.has_point(projectile.global_position):
			projectile.queue_free()
	if not reduced_effects and is_instance_valid(game) and game.has_method("shake_heavy"):
		game.shake_heavy()

func overlay_bounds() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect().grow(32.0)

func _draw() -> void:
	if not configured:
		return
	if not impacted:
		var t := clampf(elapsed / WARNING_SECONDS, 0.0, 1.0)
		draw_rect(overlay_bounds(), Color(0.035, 0.012, 0.065, t * (0.15 if reduced_effects else 0.48)))
	else:
		var age := elapsed - WARNING_SECONDS
		if not reduced_effects and age < 0.065:
			draw_rect(overlay_bounds(), Color(0.97, 0.90, 1.0, pow(1.0 - age / 0.065, 2.0) * 0.48))
