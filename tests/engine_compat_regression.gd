extends SceneTree
## Compatibility layer: old spells untouched, generic spells cast through the real SpellManager,
## old spells with unsupported keywords fail with a reason, typing/auto-cast rules (doc 18 §11).

var checks = 0
var failures = 0

class Target extends Node2D:
	var current_health = 100000.0
	var max_health = 100000.0
	var dying = false
	var taken = 0.0
	func take_damage(amount, _p = Vector2.ZERO, _s = {}):
		current_health -= amount
		taken += amount
	func apply_slow(_a, _d):
		pass

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

func bolts(game):
	return game.get_children().filter(func(n): return n is Area2D and n.get("projectile_type") == "bolt")

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var mm = game.get_node("MonsterManager")
	mm.spawn_timer.stop()
	mm.set_process(false)
	game.player.set_physics_process(false)
	var manager = game.spell_manager
	manager.set_process(false)
	var released: Array = []
	manager.manual_spell_released.connect(func(f, c, _t): released.append([f, c]))

	# Legacy spells keep their paths.
	var target = Target.new()
	game.add_child(target)
	target.global_position = game.player.global_position + Vector2(240, 0)
	target.add_to_group("enemies")
	var before = bolts(game).size()
	check(manager.cast_freeform_spell("bolt"), "Legacy Bolt still casts")
	check(bolts(game).size() > before, "Legacy Bolt spawns its own projectile")
	check(manager.last_generic_cast == null, "Legacy cast does not touch the generic engine")
	check(manager.cast_freeform_spell("mega bolt") and manager.pending_keyword_casts.size() == 1, "MEGA Bolt still uses the charge path")
	manager.discard_pending_casts()
	check(manager.cast_freeform_spell("bolt mega") and manager.pending_keyword_casts.size() == 1, "MEGA after the name also reaches the legacy charge")
	manager.discard_pending_casts()
	check(not manager.cast_freeform_spell("icy bolt") and manager.last_cast_failure == "ICY doesn't work on Bolt yet", "Unsupported keyword on an old spell fails with a reason: " + manager.last_cast_failure)
	check(not manager.cast_freeform_spell("triple mega bolt") and manager.last_cast_failure.begins_with("TRIPLE"), "Any non-MEGA keyword is refused on old spells")
	check(manager.find_cast_spell_slot("big bolt") == 0, "Legacy slot lookup unchanged")

	# Generic spells.
	check(manager.castable_generic_spells().has("spear") and not manager.castable_generic_spells().has("fireball"), "Bare forms castable, data-only spells not")
	check(manager.get_owned_incantations().has("nova"), "Bare forms appear in owned incantations")
	released.clear()
	check(manager.cast_freeform_spell("spear"), "Bare Spear casts")
	var cast = manager.last_generic_cast
	check(cast != null and is_instance_valid(cast) and cast.plan.id == "spear", "Spear runs through the generic engine")
	check(released.size() == 1 and released[0][0] == "spear", "Generic casts emit manual_spell_released")
	check(cast.source.has("cast_id") and cast.source.spell == "spear", "Generic casts carry a damage source with a cast id")
	for i in 90:
		await physics_frame
	check(target.taken > 0.0, "Generic Spear damages a legacy-only target through the fallback (" + str(target.taken) + ")")
	check(manager.cast_freeform_spell("triple mega icy spear"), "Keywords compose on a generic spell")
	check(int(manager.last_generic_cast.plan.arrangement.count) == 3, "Triple applied")
	var cracked: Array = []
	manager.keyword_cracked.connect(func(w, r): cracked.append([w, r]))
	check(manager.cast_freeform_spell("lasting spear"), "A rejected word does not stop the cast")
	check(cracked.size() == 1 and cracked[0][0] == "lasting" and manager.last_cracked.size() == 1, "The rejected word cracks with a reason: " + str(cracked))
	check(manager.last_generic_cast.plan.id == "spear" and not manager.last_generic_cast.plan.parts.spear.has("timing"), "Spear casts as if the word were absent")
	check(not manager.cast_freeform_spell("blorp spear") and manager.last_cast_failure.contains("blorp"), "Unknown words fail")
	check(not manager.cast_freeform_spell("fireball"), "Unlearned generic spells cannot be cast")
	manager.learned_generic_spells.append("fireball")
	check(manager.cast_freeform_spell("fireball"), "Learned generic spells can")
	cracked.clear()
	check(manager.cast_freeform_spell("mega mega spear") and cracked.size() == 1 and cracked[0][1] == "used twice", "A duplicate word cracks; the spell still casts")
	check(abs(float(manager.last_generic_cast.plan.bundle.power) - 1.5) < 0.001, "The cracked duplicate adds nothing")
	cracked.clear()
	check(manager.cast_freeform_spell("triple warding spear") and cracked.size() == 1 and cracked[0][0] == "warding", "Unbuilt WARDING cracks, TRIPLE still applies")
	check(not manager.cast_freeform_spell("mega mega bolt") and manager.last_cast_failure.begins_with("MEGA"), "Old spells still refuse anything but one MEGA")

	# Real enemy, typed pipeline.
	var enemy = mm.spawn_monster(mm.select_monster(), false, true)
	await process_frame
	if enemy:
		enemy.max_health = 100000.0
		enemy.current_health = 100000.0
		enemy.global_position = game.player.global_position + Vector2(0, -200)
		target.remove_from_group("enemies")
		var hp = enemy.current_health
		manager.cast_freeform_spell("iron spear")
		for i in 60:
			await physics_frame
		check(enemy.current_health < hp, "Generic spell damages a real enemy")
		check(enemy.status != null and enemy.status.bleed_meter > 0.0, "Element word status reaches a real enemy")
		target.add_to_group("enemies")

	# SANGUINE pays in health and the health bar hears about it.
	var heard: Array = []
	game.player.health_changed.connect(func(h, _m, _o): heard.append(h))
	game.player.health = game.player.max_health
	check(manager.cast_freeform_spell("sanguine spear"), "Sanguine spear casts")
	for i in 3:
		await physics_frame
	check(game.player.health < game.player.max_health and not heard.is_empty() and is_equal_approx(heard.back(), game.player.health), "Sanguine cost emits health_changed")
	check(game.player.last_damage_context.get("kind", "") == "sanguine", "Sanguine cost is attributed")

	# Auto-cast rules.
	check(manager.generic_autocast_ready("spear"), "Bare spear auto-casts")
	check(not manager.generic_autocast_ready("spea"), "Partial name does not")
	check(manager.generic_autocast_ready("mega spear"), "Keyword + name auto-casts")
	check(not manager.generic_autocast_ready("spear "), "Trailing space waits for more words")
	check(not manager.generic_autocast_ready("bolt"), "Old spell names are not generic auto-casts")
	check(not manager.generic_autocast_ready("icy bolt"), "Old spell + keyword waits for Enter (then fails with a reason)")
	print("engine_compat_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)
