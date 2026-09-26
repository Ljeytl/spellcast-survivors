extends RefCounted

const RECIPES = {
	"life_bolt": {
		"name": "Life Bolt", "incantation": "life bolt", "ingredients": ["bolt", "life"],
		"requirements": "Equip Bolt and Regeneration, then choose Life Bolt at a level-up. Evolves Bolt; Regeneration stays equipped.",
		"description": "Gain healing up to 6 HP on actual damage. Cost: only one projectile, losing ranked Bolt's extra projectiles; damage per bolt is unchanged. Keeps slot and rank.",
		"card_description": "Gain: heal up to 6 HP on damage. Cost: one projectile instead of ranked Bolt's extra bolts; same damage per bolt.",
		"heal_on_hit": 6.0, "overrides": {"type": "life_bolt"}
	},
	"meteor_lance": {
		"name": "Meteor Lance", "incantation": "meteor lance", "ingredients": ["ember_lance", "meteor_shower"],
		"requirements": "Equip Ember Lance and Meteor Shower, then choose Meteor Lance. Evolves Ember Lance; Meteor Shower stays equipped.",
		"description": "Gain: piercing hits burst for half their damage within 90. Cost: 40% less direct damage than Ember Lance. Bursts reward tightly packed enemies. Keeps slot and rank.",
		"card_description": "Gain: each hit bursts for half damage nearby. Cost: 40% less direct damage.",
		"overrides": {"explosive": true, "damage_multiplier": 0.6}
	},
	"soul_bloom": {
		"name": "Soul Bloom", "incantation": "soul bloom", "ingredients": ["plague_seed", "life"],
		"requirements": "Equip Plague Seed and Regeneration, then choose Soul Bloom. Evolves Plague Seed; Regeneration stays equipped.",
		"description": "Gain: infection heals 10% of actual damage, capped at 2 HP per half-second tick. Cost: 25% less infection damage than Plague Seed. Lasts 5 seconds; keeps slot and rank.",
		"card_description": "Gain: heal 10% of actual damage, up to 2 HP per tick. Cost: 25% less infection damage.",
		"overrides": {"lifesteal": 0.1, "damage_multiplier": 0.75}
	},
	"steam_field": {
		"name": "Steam Field", "incantation": "steam field", "ingredients": ["cinder_field", "ice_blast"],
		"requirements": "Equip Cinder Field and Ice Blast, then choose Steam Field. Evolves Cinder Field; Ice Blast stays equipped.",
		"description": "Gain: the 150-radius damaging field slows enemies by 40%. Cost: lasts 3 seconds instead of Cinder Field's 5. Same damage per half-second tick; keeps slot and rank.",
		"card_description": "Gain: field slows enemies by 40%. Cost: lasts 3 seconds instead of 5.",
		"overrides": {"slow": 0.4, "duration": 3.0}
	},
	"prism_ray": {
		"name": "Prism Ray", "incantation": "prism ray", "ingredients": ["focus_ray", "ember_lance"],
		"requirements": "Equip Focus Ray and Ember Lance, then choose Prism Ray. Evolves Focus Ray; Ember Lance stays equipped.",
		"description": "Gain: beam hits up to 3 aligned enemies. Cost: 40% less damage per target than Focus Ray. Ticks every 0.25 seconds for 2 seconds; one active beam. Keeps slot and rank.",
		"card_description": "Gain: pierce up to 3 aligned enemies. Cost: 40% less damage per target.",
		"overrides": {"beam_targets": 3, "damage_multiplier": 0.6}
	},
	"frost_sigil": {
		"name": "Frost Sigil", "incantation": "frost sigil", "ingredients": ["rune_trap", "ice_blast"],
		"requirements": "Equip Rune Trap and Ice Blast, then choose Frost Sigil. Evolves Rune Trap; Ice Blast stays equipped.",
		"description": "Gain: a larger 170-radius burst slows survivors by 40% for 2 seconds. Cost: arms after 1.4 seconds instead of Rune Trap's 0.8. Expires after 6 seconds; up to 3 traps. Keeps slot and rank.",
		"card_description": "Gain: larger burst and 40% slow for 2 seconds. Cost: arms in 1.4 seconds instead of 0.8.",
		"overrides": {"trap_radius": 170, "frost": true, "arm_delay": 1.4}
	},
	"reaping_spirit": {
		"name": "Reaping Spirit", "incantation": "reaping spirit", "ingredients": ["seeking_spirit", "plague_seed"],
		"requirements": "Equip Seeking Spirit and Plague Seed, then choose Reaping Spirit. Evolves Seeking Spirit; Plague Seed stays equipped.",
		"description": "Gain: contact kills burst for half damage within 100, without chaining. Cost: 25% less contact damage than Seeking Spirit. Strikes every 0.5 seconds for 5 seconds; up to 3 spirits. Keeps slot and rank.",
		"card_description": "Gain: contact kills burst for half damage nearby. Cost: 25% less contact damage; bursts cannot chain.",
		"overrides": {"reaping": true, "damage_multiplier": 0.75}
	}
}
