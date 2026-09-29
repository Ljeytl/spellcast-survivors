extends RefCounted

const RECIPES = {
	"lightning_bolt": {
		"name": "Lightning Bolt", "incantation": "lightning bolt", "ingredients": ["bolt", "lightning_arc"],
		"requirements": "Own Bolt and Lightning this run, then learn Lightning Bolt.",
		"description": "Bounces between enemies, striking a small lightning area at every impact. Bolt strengthens impact; Lightning strengthens the splash.",
		"card_description": "A bouncing bolt strikes a lightning area at each hit.",
		"overrides": {"type": "bouncing_projectile", "damage": 40, "bounce_count": 4, "bounce_range": 240.0}
	},
	"life_bolt": {
		"name": "Life Bolt", "incantation": "life bolt", "ingredients": ["bolt", "life"],
		"requirements": "Own Bolt and Life this run, then learn Life Bolt; both ingredients remain.",
		"description": "Hits plant healing areas. Bolt levels increase impact damage; Life levels increase healing. Own ranks alternate extra bolts and larger healing areas.",
		"card_description": "Hits plant healing areas you can collect.",
		"overrides": {"type": "life_bolt"}
	},
	"meteor_lance": {
		"name": "Meteor Lance", "incantation": "meteor lance", "ingredients": ["ember_lance", "meteor_shower"],
		"requirements": "Equip Ember Lance and Meteor Shower, then choose Meteor Lance. Both ingredients stay equipped.",
		"description": "A piercing lance detonates meteor impacts. Ember Lance strengthens direct hits; Meteor Shower strengthens explosions.",
		"card_description": "A piercing lance explodes through crowds.",
		"overrides": {"explosive": true}
	},
	"soul_bloom": {
		"name": "Soul Bloom", "incantation": "soul bloom", "ingredients": ["plague_seed", "regeneration"],
		"requirements": "Equip Plague Seed and Regeneration, then choose Soul Bloom. Both ingredients stay equipped.",
		"description": "Infected deaths leave healing blooms and lingering spores. Plague Seed strengthens infection; Regeneration increases available healing.",
		"card_description": "Infected deaths leave healing blooms and infectious spores.",
		"overrides": {}
	},
	"steam_field": {
		"name": "Steam Field", "incantation": "steam field", "ingredients": ["cinder_field", "ice_blast"],
		"requirements": "Equip Cinder Field and Ice Blast, then choose Steam Field. Both ingredients stay equipped.",
		"description": "A lasting damaging field slows enemies. Cinder Field strengthens damage; Ice Blast strengthens slowing.",
		"card_description": "Burning steam damages and slows enemies.",
		"overrides": {"slow": 0.4, "duration": 5.0}
	},
	"prism_ray": {
		"name": "Prism Ray", "incantation": "prism ray", "ingredients": ["focus_ray", "ember_lance"],
		"requirements": "Equip Focus Ray and Ember Lance, then choose Prism Ray. Both ingredients stay equipped.",
		"description": "A wide fixed-direction laser pierces aligned enemies. Both ingredients and its own ranks increase damage.",
		"card_description": "A powerful fixed-direction laser cuts through a line of enemies.",
		"overrides": {"beam_piercing": true, "beam_radius": 32.0, "beam_turn_speed": 0.0, "active_limit": 3}
	},
	"frost_sigil": {
		"name": "Frost Sigil", "incantation": "frost sigil", "ingredients": ["rune_trap", "ice_blast"],
		"requirements": "Equip Rune Trap and Ice Blast, then choose Frost Sigil. Both ingredients stay equipped.",
		"description": "A persistent frost trap bursts and slows enemies. Ingredients improve damage, radius and slowing; own ranks reduce arming time.",
		"card_description": "A large frost trap explodes and slows survivors.",
		"overrides": {"trap_radius": 170, "frost": true, "arm_delay": 1.2}
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
