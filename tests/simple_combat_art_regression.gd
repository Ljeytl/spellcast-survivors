extends SceneTree

var checks = 0
var failures = 0
var stage: Node2D
var player: Node2D

class Caster extends Node2D:
	var health = 50.0
	var max_health = 100.0
	var heals: Array = []
	func heal(amount):
		health = minf(max_health, health + amount)
	func start_healing_over_time(amount, duration):
		heals.append([amount, duration])

class Target extends Node2D:
	var current_health = 1000.0
	var dying = false
	var hits = 0
	func take_damage(amount, _from = Vector2.ZERO):
		current_health = maxf(0, current_health - amount)
		hits += 1

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func target_at(point):
	var target = Target.new()
	stage.add_child(target)
	target.position = point
	target.add_to_group("enemies")
	var box = Area2D.new()
	box.name = "HurtBox"
	target.add_child(box)
	return target

func effect(data, target = null, tactical = false):
	var node = load("res://scripts/TacticalSpellEffect.gd" if tactical else "res://scripts/BuildSpellEffect.gd").new()
	stage.add_child(node)
	node.configure(data, 20, player, target)
	node.set_physics_process(false)
	return node

func projectile(kind):
	var node = load("res://scenes/SpellProjectile.tscn").instantiate()
	stage.add_child(node)
	node.setup(Vector2.ZERO, Vector2.RIGHT, 10, Color.WHITE, kind)
	node.set_process(false)
	return node

func clear_effects():
	for child in stage.get_children():
		if child != player:
			child.free()

