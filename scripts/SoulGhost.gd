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

func _ready():
	add_to_group("soul_ghosts")
	z_index = 5
	var mine = get_tree().get_nodes_in_group("soul_ghosts").filter(func(g): return g != self and not g.is_queued_for_deletion() and g.player_ref and g.player_ref.get_ref() == player_ref.get_ref())
	while mine.size() >= CAP:
		mine.pop_front().queue_free()

func _physics_process(delta):
	age += delta
	var player = player_ref.get_ref() if player_ref else null
	if age >= LIFE or not is_instance_valid(player):
		queue_free()
		return
	var hurt = player.get("health") != null and float(player.health) < float(player.max_health)
	var target = player if hurt else _nearest_enemy()
	if target == null:
		queue_redraw()
		return
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) <= 24.0:
		if hurt:
			if player.has_method("heal"):
				player.heal(amount)
		else:
			preload("res://scripts/engine/Effects.gd").apply(target, {"type": "damage", "entries": [{"amount": amount, "damage_type": "plague"}], "element": "plague"}, source, global_position)
		queue_free()
		return
	queue_redraw()

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

func _draw():
	var a = clampf(1.0 - age / LIFE, 0.3, 1.0)
	draw_circle(Vector2.ZERO, 9.0, Color(0.75, 0.95, 0.6, 0.55 * a))
	draw_circle(Vector2.ZERO, 5.0, Color(0.95, 1.0, 0.9, 0.85 * a))
