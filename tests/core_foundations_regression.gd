extends SceneTree
## Doc 19 step 1: event bus and seeded random streams.

const EventBus = preload("res://scripts/core/EventBus.gd")
const Rng = preload("res://scripts/core/Rng.gd")

var checks: int = 0
var failures: int = 0

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

class Listener extends RefCounted:
	var seen: Array = []
	func on_kill(payload: Dictionary):
		seen.append(payload.target_id)

func run():
	# Event bus: delivery, order, unsubscribe, freed listeners, reset.
	EventBus.reset()
	var order: Array = []
	var first = func(p): order.append("first:%s" % p.target_id)
	var second = func(p): order.append("second:%s" % p.target_id)
	EventBus.on("kill", first)
	EventBus.on("kill", second)
	EventBus.on("kill", first)  # duplicate subscription is ignored
	var payload = {"target_id": 7, "source_id": 1, "cast_id": 3, "position": Vector2.ZERO}
	check(EventBus.emit("kill", payload) == 2, "Both listeners run once")
	check(order == ["first:7", "second:7"], "Listeners run in subscription order: %s" % str(order))
	EventBus.off("kill", first)
	order.clear()
	EventBus.emit("kill", payload)
	check(order == ["second:7"], "Unsubscribed listener no longer runs")
	check(EventBus.emit("damage_dealt", {"source_id": 1, "cast_id": 3, "target_id": 7, "per_type": {"fire": 5.0}, "total": 5.0, "killed": false}) == 0, "Events without listeners deliver to nobody")
	var listener = Listener.new()
	EventBus.on("kill", listener.on_kill)
	EventBus.emit("kill", payload)
	check(listener.seen == [7], "Object method listeners receive the payload")
	listener = null  # RefCounted freed: its callable becomes invalid
	check(EventBus.emit("kill", payload) == 1, "Freed listeners are dropped instead of erroring")
	check(EventBus.listener_count("kill") == 1, "Freed listener removed from the list")
	EventBus.reset()
	check(EventBus.listener_count("kill") == 0, "reset() drops every subscription")
	for event in EventBus.EVENTS:
		check(EventBus.EVENTS[event] is Array and not EventBus.EVENTS[event].is_empty(), "Event '%s' declares its fields" % event)

	# Seeded streams: same seed, same rolls; streams independent; casts reproducible.
	Rng.begin_run(12345)
	var a = [Rng.stream("spawn").randf(), Rng.stream("spawn").randf(), Rng.stream("loot").randi()]
	var cast_a = Rng.for_cast(42).randf()
	Rng.begin_run(12345)
	var loot_first = Rng.stream("loot").randi()  # touching streams in another order changes nothing
	var b = [Rng.stream("spawn").randf(), Rng.stream("spawn").randf(), loot_first]
	check(a == b, "Same run seed gives the same rolls per stream regardless of order: %s vs %s" % [str(a), str(b)])
	check(is_equal_approx(Rng.for_cast(42).randf(), cast_a), "Same cast id gives the same rolls")
	check(not is_equal_approx(Rng.for_cast(43).randf(), cast_a), "Different cast ids differ")
	check(Rng.for_cast(42, "fan").seed != Rng.for_cast(42).seed, "Salt separates rolls within one cast")
	Rng.begin_run(54321)
	check(not is_equal_approx(Rng.stream("spawn").randf(), a[0]), "A different run seed changes the rolls")
	check(Rng.derive(1, "spawn") == Rng.derive(1, "spawn") and Rng.derive(1, "spawn") != Rng.derive(2, "spawn"), "Seed derivation is stable and depends on the base seed")
	# Golden value: the same on every platform (wrapping 64-bit integer maths), so web and desktop replays agree.
	check(Rng.derive(12345, "spawn") == -7371210804004007672, "Seed derivation matches the golden value: %d" % Rng.derive(12345, "spawn"))

	print("core_foundations_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
