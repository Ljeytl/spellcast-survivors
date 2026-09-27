extends Node2D

var remaining = 10.0
var player_ref: WeakRef
var collected = false
var healing_amount = 6.0
var healing_duration = 2.0
var cap = 6

func _ready():
	add_to_group("healing_seeds")
	z_index = 4
	var seeds = get_tree().get_nodes_in_group("healing_seeds").filter(func(seed): return not seed.is_queued_for_deletion() and seed.player_ref and seed.player_ref.get_ref() == player_ref.get_ref())
	while seeds.size() > cap:
		var oldest = seeds.pop_front()
		oldest.queue_free()

func _physics_process(delta):
	var player = player_ref.get_ref() if player_ref else null
	if not is_instance_valid(player) or player.is_queued_for_deletion() or float(player.health) <= 0:
		queue_free()
		return
	remaining -= delta
	if not collected and global_position.distance_to(player.global_position) <= 28 and player.health < player.max_health and player.has_method("start_healing_over_time"):
		collected = true
		player.start_healing_over_time(healing_amount, healing_duration)
		queue_free()
		return
	if remaining <= 0:
		queue_free()
	queue_redraw()

func _draw():
	var art = preload("res://scripts/EffectArt.gd")
	if collected:
		art.wreath(self, "heal", Vector2.ZERO, 24, 0, 0.7, 3)
	else:
		art.stamp(self, "plague", Vector2.ZERO, Vector2.ONE * 24)
		art.stamp(self, "heal", Vector2(0, -13), Vector2.ONE * 10)
