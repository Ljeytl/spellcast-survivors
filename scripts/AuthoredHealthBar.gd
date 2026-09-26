extends Control

const EMPTY = preload("res://assets/typecast/UI Elements/Health Bar 1.png")
const FULL = preload("res://assets/typecast/UI Elements/Health Bar 1 full.png")
const BUFFED = preload("res://assets/typecast/UI Elements/Health Bar 1 buffed.png")
var shield_ratio = 0.0
var bar: ProgressBar

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar = get_parent()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta):
	queue_redraw()

func _draw():
	if not is_instance_valid(bar):
		return
	var factor = size.y / 15.0
	var left = 15.0 * factor
	var right = 2.0 * factor
	var width = maxf(0, size.x - left - right)
	var texture = EMPTY
	var source_width = texture.get_width()
	draw_texture_rect_region(BUFFED if shield_ratio > 0 else EMPTY, Rect2(0, 0, left, size.y), Rect2(0, 0, 15, 15))
	draw_texture_rect_region(texture, Rect2(left, 0, width, size.y), Rect2(15, 0, source_width - 17, 15))
	draw_texture_rect_region(texture, Rect2(size.x - right, 0, right, size.y), Rect2(source_width - 2, 0, 2, 15))
	var ratio = clampf((bar.value - bar.min_value) / maxf(1, bar.max_value - bar.min_value), 0, 1)
	if ratio > 0:
		draw_texture_rect_region(FULL, Rect2(left, 6 * factor, width * ratio, 6 * factor), Rect2(15, 6, 41 * ratio, 6))
	if shield_ratio > 0:
		draw_rect(Rect2(left, 11 * factor, width * shield_ratio, 2 * factor), Color("79d9e8"))
