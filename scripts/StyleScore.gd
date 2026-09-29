extends RefCounted

const VERSION := 1
const RANKS := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
const THRESHOLDS := [0.0, 150.0, 350.0, 650.0, 1000.0, 1450.0, 2000.0, 2700.0, 3500.0]
const MULTIPLIERS := [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0]
const DECAY := [5.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0, 65.0, 80.0]
const CAP := 4500.0
const GRACE := 3.0

var combo := 0.0
var run_score := 0
var peak_rank := 0
var peak_combo := 0.0
var manual_casts := 0
var clean_casts := 0
var grace_remaining := 0.0
var freshness: Dictionary = {}
var receipts: Dictionary = {}

func rank_index() -> int:
	for i in range(THRESHOLDS.size() - 1, -1, -1):
		if combo >= THRESHOLDS[i]:
			return i
	return 0

func multiplier() -> float:
	return MULTIPLIERS[rank_index()]

func progress() -> float:
	var index := rank_index()
	var upper: float = THRESHOLDS[index + 1] if index + 1 < THRESHOLDS.size() else CAP
	return clampf((combo - THRESHOLDS[index]) / (upper - THRESHOLDS[index]), 0.0, 1.0)

func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	var remaining := seconds
	var grace_used := minf(remaining, grace_remaining)
	grace_remaining -= grace_used
	remaining -= grace_used
	while remaining > 0.0 and combo > 0.0:
		var index := rank_index()
		if index > 0 and combo == THRESHOLDS[index]:
			index -= 1
		var distance: float = combo - THRESHOLDS[index]
		var duration: float = distance / DECAY[index]
		if remaining >= duration:
			combo = THRESHOLDS[index]
			remaining -= duration
		else:
			combo -= remaining * DECAY[index]
			remaining = 0.0

func award_cast(family: String, canonical: String, elapsed: float, mistakes: int, receipt: int) -> Dictionary:
	if family.is_empty() or receipts.has(receipt) or not is_finite(elapsed) or elapsed < 0.0 or mistakes < 0:
		return {}
	var length := 0
	for letter in canonical.to_lower():
		if letter >= "a" and letter <= "z":
			length += 1
	if length == 0:
		return {}
	receipts[receipt] = true
	var base := 10.0 + 2.0 * length + 0.5 * length * length
	var speed := 0.0
	if length > 1:
		speed = clampf(((length - 1) / maxf(elapsed, 0.25) / 4.0 - 1.0) * 0.5, 0.0, 0.5)
	var clean := 0.25 if mistakes == 0 else (0.10 if mistakes == 1 else 0.0)
	var fresh: float = freshness.get(family, 1.0)
	var points := int(floor(base * (1.0 + speed + clean + 0.5 * fresh) + 0.5))
	for key in freshness:
		if key != family:
			freshness[key] = minf(1.0, freshness[key] + 0.1)
	freshness[family] = maxf(0.0, fresh - 0.5)
	var old_rank := rank_index()
	combo = minf(CAP, combo + points)
	var banked := int(floor(points * multiplier() + 0.5))
	run_score += banked
	manual_casts += 1
	if mistakes == 0:
		clean_casts += 1
	peak_rank = maxi(peak_rank, rank_index())
	peak_combo = maxf(peak_combo, combo)
	grace_remaining = GRACE
	return {"points": points, "pts": points, "banked": banked, "old_rank": old_rank, "rank": rank_index(), "rank_changed": old_rank != rank_index(), "speed_bonus": speed, "clean_bonus": clean, "freshness_bonus": 0.5 * fresh, "length": length}

func take_hit() -> void:
	var index := rank_index()
	if index == 0:
		combo = 0.0
		return
	var fraction := minf(progress(), 0.999999)
	combo = THRESHOLDS[index - 1] + fraction * (THRESHOLDS[index] - THRESHOLDS[index - 1])

func summary() -> Dictionary:
	return {"scoring_version": VERSION, "run_score": run_score, "peak_rank": peak_rank, "peak_combo": peak_combo, "manual_casts": manual_casts, "clean_casts": clean_casts, "final_combo": combo}
