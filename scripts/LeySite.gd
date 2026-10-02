extends Node2D
## One ley-line site in the world. LeyLines owns the logic; this node stores the
## site's progress and draws it.

enum State { DORMANT, SIEGE, GUARDIAN, ATTUNED }

## Big enough to move and fight inside while typing words.
const RADIUS = 340.0
const COLORS = {
	State.DORMANT: Color("b48cff"),
	State.SIEGE: Color("e2d0ff"),
	State.GUARDIAN: Color("ff8175"),
	State.ATTUNED: Color("f7d87a"),
}

var state: int = State.DORMANT
var words: Array[String] = []
var bound: Array[String] = []
var wave_timer := 0.0
var guardian: Node = null
var dwell := 0.0
var spin := 0.0

func _ready():
	add_to_group("ley_sites")
	# An attuned circle holds the combo like a channelled spell: no decay inside it.
	add_to_group("style_holds")
	z_index = -1

func contains(point: Vector2) -> bool:
	return global_position.distance_to(point) <= RADIUS

func is_style_channel_active() -> bool:
	return state == State.ATTUNED and player_inside()

func player_inside() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return is_instance_valid(player) and contains(player.global_position)

func _process(delta):
	spin += delta * (2.4 if state == State.SIEGE else 0.5)
	queue_redraw()

func _draw():
	var color: Color = COLORS[state]
	var pulse = 0.5 + 0.5 * sin(spin * 2.0)
	var fill = color
	fill.a = 0.10 + (0.12 * pulse if state == State.DORMANT else 0.18 if state == State.SIEGE else 0.06)
	draw_circle(Vector2.ZERO, RADIUS, fill)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 128, color, 5.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.72, spin, spin + TAU, 96, Color(color, 0.55), 3.0)
	for i in 6:
		var angle = spin + i * TAU / 6.0
		var mark = Vector2.from_angle(angle) * RADIUS * 0.86
		draw_line(mark - Vector2.from_angle(angle) * 18.0, mark + Vector2.from_angle(angle) * 18.0, color, 4.0)
	if state != State.ATTUNED:
		draw_circle(Vector2.ZERO, 18.0 + 6.0 * pulse, Color(color, 0.8))
