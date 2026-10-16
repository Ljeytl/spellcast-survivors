extends Node2D

const MAX_PULSES := 24
var pulses: Array = []
var texture: GradientTexture2D
var owner_vfx

func _ready() -> void:
	z_index = -2
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = blend
	texture = GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.35))
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64

func emit(at: Vector2, radius: float, color: Color, strength: float) -> void:
	if strength <= 0.0 or owner_vfx.reduced_effects or not owner_vfx.presenter.enabled:
		return
	for pulse in pulses:
		if pulse.at.distance_squared_to(at) < 24.0 * 24.0 and pulse.age < 0.06:
			return
	if pulses.size() >= MAX_PULSES:
		pulses.pop_front()
	pulses.append({"at": at, "radius": clampf(radius, 24.0, 140.0), "color": color, "strength": clampf(strength, 0.0, 0.18), "age": 0.0})
	queue_redraw()

func clear() -> void:
	pulses.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if owner_vfx.reduced_effects or not owner_vfx.presenter.enabled or not owner_vfx._active:
		clear()
		return
	for pulse in pulses:
		pulse.age += delta
	pulses = pulses.filter(func(p): return p.age < 0.18)
	queue_redraw()

func _draw() -> void:
	for pulse in pulses:
		var fade: float = pow(1.0 - pulse.age / 0.18, 2.0)
		var radius: float = pulse.radius
		draw_texture_rect(texture, Rect2(pulse.at - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(pulse.color, pulse.strength * fade))
