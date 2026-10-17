extends Sprite2D

const CELL := 4.0
var part_ref: WeakRef
var refresh := 0.0
var vfx

func setup(part) -> void:
	vfx = part.get_node("/root/Vfx")
	part_ref = weakref(part)
	top_level = true
	z_as_relative = false
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE * CELL
	update_material()

static func heat(age: float, life: float) -> float:
	return clampf((life - age) / minf(1.5, life), 0.0, 1.0)

static func material(center: Vector2, radius: float, age: float, life: float) -> Image:
	var half := ceili(radius / CELL)
	var side := half * 2 + 1
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	var warmth := heat(age, life)
	if warmth <= 0.0:
		return img
	var ignition := maxf(0.0, 1.0 - age / 0.28)
	for y in side:
		for x in side:
			var offset := Vector2(x - half, y - half) * CELL
			if (offset.abs() + Vector2.ONE * CELL * 0.5).length() > radius:
				continue
			var world := center + offset
			var noise := sin(world.x * 0.13 + sin(world.y * 0.19)) * cos(world.y * 0.17 + sin(world.x * 0.11))
			var edge := 1.0 - smoothstep(0.65, 1.0, offset.length() / radius)
			var color := Color("#44241b").lerp(Color("#9b3418"), warmth * (0.35 + noise * 0.18))
			var coal := smoothstep(0.55, 0.92, noise) * warmth
			color = color.lerp(Color("#d95720"), coal * 0.7 + ignition * 0.24)
			color.a = edge * (0.25 + warmth * 0.20) * minf(1.0, warmth * 3.0)
			img.set_pixel(x, y, color)
	return img

func update_material() -> void:
	var part = part_ref.get_ref()
	if not is_instance_valid(part) or part.done:
		hide()
		queue_free()
		return
	global_position = part.global_position
	var img := material(global_position, float(part.geo("radius", 25.0)), float(part.age), float(part.total_life()))
	if texture == null or texture.get_size() != Vector2(img.get_size()):
		texture = ImageTexture.create_from_image(img)
	else:
		texture.update(img)

func _process(delta: float) -> void:
	var part = part_ref.get_ref()
	if not is_instance_valid(part) or part.done:
		hide()
		queue_free()
		return
	visible = vfx._active and vfx.presenter.enabled
	if not visible:
		return
	refresh -= delta
	if refresh <= 0.0:
		refresh = 0.1
		update_material()
