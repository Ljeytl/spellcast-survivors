extends SceneTree

class Host extends Node2D:
	signal enemy_died(enemy)
	var current_health = 1000.0
	var dying = false
	var delayed = false
	func take_damage(amount: float, _origin = Vector2.ZERO, _damage_source = {}):
		current_health = maxf(0, current_health - amount)
		if current_health <= 0:
			dying = true
			if not delayed:
				enemy_died.emit(self)
	func apply_slow(_amount, _duration): pass
	func apply_knockback(_direction, _amount): pass

class Caster extends Node2D:
	var spell_size_multiplier = 1.0
	var health = 100.0
	func heal(_amount): pass

var checks = 0
var failures = 0
var caster
var nodes: Array = []

func _initialize():
	run.call_deferred()

func check(condition, label):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func host(point: Vector2):
	var node = Host.new()
	root.add_child(node)
	node.position = point
	node.add_to_group("enemies")
	nodes.append(node)
	return node

func clear():
	for node in nodes:
		if is_instance_valid(node): node.free()
	nodes.clear()

## Every shipping spell runs on the generic engine (doc 18 phase 2): build a cast from data.
func generic(info: Dictionary, damage: float, aim = null):
	var scaled = load("res://scripts/SpellGeometry.gd").scaled_data(info, caster)
	var def = load("res://scripts/engine/SpellTemplate.gd").build(scaled, damage, {})
	var cast = load("res://scripts/engine/GenericCast.gd").new()
	cast.forced_target = aim
	cast.setup(load("res://scripts/engine/CastPlanner.gd").plan(def, {}, {}), caster, root, {"spell": str(info.id)}, true)
	root.add_child(cast)
	nodes.append(cast)
	cast.step(0.0)
	return cast

## Infestation's plague state (scripts/engine/Infection.gd); spore_linger 3 as the old fixture default.
func plague_on(first, extra: Dictionary = {}):
	var data = {"id": "infestation", "type": "plague", "duration": 1.0, "tick_interval": 0.1, "spore_linger": 3.0}
	data.merge(extra, true)
	return generic(data, 10.0, first)

func spores(cast) -> Array:
	return cast.parts[0].infection.spores if not cast.parts.is_empty() else []

