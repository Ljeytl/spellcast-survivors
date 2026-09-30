extends RefCounted

const ATLAS = preload("res://assets/tower/tower-atlas.png")
const REAR = preload("res://assets/tower/rear-arch.png")
const WIZARD = preload("res://assets/typecast/Main Character/Wizard 2.0.png")

static var textures: Dictionary = {}

static func texture(index: int) -> AtlasTexture:
	if textures.has(index):
		return textures[index]
	var result = AtlasTexture.new()
	result.atlas = ATLAS
	var regions = [
		Rect2(72,15,315,261), Rect2(440,14,308,262), Rect2(881,49,146,219), Rect2(1261,28,158,242),
		Rect2(82,290,285,192), Rect2(466,289,254,221), Rect2(820,290,251,220), Rect2(1199,289,253,222),
		Rect2(97,512,252,213), Rect2(472,511,243,241), Rect2(821,526,247,226), Rect2(1225,523,211,224),
		Rect2(99,741,245,260), Rect2(488,750,204,253), Rect2(850,792,198,200), Rect2(1227,758,233,246)
	]
	result.region = regions[index]
	if index in [7, 11]:
		result.atlas = REAR
		result.region = Rect2(368,185,800,654)
	textures[index] = result
	return result

static func sprite(index: int, width: float) -> Sprite2D:
	var result = Sprite2D.new()
	result.texture = texture(index)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.scale = Vector2.ONE * width / result.texture.get_width()
	return result
