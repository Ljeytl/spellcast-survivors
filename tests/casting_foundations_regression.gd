extends SceneTree

var checks = 0
var failures = 0
var game
var manager

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
	manager.advance_typing_slowdown(2.5)
	check(is_equal_approx(manager.typing_slowdown_remaining, 0.5), "Unscaled typing seconds drain once")
	manager.advance_typing_slowdown(1)
	check(manager.is_typing and manager.typing_slowdown_remaining == 0 and Engine.time_scale == 1, "Exhaustion preserves editable cast at normal speed")
	manager.cancel_typing()
	manager.advance_typing_slowdown(50)
	check(manager.typing_slowdown_remaining == 0, "Idle time does not refill a shared reserve")
	manager.activate_spell_slot(1)
	check(manager.typing_slowdown_remaining == 3 and is_equal_approx(Engine.time_scale, 0.2), "New numbered cast gets fresh allowance")
	manager.cancel_typing()
	manager.space_casting = true
	manager.start_freeform_typing()
	check(manager.typing_slowdown_remaining == 3, "Space cast also starts fresh")
	manager.cancel_typing()
	game._on_upgrade_selected({"name":"Focus", "effect":{"type":"slowdown_duration","value":0.5}})
	manager.activate_spell_slot(1)
	check(manager.typing_slowdown_remaining == 3.5 and is_equal_approx(Engine.time_scale,0.2), "Focus changes duration without changing strength")
	manager._scale_change_frame = -1
	manager._process(0.1)
	check(is_equal_approx(manager.typing_slowdown_remaining, 3.0), "Scaled delta converts to real time once at fixed0.2speed")
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
	for id in ["life", "regeneration", "lightning_arc", "ice_blast", "earth_shield"]:
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
	check(game.player.health == 84, "Regeneration provides distinct40HP over5seconds")
	game.player.health = 40
	game.player.start_healing_over_time(6,2)
	manager.process_healing_effects(0.5)
	check(game.player.health == 41.5, "Healing seed API ticks only actual elapsed duration")
	manager.process_healing_effects(5)
	check(game.player.health == 46, "Healing seed API clamps finaltick andtotal")
	game.queue_free()
	await process_frame
	print("Casting foundations: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
