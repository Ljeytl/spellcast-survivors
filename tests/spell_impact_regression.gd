extends SceneTree

var checks = 0
var failures = 0
var arena: Node2D
var player: Node2D

class Target extends Node2D:
	var current_health = 1000.0
	var dying = false
	var slow = false
	var pushed = false
	signal enemy_died(enemy)
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health -= amount
		if current_health <= 0:
			dying = true
			enemy_died.emit(self)
	func apply_slow(_strength, _duration):
		slow = true
	func apply_knockback(_direction, _strength):
		pushed = true

func _initialize():
	run.call_deferred()

func check(value, label):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func target(point: Vector2):
	var result = Target.new()
	arena.add_child(result)
	result.position = point
	result.add_to_group("enemies")
	return result

func clear():
	if is_instance_valid(arena):
		arena.free()
	arena = Node2D.new()
	root.add_child(arena)
	player = Node2D.new()
	arena.add_child(player)

func ice():
	var effect = preload("res://scripts/IceBlast.gd").new()
	effect.configure(Vector2.ZERO, Vector2.RIGHT, 400, 30, 200, 2, 0.6, 1)
	arena.add_child(effect)
	effect.set_physics_process(false)
	return effect

func plague(host, type = "plague_seed"):
	var effect = preload("res://scripts/BuildSpellEffect.gd").new()
	effect.configure({"id": type, "type": "plague", "duration": 5, "tick_interval": 0.5, "cast_range": 300}, 9, player, host)
	arena.add_child(effect)
	effect.set_physics_process(false)
	return effect

func run():
	root.get_node("AudioManager").quitting = true
	clear()
	var first = target(Vector2(200, 0))
	var miss = target(Vector2.from_angle(PI / 48) * 390)
	var behind = target(Vector2(-100, 0))
	var effect = ice()
	if "--known-bad-early-damage" in OS.get_cmdline_user_args():
		first.take_damage(30)
	check(first.current_health == 1000 and not first.slow, "Ice launch applies no damage or slow")
	effect.advance(0.1)
	check(first.current_health == 1000, "Visible travel precedes contact")
	effect.advance(0.25)
	check(first.current_health == 970 and first.slow and first.pushed, "Swept shard impact applies damage slow and push")
	effect.advance(0.3)
	check(first.current_health == 970, "Overlapping shards cannot multiply per-cast damage")
	check(miss.current_health == 1000 and behind.current_health == 1000, "Gaps between shards and behind caster miss")
	clear()
	var body = target(Vector2(200, 60))
	var hurtbox = Area2D.new()
	hurtbox.name = "HurtBox"
	body.add_child(hurtbox)
	var shape = CollisionShape2D.new()
	shape.name = "HurtBoxShape"
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(64, 64)
	hurtbox.add_child(shape)
	effect = ice()
	check(effect.contact_fraction(body, Vector2.ZERO, Vector2(300, 0)) < 0, "Small hurtbox outside shard path misses")
	body.scale = Vector2.ONE * 2
	check(effect.contact_fraction(body, Vector2.ZERO, Vector2(300, 0)) >= 0, "Large real hurtbox edge receives swept contact")
	body.position.y = 100
	check(effect.contact_fraction(body, Vector2.ZERO, Vector2(300, 0)) < 0, "Large hurtbox still misses a true gap")
	for spell_id in ["plague_seed", "soul_bloom"]:
		clear()
		first = target(Vector2(200, 0))
		var neighbor = target(Vector2(270, 0))
		effect = plague(first, spell_id)
		check(effect.infections.is_empty() and effect.infection_links.size() == 1, spell_id + " launches visible spore without marker")
		effect.advance(0.2)
		check(first.current_health == 1000 and effect.infections.is_empty(), spell_id + " no status or damage before arrival")
		effect.advance(0.25)
		check(effect.infections.size() == 1 and first.current_health == 1000, spell_id + " arrival attaches marker without early damage")
		effect.advance(0.55)
		check(first.current_health == 991 and neighbor.current_health == 1000 and effect.infections.size() == 1, spell_id + " tick damages host and launches spread")
		effect.advance(0.2)
		check(effect.infections.size() == 2 and neighbor.current_health == 1000, spell_id + " spread status attaches only after travel")
	clear()
	first = target(Vector2(200, 0))
	var replacement = target(Vector2(250, 0))
	effect = plague(first)
	first.free()
	effect.advance(0.6)
	check(effect.infections.size() == 1 and effect.infections[0].get_ref() == replacement, "Stale initial target retargets to eligible live host")
	clear()
	first = target(Vector2(200, 0))
	replacement = target(Vector2(400, 0))
	effect = plague(first)
	first.free()
	effect.advance(0.6)
	check(effect.infections.is_empty() and effect.infection_links.is_empty(), "Stale spore expires without acquiring outside cast range")
	clear()
	first = target(Vector2(200, 0))
	effect = plague(first)
	for index in range(12):
		effect.infect(target(Vector2(200 + index * 5, 20)), Vector2.ZERO, 300)
	var expected_hosts = 8 if effect.ENFORCE_HOST_LIMIT else 13
	check(effect.infection_links.size() == expected_hosts and effect.infections.is_empty(), "Pending spores respect configured host limit policy")
	effect.advance(0.6)
	check(effect.infections.size() == expected_hosts and effect.infection_links.is_empty(), "Arrival preserves admitted hosts without duplicate infection")
	print("Spell impacts: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
