extends SceneTree

const Geometry = preload("res://scripts/SpellGeometry.gd")
const Area = preload("res://scripts/LingeringArea.gd")
const Build = preload("res://scripts/BuildSpellEffect.gd")
const Tactical = preload("res://scripts/TacticalSpellEffect.gd")
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
	func take_damage(amount, _origin = Vector2.ZERO):
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
	for group in ["build_spell_effects", "spell_projectiles", "lingering_spell_areas", "healing_seeds", "lightning_areas", "ice_blasts"]:
		for node in get_nodes_in_group(group):
			if is_instance_valid(node): node.free()
	for node in hosts:
		if is_instance_valid(node): node.free()
	hosts.clear()

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
	manager.cast_life_spell(manager.find_spell_slot("regeneration"))
	check(is_equal_approx(manager.active_healing_effects[-1].heal_per_second, 6), "Power doubles regeneration rate")
	check(is_equal_approx(manager.active_healing_effects[-1].remaining_time, 10), "Duration doubles regeneration lifetime")
	manager.cast_earthshield_spell(manager.find_spell_slot("earth_shield"))
	check(is_equal_approx(player.overheal, 120), "Power doubles shield protection")
	check(is_equal_approx(player.overheal_timer, 32), "Duration doubles shield lifetime")
	player.spell_damage_multiplier = 1.0
	for kind in ["lightning", "meteor"]:
		var first = host(origin)
		var late = host(origin + Vector2(300, 0))
		var effect
		if kind == "lightning":
			effect = load("res://scripts/LightningArea.gd").new()
			effect.configure(origin, {"radius":80}, 20, player)
		else:
			manager.create_meteor_strike(origin, 20, 80)
			effect = get_nodes_in_group("lingering_spell_areas")[-1]
		if kind == "lightning": game.add_child(effect)
		effect.set_physics_process(false)
		check(is_equal_approx(first.current_health, 9980), kind + " immediate damage")
		effect.advance(0.21)
		late.global_position = origin
		effect.advance(0.01)
		check(is_equal_approx(late.current_health, 9980), kind + " duration admits late entrant")
		check(is_equal_approx(first.current_health, 9980), kind + " does not repeat hit")
		check(is_equal_approx(effect.duration, 0.4), kind + " active lifetime doubled")
		effect.advance(0.2)
		check(effect.is_queued_for_deletion(), kind + " expires")
		clear_effects()
	var trigger = host(origin + Vector2(100, 0))
	var trap = Tactical.new()
	trap.configure({"type":"trap", "duration":6.0, "arm_delay":0.8}, 20, player, trigger)
	game.add_child(trap)
	trap.set_physics_process(false)
	trap.advance(0.79)
	check(not trap.triggered, "Trap does not arm early")
	trap.advance(0.02)
	check(trap.triggered, "Duration does not delay trap arming")
	var newcomer = host(trap.global_position + Vector2(500, 0))
	trap.advance(0.26)
	newcomer.global_position = trap.global_position
	trap.advance(0.01)
	check(is_equal_approx(newcomer.current_health, 9980), "Trap expanded aftermath admits late entrant")
	check(is_equal_approx(trigger.current_health, 9980), "Trap no repeat hit")
	clear_effects()
	player.spell_size_multiplier = 2
	var orbit = Geometry.scaled_data({"type":"orbit", "duration":6}, player)
	check(is_equal_approx(orbit.body_radius, 84) and is_equal_approx(orbit.orbit_radius, 260), "Size grows orbit and bodies")
	var icy = load("res://scripts/IceBlast.gd").new()
	icy.configure(origin, Vector2.RIGHT, 400, 10, 0, 1, 0.5, 2, 2)
	check(is_equal_approx(icy.reach,800) and is_equal_approx(icy.shard_radius,24) and is_equal_approx(icy.speed,1240), "Ice size and velocity map to real shards/reach")
	icy.free()
	var orbit_node = Build.new()
	orbit_node.configure({"type":"orbit", "duration":6, "projectile_speed_multiplier":2}, 20, player, null)
	game.add_child(orbit_node)
	orbit_node.set_physics_process(false)
	orbit_node.advance(0.1)
	check(is_equal_approx(orbit_node.angle, 0.8), "Velocity increases angular speed")
	check(is_equal_approx(orbit_node.remaining, 11.9), "Duration extends orbit")
	clear_effects()
	player.spell_size_multiplier = 1
	learn(["focus_ray", "ember_lance", "prism_ray"])
	var target = host(origin + Vector2(200,0))
	manager.cast_build_spell(manager.find_spell_slot("prism_ray"))
	var prism = get_nodes_in_group("active_spell_channels")[-1]
	prism.set_physics_process(false)
	prism.info.projectile_speed_multiplier = 10
	if "--known-bad-prism-turn" in OS.get_cmdline_user_args():
		prism.info.beam_turn_speed = 4.0
	var initial = prism.direction
	target.global_position = origin + Vector2(0,200)
	prism.advance(0.3)
	check(prism.direction.is_equal_approx(initial), "Prism never turns even at high velocity")
	check(prism.target_ref == null, "Fixed beam does not reserve an off-axis enemy")
	check(is_equal_approx(prism.beam_radius(),32), "Prism is broad")
	check(is_equal_approx(prism.remaining,3.7), "Prism duration scales")
	clear_effects()
	learn(["bolt", "lightning_arc", "lightning_bolt"])
	player.spell_damage_multiplier = 2
	manager.get_spell_info(manager.find_spell_slot("bolt")).level = 3
	manager.get_spell_info(manager.find_spell_slot("lightning_arc")).level = 4
	var info = manager.resolve_cast_info(manager.find_spell_slot("lightning_bolt"))
	check(is_equal_approx(manager.calculate_spell_damage(info),104), "Combination impact gets ingredient and Power once")
	check(is_equal_approx(info.splash_damage,232), "Combination splash gets Lightning and Power once")
	var direct = host(origin + Vector2(100,0))
	var crowd = host(origin + Vector2(120,0))
	manager.cast_bouncing_bolt(manager.find_spell_slot("lightning_bolt"))
	var bolt = get_nodes_in_group("spell_projectiles")[-1]
	bolt.set_process(false)
	bolt.hit_enemy(direct)
	check(is_equal_approx(direct.current_health,9664), "Direct lightning target takes impact and splash")
	check(is_equal_approx(crowd.current_health,9768), "Lightning splash reaches crowd")
	check(is_equal_approx(get_nodes_in_group("lingering_spell_areas")[-1].duration,0.4), "Lightning Bolt splash duration scales once")
	clear_effects()
	learn(["plague_seed", "regeneration", "soul_bloom"])
	var doomed = host(origin + Vector2(50,0))
	doomed.current_health = 1
	manager.cast_build_spell(manager.find_spell_slot("soul_bloom"))
	var bloom = get_nodes_in_group("build_spell_effects")[-1]
	bloom.set_physics_process(false)
	bloom.advance(1.1)
	check(get_nodes_in_group("healing_seeds").size()==1, "Soul Bloom death creates healing area")
	check(bloom.resting_spores.size()==1, "Soul Bloom death independently preserves infectious spore")
	if get_nodes_in_group("healing_seeds").size()==1:
		var seed = get_nodes_in_group("healing_seeds")[0]
		check(is_equal_approx(seed.healing_amount,12), "Soul healing power once")
		check(is_equal_approx(seed.remaining,20), "Soul bloom collection lifetime duration once")
	check(is_equal_approx(bloom.spore_lifetime(),10), "Soul spore duration scales")
	clear_effects()
	var slow_target = host(origin + Vector2(40,0))
	var fast_target = host(origin + Vector2(50,0))
	var seeker = Tactical.new()
	seeker.configure({"type":"spirit", "duration":5.0},20,player,slow_target)
	game.add_child(seeker)
	seeker.set_physics_process(false)
	seeker.advance(0.15)
	check(slow_target.current_health==9980 and fast_target.current_health==9980, "Seeker damages all contacts within body")
	seeker.advance(0.1)
	check(slow_target.current_health==9980 and fast_target.current_health==9980, "Seeker per-enemy repeat gate")
	clear_effects()
	var trail = Tactical.new()
	trail.configure({"type":"trail", "duration":11.0, "emission_duration":5.0, "patch_duration":6.0},20,player,null)
	game.add_child(trail)
	trail.set_physics_process(false)
	check(is_equal_approx(trail.emission_deadline,10) and is_equal_approx(trail.info.patch_duration,12), "Duration extends trail emission and patch life")
	check(is_equal_approx(trail.remaining,22), "Emitter remains alive for final patch")
	check(is_equal_approx(trail.extend_duration({"type":"trail", "duration":11.0, "emission_duration":5.0, "patch_duration":6.0}),10), "Recast adds scaled emission once")
	clear_effects()
	var blade = Tactical.new()
	blade.configure({"type":"returning", "duration":4.0, "linger_duration":0.9},20,player,null)
	game.add_child(blade)
	blade.set_physics_process(false)
	blade.global_position = origin + Vector2(300,0)
	blade.leg = 1
	blade.linger_remaining = 0
	blade.advance_returning(0.1,player)
	check(blade.global_position.distance_to(origin)<300, "Duration never delays blade return")
	check(get_nodes_in_group("lingering_spell_areas").size()==1, "Duration leaves a useful blade aftermath")
	clear_effects()
	var guide = host(origin + Vector2(0,200))
	var focus = Tactical.new()
	focus.configure({"type":"beam", "duration":2.0,"projectile_speed_multiplier":2.0},20,player,null)
	game.add_child(focus)
	focus.set_physics_process(false)
	focus.target_ref = weakref(guide)
	focus.advance(0.1)
	check(is_equal_approx(focus.direction.angle(),0.8), "Velocity doubles Focus turning")
	clear_effects()
	learn(["bolt","life","life_bolt"])
	var a = host(origin+Vector2(100,0))
	var b = host(origin+Vector2(200,50))
	manager.upgrade_spell("life_bolt")
	manager.cast_life_bolt(manager.find_spell_slot("life_bolt"))
	var shots = get_nodes_in_group("spell_projectiles")
	check(shots.size()==2 and shots[0].target!=shots[1].target, "Life Bolt own upgrade adds distinct targeted outputs")
	for shot in shots: shot.set_process(false)
	shots[0].hit_enemy(a)
	var patch = get_nodes_in_group("healing_seeds")[0]
	patch.set_physics_process(false)
	check(is_equal_approx(patch.healing_amount,12) and is_equal_approx(patch.remaining,20), "Life seed power and duration apply once")
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
	check(preload("res://scripts/BuildVersion.gd").text()=="v0.1.35 · Playtest", "Game version0.1.35")
	game.queue_free()
	await process_frame
	print("SCALING0135: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
