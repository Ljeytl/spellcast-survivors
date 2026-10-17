extends Node

var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
var _number_frame := -1
var _prism_numbers: Dictionary = {}

func _ready():
	connect_to_existing_enemies()

func connect_to_existing_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		connect_enemy(enemy)

func connect_enemy(enemy):
	if enemy.has_signal("damage_feedback"):
		if enemy.enemy_damaged.is_connected(_on_enemy_damaged):
			enemy.enemy_damaged.disconnect(_on_enemy_damaged)
		var callback = _on_damage_feedback.bind(enemy.get_instance_id())
		if not enemy.damage_feedback.is_connected(callback):
			enemy.damage_feedback.connect(callback)
	elif not enemy.enemy_damaged.is_connected(_on_enemy_damaged):
		enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(damage: float, position: Vector2):
	_create_number(damage, position)

func _on_damage_feedback(damage: float, position: Vector2, source: Dictionary, target_id: int):
	var frame := Engine.get_physics_frames()
	if frame != _number_frame:
		_prism_numbers.clear()
		_number_frame = frame
	var cast_id = source.get("cast_id")
	var key := ""
	if str(source.get("spell", "")) == "prism_ray" and typeof(cast_id) == TYPE_INT and cast_id > 0:
		key = str(target_id) + ":" + str(cast_id)
		var existing = _prism_numbers.get(key)
		if is_instance_valid(existing) and not existing.is_queued_for_deletion():
			existing.add_damage(damage)
			return
	_create_number(damage, position, key)

func _create_number(damage: float, position: Vector2, key: String = ""):
	var number = damage_number_scene.instantiate()
	number.damage_total = damage
	if key != "":
		_prism_numbers[key] = number
	get_parent().add_child(number)
	number.setup(number.damage_total, position)
