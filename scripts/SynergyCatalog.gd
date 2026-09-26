extends RefCounted

const RECIPES = {
	"life_bolt": {
		"name": "Life Bolt", "incantation": "life bolt",
		"ingredients": ["bolt", "life"], "requirements": "Learn Bolt and Regeneration in the same run, then choose Life Bolt at a level-up.",
		"description": "Fire one homing bolt. Restore up to 6 health when it damages an enemy. Damage scales with your Bolt rank; healing cannot exceed damage dealt.",
		"card_description": "One homing bolt; damage scales with Bolt.\nHeal up to 6 HP, capped by damage dealt.",
		"heal_on_hit": 6.0
	}
}
