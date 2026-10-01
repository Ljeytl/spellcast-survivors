extends Node2D
## One ley-line site in the world: a glowing circle the player stands in to start a ritual.
## LeyLines owns the logic; this node only stores its state and draws it.

enum State { DORMANT, RITUAL, COOLING, ATTUNED }

const RADIUS = 90.0
const COLORS = {
	State.DORMANT: Color("b48cff"),
	State.RITUAL: Color("e2d0ff"),
	State.COOLING: Color("6f6a80"),
	State.ATTUNED: Color("f7d87a"),
}

var state: int = State.DORMANT
## A site only wakes again after the player has stepped out of it.
var needs_exit := false
var cooldown := 0.0
var dwell := 0.0
var spin := 0.0

func _ready():
	add_to_group("ley_sites")
	z_index = -1

func contains(point: Vector2) -> bool:
	return global_position.distance_to(point) <= RADIUS

func _process(delta):
	spin += delta * (2.4 if state == State.RITUAL else 0.5)
	queue_redraw()

func _draw():
	var color: Color = COLORS[state]
	var pulse = 0.5 + 0.5 * sin(spin * 2.0)
	var fill = color
	fill.a = 0.10 + (0.12 * pulse if state == State.DORMANT else 0.18 if state == State.RITUAL else 0.06)
	draw_circle(Vector2.ZERO, RADIUS, fill)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, color, 3.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.72, spin, spin + TAU, 48, Color(color, 0.55), 2.0)
	for i in 6:
		var angle = spin + i * TAU / 6.0
		var mark = Vector2.from_angle(angle) * RADIUS * 0.86
		draw_line(mark - Vector2.from_angle(angle) * 7.0, mark + Vector2.from_angle(angle) * 7.0, color, 3.0)
	if state != State.ATTUNED:
		draw_circle(Vector2.ZERO, 10.0 + 4.0 * pulse, Color(color, 0.8))
