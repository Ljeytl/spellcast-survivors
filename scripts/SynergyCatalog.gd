extends RefCounted

const RECIPES = {
	"lightning_bolt": {
		"name": "Lightning Bolt", "incantation": "lightning bolt", "ingredients": ["bolt", "lightning_arc"],
		"requirements": "Own Bolt and Lightning this run, then learn Lightning Bolt.",
		"description": "A traveling bolt bounces to two additional living enemies within 240 units; no repeat target.",
		"card_description": "A traveling bolt bounces between nearby enemies.",
		"overrides": {"type": "bouncing_projectile", "damage": 60, "bounce_count": 2, "bounce_range": 240.0}
	},
	"life_bolt": {
		"name": "Life Bolt", "incantation": "life bolt", "ingredients": ["bolt", "life"],
		"requirements": "Own Bolt and Life this run, then learn Life Bolt; both ingredients remain.",
		"description": "A damaging hit plants a healing seed; collect it for 6 HP over 2 seconds. Seeds last 10 seconds, maximum 6 per caster; full health does not consume them. Bonus spell starts at rank 1 and uses no active slot.",
		"card_description": "Hits plant a healing seed you can collect.",
		"overrides": {"type": "life_bolt"}
	},
	"meteor_lance": {
		"name": "Meteor Lance", "incantation": "meteor lance", "ingredients": ["ember_lance", "meteor_shower"],
		"requirements": "Equip Ember Lance and Meteor Shower, then choose Meteor Lance. Both ingredients stay equipped.",
		"description": "Gain: piercing hits burst for half their damage within 90. Cost: 40% less direct damage than Ember Lance. Bursts reward tightly packed enemies. Keeps both ingredients and starts at rank 1 without using an active slot.",
		"card_description": "Gain: each hit bursts for half damage nearby. Cost: 40% less direct damage.",
		"overrides": {"explosive": true, "damage_multiplier": 0.6}
	},
	"soul_bloom": {
		"name": "Soul Bloom", "incantation": "soul bloom", "ingredients": ["plague_seed", "regeneration"],
		"requirements": "Equip Plague Seed and Regeneration, then choose Soul Bloom. Both ingredients stay equipped.",
		"description": "Gain: infection heals 10% of actual damage, capped at 2 HP per half-second tick. Cost: 25% less infection damage than Plague Seed. Lasts 5 seconds; keeps both ingredients and uses no active slot.",
		"card_description": "Gain: heal 10% of actual damage, up to 2 HP per tick. Cost: 25% less infection damage.",
		"overrides": {"lifesteal": 0.1, "damage_multiplier": 0.75}
	},
	"steam_field": {
		"name": "Steam Field", "incantation": "steam field", "ingredients": ["cinder_field", "ice_blast"],
		"requirements": "Equip Cinder Field and Ice Blast, then choose Steam Field. Both ingredients stay equipped.",
		"description": "Gain: the 150-radius damaging field slows enemies by 40%. Cost: lasts 3 seconds instead of Cinder Field's 5. Same damage per half-second tick; keeps both ingredients and uses no active slot.",
		"card_description": "Gain: field slows enemies by 40%. Cost: lasts 3 seconds instead of 5.",
		"overrides": {"slow": 0.4, "duration": 3.0}
	},
	"prism_ray": {
		"name": "Prism Ray", "incantation": "prism ray", "ingredients": ["focus_ray", "ember_lance"],
		"requirements": "Equip Focus Ray and Ember Lance, then choose Prism Ray. Both ingredients stay equipped.",
		"description": "Gain: beam hits up to 3 aligned enemies. Cost: 40% less damage per target than Focus Ray. Ticks every 0.25 seconds for 2 seconds; one active beam. Keeps both ingredients and starts at rank 1 without using an active slot.",
		"card_description": "Gain: pierce up to 3 aligned enemies. Cost: 40% less damage per target.",
		"overrides": {"beam_targets": 3, "damage_multiplier": 0.6}
	},
	"frost_sigil": {
		"name": "Frost Sigil", "incantation": "frost sigil", "ingredients": ["rune_trap", "ice_blast"],
		"requirements": "Equip Rune Trap and Ice Blast, then choose Frost Sigil. Both ingredients stay equipped.",
		"description": "Gain: a larger 170-radius burst slows survivors by 40% for 2 seconds. Cost: arms after 1.4 seconds instead of Rune Trap's 0.8. Waits until triggered; up to 3 traps. Keeps both ingredients and starts at rank 1 without using an active slot.",
		"card_description": "Gain: larger burst and 40% slow for 2 seconds. Cost: arms in 1.4 seconds instead of 0.8.",
		"overrides": {"trap_radius": 170, "frost": true, "arm_delay": 1.4}
	},
	"reaping_spirit": {
		"enabled": false,
		"name": "Reaping Spirit", "incantation": "reaping spirit", "ingredients": ["seeking_spirit", "plague_seed"],
		"requirements": "Equip Seeking Spirit and Plague Seed, then choose Reaping Spirit. Both ingredients stay equipped.",
		"description": "Gain: contact kills burst for half damage within 100, without chaining. Cost: 25% less contact damage than Seeking Spirit. Strikes every 0.5 seconds for 5 seconds; up to 3 spirits. Keeps both ingredients and starts at rank 1 without using an active slot.",
		"card_description": "Gain: contact kills burst for half damage nearby. Cost: 25% less contact damage; bursts cannot chain.",
		"overrides": {"reaping": true, "damage_multiplier": 0.75}
	}
}
