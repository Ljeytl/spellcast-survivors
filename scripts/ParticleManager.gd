extends Node2D
class_name ParticleManager

const Burst = preload("res://scripts/EffectBurst.gd")
var particle_pool: Dictionary = {}
var max_pool_size = 12
var reduced_effects = false

func get_pooled_particle(type: String) -> GPUParticles2D:
	if not particle_pool.has(type):
		particle_pool[type] = []
	for particle in particle_pool[type]:
		var timer = particle.get_node_or_null("EmissionTimeout")
		if not particle.emitting and (not timer or timer.is_stopped()):
			return particle
	if particle_pool[type].size() >= max_pool_size:
		return null
	var particle = GPUParticles2D.new()
	particle.one_shot = true
	particle.emitting = false
	particle.amount = 4
	particle.lifetime = 0.3
	particle_pool[type].append(particle)
	add_child(particle)
	return particle

func auto_cleanup_particle(particle: GPUParticles2D, delay: float):
	var timer = particle.get_node_or_null("EmissionTimeout")
	if not timer:
		timer = Timer.new()
		timer.name = "EmissionTimeout"
		timer.one_shot = true
		timer.timeout.connect(func(): particle.emitting = false)
		particle.add_child(timer)
	timer.start(maxf(delay, particle.lifetime))

func spawn_effect(pos: Vector2, kind: String, radius: float = 24.0, duration: float = 0.35, particle_size: float = 18.0):
	if get_child_count() >= (40 if reduced_effects else 100):
		return null
	var effect = Burst.new()
	effect.kind = kind
	effect.radius = radius
	effect.duration = duration
	effect.particle_size = particle_size
	add_child(effect)
	effect.global_position = pos
	return effect

func create_spell_effect(pos: Vector2, effect_type: String, scale_factor: float = 1.0):
	return spawn_effect(pos, effect_type, 24 * scale_factor)

func create_directional_effect(pos: Vector2, direction: Vector2, effect_type: String, reach: float, half_angle: float = 0.0):
	var effect = spawn_effect(pos, "ice" if effect_type in ["ice", "ice_blast"] else "lightning", reach, 0.3)
	if effect:
		effect.mode = "directional"
		effect.direction = direction.normalized()
		effect.half_angle = half_angle
	return effect

func create_link_effect(from: Vector2, to: Vector2, effect_type: String):
	var effect = spawn_effect(from, effect_type, 12, 0.35)
	if effect:
		effect.mode = "link"
		effect.endpoint = to - from
	return effect

func follow_effect(target: Node2D, duration: float, kind: String, radius: float):
	var effect = spawn_effect(target.global_position, kind, radius, duration)
	if effect:
		effect.followed = weakref(target)
		effect.mode = "follow"
	return effect

func create_persistent_life_circle(target: Node2D, duration: float):
	return follow_effect(target, duration, "heal", 24)

func create_persistent_shield_circle(target: Node2D, duration: float):
	for effect in get_children():
		if effect is Burst and effect.kind == "stone" and effect.followed and effect.followed.get_ref() == target:
			effect.queue_free()
	return follow_effect(target, duration, "stone", 30)

func create_persistent_lightning_arc(from_target: Node2D, to_pos: Vector2, duration: float = 1.0, _to_target: Node2D = null):
	var effect = create_link_effect(from_target.global_position, to_pos, "lightning")
	if effect:
		effect.duration = minf(duration, 0.3)

func create_expanding_circle(pos: Vector2, max_radius: float, color: Color, duration: float, _fade_out: bool = true):
	return spawn_effect(pos, ["flame", "ice", "heal", "impact"][preload("res://scripts/EffectArt.gd").row_for_color(color)], max_radius, duration)

func create_spell_cast_effect(pos: Vector2):
	return spawn_effect(pos, "mana", 14)

func create_enemy_death_effect(pos: Vector2):
	return spawn_effect(pos, "smoke", 28, 0.35, 22)

func create_xp_collect_effect(pos: Vector2):
	return spawn_effect(pos, "xp", 12, 0.25, 10)

func create_spell_impact_effect(pos: Vector2):
	return spawn_effect(pos, "impact", 18, 0.3, 20)

func create_heal_effect(pos: Vector2):
	return spawn_effect(pos, "heal", 20)

func create_hurt_effect(pos: Vector2):
	return spawn_effect(pos, "hostile", 20)

func create_mana_bolt_effect(pos: Vector2):
	return spawn_effect(pos, "mana", 12)

func create_bolt_effect(pos: Vector2):
	return spawn_effect(pos, "bolt", 16)

func create_life_effect(pos: Vector2):
	return spawn_effect(pos, "heal", 24)

func create_ice_blast_effect(pos: Vector2):
	return spawn_effect(pos, "ice", 24)

func create_earthshield_effect(pos: Vector2):
	return spawn_effect(pos, "stone", 28)

func create_lightning_arc_effect(pos: Vector2):
	return spawn_effect(pos, "lightning", 24)

func create_meteor_shower_effect(pos: Vector2):
	return spawn_effect(pos, "flame", 90)

func create_level_up_effect(pos: Vector2):
	return spawn_effect(pos, "xp", 40)

func create_spell_unlock_effect(pos: Vector2):
	return spawn_effect(pos, "impact", 32)

func create_boss_death_effect(pos: Vector2):
	return spawn_effect(pos, "smoke", 70, 0.35, 28)

func create_powerful_spell_effect(pos: Vector2, spell_name: String):
	return spawn_effect(pos, "flame" if "meteor" in spell_name else "impact", 45)

func create_elite_spawn_effect(pos: Vector2, _elite_type: String):
	return spawn_effect(pos, "impact", 24)

func create_attack_warning(pos: Vector2, radius: float, delay: float, _attack_type: String = "danger"):
	var effect = Burst.new()
	effect.mode = "warning"
	effect.radius = radius
	effect.duration = delay
	add_child(effect)
	effect.global_position = pos
	return effect

func create_aoe_telegraph(pos: Vector2, radius: float, charge_time: float, _danger_color: Color = Color.RED):
	return create_attack_warning(pos, radius, charge_time)

func create_projectile_warning(from_pos: Vector2, to_pos: Vector2, delay: float):
	var effect = Burst.new()
	effect.mode = "link"
	effect.kind = "hostile"
	effect.endpoint = to_pos - from_pos
	effect.duration = delay
	add_child(effect)
	effect.global_position = from_pos
	return effect
