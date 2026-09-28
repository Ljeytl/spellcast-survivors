extends Control

var item_id = "bolt"
var passive = false

func _draw():
	if passive:
		var glyph = {"spell_damage": "DM", "movement_speed": "MV", "max_health": "HP", "xp_range": "PK", "projectile_speed": "SP", "slowdown_duration": "TM", "mana_bolt_mastery": "MB", "spell_area": "SZ", "multicast": "×2", "xp_gain": "XP", "luck": "LK", "crit_chance": "CR", "crit_damage": "CD", "enemy_population": "EN"}.get(item_id, "+")
		draw_circle(size / 2, 12, Color("dfbd76"), false, 2)
		var font = ThemeDB.fallback_font
		var width = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2((size.x - width) / 2, size.y / 2 + 4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("eee8d8"))
		return
	var kind = "rune"
	for entry in [["cinder", "flame"], ["soul", "heal"], ["meteor", "meteor"], ["lightning", "lightning"], ["prism", "prism"], ["focus", "mana"], ["blade", "blade"], ["bolt", "bolt"], ["life", "heal"], ["regeneration", "heal"], ["health", "heal"], ["ice", "ice"], ["frost", "ice"], ["fire", "flame"], ["ember", "lance"], ["plague", "plague"], ["spirit", "spirit"], ["seeker", "spirit"], ["shield", "stone"], ["orbit", "orbit"], ["steam", "steam"]]:
		if entry[0] in item_id:
			kind = entry[1]
			break
	kind = {"bolt": "mana", "life_bolt": "heal", "lightning_bolt": "lightning", "meteor_lance": "lance"}.get(item_id, kind)
	preload("res://scripts/EffectArt.gd").stamp(self, kind, size / 2, Vector2.ONE * 27)
