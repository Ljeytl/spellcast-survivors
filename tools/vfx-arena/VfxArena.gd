extends Node2D
## VFX test arena (dev tool, not shipped in normal play).
##
## Same layout as tools/vfx-reference/spell_vfx_sandbox.html: the wizard on the
## left, six dummies where the sandbox puts its enemies, camera framing the same
## 192 x 108 sandbox units. Spells loop at the sandbox's cadence through the real
## spell engine (GenericCast), so what you see here is what the game draws.
##
## Keys: Tab next page (element) · 1-9 pick a spell · B grass / sandbox-dark floor ·
##       Space pause · S slow-mo · P VFX on/off (placeholder art) · T on twos · R reset

const KP = preload("res://scripts/engine/KeywordParser.gd")
const Defs = preload("res://scripts/engine/SpellDefs.gd")
const Planner = preload("res://scripts/engine/CastPlanner.gd")
const GenericCast = preload("res://scripts/engine/GenericCast.gd")
const WPS := 1280.0 / 192.0
const ENEMY_TEX := preload("res://assets/typecast/Slime Enemies/Slime girl 1.png")
const WIZARD_TEX := preload("res://assets/typecast/Main Character/Wizard 2.0.png")
const BASE_ENEMIES := [Vector2(132, 36), Vector2(152, 50), Vector2(170, 32), Vector2(140, 72), Vector2(162, 80), Vector2(180, 60)]
const PLAYER_SU := Vector2(22, 56)
# The sandbox steps 1/60 s per animation frame, so on a 120 Hz display it runs at
# 2x. The arena mirrors what you saw there: sandbox spells fly at 2x their nominal
# speed and recast twice as often. (Vfx.FX_SPEED does the same for effect motion.)
const SANDBOX_TIME := 0.5

