extends SceneTree

const Model = preload("res://scripts/StyleScore.gd")
const Store = preload("res://scripts/StyleScoreStore.gd")
var assertions := 0
var failures := 0
var path := "user://style_score_regression_%s.json" % Time.get_ticks_usec()

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var model = Model.new()
	check(model.award_cast("bolt", "Bolt", 0.75, 0, 1).pts == 46, "Worked Bolt")
	check(model.award_cast("bolt", "Bolt", 0.75, 0, 1).is_empty(), "Duplicate receipt")
	check(model.grace_remaining == 5.0, "Successful cast grants five seconds of grace")
	check(model.manual_casts == 1 and model.run_score == 46, "No doubled award")
	check(model.award_cast("bolt", "Bolt", 0.75, 0, 2).pts == 39, "Second freshness")
	check(model.award_cast("bolt", "Bolt", 0.75, 0, 3).pts == 33, "Repeated base retained")
	var fast = Model.new()
	check(fast.award_cast("r", "Regeneration", 11.0 / 6.0, 0, 1).pts == 212, "Fast long cast")
	var typo = Model.new()
	check(typo.award_cast("r", "Regeneration", 11.0 / 6.0, 1, 1).pts == 196, "Typo clean bonus")
	var whitespace = Model.new()
	check(whitespace.award_cast("b", " B o L t!! ", 0.75, 0, 1).pts == 46, "Only letters count")
	var invalid = Model.new()
	check(invalid.award_cast("b", "Bolt", NAN, 0, 1).is_empty(), "Reject invalid timing")
	check(invalid.award_cast("b", "!!!", 1.0, 0, 2).is_empty(), "Reject empty incantation")
	var crossing = Model.new()
	crossing.combo = 90.0
	var crossing_award: Dictionary = crossing.award_cast("b", "Bolt", 0.75, 0, 1)
	check(crossing_award.banked == 58 and crossing.rank_index() == 1, "Award uses newly reached multiplier")
	check(crossing.combo == 136.0 and crossing_award.points == 46, "Rank multiplier never multiplies combo gain")
	var expected = [0.0, 100.0, 300.0, 700.0, 1300.0, 2100.0, 3100.0, 4300.0, 5700.0]
	var gaps = [100.0, 200.0, 400.0, 600.0, 800.0, 1000.0, 1200.0, 1400.0]
	for rank in range(1, expected.size()):
		check(Model.THRESHOLDS[rank] == expected[rank], "Cumulative threshold %s" % rank)
		check(Model.THRESHOLDS[rank] - Model.THRESHOLDS[rank - 1] == gaps[rank - 1], "Progressive raw rank cost %s" % rank)
		var boundary = Model.new()
		boundary.combo = expected[rank] - 0.01
		check(boundary.rank_index() == rank - 1, "Below promotion boundary")
		boundary.combo = expected[rank]
		check(boundary.rank_index() == rank and is_zero_approx(boundary.progress()), "Promote and reset bar at threshold")
		boundary.combo = (expected[rank - 1] + expected[rank]) * 0.5
		check(is_equal_approx(boundary.progress(), 0.5), "Bar reflects current rank gap")
	var banked_before: int = crossing.run_score
	crossing.take_hit()
	crossing.advance(1000.0)
	check(crossing.run_score == banked_before, "Hit and decay preserve run score")
	model.combo = 360.0
	model.grace_remaining = 0.0
	var chunked = Model.new()
	chunked.combo = 360.0
	model.advance(40.0)
	for i in 400:
		chunked.advance(0.1)
	check(is_equal_approx(model.combo, chunked.combo), "Piecewise decay frame independent")
	model.combo = 50.0
	model.grace_remaining = Model.GRACE
	model.advance(2.0)
	check(model.combo == 50.0, "Grace retained")
	model.advance(3.0)
	check(model.combo == 50.0, "Full five-second grace has no decay")
	model.advance(2.0)
	check(model.combo == 40.0, "Grace remainder integrated")
	model.combo = 3700.0
	model.take_hit()
	check(is_equal_approx(model.combo, 2600.0), "Hit preserves fraction")
	model.combo = Model.CAP
	model.award_cast("new", "Regeneration", 3.0, 0, 55)
	check(model.combo == Model.CAP and model.progress() == 1.0 and model.peak_rank == 8, "Cap and peak")
	model.take_hit()
	check(model.rank_index() == 7 and model.progress() > 0.999, "Hit at full cap still drops exactly one grade")
	model.advance(99999.0)
	check(model.combo == 0.0, "Complete decay")
	for width in [2, 3, 6]:
		var rotation = Model.new()
		var result: Dictionary
		for i in 120:
			result = rotation.award_cast(str(i % width), "Bolt", 1.0, 0, i)
		check(is_equal_approx(result.freshness_bonus, (0.5 if width == 6 else (width - 1) * 0.05)), "Rotation freshness %s" % width)
	var record := fast.summary()
	record.merge({"run_id": "a", "eligible": true, "outcome": "death"})
	check(Store.submit(record, path), "Save result")
	check(not Store.submit(record, path), "Duplicate result")
	check(Store.list_scores(path).size() == 1, "Load result")
	var malformed = record.duplicate(true)
	malformed.run_id = "malformed"
	malformed.duration = {}
	check(not Store.submit(malformed, path), "Reject malformed displayed duration")
	malformed.duration = 1.0
	malformed.peak_rank = []
	check(not Store.submit(malformed, path), "Reject malformed displayed rank")
	record.run_id = "debug"
	record.eligible = false
	check(not Store.submit(record, path), "Exclude debug")
	record.eligible = true
	record.scoring_version = 99
	check(not Store.submit(record, path), "Reject unknown schema")
	record.scoring_version = Model.VERSION
	record.run_id = "b"
	check(Store.submit(record, path), "Second save")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("corrupt")
	file.close()
	check(Store.list_scores(path).size() == 1, "Recover backup")
	for i in 105:
		record.run_id = "cap_%s" % i
		record.run_score = i
		check(Store.submit(record, path), "Record cap insert")
	var stored := Store.list_scores(path)
	check(stored.size() == 100 and stored[0].run_score >= stored[99].run_score, "Leaderboard bounded and sorted")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)
	print("Style score regression: %s assertions, %s failures" % [assertions, failures])
	quit(1 if failures else 0)
