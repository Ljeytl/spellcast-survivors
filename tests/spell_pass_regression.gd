extends SceneTree
## Doc 21 §5: the spell pass, part by part. Each spell's parts carry their own damage (multiples of
## the base hit) and effects; the new mechanics (Rune Trap's three stages, Meteor Shower's crater,
## Meteor Spear's meteors, Lightning Bolt's one strike, Prism Ray's refraction, Soul Bloom's ghosts,
## Cross Blade's held pulses, shock's stun) behave as decided.

const SpellDamage = preload("res://scripts/engine/SpellDamage.gd")
const Bridge = preload("res://scripts/engine/LegacyBridge.gd")
const Effects = preload("res://scripts/engine/Effects.gd")

var checks = 0
var failures = 0

class Foe extends Node2D:
	const FX = preload("res://scripts/engine/Effects.gd")
	var element = ""
	var resistances = {}
	var status = null
	var max_health = 1000.0
	var current_health = 1000.0
	var dying = false
	func apply_effect(e, s = {}, o = Vector2.INF):
		return FX.apply_to_entity(self, e, s, o)
	func receive_damage(a, _o = Vector2.INF, _s = {}):
		current_health -= a

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, message):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func near(a, b, eps = 0.01) -> bool:
	return absf(float(a) - float(b)) <= eps

func sum(mix: Dictionary) -> float:
	var t = 0.0
	for k in mix:
		t += float(mix[k])
	return t

func statuses(id: String, part: String) -> Array:
	return SpellDamage.statuses_for(id, part).map(func(r): return str(r.status))

func payload_statuses(def: Dictionary, part: String) -> Array:
	return def.parts[part].payload.filter(func(x): return str(x.type) == "status").map(func(x): return str(x.status))

func run():
	# Data: splits and effects per part.
	check(SpellDamage.profile("mana_bolt").damage == {"raw": 1.0}, "Magic Missile is all physical")
	check(near(sum(SpellDamage.profile("lightning_bolt", "bolt").damage), 1.5) and near(sum(SpellDamage.profile("lightning_bolt", "splash").damage), 1.5), "Lightning Bolt: 150% bolt hit, 150% strike")
	check(near(SpellDamage.profile("ember_spear", "trail").damage.get("fire", 0.0), 0.2) and statuses("ember_spear", "trail") == ["burn"], "Ember Spear's trail: 20% fire + burn")
	check(statuses("ember_spear", "spear").is_empty(), "Ember Spear's spear hit applies nothing")
	check(statuses("meteor_shower", "impact").has("stunned") and statuses("meteor_shower", "crater").is_empty(), "Meteor impact stuns; its crater does not burn")
	check(near(sum(SpellDamage.profile("meteor_shower", "crater").damage), 0.25), "Meteor crater ticks 25% of the impact")
	check(statuses("seeker", "").has("poison") and statuses("seeker", "").has("weakened"), "Seeker poisons and weakens")
	check(near(sum(SpellDamage.profile("prism_ray", "beam").damage), 0.6), "Prism Ray's laser is 60%")
	var rays = ["ray_fire", "ray_water", "ray_storm", "ray_earth", "ray_plague", "ray_life"]
	var effects = rays.map(func(r): return statuses("prism_ray", r)[0])
	check(effects == ["burn", "chilled", "shocked", "bleed", "poison", "entangled"], "Each refracted laser applies its own element's effect")
	check(rays.all(func(r): return near(sum(SpellDamage.profile("prism_ray", r).damage), 0.15)), "Each refracted laser is 15%")
	check(near(SpellDamage.profile("cross_blade", "return").damage.get("earth", 0.0), 1.25), "Cross Blade's return is 75 physical / 125 earth")

	# Built spells.
	var meteor = Bridge.build({"id": "meteor_shower", "type": "multi_aoe", "damage": 32, "radius": 220}, 32.0, {})
	check(meteor.parts.has("crater") and meteor.parts.mark.events.has("on_expire#crater"), "Meteor Shower leaves a crater after its impact")
	check(payload_statuses(meteor, "impact").has("stunned"), "The impact carries the stun")
	var bolt = Bridge.build({"id": "lightning_bolt", "type": "bouncing_projectile", "damage": 40, "bounce_count": 4}, 40.0, {})
	check(not bolt.parts.bolt.events.has("on_hit") and bolt.parts.bolt.events["on_hit#bounce"].get("end", {}).get("part", "") == "splash", "Lightning Bolt strikes once, where its chain ends")
	var trap1 = Bridge.build({"id": "rune_trap", "type": "trap", "damage": 55, "level": 1}, 55.0, {})
	var trap6 = Bridge.build({"id": "rune_trap", "type": "trap", "damage": 55, "level": 7}, 55.0, {})
	check(trap1.parts.rune.events.on_trigger.part == "activate" and trap1.parts.activate.events.on_expire.part == "burst", "Rune Trap: arm, activate, explode")
	check(payload_statuses(trap1, "activate") == ["rooted"], "Rank 1: activate roots, no vulnerable")
	var vuln = trap6.parts.activate.payload.filter(func(x): return str(x.get("status", "")) == "vulnerable")
	check(vuln.size() == 1 and near(vuln[0].stacks, 5.0), "Rank 6+: activate adds 5 vulnerable stacks")
	var spear = Bridge.build({"id": "meteor_spear", "type": "piercing", "damage": 45, "burn_trail": true, "explosive": true}, 45.0, {})
	check(spear.parts.has("drop") and spear.parts.has("meteor") and spear.parts.spear.events.on_hit.part == "drop", "Meteor Spear drops a small meteor on every enemy it pierces")
	check(payload_statuses(spear, "meteor").has("stunned"), "Its meteors stun")
	var prism = Bridge.build({"id": "prism_ray", "type": "beam", "damage": 18, "refract": true}, 18.0, {})
	check(rays.all(func(r): return prism.parts.has(r) and prism.parts.beam.events.has("on_hit#" + r)), "Prism Ray refracts into six lasers")
	var blade = Bridge.build({"id": "cross_blade", "type": "returning", "damage": 11, "linger_duration": 0.9}, 11.0, {})
	check(int(blade.parts.blade.motion[2].status_repeat) == 2 and near(sum(blade.parts.blade.motion[1].pulse.mix), 1.0), "Cross Blade: 100% pulses while holding, double bleed on return")
	var ice = Bridge.build({"id": "ice_blast", "type": "aoe", "damage": 35, "degrees_per_shard": 30}, 35.0, {})
	check(not ice.parts.shard.payload.any(func(x): return str(x.type) == "slow") and payload_statuses(ice, "shard").has("chilled"), "Ice Blast: chill, no separate slow")

	# Statuses: shock stuns; Prism's shock is the mark alone.
	var a = Foe.new()
	root.add_child(a)
	Effects.apply(a, {"type": "status", "status": "shocked"}, {"cast_id": 1})
	check(a.status.has("shocked") and a.status.has("stunned"), "Shock marks and stuns")
	var b = Foe.new()
	root.add_child(b)
	Effects.apply(b, {"type": "status", "status": "shocked", "no_stun": true}, {"cast_id": 2})
	check(b.status.has("shocked") and not b.status.has("stunned"), "Prism's shock is the mark alone")
	var c = Foe.new()
	root.add_child(c)
	Effects.apply(c, {"type": "status", "status": "vulnerable", "stacks": 0.5}, {})
	Effects.apply(c, {"type": "status", "status": "vulnerable", "stacks": 0.5}, {})
	check(near(c.status.damage_taken_multiplier(), 1.05), "Two Focus Ray ticks make one vulnerable stack (+5%)")

	print("spell_pass_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
