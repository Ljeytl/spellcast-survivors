extends SceneTree

const Geometry = preload("res://scripts/SpellGeometry.gd")
const Bridge = preload("res://scripts/engine/SpellTemplate.gd")
var checks = 0
var failures = 0
var game
var player
var manager
var hosts: Array = []

class Host extends Node2D:
	signal enemy_died(enemy)
	var current_health = 10000.0
	var dying = false
	var slow = 1.0
	func take_damage(amount, _origin = Vector2.ZERO, _damage_source = {}):
		current_health = maxf(0, current_health - amount)
		if current_health <= 0 and not dying:
			dying = true
			enemy_died.emit(self)
	func apply_slow(amount, _duration): slow = amount
	func apply_knockback(_direction, _amount): pass

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, label):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func host(point: Vector2):
	var node = Host.new()
	game.add_child(node)
	node.global_position = point
	node.add_to_group("enemies")
	hosts.append(node)
	return node

func clear_effects():
	for group in ["generic_casts", "spell_projectiles", "lingering_spell_areas", "healing_seeds"]:
		for node in get_nodes_in_group(group):
			if is_instance_valid(node): node.free()
	for node in hosts:
		if is_instance_valid(node): node.free()
	hosts.clear()

## Ported spells run on the generic engine (doc 18 phase 2): spawn one from explicit data, driven by hand.
func ported(info: Dictionary, damage: float, aim = null):
	var cast = manager.spawn_ported(info, damage, {}, aim)
	if cast != null:
		cast.manual = true
	return cast