# Sandbox reference spells, rebuilt as spell-engine data with sandbox numbers
# (speeds and radii in sandbox units x WPS, speeds x2 for the 120 Hz sandbox).
static func arena_defs() -> Dictionary:
	return {
		"arena_fire_bolt": {"name": "Fire Bolt", "incantation": "arena fire bolt", "element": "fire", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 170 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}}}},
		"arena_fireball": {"name": "Fireball", "incantation": "arena fireball", "element": "fire", "acquire": "data_only", "root": "orb",
			"parts": {"orb": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 105 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "ball"}, "events": {"on_hit": {"part": "blast"}}},
				"blast": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": (9 * 1.4 + 3) * WPS},
				"payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}]}}},
		"arena_ember_spear": {"name": "Ember Spear", "incantation": "arena ember spear", "element": "fire", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 240 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_cinder_field": {"name": "Cinder Field", "incantation": "arena cinder field", "element": "fire", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "burn"}]}}},
		"arena_fire_nova": {"name": "Fire Nova", "incantation": "arena fire nova", "element": "fire", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "burn"}]}}},
		# Sandbox ice: eShoot 160 (shatter r 11), ice spear 230, eField r 20 for 6 s, eNova 34 su over 0.5 s
		"arena_ice_bolt": {"name": "Ice Bolt", "incantation": "arena ice bolt", "element": "water", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt", "look": "ice"}, "events": {"on_hit": {"part": "shatter"}}},
				"shatter": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 11 * WPS},
				"payload": [{"type": "status", "status": "chilled"}]}}},
		"arena_ice_spear": {"name": "Ice Spear", "incantation": "arena ice spear", "element": "water", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "chilled"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear", "look": "ice"}}}},
		"arena_ice_field": {"name": "Ice Field", "incantation": "arena ice field", "element": "water", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "chilled"}]}}},
		"arena_ice_nova": {"name": "Ice Nova", "incantation": "arena ice nova", "element": "water", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "status", "status": "chilled"}]}}},
		# Sandbox water (polish pass 2): eShoot 160 -> splash r 11, spear 230, pool r 20 6 s, nova 34 su / 0.5 s
		"arena_water_bolt": {"name": "Water Bolt", "incantation": "arena water bolt", "element": "water", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}, "events": {"on_hit": {"part": "splash"}}},
				"splash": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 11 * WPS},
				"payload": [{"type": "damage", "amount": 1}]}}},
		"arena_water_spear": {"name": "Water Spear", "incantation": "arena water spear", "element": "water", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_water_pool": {"name": "Pool", "incantation": "arena water pool", "element": "water", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "damage", "amount": 1}]}}},
		"arena_water_nova": {"name": "Water Nova", "incantation": "arena water nova", "element": "water", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "damage", "amount": 1}]}}},
		# Sandbox life: eShoot 160 -> bloom r 10, spear 230, field r 20 6 s, nova 34 su / 0.5 s
		"arena_life_bolt": {"name": "Life Bolt", "incantation": "arena life bolt", "element": "life", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}, "events": {"on_hit": {"part": "bloom"}}},
				"bloom": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 10 * WPS},
				"payload": [{"type": "status", "status": "entangled"}]}}},
		"arena_life_spear": {"name": "Thorn Spear", "incantation": "arena life spear", "element": "life", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_life_field": {"name": "Overgrowth", "incantation": "arena life field", "element": "life", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "entangled"}]}}},
		"arena_life_nova": {"name": "Life Nova", "incantation": "arena life nova", "element": "life", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "status", "status": "entangled"}]}}},
		# Sandbox plague (polish pass 2) and earth
		"arena_plague_bolt": {"name": "Plague Bolt", "incantation": "arena plague bolt", "element": "plague", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}, "events": {"on_hit": {"part": "hit"}}},
				"hit": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 11 * WPS},
				"payload": [{"type": "status", "status": "poison"}]}}},
		"arena_plague_spear": {"name": "Plague Spear", "incantation": "arena plague spear", "element": "plague", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "poison"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_plague_field": {"name": "Plague Field", "incantation": "arena plague field", "element": "plague", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "poison"}]}}},
		"arena_plague_nova": {"name": "Plague Nova", "incantation": "arena plague nova", "element": "plague", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "status", "status": "poison"}]}}},
		"arena_earth_bolt": {"name": "Earth Bolt", "incantation": "arena earth bolt", "element": "earth", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}, "events": {"on_hit": {"part": "hit"}}},
				"hit": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 12 * WPS},
				"payload": [{"type": "status", "status": "bleed"}]}}},
		"arena_earth_spear": {"name": "Earth Spear", "incantation": "arena earth spear", "element": "earth", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "bleed"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_earth_field": {"name": "Earth Field", "incantation": "arena earth field", "element": "earth", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "bleed"}]}}},
		"arena_earth_nova": {"name": "Earth Nova", "incantation": "arena earth nova", "element": "earth", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "status", "status": "bleed"}]}}},
		# Sandbox lightning: bolt lands -> sky strike (r 10), spear 230, field r 20, nova 34 su over 0.5 s
		"arena_lightning_bolt": {"name": "Lightning Bolt", "incantation": "arena lightning bolt", "element": "storm", "acquire": "data_only", "root": "bolt",
			"parts": {"bolt": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 160 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}],
				"limits": {"pierce": 0}, "vfx": {"family": "bolt"}, "events": {"on_hit": {"part": "charge"}}},
				# sandbox: bolt lands -> 0.45 s charge telegraph on the target -> sky strike
				"charge": {"delivery": "aura", "origin": "parent", "anchor": "hit_target", "geometry": {"type": "disk", "radius": 10 * WPS},
				"timing": {"duration": 0.45}, "events": {"on_expire": {"part": "strike"}}},
				"strike": {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": 10 * WPS},
				"payload": [{"type": "status", "status": "shocked"}]}}},
		"arena_lightning_spear": {"name": "Lightning Spear", "incantation": "arena lightning spear", "element": "storm", "acquire": "data_only", "root": "spear",
			"parts": {"spear": {"delivery": "projectile", "origin": "caster", "geometry": {"type": "body", "radius": 4.5 * WPS},
				"motion": [{"type": "straight", "speed": 2 * 230 * WPS, "range": 1400}], "payload": [{"type": "damage", "amount": 1}, {"type": "status", "status": "shocked"}],
				"limits": {"pierce": -1}, "vfx": {"family": "spear"}}}},
		"arena_lightning_field": {"name": "Lightning Field", "incantation": "arena lightning field", "element": "storm", "acquire": "data_only", "root": "field",
			"parts": {"field": {"delivery": "field", "origin": "target", "geometry": {"type": "disk", "radius": 20 * WPS},
				"timing": {"type": "periodic", "interval": 0.5, "duration": 6.0}, "payload": [{"type": "status", "status": "shocked"}]}}},
		"arena_lightning_nova": {"name": "Lightning Nova", "incantation": "arena lightning nova", "element": "storm", "acquire": "data_only", "root": "ring",
			"parts": {"ring": {"delivery": "volume", "origin": "caster", "geometry": {"type": "ring", "radius": 34 * WPS, "thickness": 6 * WPS},
				"propagation": {"type": "expanding", "speed": 2 * 68 * WPS}, "payload": [{"type": "status", "status": "shocked"}]}}},
	}

