extends SceneTree
## Ember Spear always goes through the nearest enemy, tilting only to catch more behind it.

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
	# Nearest enemy straight ahead; a line of five sits 10 degrees off. Aiming straight at the
	# nearest misses the line; tilting 10 degrees still passes through the nearest and hits all five.
	var nearest = add(Vector2(60, 0))
	var line: Array = []
	for i in 5:
		line.append(add(Vector2.from_angle(deg_to_rad(10)) * (150 + i * 80)))
	# A bigger crowd far off to the side that the spear can't reach without missing the nearest.
	var crowd: Array = []
	for i in 8:
		crowd.append(add(Vector2(0, -150 - i * 40)))
	await process_frame
	var picked = Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0)
	check(picked in line, "Tilts toward the line that still passes through the nearest enemy")
	check(not picked in crowd, "Never abandons the nearest enemy for a bigger crowd elsewhere")
	for t in line:
		t.queue_free()
	await process_frame
	check(Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0) == nearest, "With no better line it aims straight at the nearest enemy")
	for t in crowd:
		t.queue_free()
	nearest.queue_free()
	await process_frame
	check(Targeting.select_line(self, Vector2.ZERO, 24.0, 1050.0) == null, "No enemies, no target")
	print("lance_aim_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
