extends RefCounted

const VERSION = preload("res://scripts/StyleScore.gd").VERSION
const DEFAULT_PATH := "user://style_scores_v1.json"
const LIMIT := 100

static func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	var data = parser.data
	if not data is Dictionary or data.get("version") != VERSION or not data.get("records") is Array:
		return null
	var records: Array = []
	for record in data.records:
		if _valid(record):
			records.append(record)
	return records

static func _valid(record: Variant) -> bool:
	if not record is Dictionary:
		return false
	if record.get("scoring_version") != VERSION or record.get("eligible", false) != true:
		return false
	if not record.get("run_id") is String or record.run_id.is_empty():
		return false
	if record.get("outcome", "") not in ["victory", "death"]:
		return false
	for field in ["peak_rank", "duration", "manual_casts", "clean_casts", "special_casts"]:
		var value = record.get(field, 0)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0:
			return false
		if field != "duration" and floor(float(value)) != float(value):
			return false
	if float(record.get("peak_rank", 0)) > 8:
		return false
	var score = record.get("run_score")
	return (score is int or score is float) and is_finite(float(score)) and score >= 0 and floor(float(score)) == float(score)

static func list_scores(path: String = DEFAULT_PATH) -> Array:
	var records = _read(path)
	if records == null:
		records = _read(path + ".bak")
	if records == null:
		return []
	records.sort_custom(func(a, b): return a.run_score > b.run_score)
	return records.slice(0, LIMIT)

static func submit(record: Dictionary, path: String = DEFAULT_PATH) -> bool:
	if not _valid(record):
		return false
	var records := list_scores(path)
	for existing in records:
		if existing.run_id == record.run_id:
			return false
	records.append(record.duplicate(true))
	records.sort_custom(func(a, b): return a.run_score > b.run_score)
	records = records.slice(0, LIMIT)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": VERSION, "records": records}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _read(temporary) == null:
		DirAccess.remove_absolute(temporary)
		return false
	if _read(path) != null:
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			DirAccess.remove_absolute(temporary)
			return false
	return DirAccess.rename_absolute(temporary, path) == OK
