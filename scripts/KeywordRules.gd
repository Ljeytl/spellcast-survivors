extends RefCounted

const DEFINITIONS = {
	"mega": {"power": 1.5, "size": 1.5, "charge_seconds": 0.35, "style": 1.1, "color": Color("ffe49b")}
}

static func for_incantation(text: String) -> Dictionary:
	var word = text.strip_edges().to_lower().get_slice(" ", 0)
	return DEFINITIONS.get(word, {})

static func cast_color(info: Dictionary) -> Color:
	var value = info.get("color", Color("ffe49b"))
	var color = Color("ffe49b")
	if value is Color:
		color = value
	elif value is Array and value.size() >= 3:
		color = Color(float(value[0]),float(value[1]),float(value[2]),float(value[3]) if value.size()>3 else 1.0)
	return color.lerp(Color.WHITE, 0.25)
