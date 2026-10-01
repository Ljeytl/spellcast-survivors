extends RefCounted

const VERSION := 3
const RANKS := ["F", "E", "D", "C", "B", "A", "S", "SS", "SSS"]
const THRESHOLDS := [0.0, 100.0, 300.0, 700.0, 1300.0, 2100.0, 3100.0, 4300.0, 5700.0]
const MULTIPLIERS := [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0]
const DECAY := [5.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0, 65.0, 80.0]
const CAP := 12000.0
## Atomic: every ATOMIC_COMBO_PER_CHARGE combo score earns a charge (max ATOMIC_MAX_CHARGES).
## Casting needs rank S or better and spends one charge. Charges are lost when the combo ends.
const ATOMIC_COMBO_PER_CHARGE := 10000
const ATOMIC_MAX_CHARGES := 3
const ATOMIC_RANK := 6
const GRACE := 5.0
const PICKUP_POINTS := 200

var combo := 0.0
var run_score := 0
## Banked points earned during the current combo; resets when the bar empties completely.
var combo_score := 0
var best_combo_score := 0
var atomic_charges := 0
var next_charge_at := ATOMIC_COMBO_PER_CHARGE
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
	end_combo_if_empty()

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
	var keyword_multiplier = float(preload("res://scripts/KeywordRules.gd").for_incantation(canonical).get("style", 1.0))
	var points := int(floor(base * (1.0 + speed + clean + 0.5 * fresh) * keyword_multiplier + 0.5))
	for key in freshness:
		if key != family:
			freshness[key] = minf(1.0, freshness[key] + 0.1)
	freshness[family] = maxf(0.0, fresh - 0.5)
	var old_rank := rank_index()
	combo = minf(CAP, combo + points)
	var banked := int(floor(points * multiplier() + 0.5))
	bank(banked)
	manual_casts += 1
	if mistakes == 0:
		clean_casts += 1
	peak_rank = maxi(peak_rank, rank_index())
	peak_combo = maxf(peak_combo, combo)
	grace_remaining = GRACE
	return {"keyword_multiplier": keyword_multiplier, "points": points, "pts": points, "banked": banked, "old_rank": old_rank, "rank": rank_index(), "rank_changed": old_rank != rank_index(), "speed_bonus": speed, "clean_bonus": clean, "freshness_bonus": 0.5 * fresh, "length": length}

func award_pickup() -> Dictionary:
	var before := rank_index()
	var banked := int(round(PICKUP_POINTS * multiplier()))
	combo = minf(CAP, combo + PICKUP_POINTS)
	bank(banked)
	peak_rank = maxi(peak_rank, rank_index())
	peak_combo = maxf(peak_combo, combo)
	return {"points": PICKUP_POINTS, "banked": banked, "old_rank": before, "rank": rank_index()}

## Kills bank score at full value and add combo scaled by combo_factor (cast age, 0 for
## Magic Missile/Atomic). They never refresh decay grace. Points are the enemy's XP value.
func award_kill(points: float, combo_factor: float = 1.0) -> Dictionary:
	if not is_finite(points) or points <= 0.0:
		return {}
	var before := rank_index()
	var banked := int(round(points * multiplier()))
	combo = minf(CAP, combo + points * clampf(combo_factor, 0.0, 1.0))
	bank(banked)
	peak_rank = maxi(peak_rank, rank_index())
	peak_combo = maxf(peak_combo, combo)
	return {"points": points, "banked": banked, "old_rank": before, "rank": rank_index()}

## Adds banked points to total score and to the current combo, earning Atomic charges.
func bank(points: int) -> void:
	run_score += points
	combo_score += points
	best_combo_score = maxi(best_combo_score, combo_score)
	while combo_score >= next_charge_at:
		next_charge_at += ATOMIC_COMBO_PER_CHARGE
		atomic_charges = mini(ATOMIC_MAX_CHARGES, atomic_charges + 1)

## The combo ends only when the bar is completely empty: combo score and unspent charges go with it.
func end_combo_if_empty() -> void:
	if combo > 0.0 or combo_score == 0:
		return
	combo_score = 0
	atomic_charges = 0
	next_charge_at = ATOMIC_COMBO_PER_CHARGE

func take_hit() -> void:
	var index := rank_index()
	if index == 0:
		combo = 0.0
		end_combo_if_empty()
		return
	var fraction := minf(progress(), 0.999999)
	combo = THRESHOLDS[index - 1] + fraction * (THRESHOLDS[index] - THRESHOLDS[index - 1])

func summary() -> Dictionary:
	return {"scoring_version": VERSION, "run_score": run_score, "best_combo_score": best_combo_score, "peak_rank": peak_rank, "peak_combo": peak_combo, "manual_casts": manual_casts, "clean_casts": clean_casts, "final_combo": combo}
