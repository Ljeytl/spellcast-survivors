extends Control

var item_id = "bolt"
var passive = false

func _ready():
	if passive:
		var glyph = {"spell_duration": "DU", "spell_damage": "PW", "movement_speed": "MV", "max_health": "HP", "xp_range": "PK", "projectile_speed": "SP", "slowdown_duration": "TM", "mana_bolt_mastery": "MM", "spell_area": "SZ", "multicast": "×2", "xp_gain": "XP", "luck": "LK", "crit_chance": "CR", "crit_damage": "CD", "enemy_population": "EN"}.get(item_id, "+")
		if not has_node("Glyph"):
			var label = Label.new()
			label.name = "Glyph"
			label.text = glyph
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 12)
			add_child(label)
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw():
	if passive:
		draw_circle(size / 2, minf(12, size.x / 2 - 1), Color("dfbd76"), false, 2)
		return
	if item_id == "focus_ray":
		var center = size / 2
		draw_line(Vector2(3, center.y), Vector2(size.x - 3, center.y), Color("202334"), 10)
		draw_line(Vector2(3, center.y), Vector2(size.x - 3, center.y), Color("69c5ce"), 6)
		draw_line(Vector2(3, center.y), Vector2(size.x - 3, center.y), Color("efffff"), 2)
		draw_rect(Rect2(center - Vector2(3, 7), Vector2(6, 14)), Color("69c5ce"), false, 2)
		return
	var kind = "rune"
	for entry in [["cinder", "flame"], ["soul", "heal"], ["meteor", "meteor"], ["lightning", "lightning"], ["prism", "prism"], ["focus", "mana"], ["blade", "blade"], ["bolt", "bolt"], ["life", "heal"], ["regeneration", "heal"], ["health", "heal"], ["ice", "ice"], ["frost", "ice"], ["fire", "flame"], ["ember", "lance"], ["plague", "plague"], ["spirit", "spirit"], ["seeker", "spirit"], ["shield", "stone"], ["orbit", "orbit"], ["steam", "steam"]]:
		if entry[0] in item_id:
			kind = entry[1]
			break
	kind = {"bolt": "mana", "life_bolt": "heal", "lightning_bolt": "lightning", "meteor_lance": "lance"}.get(item_id, kind)
	preload("res://scripts/EffectArt.gd").stamp(self, kind, size / 2, Vector2.ONE * minf(27, size.x))