# label, incantation, cadence (s) — cadence from the sandbox's SPELLS[*].every
const PAGES := [
	["Arcane", [
		["nova", "nova", 1.6],
		["field", "field", 3.5],
		["orbit", "orbit", 4.5],
		["trap", "trap", 3.0],
		["slash", "slash", 0.9],
		["fiery nova (keyword accent)", "fiery nova", 1.6],
		["icy field (keyword accent)", "icy field", 3.5],
		["shocking slash (keyword accent)", "shocking slash", 0.9],
		["verdant trap (keyword accent)", "verdant trap", 3.0],
	]],
	["Fire", [
		["Fire Bolt (sandbox: Fire > Fire Bolt)", "arena fire bolt", 0.55],
		["Fireball (sandbox: Fire > Fireball)", "arena fireball", 1.7],
		["Ember Spear (sandbox: Fire > Ember Spear)", "arena ember spear", 1.1],
		["Cinder Field (sandbox: Fire > Cinder Field)", "arena cinder field", 6.6],
		["fireball (game data)", "fireball", 1.7],
		["fiery spear (keyword accent)", "fiery spear", 1.1],
		["flame wall (game data)", "flame wall", 6.0],
		["spear (bare, arcane)", "spear", 1.1],
		["Fire Nova (sandbox: Fire > Fire Nova)", "arena fire nova", 2.2],
	]],
	["Ice", [
		["Ice Bolt (sandbox: Ice > Bolt)", "arena ice bolt", 0.6],
		["Ice Spear (sandbox: Ice > Spear)", "arena ice spear", 1.1],
		["Ice Field (sandbox: Ice > Field)", "arena ice field", 6.6],
		["Ice Nova (sandbox: Ice > Nova)", "arena ice nova", 2.2],
		["frost nova (game data)", "frost nova", 2.2],
		["icy spear (keyword accent)", "icy spear", 1.1],
	]],
	["Water", [
		["Water Bolt (sandbox: Water > Bolt)", "arena water bolt", 0.6],
		["Water Spear (sandbox: Water > Spear)", "arena water spear", 1.1],
		["Pool (sandbox: Water > Pool)", "arena water pool", 6.6],
		["Water Nova (sandbox: Water > Nova)", "arena water nova", 2.2],
		["tsunami (game data)", "tsunami", 2.6],
	]],
	["Life", [
		["Life Bolt (sandbox: Life > Bolt)", "arena life bolt", 0.6],
		["Thorn Spear (sandbox: Life > Spear)", "arena life spear", 1.1],
		["Overgrowth (sandbox: Life > Field)", "arena life field", 6.6],
		["Life Nova (sandbox: Life > Nova)", "arena life nova", 2.2],
		["regrowth (game data, self heal)", "regrowth", 1.6],
		["verdant spear (keyword accent)", "verdant spear", 1.1],
	]],
	["Plague", [
		["Plague Bolt (sandbox: Plague > Bolt)", "arena plague bolt", 0.6],
		["Plague Spear (sandbox: Plague > Spear)", "arena plague spear", 1.1],
		["Plague Field (sandbox: Plague > Field)", "arena plague field", 6.6],
		["Plague Nova (sandbox: Plague > Nova)", "arena plague nova", 2.2],
		["toxic slash (keyword accent)", "toxic slash", 0.9],
	]],
	["Earth", [
		["Earth Bolt (sandbox: Earth > Bolt)", "arena earth bolt", 0.6],
		["Earth Spear (sandbox: Earth > Spear)", "arena earth spear", 1.1],
		["Earth Field (sandbox: Earth > Field)", "arena earth field", 6.6],
		["Earth Nova (sandbox: Earth > Nova)", "arena earth nova", 2.2],
		["earthen nova (keyword accent)", "earthen nova", 1.6],
	]],
	["Lightning", [
		["Lightning Bolt (sandbox: Lightning > Bolt)", "arena lightning bolt", 1.2],
		["Lightning Spear (sandbox: Lightning > Spear)", "arena lightning spear", 1.1],
		["Lightning Field (sandbox: Lightning > Field)", "arena lightning field", 6.6],
		["Lightning Nova (sandbox: Lightning > Nova)", "arena lightning nova", 2.2],
		["lightning rod (game data)", "lightning rod", 4.5],
		["shocking spear (keyword accent)", "shocking spear", 1.1],
	]],
]
var page := 0
var MENU: Array:
	get:
		return PAGES[page][1]

