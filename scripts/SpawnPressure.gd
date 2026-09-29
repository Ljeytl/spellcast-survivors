extends RefCounted

var level := 0.0
var elapsed := 0.0
var sample_elapsed := 0.0
var kills := 0
var kill_seconds: Dictionary = {}
var refill_elapsed := 0.0

func record_kill():
	kills += 1
	kill_seconds[int(elapsed)] = true

func advance(delta: float, population: int, target: int):
	if delta <= 0.0:
		return
	elapsed += delta
	sample_elapsed += delta
	refill_elapsed = maxf(0.0, refill_elapsed - delta)
	if sample_elapsed < 5.0:
		return
	if delta <= 5.0 and kills >= 6 and kill_seconds.size() >= 3 and population < target * 2:
		level = minf(1.0, level + 0.125)
	else:
		level = maxf(0.0, level - 0.0625 * floorf(sample_elapsed / 5.0))
	sample_elapsed = 0.0
	kills = 0
	kill_seconds.clear()

func refill_count(population: int, target: int) -> int:
	if refill_elapsed > 0.0 or population >= target:
		return 0
	refill_elapsed = 0.6
	return mini(6, target - population)
