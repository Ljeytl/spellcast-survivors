extends "res://tools/capture_spell_combat.gd"

const NumberScene = preload("res://scripts/DamageNumber.gd")
var number_records: Dictionary = {}
var numbers: Array[WeakRef] = []
var resolved_events: Array = []

func _initialize():
	node_added.connect(_observe_node)
	process_frame.connect(_snapshot_numbers)
	super._initialize()

func _observe_node(node):
	if node.has_signal("damage_feedback"):
		var target_id: int = node.get_instance_id()
		node.damage_feedback.connect(func(amount, position, source):
			resolved_events.append({"target": target_id, "frame": Engine.get_physics_frames(), "amount": amount, "position": [position.x, position.y], "source": source.duplicate(true)}))
	if node.get_script() == NumberScene:
		var id: int = node.get_instance_id()
		number_records[id] = {"created_frame": Engine.get_physics_frames(), "amount": 0.0}
		var reference = weakref(node)
		numbers.append(reference)
		node.tree_exiting.connect(func(): _snapshot_number(reference))

func _snapshot_number(reference: WeakRef):
	var node = reference.get_ref()
	if is_instance_valid(node):
		number_records[node.get_instance_id()].amount = node.damage_total

func _snapshot_numbers():
	for reference in numbers:
		_snapshot_number(reference)

func run():
	await super.run()
	_snapshot_numbers()
	var resolved_total := 0.0
	for event in resolved_events:
		resolved_total += float(event.amount)
	var displayed_total := 0.0
	for record in number_records.values():
		displayed_total += float(record.amount)
	var result = {"resolved_events": resolved_events, "numbers": number_records, "resolved_count": resolved_events.size(), "number_count": number_records.size(), "resolved_total": resolved_total, "displayed_raw_total": displayed_total}
	var folder = OS.get_cmdline_user_args()[2]
	FileAccess.open(folder + "/number-telemetry.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("NUMBER_CAPTURE ", JSON.stringify({"resolved_count":resolved_events.size(), "number_count":number_records.size(), "resolved_total":resolved_total, "displayed_raw_total":displayed_total}))
	if resolved_events.is_empty() or not is_equal_approx(resolved_total, displayed_total):
		quit(1)
