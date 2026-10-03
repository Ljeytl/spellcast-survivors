extends Control
## Bottom-right minimap: the player at the centre, ley sites by state, bosses in red.
## Anything beyond the map's range is pinned to its edge in the right direction.

const SIZE = 168.0
## World units from the centre to the map's edge.
const RANGE = 2600.0
const MARGIN = Vector2(16, 40)

var game: Node
var ley: Node

func _ready():
	name = "Minimap"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -SIZE - MARGIN.x
	offset_top = -SIZE - MARGIN.y
	offset_right = -MARGIN.x
	offset_bottom = -MARGIN.y

func _process(_delta):
	visible = game.current_state in [game.GameState.PLAYING, game.GameState.LEVEL_UP]
	queue_redraw()

func to_map(world: Vector2) -> Vector2:
	var center = Vector2(SIZE, SIZE) / 2.0
	var offset = (world - game.player.global_position) / RANGE * (SIZE / 2.0 - 10.0)
	if offset.length() > SIZE / 2.0 - 10.0:
		offset = offset.normalized() * (SIZE / 2.0 - 10.0)
	return center + offset

func _draw():
	var center = Vector2(SIZE, SIZE) / 2.0
	var radius = SIZE / 2.0
	draw_circle(center, radius, Color(0.06, 0.07, 0.1, 0.72))
	draw_arc(center, radius, 0, TAU, 64, Color("e2d0ff", 0.55), 2.0)
	draw_arc(center, radius * 0.5, 0, TAU, 48, Color("e2d0ff", 0.12), 1.0)
	if not is_instance_valid(game.player):
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.get("boss"):
			var p = to_map(enemy.global_position)
			if p.distance_to(center) < radius - 11.0:
				draw_circle(p, 1.5, Color(1, 1, 1, 0.35))
	if ley:
		for site in ley.sites:
			if not is_instance_valid(site):
				continue
			var color = site.COLORS[site.state]
			var p = to_map(site.global_position)
			draw_circle(p, 7.0, Color(color, 0.35))
			draw_arc(p, 7.0, 0, TAU, 20, color, 2.0)
			if site.state != site.State.ATTUNED:
				draw_circle(p, 2.5, color)
	for boss in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(boss) and not boss.dying:
			var p = to_map(boss.global_position)
			draw_circle(p, 5.5, Color("ff8175"))
			draw_arc(p, 5.5, 0, TAU, 16, Color("17101f"), 1.5)
	draw_circle(center, 4.5, Color("79d9e8"))
	draw_arc(center, 4.5, 0, TAU, 16, Color("17101f"), 1.5)
