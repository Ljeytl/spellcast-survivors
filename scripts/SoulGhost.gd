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
var trail: Array[Vector2] = []

func _ready():
	add_to_group("soul_ghosts")
	z_index = 5
	var visual = preload("res://scripts/vfx/SpiritVisual.gd").new()
	visual.soul = true
	visual.radius = 22.0
	add_child(visual)
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
	healing = hurt
	var target = player if hurt else _nearest_enemy()
	if target == null:
		if not trail.is_empty():
			trail.pop_back()
		queue_redraw()
		return
	heading = global_position.direction_to(target.global_position)
	trail.push_front(global_position)
	if trail.size() > 9:
		trail.pop_back()
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) <= 24.0:
		var arrival_handled := false
		var healed := false
		if hurt:
			if player.has_method("heal"):
				var before: float = player.health
				arrival_handled = player.heal(amount, 1.0, "soul_bloom") == true
				healed = player.health > before
		else:
			preload("res://scripts/engine/Effects.gd").apply(target, {"type": "damage", "entries": [{"amount": amount, "damage_type": "plague"}], "element": "plague"}, source, global_position)
		if not hurt or (healed and not arrival_handled):
			if not _arrival(target.global_position) and healed:
				var particles = player.get_parent().get("particle_manager")
				if is_instance_valid(particles) and particles.has_method("create_heal_effect"):
					particles.create_heal_effect(target.global_position)
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

func _arrival(at: Vector2) -> bool:
	var vfx = get_node_or_null("/root/Vfx")
	if vfx == null or not vfx._active:
		return false
	var point := at / (1280.0 / 192.0)
	var colors := [Color("#fff5ce"), Color("#a5f5d2"), Color("#4a98a8")] if healing else [Color("#e0f3a3"), Color("#9d80c9"), Color("#51416d")]
	vfx.ring(point.x, point.y, 4.2, 0.24, colors)
	vfx.star(point.x, point.y, 2.0, 0.14, 4 if healing else 6, colors[0])
	return true