class Dummy extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var armour = 0.0
	var status = null
	var max_health = 1.0e9
	var current_health = 1.0e9
	var damage = 0.0
	var dying = false
	var velocity := Vector2.ZERO
	var home := Vector2.ZERO
	var phase := 0.0
	func apply_effect(e, s = {}, o = Vector2.INF):
		return FX.apply_to_entity(self, e, s, o)
	func receive_damage(_a, _o = Vector2.INF, _s = {}):
		pass
	func armour_value():
		return armour
	func process_status_effects(_d):
		pass
	func apply_knockback(_dir, _force):
		pass

class ArenaCaster extends Node2D:
	var health = 100.0
	var max_health = 100.0
	var velocity := Vector2.ZERO
	func heal(_a, _v = 1.0):
		pass

var caster: ArenaCaster
var dummies: Array = []
var cam: Camera2D
var hud: Label
var floor_node: Node2D
var current := 0
var cooldown := 0.0
var t := 0.0
var dark := false
var slow := false
var paused_cast := false
var seed_counter := 1

func _ready():
	# ?page=ice (or fire, lightning) opens that page; ?twos=1 starts on twos
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("location.search", true)).to_lower()
		for i in PAGES.size():
			if q.contains("page=" + str(PAGES[i][0]).to_lower()):
				page = i
		var v0 = get_node_or_null("/root/Vfx")
		if v0:
			v0.on_twos = q.contains("twos=1")
	for id in arena_defs():
		var d: Dictionary = arena_defs()[id].duplicate(true)
		d.id = id
		Defs.register(d)
	floor_node = ArenaFloor.new()
	floor_node.arena = self
	add_child(floor_node)
	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * preload("res://scripts/VisualDefaults.gd").CAMERA_ZOOM
	cam.position = Vector2(96, 54) * WPS
	add_child(cam)
	cam.make_current()
	caster = ArenaCaster.new()
	caster.position = PLAYER_SU * WPS
	var ws := Sprite2D.new()
	ws.texture = WIZARD_TEX
	ws.scale = Vector2(2, 2)
	ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ws.offset = Vector2(0, -WIZARD_TEX.get_height() * 0.5)
	caster.add_child(ws)
	add_child(caster)
	for i in BASE_ENEMIES.size():
		var d := Dummy.new()
		d.home = BASE_ENEMIES[i] * WPS
		d.position = d.home
		d.phase = i * 1.7
		var s := Sprite2D.new()
		s.texture = ENEMY_TEX
		s.scale = Vector2(2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.offset = Vector2(0, -ENEMY_TEX.get_height() * 0.5)
		d.add_child(s)
		add_child(d)
		d.add_to_group("enemies")
		dummies.append(d)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)
	_update_hud()

