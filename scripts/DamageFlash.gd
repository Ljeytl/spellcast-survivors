extends Sprite2D

const DURATION = 0.1
static var masks: Dictionary = {}
var remaining = 0.0
var source: Sprite2D

static func trigger(target: Sprite2D, duration: float = DURATION):
	if not is_instance_valid(target) or target.texture == null:
		return null
	var flash = target.get_node_or_null("DamageFlash")
	if flash == null:
		flash = new()
		flash.name = "DamageFlash"
		flash.source = target
		target.add_child(flash)
	flash.remaining = duration
	flash.visible = true
	flash.sync_sprite()
	return flash

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	self_modulate = Color(1.0, 0.12, 0.08, 0.9)

func sync_sprite():
	if not is_instance_valid(source) or source.texture == null:
		visible = false
		return
	if not masks.has(source.texture):
		var image = source.texture.get_image()
		if image == null or image.is_empty():
			visible = false
			return
		image.convert(Image.FORMAT_RGBA8)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				image.set_pixel(x, y, Color(1, 1, 1, image.get_pixel(x, y).a))
		masks[source.texture] = ImageTexture.create_from_image(image)
	texture = masks[source.texture]
	self_modulate.a = 0.9 * source.self_modulate.a
	hframes = source.hframes
	vframes = source.vframes
	frame = source.frame
	region_enabled = source.region_enabled
	region_rect = source.region_rect
	centered = source.centered
	offset = source.offset
	flip_h = source.flip_h
	flip_v = source.flip_v

func _process(delta):
	advance(delta)

func advance(delta: float):
	remaining = maxf(0, remaining - delta)
	visible = remaining > 0
	if visible:
		sync_sprite()