func run():
	stage = Node2D.new()
	root.add_child(stage)
	current_scene = stage
	player = Caster.new()
	stage.add_child(player)
	player.add_to_group("player")
	var enemy = target_at(Vector2(100, 0))
	var plague = effect({"type": "plague", "duration": 5.0}, enemy)
	check(plague.infection_links.size() == 1, "Seed-to-host link exists at cast")
	var neighbor = target_at(Vector2(150, 0))
	plague.advance(0.5)
	check(plague.infections.size() == 2 and plague.infection_links.size() == 1, "Spread produces a real transfer link")
	plague.advance(0.4)
	check(plague.infection_links.is_empty(), "Transfer feedback expires")
	clear_effects()
	var trap = effect({"type": "trap", "duration": 6.0}, null, true)
	trap.advance(60)
	check(not trap.is_queued_for_deletion() and not trap.triggered, "Untriggered trap survives beyond old expiry")
	enemy = target_at(trap.position)
	trap.advance(0.05)
	check(trap.triggered and enemy.hits == 1, "Persistent trap still triggers once")
	trap.advance(1)
	check(trap.is_queued_for_deletion() and enemy.hits == 1, "Triggered trap ends promptly")
	clear_effects()
	for speed in [1.0, 2.0]:
		enemy = target_at(Vector2(100, 0))
		var blade = effect({"type": "returning", "duration": 3.0, "projectile_speed_multiplier": speed}, enemy, true)
		blade.advance(0.7 / speed)
		check(is_equal_approx(blade.position.x, 350), "Speed buff preserves outbound range")
		check(enemy.hits == 1, "Outbound path hits once")
		blade.advance(0.2)
		check(is_equal_approx(blade.position.x, 350), "Blade visibly lingers before return")
		blade.advance(1.5)
		check(enemy.hits == 2 and blade.is_queued_for_deletion(), "Return contributes second useful hit")
		clear_effects()
	enemy = target_at(Vector2(300, 0))
	var spirit = effect({"type": "spirit", "duration": 5.0, "projectile_speed_multiplier": 2.0}, enemy, true)
	spirit.advance(0.2)
	check(is_equal_approx(spirit.position.x, 128), "Seeker uses projectile-speed snapshot")
	check(enemy.hits == 0, "Seeker cannot damage before arriving")
	clear_effects()
	enemy = target_at(Vector2(40, 0))
	neighbor = target_at(Vector2(100, 0))
	var third = target_at(Vector2(160, 0))
	var bolt = projectile("lightning_bolt")
	bolt.set_meta("bounce_count", 2)
	bolt.set_meta("bounce_range", 240.0)
	bolt._on_area_entered(enemy.get_node("HurtBox"))
	check(bolt.target == neighbor and enemy.hits == 1, "Bounce acquires nearest living unhit target")
	bolt._on_area_entered(enemy.get_node("HurtBox"))
	check(enemy.hits == 1, "Bounce cannot repeat target")
	bolt.position = neighbor.position
	bolt._on_area_entered(neighbor.get_node("HurtBox"))
	check(bolt.target == third and not bolt.despawning, "Second bounce reaches third target")
	bolt.position = third.position
	bolt._on_area_entered(third.get_node("HurtBox"))
	check(bolt.despawning and third.hits == 1, "Bounce limit despawns after three hits")
	clear_effects()
	enemy = target_at(Vector2(40, 0))
	neighbor = target_at(Vector2(100, 0))
	neighbor.dying = true
	bolt = projectile("lightning_bolt")
	bolt.set_meta("bounce_count", 2)
	bolt._on_area_entered(enemy.get_node("HurtBox"))
	check(bolt.despawning, "No eligible bounce ends projectile")
	clear_effects()
	enemy = target_at(Vector2(100, 0))
	bolt = projectile("life_bolt")
	bolt.position = enemy.position
	bolt._on_area_entered(enemy.get_node("HurtBox"))
	await process_frame
	var seeds = get_nodes_in_group("healing_seeds")
	check(seeds.size() == 1 and player.heals.is_empty(), "Actual Life Bolt hit leaves seed without remote healing")
	var seed = seeds[0]
	seed.set_physics_process(false)
	player.position = seed.position
	player.health = player.max_health
	seed._physics_process(0.1)
	check(not seed.is_queued_for_deletion() and player.heals.is_empty(), "Full health does not waste seed")
	player.health = 50
	seed._physics_process(0.1)
	check(seed.is_queued_for_deletion() and player.heals == [[6.0, 2.0]], "Pickup grants brief six-HP healing over time")
	clear_effects()
	for index in range(8):
		seed = load("res://scripts/HealingSeed.gd").new()
		seed.player_ref = weakref(player)
		stage.add_child(seed)
		seed.set_physics_process(false)
	check(get_nodes_in_group("healing_seeds").filter(func(item): return not item.is_queued_for_deletion()).size() == 6, "World seeds bounded to six per owner")
	seed.position = Vector2(1000, 0)
	seed._physics_process(11)
	check(seed.is_queued_for_deletion(), "Uncollected seed expires")
	clear_effects()
	var particles = load("res://scripts/ParticleManager.gd").new()
	stage.add_child(particles)
	var visual = projectile("meteor")
	enemy = target_at(Vector2.ZERO)
	visual._on_area_entered(enemy.get_node("HurtBox"))
	check(enemy.hits == 0, "Visual-only impacts never inflict extra collision damage")
	var pooled = projectile("life_bolt")
	pooled.set_meta("healing_seed_owner", weakref(player))
	pooled.set_meta("bounce_count", 2)
	pooled.hit_ids[123] = true
	pooled.reset_for_pool()
	check(not pooled.has_meta("healing_seed_owner") and not pooled.has_meta("bounce_count") and pooled.hit_ids.is_empty(), "Pooling clears seed and bounce ownership")
	var cone = particles.create_directional_effect(Vector2.ZERO, Vector2.RIGHT, "ice_blast", 200, PI / 4)
	check(cone.half_angle == PI / 4 and cone.radius == 200, "Cone feedback receives exact reach and angle")
	for index in range(150):
		particles.create_spell_impact_effect(Vector2.ZERO)
	check(particles.get_child_count() == 100, "Cosmetic feedback budget bounded")
	var warning = particles.create_attack_warning(Vector2.ZERO, 120, 1)
	check(is_instance_valid(warning), "Critical hazard telegraph survives cosmetic saturation")
	await process_frame
	stage.queue_free()
	await process_frame
	print("Simple combat art regression: %s checks, %s failures" % [checks, failures])
	quit(1 if failures else 0)