func _process(delta: float):
	t += delta
	for d in dummies:
		# sandbox drift: hx + sin(ph + T*0.7)*5, hy + cos(ph*1.3 + T*0.5)*3  (sandbox units)
		var p: Vector2 = d.home + Vector2(sin(d.phase + t * 0.7) * 5.0, cos(d.phase * 1.3 + t * 0.5) * 3.0) * WPS
		d.velocity = (p - d.position) / maxf(delta, 0.0001)
		d.position = p
		if d.status != null and is_instance_valid(d.status):
			d.status.tick(delta)
	if paused_cast:
		return
	cooldown -= delta
	if cooldown <= 0.0:
		cooldown = float(MENU[current][2]) * SANDBOX_TIME
		var what = MENU[current][1]
		if what is Array:
			for w in what:
				cast(str(w))
		else:
			cast(str(what))

func cast(text: String):
	var parsed = KP.parse(text, Defs.by_incantation().keys())
	if not parsed.ok:
		push_warning("arena: cannot parse " + text)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_counter
	seed_counter += 1
	var plan = Planner.plan(Defs.get_def(Defs.by_incantation()[parsed.spell]), parsed.bundle, {"rng": rng})
	var c = GenericCast.new()
	add_child(c)
	c.setup(plan, caster, self, {"spell": plan.id, "cast_clock": t, "cast_id": seed_counter}, false, seed_counter)

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < MENU.size():
		select(k - KEY_1)
	elif k == KEY_TAB:
		page = (page + 1) % PAGES.size()
		select(0)
	elif k == KEY_B:
		dark = not dark
		floor_node.queue_redraw()
	elif k == KEY_SPACE:
		paused_cast = not paused_cast
	elif k == KEY_S:
		slow = not slow
		Engine.time_scale = 0.25 if slow else 1.0
	elif k == KEY_P:
		var v = get_node_or_null("/root/Vfx")
		if v:
			v.presenter.enabled = not v.presenter.enabled
	elif k == KEY_T:
		var v2 = get_node_or_null("/root/Vfx")
		if v2:
			v2.on_twos = not v2.on_twos
	elif k == KEY_R:
		select(current)
	_update_hud()

func select(i: int):
	current = i
	cooldown = 0.0
	for n in get_children():
		if n is GenericCast:
			n.queue_free()
	var v = get_node_or_null("/root/Vfx")
	if v:
		v.clear()
		v.presenter._parts.clear()
	for d in dummies:
		if d.status != null and is_instance_valid(d.status):
			d.status.queue_free()
			d.status = null
	_update_hud()

func _update_hud():
	var v = get_node_or_null("/root/Vfx")
	var lines := ["VFX ARENA   [%s]  %s      Tab: next page" % [PAGES[page][0], str(MENU[current][0])]]
	var menu := []
	for i in MENU.size():
		menu.append(str(i + 1) + " " + str(MENU[i][0]).split(" (")[0])
	lines.append("  ".join(menu))
	lines.append("B floor: %s   Space %s   S slow-mo %s   P VFX %s   T twos %s   R reset" % [
		"dark" if dark else "grass", "paused" if paused_cast else "casting", "on" if slow else "off",
		"on" if v and v.presenter.enabled else "off", "on" if v and v.on_twos else "off"])
	hud.text = "\n".join(lines)

class ArenaFloor extends Node2D:
	const ART = "res://assets/typecast/"
	var arena
	var tiles: Array = []
	func _ready():
		z_index = -100
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for i in range(1, 10):
			tiles.append(load(ART + "Level Tiles/Grass Tile %d.png" % i))
	func _draw():
		var wps := 1280.0 / 192.0
		if arena.dark:
			# sandbox floorPx: vn(x*.35, y*.35) + hs(x,y)*.25 -> three tones, one rect per sandbox px
			var V = preload("res://scripts/vfx/Vfx.gd")
			for y in range(-10, 120):
				for x in range(-20, 212):
					var n: float = V.vn(x * 0.35, y * 0.35) + V.hs(x, y) * 0.25
					var c := Color("#25222c") if n > 0.82 else (Color("#1b1820") if n < 0.25 else Color("#1f1c25"))
					draw_rect(Rect2(Vector2(x, y) * wps, Vector2.ONE * wps), c)
		else:
			for y in range(-2, 8):
				for x in range(-2, 13):
					var idx := posmod(x * 7 + y * 13, tiles.size())
					draw_texture_rect(tiles[idx], Rect2(Vector2(x, y) * 128.0, Vector2.ONE * 128.0), false, Color(0.72, 0.78, 0.72))