func learn(ids: Array):
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	for id in ids:
		check(manager.learn_spell(id), "Learn " + id)

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	player = game.player
	manager = game.spell_manager
	manager.set_process(false)
	player.set_physics_process(false)
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	await process_frame
	var origin = player.global_position
	check(player.apply_upgrade({"effect": {"type": "spell_duration", "value": 0.1}}), "Duration is acquirable")
	check(is_equal_approx(player.spell_duration_multiplier, 1.1), "Duration rank adds ten percent")
	player.passive_ranks = {"spell_duration":1, "spell_damage":1, "spell_area":1, "max_health":1, "movement_speed":1, "mana_bolt_mastery":1}
	check(not player.can_acquire_passive("projectile_speed"), "Six families still cap acquisition")
	check(player.can_acquire_passive("spell_duration"), "Owned duration still upgrades at six families")
	player.passive_ranks.clear()
	player.spell_duration_multiplier = 1.0 if "--known-bad-duration" in OS.get_cmdline_user_args() else 2.0
	player.spell_damage_multiplier = 2.0
	learn(["life", "regeneration", "earth_shield"])
	player.health = 10
	manager.cast_spell_by_type(manager.find_spell_slot("life"))
	check(is_equal_approx(player.health, 18), "Power doubles Life heal")
	manager.cast_spell_by_type(manager.find_spell_slot("regeneration"))
	var regen = manager.last_generic_cast.root_parts()[0]   # generic life aura
	regen.cast.manual = true
	check(is_equal_approx(float(regen.def.heal_rate), 6), "Power doubles regeneration rate")
	check(is_equal_approx(regen.remaining_life(), 10), "Duration doubles regeneration lifetime")
	manager.cast_spell_by_type(manager.find_spell_slot("earth_shield"))
	check(is_equal_approx(player.earth_shield.charges[0].damage, 120), "Power doubles shield retaliation")
	check(is_equal_approx(player.earth_shield.charges[0].remaining, 32), "Duration doubles shield lifetime")
	player.spell_damage_multiplier = 1.0
	for kind in ["lightning", "meteor"]:
		var first = host(origin)
		var effect
		if kind == "lightning":
			effect = ported({"id": "lightning", "type": "direct_strike", "radius": 80}, 20, first)
		else:
			effect = ported({"id": "meteor_shower", "type": "multi_aoe", "radius": 80, "meteor_count": 1, "warning_duration": 0.0}, 20, first)
		var late = host(origin + Vector2(300, 0))   # after the cast: the meteor lands on `first`
		if kind == "lightning":
			effect.advance(0.33)   # the warning ring before the strike lands (playtest)
		check(is_equal_approx(first.current_health, 9980), kind + " immediate damage (%s)" % first.current_health)
		effect.advance(0.21)
		late.global_position = origin
		effect.advance(0.01)
		check(is_equal_approx(late.current_health, 9980), kind + " duration admits late entrant")
		check(is_equal_approx(first.current_health, 9980), kind + " does not repeat hit")
		var blast = effect.plan.parts.strike if kind == "lightning" else effect.plan.parts.impact
		check(is_equal_approx(float(blast.propagation.linger), 0.4), kind + " active lifetime doubled")
		effect.advance(0.2 if kind == "lightning" else 2.5)   # the meteor's crater lingers (doc 21 §5.2)
		check(effect.finished, kind + " expires")
		clear_effects()
	var trigger = host(origin + Vector2(100, 0))
	var trap = ported({"id": "rune_trap", "type": "trap", "duration": 6.0, "arm_delay": 0.8}, 20, trigger)
	var rune_at = trap.root_parts()[0].global_position
	trap.advance(0.79)
	check(is_equal_approx(trigger.current_health, 10000), "Trap does not arm early")
	trap.advance(0.02)
	check(is_equal_approx(trigger.current_health, 10000), "Stepping in activates the rune; the explosion waits for its fuse")
	trap.advance(0.41)
	check(is_equal_approx(trigger.current_health, 9980), "Duration does not delay trap arming")
	var newcomer = host(rune_at + Vector2(500, 0))
	trap.advance(0.26)
	newcomer.global_position = rune_at
	trap.advance(0.01)
	check(is_equal_approx(newcomer.current_health, 9980), "Trap expanded aftermath admits late entrant")
	check(is_equal_approx(trigger.current_health, 9980), "Trap no repeat hit")
	clear_effects()
	player.spell_size_multiplier = 2
	var orbit = Geometry.scaled_data({"id": "arcane_orbit", "duration": 6}, player)   # size defaults come from its data
	check(is_equal_approx(orbit.body_radius, 84) and is_equal_approx(orbit.orbit_radius, 260), "Size grows orbit and bodies")
	var icy = Bridge.build(Geometry.scaled_data({"id": "ice_blast", "type": "aoe", "radius": 400}, player), 10, {"speed_mult": 2.0})
	var shard = icy.parts.shard
	check(is_equal_approx(float(shard.motion[0].range), 800) and is_equal_approx(float(shard.geometry.radius), 24) and is_equal_approx(float(shard.motion[0].speed), 1240), "Ice size and velocity map to real shards/reach")
	player.spell_size_multiplier = 1
	player.projectile_speed_multiplier = 2
	var orbit_cast = ported({"id": "arcane_orbit", "type": "orbit", "duration": 6}, 20)
	var orb = orbit_cast.root_parts()[0]
	var start_angle = orb.orbit_angle
	orbit_cast.advance(0.1)
	check(is_equal_approx(orb.orbit_angle - start_angle, 0.8), "Velocity increases angular speed")
	check(is_equal_approx(orb.remaining_life(), 11.9), "Duration extends orbit")
	clear_effects()
	learn(["focus_ray", "ember_spear", "prism_ray"])
	var target = host(origin + Vector2(200,0))
	player.projectile_speed_multiplier = 10
	manager.cast_spell_by_type(manager.find_spell_slot("prism_ray"))
	var prism_cast = manager.last_generic_cast
	prism_cast.manual = true
	var prism = prism_cast.root_parts()[0]
	if "--known-bad-prism-turn" in OS.get_cmdline_user_args():
		prism.def = prism.def.duplicate(true)
		prism.def.aim = {"turn": 4.0}
	var initial = prism.direction
	target.global_position = origin + Vector2(0,200)
	prism_cast.advance(0.3)
	check(absf(initial.angle_to(prism.direction)) > 0.2, "Prism tracks like Focus Ray (doc 21 §5.6) (%s)" % absf(initial.angle_to(prism.direction)))
	check(prism.target_ref != null and prism.target_ref.get_ref() == target, "Prism keeps tracking its moving target")
	check(is_equal_approx(prism.geo("width") * 0.5, 32), "Prism is broad")
	# Prism starts at Focus Ray's maxed duration; Duration ×2, minus the 0.3s advanced above.
	var focus_info = manager.spell_catalog.focus_ray
	var focus_max = float(focus_info.get("rank_growth", {}).get("duration", {}).get("max", focus_info.duration))
	check(is_equal_approx(prism.remaining_life(), focus_max * 2.0 - 0.3), "Prism duration scales")
	player.projectile_speed_multiplier = 1
	clear_effects()
	learn(["bolt", "lightning", "lightning_bolt"])
	player.spell_damage_multiplier = 2
	manager.get_spell_info(manager.find_spell_slot("bolt")).level = 3
	manager.get_spell_info(manager.find_spell_slot("lightning")).level = 4
	var info = manager.resolve_cast_info(manager.find_spell_slot("lightning_bolt"))
	var Scaling = preload("res://scripts/CombinationScaling.gd")
	var expected_impact = 2.0 * Scaling.ingredient_damage("bolt", 3, 0.0)
	var expected_splash = 2.0 * Scaling.ingredient_damage("lightning", 4, 0.0)
	check(is_equal_approx(manager.calculate_spell_damage(info),expected_impact), "Combination impact gets ingredient and Power once")
	check(is_equal_approx(info.splash_damage,expected_splash), "Combination splash gets Lightning and Power once")
	var direct = host(origin + Vector2(100,0))
	var crowd = host(origin + Vector2(120,0))
	# Lightning Bolt runs on the generic engine (doc 18 phase 2).
	manager.cast_spell_by_type(manager.find_spell_slot("lightning_bolt"))
	var bolt_cast = manager.last_generic_cast
	bolt_cast.manual = true
	var bolt = bolt_cast.root_parts()[0]
	bolt.hit(direct)
	# Doc 21 §5.6: each bolt hit is 75% arcane + 75% storm; one strike lands only where the chain ends.
	check(is_equal_approx(direct.current_health,10000.0 - expected_impact * 1.5), "Direct lightning target takes the 150%% bolt hit (%s)" % (10000.0 - direct.current_health))
	check(is_equal_approx(crowd.current_health,10000.0), "No strike until the chain ends")
	check(is_equal_approx(float(bolt_cast.plan.parts.splash.geometry.radius), float(info.splash_radius) * preload("res://scripts/SpellGeometry.gd").multiplier(player)), "Lightning Bolt splash size scales once")
	bolt_cast.queue_free()
	clear_effects()
	learn(["infestation", "regeneration", "soul_bloom"])
	var doomed = host(origin + Vector2(50,0))
	doomed.current_health = 1
	manager.cast_spell_by_type(manager.find_spell_slot("soul_bloom"))
	var bloom_cast = manager.last_generic_cast
	bloom_cast.manual = true
	var bloom = bloom_cast.root_parts()[0].infection
	bloom_cast.advance(1.1)
	check(get_nodes_in_group("soul_ghosts").size()==1, "Soul Bloom death releases a ghost (doc 21 §5.6)")
	check(bloom.spores.size()==1, "Soul Bloom death independently preserves infectious spore")
	if get_nodes_in_group("healing_seeds").size()==1:
		var seed = get_nodes_in_group("healing_seeds")[0]
		check(is_equal_approx(seed.healing_amount,12), "Soul healing power once")
		check(is_equal_approx(seed.remaining,20), "Soul bloom collection lifetime duration once")
	check(is_equal_approx(bloom.spore_life(),10), "Soul spore duration scales")
	clear_effects()
	var slow_target = host(origin + Vector2(40,0))
	var fast_target = host(origin + Vector2(50,0))
	var seeker = ported({"id": "seeker", "type": "spirit", "duration": 5.0}, 20, slow_target)
	seeker.advance(0.15)
	check(slow_target.current_health==9980 and fast_target.current_health==10000, "Seeker drains only its first body contact")
	seeker.advance(0.1)
	check(slow_target.current_health==9980 and fast_target.current_health==10000, "Spent or returning Seeker does not repeat damage")
	clear_effects()
	var walk_data = {"id": "firewalk", "type": "trail", "duration": 11.0, "emission_duration": 5.0, "patch_duration": 6.0, "recast_behavior": "extend"}
	var trail = ported(walk_data, 20)
	var emitter = trail.root_parts()[0]
	check(is_equal_approx(emitter.total_life(), 10) and is_equal_approx(float(trail.plan.parts.patch.timing.duration), 12), "Duration extends trail emission and patch life")
	check(ported(walk_data, 20) == trail and is_equal_approx(emitter.total_life(), 20), "Recast adds scaled emission once")
	trail.advance(19.85)
	player.position += Vector2(40, 0)
	trail.advance(0.2)
	player.position -= Vector2(40, 0)
	check(emitter.done and not trail.finished, "Emitter ends while the final patch still burns")
	trail.advance(12.0)
	check(trail.finished, "Trail ends once the final patch burns out")
	clear_effects()
	var blade = Bridge.build(Geometry.scaled_data({"id": "cross_blade", "type": "returning", "duration": 4.0, "linger_duration": 0.9}, player), 20, {})
	# Doc 21 §5.4: Duration makes the blade hold longer; nothing is left behind.
	check(float(blade.parts.blade.motion[1].time) > 0.9 + 0.001, "Duration makes the blade hold longer (%s)" % blade.parts.blade.motion[1].time)
	check(not blade.parts.has("echo"), "Duration leaves no afterimage")
	var guide = host(origin + Vector2(0,200))
	player.projectile_speed_multiplier = 2
	var focus_cast = ported({"id": "focus_ray", "type": "beam", "duration": 2.0}, 20, guide)
	var focus = focus_cast.root_parts()[0]
	focus.direction = Vector2.RIGHT
	focus.beam_offset = Vector2.ZERO
	focus_cast.advance(0.1)
	check(is_equal_approx(focus.direction.angle(),0.8), "Velocity doubles Focus turning (%s)" % focus.direction.angle())
	player.projectile_speed_multiplier = 1
	clear_effects()
	learn(["bolt","life","life_bolt"])
	var a = host(origin+Vector2(100,0))
	var b = host(origin+Vector2(200,50))
	manager.upgrade_spell("life_bolt")
	manager.cast_spell_by_type(manager.find_spell_slot("life_bolt"))
	var life_cast = manager.last_generic_cast   # generic engine (doc 18 phase 2)
	life_cast.manual = true
	var shots = life_cast.root_parts()
	check(shots.size()==2 and shots[0].assigned!=shots[1].assigned, "Life Bolt own upgrade adds distinct targeted outputs")
	shots[0].hit(a)
	var patch = get_nodes_in_group("healing_seeds")[0]
	patch.set_physics_process(false)
	var dealt_a = 10000.0 - a.current_health
	check(is_equal_approx(patch.healing_amount, dealt_a * 0.15) and is_equal_approx(patch.remaining,20), "Life seed heals 15%% of the hit's damage; duration applies once (%s of %s)" % [patch.healing_amount, dealt_a])
	player.health = player.max_health
	patch.global_position = player.global_position
	patch._physics_process(0)
	check(not patch.collected, "Full health preserves healing patch")
	player.health = 10
	patch._physics_process(0)
	check(patch.collected and patch.is_queued_for_deletion(), "Injured player claims healing patch")
	clear_effects()
	var monsters = game.get_node("MonsterManager")
	var victims: Array = []
	for offset in [Vector2(200,-25),Vector2(200,25),Vector2(400,0)]:
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
		enemy.set_physics_process(false)
		enemy.global_position = origin+offset
		enemy.max_health = 10000
		enemy.current_health = 10000
		victims.append(enemy)
	player.spell_size_multiplier = 2
	var projectile = load("res://scenes/SpellProjectile.tscn").instantiate()
	game.add_child(projectile)
	projectile.setup(origin+Vector2(200,0),Vector2.RIGHT,25,Color.WHITE,"bolt")
	projectile.set_process(false)
	if "--known-bad-projectile-contact" in OS.get_cmdline_user_args():
		projectile.area_entered.disconnect(projectile._on_area_entered)
		projectile.area_entered.connect(func(area):
			if area.name == "HurtBox" and not projectile.despawning:
				projectile.hit_enemy(area.get_parent())
				projectile.despawn())
	await physics_frame
	await physics_frame
	await process_frame
	check(victims[0].current_health==9975 and victims[1].current_health==9975,"Enlarged projectile physics hits simultaneous hurtboxes")
	check(victims[2].current_health==10000,"Enlarged projectile does not gain line piercing")
	for enemy in victims: enemy.free()
	check(preload("res://scripts/BuildVersion.gd").text()=="v%s · Playtest" % ProjectSettings.get_setting("application/config/version"), "Game version label matches project version")
	game.queue_free()
	await process_frame
	print("SCALING0135: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
