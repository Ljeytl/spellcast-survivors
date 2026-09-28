extends Control

var item_id = "bolt"
var passive = false

func _ready():
	if passive:
		var glyph = {"spell_damage": "DM", "movement_speed": "MV", "max_health": "HP", "xp_range": "PK", "projectile_speed": "SP", "slowdown_duration": "TM", "mana_bolt_mastery": "MB", "spell_area": "SZ", "multicast": "×2", "xp_gain": "XP", "luck": "LK", "crit_chance": "CR", "crit_damage": "CD", "enemy_population": "EN"}.get(item_id, "+")
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
		draw_circle(size / 2, 12, Color("dfbd76"), false, 2)
		return
	var kind = "rune"
	for entry in [["cinder", "flame"], ["soul", "heal"], ["meteor", "meteor"], ["lightning", "lightning"], ["prism", "prism"], ["focus", "mana"], ["blade", "blade"], ["bolt", "bolt"], ["life", "heal"], ["regeneration", "heal"], ["health", "heal"], ["ice", "ice"], ["frost", "ice"], ["fire", "flame"], ["ember", "lance"], ["plague", "plague"], ["spirit", "spirit"], ["seeker", "spirit"], ["shield", "stone"], ["orbit", "orbit"], ["steam", "steam"]]:
		if entry[0] in item_id:
			kind = entry[1]
			break
	kind = {"bolt": "mana", "life_bolt": "heal", "lightning_bolt": "lightning", "meteor_lance": "lance"}.get(item_id, kind)
	preload("res://scripts/EffectArt.gd").stamp(self, kind, size / 2, Vector2.ONE * 27)
