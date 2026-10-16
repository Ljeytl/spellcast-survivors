extends Control
## While a boss is alive (playtest 0.3.4: "I forget there's a boss, I just sat there and farmed"):
## its name and health across the top of the screen, and when it is off screen a large pulsing
## arrow at the screen edge pointing at the nearest one, with its distance.

const RED := Color("ff8175")
const BAR_RED := Color("e0503c")
const PAPER := Color("eee8d8")
const SHADOW := Color("17231c")
const BAR_WIDTH := 420.0

var game: Node
var arrow_position = Vector2.ZERO
var angle = 0.0
var has_target = false
var target_distance := 0.0
var shown_boss: Node = null   # the boss named on the bar (nearest alive)

func _ready():
	name = "BossDirection"
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	has_target = false
	shown_boss = null
	if game.current_state != game.GameState.PLAYING:
		queue_redraw()
		return
	var rect = Rect2(Vector2.ZERO, game.hud.size)
	var closest = INF
	var nearest_world = INF
	for boss in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(boss) or boss.dying:
			continue
		var world_distance: float = boss.global_position.distance_to(game.player.global_position)
		if world_distance < nearest_world:
			nearest_world = world_distance
			shown_boss = boss
		var screen = game.hud.get_global_transform_with_canvas().affine_inverse() * (boss.get_global_transform_with_canvas() * Vector2.ZERO)
		if rect.has_point(screen):
			continue
		var distance = screen.distance_squared_to(rect.get_center())
		if distance >= closest:
			continue
		closest = distance
		var direction = screen - rect.get_center()
		var bounds = rect.size / 2 - Vector2(44, 56)
		var factor = minf(bounds.x / maxf(absf(direction.x), 0.01), bounds.y / maxf(absf(direction.y), 0.01))
		arrow_position = rect.get_center() + direction * factor
		angle = direction.angle()
		target_distance = world_distance
		has_target = true
	queue_redraw()

func _draw():
	var font = get_theme_default_font()
	if is_instance_valid(shown_boss):
		var top := Vector2((size.x - BAR_WIDTH) / 2.0, 92.0)
		var health = shown_boss.get("current_health")
		var most = shown_boss.get("max_health")
		var frac := clampf(float(health) / maxf(1.0, float(most)), 0.0, 1.0) if health != null and most != null else 1.0
		draw_rect(Rect2(top - Vector2(2, 2), Vector2(BAR_WIDTH + 4, 14)), SHADOW)
		draw_rect(Rect2(top, Vector2(BAR_WIDTH * frac, 10)), BAR_RED)
		var title = shown_boss.get("encounter_name")
		var text := str(title) if title != null else "Boss"
		draw_string_outline(font, top + Vector2(0, -7), text, HORIZONTAL_ALIGNMENT_CENTER, BAR_WIDTH, 17, 5, SHADOW)
		draw_string(font, top + Vector2(0, -7), text, HORIZONTAL_ALIGNMENT_CENTER, BAR_WIDTH, 17, PAPER)
	if not has_target:
		return
	var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 150.0)
	draw_set_transform(arrow_position, angle, Vector2.ONE * 1.8 * pulse)
	var shape = PackedVector2Array([Vector2(13, 0), Vector2(-8, -9), Vector2(-4, 0), Vector2(-8, 9)])
	draw_colored_polygon(shape, RED)
	shape.append(shape[0])
	draw_polyline(shape, SHADOW, 2)
	draw_set_transform(Vector2.ZERO)
	var label := "BOSS · %dm" % int(target_distance / 32.0)
	var at: Vector2 = arrow_position - Vector2.from_angle(angle) * 34.0 + Vector2(-70, 5)
	draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 140, 14, 5, SHADOW)
	draw_string(font, at, label, HORIZONTAL_ALIGNMENT_CENTER, 140, 14, PAPER)
