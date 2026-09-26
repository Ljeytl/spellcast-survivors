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
	},
	"prism_ray": {
		"name": "Prism Ray", "incantation": "prism ray", "ingredients": ["focus_ray", "ember_lance"],
		"requirements": "Equip Focus Ray and Ember Lance, then choose Prism Ray. Evolves Focus Ray; Ember Lance stays equipped.",
		"description": "A tracking beam hits up to 3 aligned enemies every 0.25 seconds for 2 seconds. One active beam. Keeps the ray's slot and rank.",
		"card_description": "The focused beam now pierces up to 3 aligned enemies.",
		"overrides": {"beam_targets": 3}
	},
	"frost_sigil": {
		"name": "Frost Sigil", "incantation": "frost sigil", "ingredients": ["rune_trap", "ice_blast"],
		"requirements": "Equip Rune Trap and Ice Blast, then choose Frost Sigil. Evolves Rune Trap; Ice Blast stays equipped.",
		"description": "After 0.8 seconds, proximity triggers one 170-radius burst and a 40% slow for 2 seconds. Expires after 6 seconds; up to 3 sigils. Keeps the trap's slot and rank.",
		"card_description": "Larger trap burst slows survivors by 40% for 2 seconds.",
		"overrides": {"trap_radius": 170, "frost": true}
	},
	"reaping_spirit": {
		"name": "Reaping Spirit", "incantation": "reaping spirit", "ingredients": ["seeking_spirit", "plague_seed"],
		"requirements": "Equip Seeking Spirit and Plague Seed, then choose Reaping Spirit. Evolves Seeking Spirit; Plague Seed stays equipped.",
		"description": "A pursuing spirit strikes every 0.5 seconds on contact for 5 seconds. Its contact kills burst for half damage within 100; bursts do not chain. Up to 3 spirits. Keeps the spirit's slot and rank.",
		"card_description": "Spirit contact kills burst for half damage nearby; bursts cannot chain.",
		"overrides": {"reaping": true}
	}
}
