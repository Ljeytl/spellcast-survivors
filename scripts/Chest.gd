extends Area2D
class_name Chest

enum ChestType {
	HEALTH,
	XP,
	MIXED
}

@export var chest_type: ChestType = ChestType.MIXED
@export var health_amount: float = 25.0
@export var xp_amount: float = 50.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collection_area: Area2D = $CollectionArea

var closed_texture = preload("res://sprites/items/chest_2_closed.png")
var open_texture = preload("res://sprites/items/chest_2_open.png")

var is_collected: bool = false
var collection_range: float = 40.0

signal chest_collected(chest_type: ChestType, health: float, xp: float)

func _ready():
	# Connect collection area
	if collection_area:
		collection_area.body_entered.connect(_on_collection_area_entered)
	
	# Set initial sprite
	if sprite:
		sprite.texture = closed_texture
	
	# Set collection area size
	var collection_shape = RectangleShape2D.new()
	collection_shape.size = Vector2(collection_range, collection_range)
	$CollectionArea/CollectionShape.shape = collection_shape
	
	# Add visual feedback
	add_glow_effect()

func _on_collection_area_entered(body):
	if is_collected:
		return
	
	# Check if it's the player
	if body.has_method("collect_chest") or body.is_in_group("player"):
		collect_chest(body)

func collect_chest(player):
	if is_collected:
		return
	
	is_collected = true
	
	# Change sprite to open chest
	if sprite:
		sprite.texture = open_texture
	
	# Determine rewards based on chest type
	var health_reward: float = 0.0
	var xp_reward: float = 0.0
	
	match chest_type:
		ChestType.HEALTH:
			health_reward = health_amount
		ChestType.XP:
			xp_reward = xp_amount
		ChestType.MIXED:
			health_reward = health_amount * 0.6
			xp_reward = xp_amount * 0.8
	
	# Apply rewards to player
	if player.has_method("heal"):
		player.heal(health_reward)
	if player.has_method("gain_xp"):
		player.gain_xp(xp_reward)
	
	# Emit signal for game manager
	chest_collected.emit(chest_type, health_reward, xp_reward)
	
	# Create collection effects
	create_collection_effects()
	
	# Remove chest after a brief delay
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(queue_free)

func create_collection_effects():
	# Get game node for particle effects
	var game = get_tree().get_first_node_in_group("game")
	if game:
		match chest_type:
			ChestType.HEALTH:
				if game.has_method("create_heal_effect"):
					game.create_heal_effect(global_position)
			ChestType.XP:
				if game.has_method("create_xp_collect_effect"):
					game.create_xp_collect_effect(global_position)
			ChestType.MIXED:
				if game.has_method("create_heal_effect"):
					game.create_heal_effect(global_position)
				if game.has_method("create_xp_collect_effect"):
					game.create_xp_collect_effect(global_position + Vector2(10, 0))

func add_glow_effect():
	# Add a subtle glow effect to make chests more visible
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.0), 1.0)
	glow_tween.tween_property(sprite, "modulate", Color.WHITE, 1.0)

func set_random_chest_type():
	# Randomly set chest type with equal probability
	var rand_val = randf()
	if rand_val < 0.33:
		chest_type = ChestType.HEALTH
		if sprite:
			sprite.modulate = Color(1.0, 0.8, 0.8)  # Red tint for health
	elif rand_val < 0.66:
		chest_type = ChestType.XP
		if sprite:
			sprite.modulate = Color(0.8, 0.8, 1.0)  # Blue tint for XP
	else:
		chest_type = ChestType.MIXED
		if sprite:
			sprite.modulate = Color(1.0, 1.0, 0.8)  # Yellow tint for mixed