func run():
	root.get_node("AudioManager").quitting = true
	caster = Caster.new()
	root.add_child(caster)
	caster.add_to_group("player")
	for scale in [1.0, 2.0]:
		caster.spell_size_multiplier = 1.0 if "--known-bad-size" in OS.get_cmdline_user_args() else scale
		# Ember Spear runs on the generic engine (doc 18 phase 2); same hitbox as its old body.
		var spear_r = 24.0 * scale
		var Bridge = load("res://scripts/engine/SpellTemplate.gd")
		var spear_def = Bridge.build({"id": "ember_spear", "type": "piercing", "spear_radius": 24.0, "projectile_size_multiplier": scale}, 10.0, {})
		var spear_cast = load("res://scripts/engine/GenericCast.gd").new()
		spear_cast.setup(load("res://scripts/engine/CastPlanner.gd").plan(spear_def, {}, {}), caster, root, {"spell": "ember_spear"}, true)
		root.add_child(spear_cast)
		nodes.append(spear_cast)
		spear_cast.step(1.0 / 60.0)  # no enemies yet: the spear flies right (caster facing)
		var tip = spear_cast.parts[0].global_position
		var spear_in = host(tip + Vector2(5, spear_r - 0.1))
		var spear_out = host(tip + Vector2(5, -spear_r - 0.1))
		spear_cast.step(1.0 / 60.0)
		check(spear_in.current_health < 1000, "piercing %sx hits just inside visible body" % scale)
		check(spear_out.current_health == 1000, "piercing %sx misses just outside visible body" % scale)
		clear()
		var ids = {"field": "cinder_field", "trail": "firewalk", "trap": "rune_trap", "beam": "focus_ray", "returning": "cross_blade", "spirit": "seeker", "orbit": "arcane_orbit"}
		for type in ["field", "trail", "trap", "beam", "returning", "spirit", "orbit"]:
			var radius = {"field":150, "trail":65, "trap":130, "beam":20, "returning":33.6, "spirit":24, "orbit":42}[type] * scale
			var center = Vector2.ZERO
			if type == "trap": center = Vector2(160, 0)
			if type == "orbit": center = Vector2(130 * scale, 0)
			if type == "beam": center = Vector2(100, 0)
			var inside = host(center + Vector2(0, radius - 0.1))
			var outside = host(center + Vector2(0, radius + 0.1))
			var cast = generic({"id": ids[type], "type": type, "duration": 1.0, "tick_interval": 0.1, "arm_delay": 0.0, "angular_speed": 0.0, "orb_count": 1, "blade_count": 1}, 10.0)
			# The part that deals the damage, placed where the old fixture measured it.
			var part
			match type:
				"trail":
					part = cast.parts.filter(func(p): return p.part_name == "patch")[0]
				"trap":
					part = cast._make_part("burst", center, Vector2.RIGHT, 1, 1.0, 1.0)
				_:
					part = cast.root_parts()[0]
			part.global_position = Vector2.ZERO if type == "beam" else center
			part.direction = Vector2.RIGHT
			check(part.contains(inside.global_position, part.pad_for(inside)), "%s %sx hits just inside visible body" % [type, scale])
			check(not part.contains(outside.global_position, part.pad_for(outside)), "%s %sx misses just outside visible body" % [type, scale])
			clear()
		var ice = generic({"id": "ice_blast", "type": "aoe", "radius": 400}, 10.0)
		var shard = ice.root_parts()[0]
		shard.prev_pos = Vector2.ZERO
		shard.global_position = Vector2(100, 0)
		var inside = host(Vector2(50, 12 * scale - 0.1))
		var outside = host(Vector2(50, 12 * scale + 0.1))
		check(shard._swept_contains(inside), "Ice shard inside boundary")
		check(not shard._swept_contains(outside), "Ice shard outside boundary")
		clear()
	caster.spell_size_multiplier = 1
	var first = host(Vector2.ZERO)
	var plague = plague_on(first)
	plague.advance(0.9)
	first.take_damage(2000)
	plague.advance(0.025)
	check(spores(plague).size() == 1, "Other spell kill leaves one resting spore near original expiry")
	first.enemy_died.emit(first)
	plague.advance(0.025)
	check(spores(plague).size() == 1, "Duplicate death notification does not duplicate spore")
	plague.advance(2.85)
	check(not plague.finished, "Resting spore survives original cast lifetime")
	var second = host(Vector2(120,0))
	plague.advance(0.025)
	check(second.current_health == 1000 and plague.parts[0].infection.links.size() == 1, "Spore launches without instant infection")
	plague.advance(0.5)
	check(second.current_health < 1000, "Late recipient takes infection damage after arrival beyond original lifetime")
	clear()
	first = host(Vector2.ZERO)
	first.current_health = 5
	plague = plague_on(first)
	plague.advance(0.2)
	check(spores(plague).size() == 1, "Plague kill leaves resting spore")
	plague.advance(3.1)
	check(spores(plague).is_empty() and plague.finished, "Unclaimed spore expires and effect ends")
	clear()
	first = host(Vector2.ZERO)
	first.delayed = true
	plague = plague_on(first)
	plague.advance(0.1)
	first.take_damage(2000)
	plague.advance(0.025)
	check(spores(plague).size() == 1, "Delayed death signal detected through dead host state")
	first.enemy_died.emit(first)
	plague.advance(0.025)
	check(spores(plague).size() == 1, "Delayed signal cannot duplicate transfer")
	clear()
	first = host(Vector2(100,0))
	plague = plague_on(first)
	first.take_damage(2000)
	plague.advance(0.025)
	check(spores(plague).size() == 1, "Pending target dies: traveling spore rests")
	clear()
	first = host(Vector2.ZERO)
	plague = plague_on(first, {"duration": 2.0})
	var spread = plague.parts[0].infection
	for index in range(15): host(Vector2(index + 1, 0))
	plague.advance(2.5)
	check(spread.hosts_started > 8, "A cast can spread beyond eight hosts")
	clear()
	first = host(Vector2(200, 0))
	plague = plague_on(first)
	spread = plague.parts[0].infection
	var deadline = spread.links[0].expires
	for index in range(9):
		first.take_damage(2000)
		first = host(Vector2(200,0))
		plague.advance(0.01)
	check(spread.hosts_started == 0 and spread.links.size() == 1, "Failed pending targets do not consume infection budget")
	check(not spread.links.is_empty() and is_equal_approx(spread.links[0].expires, deadline), "Retargeting preserves absolute pending deadline")
	clear()
	caster.spell_size_multiplier = 1
	var projectile = load("res://scenes/SpellProjectile.tscn").instantiate()
	root.add_child(projectile)
	projectile.set_process(false)
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, 10, Color.WHITE, "bolt")
	check(is_equal_approx(projectile.get_node("CollisionShape2D").shape.radius, 12.75), "Bolt base collision follows visible width")
	caster.spell_size_multiplier = 2
	projectile.reset_for_pool()
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, 10, Color.WHITE, "bolt")
	check(is_equal_approx(projectile.get_node("CollisionShape2D").shape.radius, 25.5) and projectile.spell_size == 1.5, "Pooled bolt refreshes collision and artwork after upgrade")
	projectile.free()
	projectile = load("res://scenes/SpellProjectile.tscn").instantiate()
	projectile.add_to_group("enemy_projectiles")
	root.add_child(projectile)
	projectile.setup(Vector2.ZERO, Vector2.RIGHT, 10, Color.RED, "enemy_shot")
	check(projectile.spell_size == 1 and projectile.get_node("CollisionShape2D").shape.radius == 8, "Hostile shot does not inherit player size")
	projectile.free()
	for size in [1.0, 2.0]:
		caster.spell_size_multiplier = size
		for inside in [true, false]:
			var victim = host(Vector2(0, 12.75 * size + (0.5 if inside else 2.0)))
			var hurtbox = Area2D.new()
			hurtbox.name = "HurtBox"
			hurtbox.collision_layer = 4
			hurtbox.collision_mask = 16
			var shape = CollisionShape2D.new()
			shape.shape = RectangleShape2D.new()
			shape.shape.size = Vector2(2,2)
			hurtbox.add_child(shape)
			victim.add_child(hurtbox)
			var bolt = load("res://scenes/SpellProjectile.tscn").instantiate()
			root.add_child(bolt)
			bolt.setup(Vector2.ZERO, Vector2.RIGHT, 10, Color.WHITE, "bolt")
			bolt.speed = 0
			for frame in range(4): await physics_frame
			check((victim.current_health < 1000) == inside, "Actual bolt physics boundary %sx inside=%s" % [size, inside])
			if is_instance_valid(bolt): bolt.free()
			clear()
	var player = load("res://scripts/Player.gd").new()
	for family in ["spell_area", "spell_damage", "movement_speed", "xp_range", "projectile_speed", "slowdown_duration"]:
		check(player.apply_upgrade({"effect":{"type":family,"value":0.12}}), "Passive acquired: " + family)
	check(player.passive_ranks.size() == 6 and not player.can_acquire_passive("max_health"), "Spell Size uses one of six passive slots")
	check(player.apply_upgrade({"effect":{"type":"spell_area","value":0.12}}) and is_equal_approx(player.spell_size_multiplier, 1.24), "Existing Spell Size can upgrade at six-slot cap")
	player.free()
	print("Spell geometry/spores: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
