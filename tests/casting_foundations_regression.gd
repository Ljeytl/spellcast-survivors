extends SceneTree

var checks = 0
var failures = 0
var game
var manager

class Target extends Node2D:
	var current_health = 1000.0
	var dying = false
	var slowed = false
	func take_damage(amount, _source = Vector2.ZERO, _damage_source = {}):
		current_health -= amount
	func apply_slow(_strength, _duration):
		slowed = true

func target_at(offset: Vector2):
	var target = Target.new()
	game.add_child(target)
	target.global_position = game.player.global_position + offset
	target.add_to_group("enemies")
	return target

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func fresh():
	paused = false
	if is_instance_valid(game):
		game.free()
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	manager = game.spell_manager
	manager.set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	game.get_node("MonsterManager").set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true

func run():
	fresh()
	check(manager.MAX_EQUIPPED_SPELLS == 6 and game.spell_slots.size() == 6, "Six active slots exist")
	check(manager.spells.size() == 1 and manager.spells[1].id == "bolt" and manager.spells[1].name == "Bolt", "Start only with Bolt in slot1")
	check(not manager.cast_freeform_spell("lightning bolt") and not manager.cast_freeform_spell("lightning"), "Neither Lightning identity is a starter alias")
	manager.activate_spell_slot(1)
	manager.advance_typing_slowdown(1.0)
	check(is_equal_approx(manager.typing_slowdown_remaining, 0.5), "Unscaled typing seconds drain once")
	manager.advance_typing_slowdown(1)
	check(manager.is_typing and manager.typing_slowdown_remaining == 0 and Engine.time_scale == 1, "Exhaustion preserves editable cast at normal speed")
	manager.cancel_typing()
	manager.advance_typing_slowdown(50)
	check(manager.typing_slowdown_remaining == 0, "Idle time does not refill a shared reserve")
	manager.activate_spell_slot(1)
	check(manager.typing_slowdown_remaining == 1.5 and is_equal_approx(Engine.time_scale, 0.2), "New numbered cast gets fresh allowance")
	manager.cancel_typing()
	manager.space_casting = true
	manager.start_freeform_typing()
	check(manager.typing_slowdown_remaining == 1.5, "Space cast also starts fresh")
	manager.cancel_typing()
	game._on_upgrade_selected({"name":"Focus", "effect":{"type":"slowdown_duration","value":0.5}})
	manager.activate_spell_slot(1)
	check(manager.typing_slowdown_remaining == 2.0 and is_equal_approx(Engine.time_scale,0.2), "Focus changes duration without changing strength")
	manager._scale_change_frame = -1
	manager._process(0.1)
	check(is_equal_approx(manager.typing_slowdown_remaining, 1.5), "Scaled delta converts to real time once at fixed0.2speed")
	manager.set_process(true)
	paused = true
	var pause_budget = manager.typing_slowdown_remaining
	await process_frame
	await process_frame
	check(manager.typing_slowdown_remaining == pause_budget, "Paused frames do not consume typing allowance")
	paused = false
	manager.set_process(false)
	manager.cancel_typing()
	fresh()
	var before = manager.spells.duplicate(true)
	root.get_node("CharacterManager").discovered_synergies = ["life_bolt", "lightning_bolt"]
	check(not manager.learn_spell("life_bolt") and manager.spells == before, "Discovery memory cannot grant bonus without current ingredients")
	for id in ["life", "regeneration", "lightning", "ice_blast", "earth_shield"]:
		check(manager.learn_spell(id), "Fill primary: " + id)
	check(manager.spells.size() == 6 and not manager.learn_spell("meteor_shower"), "Seventh base cannot enter full kit")
	manager.upgrade_spell("bolt")
	manager.upgrade_spell("life")
	before = manager.spells.duplicate(true)
	check(manager.learn_spell("life_bolt"), "Full kit learns bonus")
	check(manager.spells == before and manager.bonus_spells.size() == 1, "Bonus keeps every ingredient slot, data and rank")
	check(manager.get_spell_rank("life_bolt") == 1, "Bonus starts independently at rank1")
	check(not manager.learn_spell("life_bolt"), "Duplicate bonus rejected")
	manager.upgrade_spell("life_bolt")
	check(manager.get_spell_rank("life_bolt") == 2 and manager.get_spell_rank("bolt") == 2, "Bonus ranks independently")
	check(manager.find_spell_slot("life_bolt") > 6 and manager.find_cast_spell_slot("life bolt") > 6, "Internal and player bonus lookup work")
	check(manager.get_owned_incantations().has("life bolt") and manager.freeform_spells.has("life bolt"), "Bonus exposed in owned casting library")
	check(not manager.cast_freeform_spell("life_bolt"), "Internal underscored ID cannot bypass typed canonical phrase")
	check(manager.cast_freeform_spell("life bolt"), "Owned bonus can be cast")
	check(manager.learn_spell("lightning_bolt"), "Bolt plus Lightning unlocks distinct bonus")
	check(manager.find_cast_spell_slot("lightning") != manager.find_cast_spell_slot("lightning bolt"), "Lightning and Lightning Bolt resolve separately")
	check(manager.get_spell_info(manager.find_spell_slot("lightning_bolt")).type == "bouncing_projectile", "Bonus dispatches bouncing projectile contract")
	var chain_slot = manager.find_spell_slot("lightning_bolt")
	check(manager.resolve_cast_info(chain_slot).bounce_count == 4, "Lightning Bolt starts with four additional bounces")
	manager.upgrade_spell("lightning_bolt")
	check(manager.resolve_cast_info(chain_slot).bounce_count == 5, "Lightning Bolt upgrade adds a bounce")
	check("bounce" in preload("res://scripts/UpgradeCopy.gd").rank_description("lightning_bolt", manager), "Upgrade copy advertises extra bounce")
	var chain_targets: Array = []
	for i in 7:
		var target = target_at(Vector2(80 + i * 50, 0))
		var hurtbox = Area2D.new()
		hurtbox.name = "HurtBox"
		target.add_child(hurtbox)
		chain_targets.append(target)
	manager.cast_bouncing_bolt(chain_slot)
	var chain
	for candidate in get_nodes_in_group("spell_projectiles"):
		if candidate.projectile_type == "lightning_bolt":
			chain = candidate
	check(is_instance_valid(chain), "Upgraded Lightning Bolt spawns an actual traveling chain")
	for i in 6:
		var victim = chain.target
		chain.global_position = victim.global_position
		chain._on_area_entered(victim.get_node("HurtBox"))
	check(chain.hit_ids.size() == 6 and chain.despawning, "Five bounces damage six distinct enemies and terminate")
	check(chain_targets.all(func(target): return target.current_health < 1000.0), "Impact splash can hit the seventh enemy without another direct bounce")
	for target in chain_targets:
		target.free()
	game.level_up_screen.generate_upgrade_options({}, 5)
	var pool = game.level_up_screen.current_upgrade_pool
	check(pool.any(func(card): return card.key == "rank:life_bolt"), "Bonus rank offered in real upgrade pool")
	check(not pool.any(func(card): return card.key == "learn:life_bolt"), "Learned bonus not reoffered")
	check(not manager.synergy_eligible("reaping_spirit"), "Deferred Reaping Spirit unavailable")
	check(manager.spells.size() == 6, "Bonuses never consume primary capacity")
	fresh()
	check(manager.bonus_spells.is_empty() and manager.spells.size() == 1, "New run clears bonus ownership and active build")
	for family in ["spell_damage", "movement_speed", "max_health", "xp_range", "projectile_speed", "slowdown_duration"]:
		check(game.player.apply_upgrade({"effect":{"type":family,"value":0.1}}), "Passive family acquired: " + family)
	check(game.player.passive_ranks.size() == 6, "Six distinct passive families")
	check(not game.player.apply_upgrade({"effect":{"type":"mana_bolt_mastery","value":1}}), "Seventh passive family rejected atomically")
	check(game.player.apply_upgrade({"effect":{"type":"spell_damage","value":0.1}}) and game.player.passive_ranks.spell_damage == 2, "Existing passive rank consumes no new slot")
	game.level_up_screen.generate_upgrade_options({}, 8)
	check(not game.level_up_screen.current_upgrade_pool.any(func(card): return card.effect.type == "mana_bolt_mastery"), "Full passive build does not offer new passive families")
	check(not game.level_up_screen.current_upgrade_pool.any(func(card): return card.effect.type == "cast_speed"), "Automatic attack speed not separate mastery slot tax")
	fresh()
	game._on_upgrade_selected({"name":"Mana Mastery", "effect":{"type":"mana_bolt_mastery","value":1}})
	check(manager.mana_bolt_level == 2 and is_equal_approx(game.player.cast_speed_multiplier,1.1) and game.player.passive_ranks.size()==1, "Mana mastery bundles damage/rate progression in one passive")
	manager.learn_spell("regeneration")
	game.player.health = 40
	check(not manager.cast_freeform_spell("life"), "Life does not invoke owned Regeneration")
	manager.learn_spell("life")
	manager.cast_spell_by_type(manager.find_spell_slot("life"))
	check(game.player.health == 44 and manager.active_healing_effects.is_empty(), "Life heals4HP immediately")
	manager.cast_spell_by_type(manager.find_spell_slot("regeneration"))
	manager.process_healing_effects(5)
	check(game.player.health == 59, "Regeneration provides distinct15HP over5seconds")
	game.player.health = 40
	game.player.start_healing_over_time(6,2)
	manager.process_healing_effects(0.5)
	check(game.player.health == 41.5, "Healing seed API ticks only actual elapsed duration")
	manager.process_healing_effects(5)
	check(game.player.health == 46, "Healing seed API clamps finaltick andtotal")
	fresh()
	game.player.health = 20
	var feedback_before = game.particle_manager.get_child_count()
	for i in range(100):
		game.player.heal(0.1)
	check(is_equal_approx(game.player.health, 30), "Feedback coalescing preserves every heal tick")
	check(game.particle_manager.get_child_count() <= feedback_before + 1, "One hundred same-frame heals emit at most one feedback burst")
	game.player.health = game.player.max_health
	game.player.next_heal_feedback_msec = 0
	feedback_before = game.particle_manager.get_child_count()
	game.player.heal(10)
	check(game.particle_manager.get_child_count() == feedback_before, "Full health emits no healing feedback")
	var front = target_at(Vector2(30, 0))
	var inside = target_at(Vector2.from_angle(PI / 6) * 220)
	var behind = target_at(Vector2(-70, 0))
	var side = target_at(Vector2(30, 100))
	var beyond = target_at(Vector2(425, 0))
	var boundary = target_at(Vector2(400, 0))
	manager.learn_spell("ice_blast")
	# Cone contract at rank 2: 15 shards over 90 degrees, reach under 400. Rank 8 is a full ring (checked below).
	manager.get_spell_info(manager.find_spell_slot("ice_blast")).level = 2
	manager.cast_freeform_spell("ice blast")
	check(front.current_health == 1000 and inside.current_health == 1000, "Ice shards do not damage before arrival")
	var ice = get_nodes_in_group("ice_blasts").back()
	ice.set_physics_process(false)
	ice.advance(1.0)
	check(front.current_health < 1000 and inside.current_health < 1000 and boundary.current_health == 1000, "Ice shards hit their paths and the leading enemy blocks its shard")
	check(behind.current_health == 1000 and side.current_health == 1000 and beyond.current_health == 1000, "Ice cone excludes behind, outside angle and beyond reach")
	check(front.slowed and inside.slowed and not behind.slowed, "Ice control follows the same cone as damage")
	manager.learn_spell("lightning")
	var before_lightning = front.current_health
	var neighbor_health = inside.current_health
	# Area spells only centre on visible enemies; give the headless viewport a real screen size.
	root.size = Vector2i(1280, 720)
	await process_frame
	manager.cast_freeform_spell("lightning")
	check(front.current_health < before_lightning and side.current_health < 1000 and inside.current_health == neighbor_health, "Lightning strikes nearby group and excludes enemies beyond circle")
	if is_instance_valid(ice):
		ice.queue_free()
	manager.get_spell_info(manager.find_spell_slot("ice_blast")).level = 8
	manager.cast_freeform_spell("ice blast")
	var ring = get_nodes_in_group("ice_blasts").back()
	ring.set_physics_process(false)
	ring.advance(1.0)
	check(behind.current_health < 1000 and behind.slowed, "Rank 8 Ice Blast is a full ring that reaches behind")
	manager.cast_freeform_spell("bolt")
	var bolts = game.get_children().filter(func(node): return node is Area2D and node.get("is_homing") != null and not node.is_queued_for_deletion())
	check(bolts.any(func(node): return not node.is_homing and node.get("damage") > 0), "Typed Bolt travels straight")
	fresh()
	root.size = Vector2i(1280, 720)
	game.get_node("Camera2D").global_position = game.player.global_position
	game.get_node("Camera2D").force_update_scroll()
	manager.learn_spell("infestation")
	var plague_slot = manager.find_spell_slot("infestation")
	var plague_info = manager.get_spell_info(plague_slot)
	var corpse = target_at(Vector2(10, 0))
	corpse.dying = true
	var hidden = target_at(Vector2(20, 0))
	hidden.hide()
	var offscreen = target_at(Vector2(5000, 0))
	check(manager.get_visible_plague_host(plague_info) == null, "Plague excludes dying, hidden and offscreen hosts")
	var cast_count = game.spells_cast
	var feedback_count = game.particle_manager.get_child_count()
	check(not manager.cast_freeform_spell("infection"), "Empty host selection reports cast failure")
	check(game.spells_cast == cast_count and game.particle_manager.get_child_count() == feedback_count, "Failed Plague produces no success count or flash")
	check(get_nodes_in_group("build_spell_effects").is_empty(), "Failed Plague creates no empty infection effect")
	manager.cancel_typing()
	manager.queue_spell(plague_slot)
	manager.start_typing()
	manager.current_typing_text = "infection"
	manager.advance_typing_slowdown(1.0)
	manager.attempt_cast()
	check(manager.is_typing and manager.current_typing_text == "infection" and manager.spell_queue.size() == 1, "Numbered no-target cast remains editable and retryable")
	check("No target in range" in game.typing_label.text and game.typing_keycaps.completion_remaining == 0, "Numbered failure displays no-target instead of successful completion")
	check(manager.typing_slowdown_remaining == 0.5, "Failed retry does not reset slowdown")
	manager.cancel_typing()
	manager.space_casting = true
	manager.start_freeform_typing()
	manager.current_typing_text = "infection"
	manager.attempt_freeform_cast()
	check(manager.is_typing and "No target in range" in game.typing_label.text, "Space failure preserves input and displays targeting reason")
	var visible = target_at(Vector2(80, 0))
	var farther = target_at(Vector2(160, 0))
	check(manager.get_visible_plague_host(plague_info) == visible, "Nearest valid visible host selected past invalid nearer targets")
	var ranged = plague_info.duplicate(true)
	ranged.cast_range = 79
	check(manager.get_visible_plague_host(ranged) == null, "Authored initial cast range is distinct from spread radius")
	ranged.cast_range = 80
	check(manager.get_visible_plague_host(ranged) == visible, "Authored cast range includes its boundary")
	manager.attempt_freeform_cast()
	check(not manager.is_typing and game.spells_cast == cast_count + 1, "Same typed cast succeeds when a valid host enters")
	var infection = get_nodes_in_group("build_spell_effects").back()
	check(infection.infections.is_empty() and infection.infection_links.size() == 1, "Successful Plague launches a spore before host infection")
	visible.dying = true
	check(manager.get_visible_plague_host(plague_info) == farther, "Host acquisition excludes newly dying target")
	farther.queue_free()
	check(manager.get_visible_plague_host(plague_info) == null, "Queued host is excluded immediately")
	var effects_before = get_nodes_in_group("build_spell_effects").size()
	check(not manager.cast_spell_by_type(plague_slot) and get_nodes_in_group("build_spell_effects").size() == effects_before and not infection.is_queued_for_deletion(), "Failed direct dispatch preserves existing infections")
	manager.learn_spell("regeneration")
	manager.learn_spell("soul_bloom")
	check(not manager.cast_freeform_spell("soul bloom"), "Bonus infection uses the same visible living-host contract")
	check(manager.cast_freeform_spell("bolt"), "Unrelated projectile spell still casts without a visible host")
	fresh()
	game.player.is_invincible = false
	game.player.health = 100
	game.player.overheal = 10
	game.player.take_damage(5)
	var feedback = game.particle_manager.get_children()
	check(feedback.filter(func(node): return node.get("kind") == "stone").size() == 1 and not feedback.any(func(node): return node.get("kind") == "hostile"), "Shield-only damage emits stone feedback without red hurt")
	check(game.player.health == 100 and game.player.overheal == 5 and not game.player.is_flashing, "Shield-only absorption preserves health and avoids red player flash")
	check(game.player.last_damage_context.health_loss == 0 and game.player.last_damage_context.overheal_loss == 5, "Shield telemetry records actual absorption")
	for node in feedback:
		node.free()
	game.player.take_damage(8)
	feedback = game.particle_manager.get_children()
	check(feedback.any(func(node): return node.get("kind") == "stone") and feedback.any(func(node): return node.get("kind") == "hostile"), "Overflow emits both shield and health feedback")
	check(game.player.health == 97 and game.player.last_damage_context.health_loss == 3 and game.player.last_damage_context.overheal_loss == 5, "Overflow preserves actual health and shield loss telemetry")
	for node in feedback:
		node.free()
	game.player.take_damage(2)
	feedback = game.particle_manager.get_children()
	check(feedback.any(func(node): return node.get("kind") == "hostile") and not feedback.any(func(node): return node.get("kind") == "stone"), "Unshielded damage emits only red hurt feedback")
	manager.cancel_typing()
	game.queue_free()
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
	await create_timer(0.25).timeout
	print("Casting foundations: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
