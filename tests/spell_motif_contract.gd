extends SceneTree

const Art = preload("res://scripts/EffectArt.gd")
const Geometry = preload("res://scripts/SpellGeometry.gd")
var checks = 0
var failures = 0

func _initialize():
	var image = Art.SPELL_MOTIFS.get_image()
	check(image.get_width() == 1261 and image.get_height() == 1247, "One 4x4 motif atlas has the authored dimensions")
	check(Art.MOTIF_CELLS.size() == 16 and Art.MOTIF_BOUNDS.size() == 16, "Every motif has one source cell and opaque crop")
	for kind in Art.MOTIF_CELLS:
		var index: int = Art.MOTIF_CELLS[kind]
		var region: Rect2 = Art.motif_region(kind)
		var cell = Rect2(index % 4 * 315, int(index / 4) * 311, 315, 311)
		check(cell.encloses(region) and region.size.x > 100 and region.size.y > 100, "%s opaque crop stays within its atlas cell" % kind)
		var visible = 0
		for y in range(int(region.position.y), int(region.end.y), 8):
			for x in range(int(region.position.x), int(region.end.x), 8):
				if image.get_pixel(x, y).a > 0.25:
					visible += 1
		check(visible >= 15, "%s crop contains visible authored pixels" % kind)
	for kind in ["mana", "bolt", "lance", "spirit", "blade", "orbit"]:
		var radius = 24.0
		var base = Geometry.stamp_dimensions(kind, radius)
		var upgraded = Geometry.stamp_dimensions(kind, radius * 1.12)
		check(upgraded.is_equal_approx(base * 1.12), "%s visible body follows gameplay Spell Size" % kind)
	for kind in ["mana", "bolt", "spirit"]:
		var radius = 24.0
		var crop: Rect2 = Art.motif_region(kind)
		var body: Rect2 = Art.MOTIF_BODIES[kind]
		var size = Geometry.stamp_dimensions(kind, radius)
		var offset = Geometry.stamp_offset(kind, radius)
		var sign_x = -1.0 if kind in ["mana", "bolt"] else 1.0
		var center = offset + Vector2(sign_x * (body.get_center().x - crop.get_center().x) / crop.size.x * size.x, (body.get_center().y - crop.get_center().y) / crop.size.y * size.y)
		var diameter = body.size / crop.size * size
		check(center.length() < 0.01 and diameter.is_equal_approx(Vector2.ONE * radius * 2), "%s opaque contact body centers on its actual hit circle" % kind)
	var lance_front = Geometry.stamp_offset("lance", 24).x + Geometry.stamp_dimensions("lance", 24).x * 0.5
	check(is_equal_approx(lance_front, 24), "Piercing spear tip ends at the swept contact radius")
	check(Geometry.stamp_dimensions("bolt", 17).y == 34 and Geometry.stamp_dimensions("blade", 42).y == 84, "Nominal atlas padding does not enlarge visible hit bodies")
	print("Spell motif contract: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)
