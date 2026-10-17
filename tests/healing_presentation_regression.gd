extends "res://tools/capture_spell_gallery.gd"

class OneArgCaster:
	extends Node2D
	var received := 0.0
	func heal(amount):
		received += amount

class TwoArgCaster:
	extends Node2D
	var received := 0.0
	var size := 0.0
	func heal(amount, visual_size):
		received += amount
		size = visual_size

var checks := 0
var failures := 0

func check(condition: bool, title: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", title)

func pulse_count():
	var count := 0
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/HealingPulse.gd"):
			count += 1
	return count

func run():
	var generic = preload("res://scripts/engine/GenericCast.gd").new()
	var one = OneArgCaster.new()
	var two = TwoArgCaster.new()
	generic.caster = one
	generic.heal_caster(3.0, 2.0)
	check(one.received == 3.0, "one argument healing compatible")
	generic.caster = two
	generic.heal_caster(4.0, 1.5)
	check(two.received == 4.0 and two.size == 1.5, "two argument healing compatible")
	generic.free()
	one.free()
	two.free()
	await setup()
	root.get_node("AudioManager").quitting = true
	var player = game.player
	var vfx = root.get_node("Vfx")
	player.health = player.max_health
	player.heal(4.0, 1.0, "life")
	check(pulse_count() == 0, "full health does not announce recovery")
	player.health = 1.0
	player.next_heal_feedback_msec = 0
	player.heal(4.0, 1.0, "life")
	check(player.health == 5.0, "Life preserves actual heal amount")
	check(pulse_count() == 1, "actual Life recovery emits pulse")
	await create_timer(0.8).timeout
	check(pulse_count() == 0, "Life pulse expires")
	player.next_heal_feedback_msec = 0
	player.heal(0.1, 1.0, "regeneration")
	check(is_equal_approx(player.health, 5.1), "fractional regeneration unchanged")
	check(pulse_count() == 1, "actual regeneration recovery emits pulse")
	var pulse = get_nodes_in_group("healing_visuals")[0]
	vfx.presenter.enabled = false
	await process_frame
	await process_frame
	check(not pulse.visible, "healing pulse obeys presentation toggle")
	vfx.presenter.enabled = true
	check(pulse.gentle, "regeneration recovery uses small gather")
	player.heal(0.1, 1.0, "regeneration")
	check(pulse_count() == 1, "continuous healing feedback remains throttled")
	vfx.clear()
	await process_frame
	check(get_nodes_in_group("healing_visuals").is_empty(), "scene clear removes healing visuals")
	player.next_heal_feedback_msec = 0
	player.heal(1.0)
	check(pulse_count() == 0, "unsourced spirit and pickup healing keeps established feedback")
	assert(game.spell_manager.learn_spell("regeneration"))
	var slot = game.spell_manager.find_spell_slot("regeneration")
	assert(game.spell_manager.cast_spell_by_type(slot))
	await process_frame
	var aura_count := 0
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/RegenerationAura.gd"):
			aura_count += 1
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/RegenerationAura.gd"):
			var held_age = node.age
			paused = true
			await process_frame
			check(node.age == held_age, "aura pauses with game")
			paused = false
			vfx.presenter.enabled = false
			await process_frame
			check(not node.visible, "aura obeys presentation toggle")
			vfx.presenter.enabled = true
	check(aura_count == 1, "real aura part registers persistent visual")
	await create_timer(2.0).timeout
	check(game.spell_manager.cast_spell_by_type(slot), "active regeneration recast accepted")
	await create_timer(3.5).timeout
	var surviving_auras := 0
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/RegenerationAura.gd"):
			surviving_auras += 1
	check(surviving_auras == 1, "recast extends same aura beyond original expiry")
	await create_timer(5.5).timeout
	check(get_nodes_in_group("healing_visuals").is_empty(), "aura and recovery pulses expire with actual spell")
	check(game.spell_manager.cast_spell_by_type(slot), "death scenario cast accepted")
	await process_frame
	var death_auras := 0
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/RegenerationAura.gd"):
			death_auras += 1
	check(death_auras == 1, "death scenario starts with active aura")
	player.health = 0.0
	await create_timer(0.5).timeout
	var remaining_auras := 0
	for node in get_nodes_in_group("healing_visuals"):
		if node.get_script() == preload("res://scripts/vfx/RegenerationAura.gd"):
			remaining_auras += 1
	check(remaining_auras == 0, "aura retires when caster dies")
	print("HEALING PRESENTATION: ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
