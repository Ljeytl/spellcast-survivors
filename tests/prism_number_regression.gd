extends SceneTree

const Manager = preload("res://scripts/DamageManager.gd")
const Number = preload("res://scripts/DamageNumber.gd")
var checks := 0
var failures := 0
var world: Node2D
var manager

class Legacy extends Node2D:
	signal enemy_damaged(amount: float, position: Vector2)

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func labels() -> Array:
	return world.get_children().filter(func(node): return node.get_script() == Number)

func probe():
	var enemy = load("res://scenes/Enemy.tscn").instantiate()
	enemy.set_meta("training_dummy", true)
	world.add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.max_health = 1000.0
	enemy.current_health = 1000.0
	manager.connect_enemy(enemy)
	return enemy

func run():
	root.get_node("AudioManager").quitting = true
	world = Node2D.new()
	root.add_child(world)
	manager = Manager.new()
	world.add_child(manager)
	var source := {"spell":"prism_ray", "cast_id":7}
	var a = probe()
	a.enemy_damaged.connect(manager._on_enemy_damaged)
	manager.connect_enemy(a)
	manager.connect_enemy(a)
	var legacy_events: Array = []
	a.enemy_damaged.connect(func(amount, position): legacy_events.append([amount, position]))
	a.receive_damage(12.4, Vector2.INF, source)
	check(labels().size() == 1 and labels()[0].label.text == "12", "First feedback is immediate and connection upgrade emits one label")
	var number = labels()[0]
	var tween: Tween
	for candidate in get_processed_tweens():
		var before_position = number.global_position
		candidate.custom_step(0.3)
		if number.global_position != before_position:
			tween = candidate
			break
	check(tween != null and number.modulate.a < 1.0, "Fixture advances actual number movement and fade")
	var elapsed = tween.get_total_elapsed_time()
	var position = number.global_position
	var opacity = number.modulate.a
	var tween_count = get_processed_tweens().size()
	a.receive_damage(13.2, Vector2.INF, source)
	check(labels().size() == 1 and is_equal_approx(number.damage_total, 25.6), "Same target cast and tick sum raw resolved damage")
	check(number.label.text == "25" and number.label.get_theme_color("font_color") == Color.ORANGE, "Sum refreshes existing amount thresholds")
	check(number.global_position == position and number.modulate.a == opacity and tween.get_total_elapsed_time() == elapsed and get_processed_tweens().size() == tween_count, "Accumulation never resets position fade or animation")
	check(legacy_events.size() == 2 and is_equal_approx(a.current_health, 974.4), "Legacy signals and actual health retain every contribution")
	var b = probe()
	b.receive_damage(4.0, Vector2.INF, source)
	a.receive_damage(5.0, Vector2.INF, {"spell":"prism_ray", "cast_id":8})
	a.receive_damage(7.0, Vector2.INF, {})
	check(a.last_damage_source.spell == "prism_ray" and labels().back().damage_total == 7.0, "Explicit empty source stays separate despite stale Prism attribution")
	a.receive_damage(6.0, Vector2.INF, {"spell":"mana_bolt", "cast_id":7})
	a.receive_damage(8.0, Vector2.INF, {"spell":"prism_ray"})
	check(labels().size() == 6, "Other target cast spell empty source and missing cast remain separate")
	await physics_frame
	a.receive_damage(9.0, Vector2.INF, source)
	check(labels().size() == 7, "A later physics tick creates fresh immediate feedback")
	var replacement = labels().back()
	replacement.queue_free()
	a.receive_damage(10.0, Vector2.INF, source)
	check(labels().size() == 8 and labels().back() != replacement, "Queued label is never reused")
	var dying = probe()
	dying.current_health = 1.0
	dying.receive_damage(2.0, Vector2.INF, source)
	check(dying.dying and labels().back().damage_total == 2.0, "Killing contribution creates feedback before enemy disposal")
	dying.free()
	var legacy = Legacy.new()
	world.add_child(legacy)
	manager.connect_enemy(legacy)
	manager.connect_enemy(legacy)
	var before = labels().size()
	legacy.enemy_damaged.emit(3.0, Vector2.ZERO)
	check(labels().size() == before + 1, "Legacy-only emitter remains compatible and idempotent")
	var detached = probe()
	var initial_health = detached.current_health
	var callback = manager._on_damage_feedback.bind(detached.get_instance_id())
	detached.damage_feedback.disconnect(callback)
	detached.receive_damage(12.4, Vector2.INF, source)
	detached.receive_damage(13.2, Vector2.INF, source)
	check(is_equal_approx(initial_health - detached.current_health, 25.6), "Disconnecting number presentation leaves resolved damage identical")
	await create_timer(1.1).timeout
	check(labels().is_empty(), "All numbers expire on original one-second lifecycle")
	world.queue_free()
	await process_frame
	print("Prism numbers: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
