extends Node

var damage_number_scene = preload("res://scenes/DamageNumber.tscn")

func _ready():
	# Connect to all enemy damage signals
	connect_to_existing_enemies()

func connect_to_existing_enemies():
	# Connect to any enemies that already exist
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not enemy.enemy_damaged.is_connected(_on_enemy_damaged):
			enemy.enemy_damaged.connect(_on_enemy_damaged)

func _on_enemy_damaged(damage: float, position: Vector2):
	# Create floating damage number
	var damage_number = damage_number_scene.instantiate()
	damage_number.setup(damage, position)
	get_parent().add_child(damage_number)
