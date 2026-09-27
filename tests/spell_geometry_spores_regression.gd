extends SceneTree

class Host extends Node2D:
	signal enemy_died(enemy)
	var current_health = 1000.0
	var dying = false
	var delayed = false
	func take_damage(amount: float, _origin = Vector2.ZERO):
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

func effect(type: String, target = null, extra: Dictionary = {}):
	var data = {"type": type, "duration": 1.0, "tick_interval": 0.1}
	data.merge(extra, true)
	var node = load("res://scripts/TacticalSpellEffect.gd" if type in ["beam", "trail", "returning", "trap", "spirit"] else "res://scripts/BuildSpellEffect.gd").new()
	node.configure(data, 10.0, caster, target)
	root.add_child(node)
	node.set_physics_process(false)
	nodes.append(node)
	return node

func run():
	root.get_node("AudioManager").quitting = true
	caster = Caster.new()
	root.add_child(caster)
	caster.add_to_group("player")
	for scale in [1.0, 2.0]:
		caster.spell_size_multiplier = 1.0 if "--known-bad-size" in OS.get_cmdline_user_args() else scale
		for type in ["field", "trail", "trap", "beam", "piercing", "returning", "spirit", "orbit"]:
			var radius = {"field":150, "trail":65, "trap":130, "beam":20, "piercing":24, "returning":42, "spirit":24, "orbit":42}[type] * scale
			var center = Vector2.ZERO
			if type == "trap": center = Vector2(160, 0)
			if type == "orbit": center = Vector2(130, 0)
			var inside = host(center + Vector2(0, radius - 0.1))
			var outside = host(center + Vector2(0, radius + 0.1))
			var node = effect(type, null, {"arm_delay":0.0,"angular_speed":0.0,"orb_count":1})
			match type:
				"trap":
					host(center)
					node.advance_trap()
				"beam":
					node.target_ref = null
					inside.position.x = 100
					outside.position.x = 100
					var guide = host(Vector2(300,0))
					node.target_ref = weakref(guide)
					node.info.beam_targets = 5
					node.tick_remaining = 0
					node.advance_beam(0.01, caster)
				"spirit":
					node.target_ref = weakref(inside)
					node.advance_spirit(0, caster)
					node.strike_ready = 0
					node.target_ref = weakref(outside)
					node.advance_spirit(0, caster)
				"orbit": node.advance_orbit(0.01)
				"returning": node.advance_returning(0, caster)
				_: node.advance(0.11)
			check(inside.current_health < 1000, "%s %sx hits just inside visible body" % [type, scale])
			check(outside.current_health == 1000, "%s %sx misses just outside visible body" % [type, scale])
			clear()
		var ice = load("res://scripts/IceBlast.gd").new()
		ice.configure(Vector2.ZERO, Vector2.RIGHT, 400, 10, 0, 1, 0.5, 1, scale)
		root.add_child(ice)
		ice.set_physics_process(false)
		nodes.append(ice)
		var inside = host(Vector2(50, 12 * scale - 0.1))
		var outside = host(Vector2(50, 12 * scale + 0.1))
		check(ice.contact_fraction(inside, Vector2.ZERO, Vector2(100,0)) >= 0, "Ice shard inside boundary")
		check(ice.contact_fraction(outside, Vector2.ZERO, Vector2(100,0)) < 0, "Ice shard outside boundary")
		clear()
	caster.spell_size_multiplier = 1
	var first = host(Vector2.ZERO)
	var plague = effect("plague", first)
	plague.advance(0.9)
	first.take_damage(2000)
	if "--known-bad-spores" in OS.get_cmdline_user_args():
		plague.resting_spores.clear()
		plague.remaining = 0.01
	check(plague.resting_spores.size() == 1, "Other spell kill leaves one resting spore near original expiry")
	plague._on_infected_host_died(first)
	check(plague.resting_spores.size() == 1, "Duplicate death notification does not duplicate spore")
	plague.advance(2.9)
	check(not plague.is_queued_for_deletion(), "Resting spore survives original cast lifetime")
	var second = host(Vector2(120,0))
	plague.advance(0.025)
	check(second.current_health == 1000 and plague.infection_links.size() == 1, "Spore launches without instant infection")
	plague.advance(0.5)
	check(second.current_health < 1000, "Late recipient takes infection damage after arrival beyond original lifetime")
	clear()
	first = host(Vector2.ZERO)
	first.current_health = 5
	plague = effect("plague", first)
	plague.advance(0.2)
	check(plague.resting_spores.size() == 1, "Plague kill leaves resting spore")
	plague.advance(3.1)
	check(plague.resting_spores.is_empty() and plague.is_queued_for_deletion(), "Unclaimed spore expires and effect ends")
	clear()
	first = host(Vector2.ZERO)
	first.delayed = true
	plague = effect("plague", first)
	plague.advance(0.1)
	first.take_damage(2000)
	plague.advance(0.025)
	check(plague.resting_spores.size() == 1, "Delayed death signal detected through dead host state")
	first.enemy_died.emit(first)
	check(plague.resting_spores.size() == 1, "Delayed signal cannot duplicate transfer")
	clear()
	first = host(Vector2(100,0))
	plague = effect("plague", first)
	first.take_damage(2000)
	plague.advance(0.025)
	check(plague.resting_spores.size() == 1, "Pending target dies: traveling spore rests")
	clear()
	first = host(Vector2.ZERO)
	plague = effect("plague", first, {"duration":2.0})
	for index in range(15): host(Vector2(index + 1, 0))
	plague.advance(1.5)
	check(plague.hosts_started == 8 and plague.infections.size() + plague.infection_links.size() + plague.resting_spores.size() <= 8, "Finite eight-host cast budget bounds all spore states")
	clear()
	first = host(Vector2(200, 0))
	plague = effect("plague", first)
	var deadline = plague.infection_links[0].expires
	for index in range(9):
		first.take_damage(2000)
		first = host(Vector2(200,0))
		plague.advance(0.01)
	check(plague.hosts_started == 0 and plague.infection_links.size() == 1, "Failed pending targets do not consume infection budget")
	check(is_equal_approx(plague.infection_links[0].expires, deadline), "Retargeting preserves absolute pending deadline")
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
