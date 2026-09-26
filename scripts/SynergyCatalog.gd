extends RefCounted

const RECIPES = {
	"life_bolt": {
		"name": "Life Bolt", "incantation": "life bolt", "ingredients": ["bolt", "life"],
		"requirements": "Equip Bolt and Regeneration, then choose Life Bolt at a level-up. Evolves Bolt; Regeneration stays equipped.",
		"description": "One homing bolt heals up to 6 health on damage, capped by health lost. Keeps Bolt's slot and rank.",
		"card_description": "One homing bolt. Heal up to 6 HP on damage.",
		"heal_on_hit": 6.0, "overrides": {"type": "life_bolt"}
	},
	"meteor_lance": {
		"name": "Meteor Lance", "incantation": "meteor lance", "ingredients": ["ember_lance", "meteor_shower"],
		"requirements": "Equip Ember Lance and Meteor Shower, then choose Meteor Lance. Evolves Ember Lance; Meteor Shower stays equipped.",
		"description": "Pierces enemies in a straight line. Each enemy hit bursts for half damage in a 90-radius area. Keeps the lance's slot and rank.",
		"card_description": "Piercing lance; each hit explodes for half damage nearby.",
		"overrides": {"explosive": true}
	},
	"soul_bloom": {
		"name": "Soul Bloom", "incantation": "soul bloom", "ingredients": ["plague_seed", "life"],
		"requirements": "Equip Plague Seed and Regeneration, then choose Soul Bloom. Evolves Plague Seed; Regeneration stays equipped.",
		"description": "Infects up to 8 enemies for 5 seconds. Damage ticks heal 10% of actual health lost, up to 2 HP per tick. Keeps the seed's slot and rank.",
		"card_description": "Spreading infection; heal 10% of damage dealt, up to 2 HP per tick.",
		"overrides": {"lifesteal": 0.1}
	},
	"steam_field": {
		"name": "Steam Field", "incantation": "steam field", "ingredients": ["cinder_field", "ice_blast"],
		"requirements": "Equip Cinder Field and Ice Blast, then choose Steam Field. Evolves Cinder Field; Ice Blast stays equipped.",
		"description": "A stationary 150-radius field damages enemies every half second for 5 seconds and slows them by 40%. Keeps the field's slot and rank.",
		"card_description": "Persistent damaging field also slows enemies by 40%.",
		"overrides": {"slow": 0.4}
	}
}
