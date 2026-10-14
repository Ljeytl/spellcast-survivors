extends Node2D
## A healing circle left by a healing word on an area impact (doc 21 §4.3): while the caster stands
## inside, it heals them at total / duration, until the time or the healing runs out.

var player_ref: WeakRef
var radius := 60.0
var total := 10.0
var duration := 3.0
var age := 0.0
var given := 0.0

func _ready():
	add_to_group("healing_zones")
	z_index = 3

func _physics_process(delta):
	age += delta
	var player = player_ref.get_ref() if player_ref else null
	if age >= duration or given >= total - 0.0001 or not is_instance_valid(player):
		queue_free()
		return
	if global_position.distance_to(player.global_position) <= radius and player.has_method("heal"):
		var amount = minf(total / duration * delta, total - given)
		given += amount
		player.heal(amount)
	queue_redraw()

func _draw():
	preload("res://scripts/AreaArt.gd").circle(self, Vector2.ZERO, radius, Color("91dca2"), clampf(1.0 - age / maxf(duration, 0.01), 0.2, 1.0))
