extends Control

signal closed
const STORE = preload("res://scripts/StyleScoreStore.gd")
const MODEL = preload("res://scripts/StyleScore.gd")
var highlight_id = ""
var back: Button

func _ready():
	name = "StyleLeaderboard"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preload("res://scripts/GameplayReadability.gd").apply_theme(self)
	var background = ColorRect.new()
	background.color = Color("111a1b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title = Label.new()
	title.text = "LOCAL HIGH SCORES"
	title.add_theme_font_size_override("font_size", 28)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var hint = Label.new()
	hint.text = "Vary your spells. Cast clean. Keep the combo alive."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 14)
	scroll.add_child(rows)
	var records = STORE.list_scores()
	if records.is_empty():
		var empty = Label.new()
		empty.text = "Your first run starts the legend.\nFinish a run to record a score."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rows.add_child(empty)
	for index in records.size():
		var record = records[index]
		var row = Label.new()
		var seconds = int(record.get("duration", 0))
		var rank = clampi(int(record.get("peak_rank", 0)), 0, MODEL.RANKS.size() - 1)
		row.text = "%02d   %d   ·   %s\n%d:%02d  ·  %s  ·  %s" % [index + 1, int(record.run_score), MODEL.RANKS[rank], seconds / 60, seconds % 60, "Victory" if record.outcome == "victory" else "Defeated", str(record.get("recorded_at", "")).left(10)]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 22)
		if record.run_id == highlight_id:
			row.modulate = Color("f4cf83")
		rows.add_child(row)
	back = Button.new()
	back.text = "BACK"
	back.custom_minimum_size.y = 48
	back.pressed.connect(close)
	column.add_child(back)
	back.grab_focus.call_deferred()

func close():
	closed.emit()
	queue_free()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
