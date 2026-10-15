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

## Ice Blast and Infestation run on the generic engine (doc 18 phase 2): build the cast from data.
func generic(info: Dictionary, damage: float, aim):
	var def = load("res://scripts/engine/SpellTemplate.gd").build(load("res://scripts/SpellGeometry.gd").scaled_data(info, player), damage, {})
	var cast = load("res://scripts/engine/GenericCast.gd").new()
	cast.forced_target = aim
	cast.setup(load("res://scripts/engine/CastPlanner.gd").plan(def, {}, {}), player, arena, {"spell": str(info.id)}, true)
	arena.add_child(cast)
	cast.step(0.0)
	return cast

func ice(aim):
	return generic({"id": "ice_blast", "type": "aoe", "radius": 400, "knockback": 200, "level": 1}, 30, aim)

func plague(host, type = "infestation"):
	var cast = generic({"id": type, "type": "plague", "duration": 5, "tick_interval": 0.5, "cast_range": 300}, 9, host)
	return cast.root_parts()[0].infection

func run():
	root.get_node("AudioManager").quitting = true
	clear()
	var first = target(Vector2(200, 0))
	var miss = target(Vector2.from_angle(PI / 48) * 390)
	var behind = target(Vector2(-100, 0))
	var effect = ice(first)
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
	effect = ice(body)
	# One shard swept from the caster to 300 along +x.
	var shard = effect.root_parts()[0]
	shard.prev_pos = Vector2.ZERO
	shard.global_position = Vector2(300, 0)
	body.position = Vector2(200, 60)
	check(not shard._swept_contains(body), "Small hurtbox outside shard path misses")
	body.scale = Vector2.ONE * 2
	check(shard._swept_contains(body), "Large real hurtbox edge receives swept contact")
	body.position.y = 100
	check(not shard._swept_contains(body), "Large hurtbox still misses a true gap")
	for spell_id in ["infestation", "soul_bloom"]:
		clear()
		first = target(Vector2(200, 0))
		var neighbor = target(Vector2(270, 0))
		effect = plague(first, spell_id)
		check(effect.hosts.is_empty() and effect.links.size() == 1, spell_id + " launches visible spore without marker")
		effect.part.cast.advance(0.2)
		check(first.current_health == 1000 and effect.hosts.is_empty(), spell_id + " no status or damage before arrival")
		effect.part.cast.advance(0.25)
		check(effect.hosts.size() == 1 and first.current_health == 1000, spell_id + " arrival attaches marker without early damage")
		effect.part.cast.advance(0.55)
		check(first.current_health == 991 and neighbor.current_health == 1000 and effect.hosts.size() == 1, spell_id + " tick damages host and launches spread")
		effect.part.cast.advance(0.2)
		check(effect.hosts.size() == 2 and neighbor.current_health == 1000, spell_id + " spread status attaches only after travel")
	clear()
	first = target(Vector2(200, 0))
	var replacement = target(Vector2(250, 0))
	effect = plague(first)
	first.free()
	effect.part.cast.advance(0.6)
	check(effect.hosts.size() == 1 and effect.hosts[0].ref.get_ref() == replacement, "Stale initial target retargets to eligible live host")
	clear()
	first = target(Vector2(200, 0))
	replacement = target(Vector2(400, 0))
	effect = plague(first)
	first.free()
	effect.part.cast.advance(0.6)
	check(effect.hosts.is_empty() and effect.links.is_empty(), "Stale spore expires without acquiring outside cast range")
	clear()
	first = target(Vector2(200, 0))
	effect = plague(first)
	for index in range(12):
		effect.infect(target(Vector2(200 + index * 5, 20)), Vector2.ZERO, 300)
	var expected_hosts = 13   # no host cap (the old ENFORCE_HOST_LIMIT switch stayed off)
	check(effect.links.size() == expected_hosts and effect.hosts.is_empty(), "Pending spores respect configured host limit policy")
	effect.part.cast.advance(0.6)
	check(effect.hosts.size() == expected_hosts and effect.links.is_empty(), "Arrival preserves admitted hosts without duplicate infection")
	print("Spell impacts: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
