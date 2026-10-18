extends SceneTree

var checks := 0
var failures := 0
var game
var vfx

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func arrive(amount: float = 6.0):
	var spirit = preload("res://scripts/SoulGhost.gd").new()
	spirit.player_ref = weakref(game.player)
	spirit.amount = amount
	game.add_child(spirit)
	spirit.set_physics_process(false)
	spirit.global_position = game.player.global_position + Vector2(10,0)
	spirit._physics_process(0.01)
	return spirit

func run():
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.spell_manager.set_process(false)
	game.spell_manager.set_process_input(false)
	game.spell_manager.cancel_typing()
	game.player.set_physics_process(false)
	game.get_node("MonsterManager").set_process(false)
	game.get_node("MonsterManager").spawn_timer.stop()
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	vfx = root.get_node("Vfx")
	vfx.set_process(false)
	vfx._active = true
	vfx.clear()
	game.player.health = 50
	game.player.next_heal_feedback_msec = 0
	var signals: Array = []
	game.player.health_changed.connect(func(health, _max, _over): signals.append({"health":health,"rings":vfx._rings.size()}))
	var first = arrive()
	check(game.player.health == 56 and first.is_queued_for_deletion(),"Actual Soul arrival heals once and retires")
	check(signals.size() == 1 and signals[0].rings == 0,"Health signal precedes compact Soul feedback")
	check(vfx._rings.size() == 1 and vfx._stars.size() == 1,"Soul arrival emits exactly one compact ring/star")
	game.player.next_heal_feedback_msec = Time.get_ticks_msec()+5000
	var throttle: int = game.player.next_heal_feedback_msec
	arrive()
	if "--known-bad-generic-burst" in OS.get_cmdline_user_args():
		vfx.prop_burst("heal",game.player.global_position)
	check(game.player.health == 62 and vfx._rings.size() == 2 and vfx._stars.size() == 2,"Clustered arrival retains one compact cue within throttle")
	check(vfx.elements.leaves.is_empty() and vfx.elements.motes.is_empty(),"Soul arrivals omit generic leaf/mote burst")
	check(game.player.next_heal_feedback_msec == throttle,"Soul arrival preserves active generic throttle")
	vfx.clear()
	game.player.health = 98
	arrive()
	check(game.player.health == 100 and vfx._rings.size() == 1,"Soul healing caps at maximum with one cue")
	var before: int = vfx._rings.size()
	check(game.player.heal(6,1,"soul_bloom") == false and vfx._rings.size() == before,"Full-health no-op reports unhandled without false heal cue")
	check(game.player.heal(0,1,"soul_bloom") == false and vfx._rings.size() == before,"Zero heal cannot report handled feedback")
	vfx.clear()
	game.player.health = 50
	vfx.presenter.enabled = false
	arrive()
	check(game.player.health == 56 and vfx._rings.size() == 1 and vfx._stars.size() == 1,"Unavailable dedicated presenter retains existing compact fallback")
	vfx.presenter.enabled = true
	vfx.clear()
	vfx._active = false
	var children_before: int = game.particle_manager.get_child_count()
	arrive()
	check(game.player.health == 62 and game.particle_manager.get_child_count() > children_before,"Inactive VFX retains particle fallback after actual heal")
	vfx._active = true
	vfx.clear()
	game.player.next_heal_feedback_msec = 0
	game.player.heal(6)
	check(game.player.health == 68 and vfx.elements.leaves.size() == 7 and vfx.elements.motes.size() == 5 and vfx._rings.size() == 1,"Ordinary heal retains generic burst and health behavior")
	game.player.heal(6)
	check(game.player.health == 74 and vfx.elements.leaves.size() == 7 and vfx._rings.size() == 1,"Ordinary clustered heal remains throttled")
	game.queue_free()
	await process_frame
	vfx.clear()
	print("SOUL_HEAL checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
