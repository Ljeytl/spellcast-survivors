extends SceneTree
## Ember Lance aims through the line with the most enemies, not at the nearest enemy.

var checks = 0
var failures = 0
const Targeting = preload("res://scripts/SpellTargeting.gd")

class Target extends Node2D:
	var current_health = 100.0
	var dying = false

func _initialize():
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func add(position: Vector2) -> Node2D:
	var t = Target.new()
	t.position = position
	root.add_child(t)
	t.add_to_group("enemies")
	return t

func run():
	var lone = add(Vector2(60, 0))
	var line: Array = []
	for i in 5:
		line.append(add(Vector2(0, -150 - i * 80)))
	await process_frame
	var picked = Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0)
	check(picked in line, "Aims through the five-enemy line instead of the nearest lone enemy")
	for t in line:
		t.queue_free()
	await process_frame
	check(Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0) == lone, "With one enemy left it aims at that enemy")
	lone.queue_free()
	await process_frame
	check(Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0) == null, "No enemies, no target")
	print("lance_aim_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
