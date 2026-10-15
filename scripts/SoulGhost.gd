extends Node2D
## Soul Bloom's ghost (doc 21 §5.6): leaves an infected enemy that died. If the caster is hurt it flies
## to them and heals `amount`; otherwise it hunts the nearest enemy and deals `amount` as plague.
## At most three at once per caster; each fades after a few seconds.

const SPEED = 320.0
const LIFE = 4.0
const CAP = 3

var cast_ref: WeakRef
var player_ref: WeakRef
var amount := 6.0
var source: Dictionary = {}
var age := 0.0
var healing := false
var heading := Vector2.RIGHT
var visual: Node2D

func _ready():
	add_to_group("soul_ghosts")
	z_index = 5
	visual = preload("res://scripts/vfx/SpiritVisual.gd").new()
	visual.soul = true
	visual.radius = 22.0
	add_child(visual)
	var mine = get_tree().get_nodes_in_group("soul_ghosts").filter(func(g): return g != self and not g.is_queued_for_deletion() and g.player_ref and g.player_ref.get_ref() == player_ref.get_ref())
	while mine.size() >= CAP:
		mine.pop_front()._retire()

func _physics_process(delta):
	age += delta
	var player = player_ref.get_ref() if player_ref else null
	if age >= LIFE or not is_instance_valid(player):
		_retire()
		return
	var hurt = player.get("health") != null and float(player.health) < float(player.max_health)
	healing = hurt
	var target = player if hurt else _nearest_enemy()
	if target == null:
		return
	heading = global_position.direction_to(target.global_position)
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) <= 24.0:
		if hurt:
			if player.has_method("heal"):
				player.heal(amount)
		else:
			preload("res://scripts/engine/Effects.gd").apply(target, {"type": "damage", "entries": [{"amount": amount, "damage_type": "plague"}], "element": "plague"}, source, global_position)
		_arrival(target.global_position)
		_retire(true, target.global_position)
		return

func _nearest_enemy():
	var best = null
	var best_d = INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("dying")):
			continue
		var d = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _arrival(at: Vector2) -> void:
	var vfx = get_node_or_null("/root/Vfx")
	if vfx == null:
		return
	var point := at / (1280.0 / 192.0)
	var colors := [Color("#fff5ce"), Color("#a5f5d2"), Color("#4a98a8")] if healing else [Color("#e0f3a3"), Color("#9d80c9"), Color("#51416d")]
	vfx.ring(point.x, point.y, 4.2, 0.24, colors)
	vfx.star(point.x, point.y, 2.0, 0.14, 4 if healing else 6, colors[0])

func _retire(delivered := false, at := Vector2.ZERO) -> void:
	if is_queued_for_deletion():
		return
	if is_instance_valid(visual):
		visual.finish(delivered, at)
	set_physics_process(false)
	queue_free()
