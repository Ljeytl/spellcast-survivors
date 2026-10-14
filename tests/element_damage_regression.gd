extends SceneTree
## Typed damage for shipping spells (doc 18 §5.5, §6.1, §6.5): hits split by spell, one resistance per
## damage type (no armour), the type chart on elemental enemies, and on-hit bleed for Cross Blade / Earth Shield.

const SpellDamage = preload("res://scripts/engine/SpellDamage.gd")
static var Recipes: Dictionary = preload("res://scripts/SynergyCatalog.gd").RECIPES  # data/recipes.json

class VfxStub extends Node:
	var seen: Array = []
	var chain_targets = 0
	func status_event(_enemy, event: String, data: Dictionary):
		seen.append(event + ":" + str(data.get("status", data.get("name", ""))))
		if data.get("name", "") == "chain":
			chain_targets = data.get("targets", []).size()

var checks = 0
var failures = 0
var manager
var next_cast = 1000

func _initialize():
	run.call_deferred()

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func near(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

func fresh(id: String = "pursuer"):
	var definition: Dictionary = manager.encounter_config.variants[id].duplicate(true)
	definition.id = id
	var enemy = manager.spawn_monster(definition, false, true)
	enemy.set_physics_process(false)
	enemy.set_process(false)
	enemy.max_health = 10000.0
	enemy.current_health = 10000.0
	return enemy

func hit(enemy, amount: float, spell: String) -> float:
	var before = enemy.current_health
	next_cast += 1  # each hit is its own cast, so statuses from earlier hits can react
	enemy.take_damage(amount, Vector2.INF, {"spell": spell, "cast_clock": 0.0, "cast_id": next_cast})
	return before - enemy.current_health

func run():
	root.get_node("AudioManager").quitting = true
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	var ids: Array = load("res://scripts/SpellManager.gd").BASE_SPELL_IDS.duplicate() + Recipes.keys() + ["mana_bolt", "atomic"]
	for id in ids:
		var effect = SpellDamage.effect(100.0, id)
		var total = 0.0
		for entry in effect.entries:
			total += float(entry.amount)
		check(near(total, 100.0), "%s damage shares sum to the hit" % id)
		var enemy = fresh()
		# Chill adds frostbite: 4% of the hit as water damage (data/statuses.json).
		var expected = 104.0 if id in ["ice_blast", "frost_sigil"] else 100.0
		check(near(hit(enemy, 100.0, id), expected), "%s does unchanged direct damage to a neutral Woodland enemy" % id)
		enemy.queue_free()
	check(near(hit(fresh(), 50.0, ""), 50.0), "Unknown sources are plain raw damage")
	# Armoured elite: 30% on everything, Arcane partly pierces.
	var armored = fresh()
	armored.is_elite = true
	armored.elite_type = armored.EliteType.ARMORED
	armored.resistances = SpellDamage.resistance_profile("elite_armored")
	check(near(hit(armored, 100.0, "bolt"), 85.0), "Bolt (arcane) pierces half the armour")
	check(near(hit(armored, 100.0, "lightning"), 70.0), "Lightning (storm) meets full armour")
	check(near(hit(armored, 100.0, "ember_spear"), 70.0), "Ember Spear raw + fire both meet armour")
	check(near(hit(armored, 100.0, "atomic"), 100.0), "Atomic is pure and ignores resistance")
	# Type chart on an elemental enemy (the FROST elite is Water/Ice).
	# A fresh Frost enemy per check, so leftover chill or shock cannot trigger reactions (Thaw).
	var frost_hit = func(spell: String) -> float:
		var frost = fresh()
		frost.element = "water"
		return hit(frost, 100.0, spell)
	check(near(frost_hit.call("lightning"), 125.0), "Storm beats Water/Ice")
	check(near(frost_hit.call("ice_blast"), 75.0 + 4.0 * 0.75), "Same element resists the whole Ice Blast hit (and its frostbite)")
	check(near(frost_hit.call("ember_spear"), 100.0), "Fire against Water/Ice is neutral (only Water beats Fire)")
	check(near(frost_hit.call("bolt"), 100.0), "Arcane is neutral")
	check(near(frost_hit.call("steam_field"), 50.0 + 37.5), "Steam Field's water share is resisted, fire share neutral")
	var stormy = fresh()
	stormy.element = "storm"
	check(near(hit(stormy, 100.0, "cross_blade"), 125.0), "Earth/Steel raw share still beats Storm (keyed on spell element)")
	# On-hit bleed and the Overload reaction.
	var bled = fresh()
	hit(bled, 100.0, "cross_blade")
	check(bled.status != null and bled.status.has("bleed"), "Cross Blade applies bleed")
	var hp = bled.current_health
	bled.status.tick(4.0)
	check(near(hp - bled.current_health, 0.03 * 100.0 * 8.0, 0.1), "Bleed ticks 3% of the hit for 4 s")
	hit(bled, 100.0, "cross_blade")
	hp = bled.current_health
	hit(bled, 10.0, "bolt")
	check(bled.status.reactions_fired.has("overload") and hp - bled.current_health > 10.0, "Bolt overloads the bleed")
	var shielded = fresh()
	hit(shielded, 50.0, "earth_shield")
	check(shielded.status != null and shielded.status.has("bleed"), "Earth Shield eruption applies bleed")
	var plain = fresh()
	hit(plain, 100.0, "bolt")
	check(plain.status == null or not plain.status.has("bleed"), "Bolt applies no status")
	# Per-application bleed: each hit's bleed expires 4 s after that hit, so the pool cannot grow forever.
	var stacked = fresh()
	hit(stacked, 100.0, "cross_blade")
	stacked.status.tick(3.0)
	hit(stacked, 100.0, "cross_blade")
	check(stacked.status.bleed.stacks.size() == 2, "Two hits, two bleed stacks")
	stacked.status.tick(1.0)
	check(stacked.status.bleed.stacks.size() == 1, "The first stack expires 4 s after its own hit")
	stacked.status.tick(3.0)
	check(not stacked.status.has("bleed"), "The second expires 4 s after its hit")
	# Burn: Ember Spear's trail burns, the spear itself does not; fire fields burn.
	var speared = fresh()
	hit(speared, 100.0, "ember_spear")
	check(speared.status == null or not speared.status.has("burn"), "The Ember Spear hit does not burn")
	var trailed = fresh()
	trailed.take_damage(10.0, Vector2.INF, {"spell": "ember_spear", "cast_id": 77, "part": "trail"})
	check(trailed.status != null and trailed.status.has("burn"), "Ember Spear's trail burns")
	for id in ["cinder_field", "firewalk", "steam_field"]:
		var scorched = fresh()
		hit(scorched, 10.0, id)
		check(scorched.status != null and scorched.status.has("burn"), "%s burns" % id)
	for id in ["meteor_shower", "meteor_spear", "seeker", "bolt", "focus_ray"]:
		var clean = fresh()
		hit(clean, 10.0, id)
		check(clean.status == null or (not clean.status.has("burn") and not clean.status.has("bleed") and not clean.status.has("poison")), "%s applies no damage over time" % id)
	# Control statuses: Ice Blast chills (5 stacks freeze), Lightning shocks.
	var iced = fresh()
	for i in 4:
		hit(iced, 10.0, "ice_blast")
	check(iced.status.chill_stacks() == 4 and not iced.status.has("frozen"), "Four Ice Blast hits: four chill stacks")
	hit(iced, 10.0, "ice_blast")
	check(iced.status.has("frozen"), "The fifth freezes")
	var zapped = fresh()
	zapped.global_position = Vector2(5000, 5000)
	var neighbour = fresh()
	neighbour.global_position = Vector2(5100, 5000)
	hit(zapped, 100.0, "lightning")
	check(zapped.status.has("shocked") and neighbour.current_health == 10000.0, "Lightning shocks; the first cast does not arc")
	hit(zapped, 100.0, "lightning")
	check(zapped.status.reactions_fired.has("chain") and near(10000.0 - neighbour.current_health, 40.0), "The next Lightning cast chains to a neighbour")
	var conducted = fresh()
	conducted.global_position = Vector2(-5000, -5000)
	hit(conducted, 100.0, "lightning")
	conducted.status.reaction_ready_at = 0.0
	var conduct_damage = hit(conducted, 100.0, "ice_blast")
	check(conducted.status.reactions_fired.has("conduct") and conduct_damage > 104.0, "Ice Blast conducts a shock for bonus storm damage")
	var grounded = fresh()
	hit(grounded, 100.0, "lightning")
	hit(grounded, 100.0, "cross_blade")
	check(not grounded.status.has("shocked"), "Cross Blade (earth) grounds the shock")
	# Burn is credited as damage over time on the end screen.
	game.style_session.damage_by_spell.clear()
	game.style_session.damage_by_effect.clear()
	var burning = fresh()
	hit(burning, 100.0, "cinder_field")
	burning.status.tick(2.0)
	check(float(game.style_session.damage_by_effect.get("cinder_field", {}).get("burn", 0.0)) > 0.0, "Cinder Field's burn is credited as burn")
	# Status moments reach /root/Vfx.status_event when it exists (docs/VFX_EVENTS.md).
	var real_vfx = root.get_node_or_null("Vfx")
	if real_vfx:
		real_vfx.name = "VfxReal"
	var stub = VfxStub.new()
	stub.name = "Vfx"
	root.add_child(stub)
	var watched = fresh()
	watched.global_position = Vector2(9000, 9000)
	var watched_near = fresh()
	watched_near.global_position = Vector2(9080, 9000)
	hit(watched, 100.0, "lightning")
	watched.status.reaction_ready_at = 0.0
	hit(watched, 100.0, "lightning")
	check(stub.seen.has("applied:shocked"), "Applying shock is announced")
	check(stub.seen.has("reaction:chain") and stub.chain_targets == 1, "Chain is announced with its target positions")
	hit(watched_near, 100.0, "cross_blade")
	check(stub.seen.has("reaction:grounded"), "Grounding is announced")
	watched_near.status.tick(5.0)
	check(stub.seen.has("expired:bleed"), "Bleed ending is announced")
	stub.queue_free()
	root.remove_child(stub)
	if real_vfx:
		real_vfx.name = "Vfx"
	# DoT credit: bleed ticks count toward Cross Blade and are listed separately on the end screen.
	var session = game.style_session
	session.damage_by_spell.clear()
	session.damage_by_effect.clear()
	var credited = fresh()
	hit(credited, 100.0, "cross_blade")
	credited.status.tick(4.0)
	var bleed_credit = float(session.damage_by_effect.get("cross_blade", {}).get("bleed", 0.0))
	check(near(bleed_credit, 24.0, 0.1), "Bleed ticks are credited to Cross Blade as bleed")
	check(near(float(session.damage_by_spell.get("cross_blade", 0.0)), 124.0, 0.1), "Cross Blade total includes its bleed")
	var summary = game.game_over_screen.damage_summary(session.damage_by_spell, session.damage_by_effect)
	check(summary.contains("Cross Blade") and summary.contains("· bleed 24"), "End screen lists bleed under Cross Blade")
	# Shared bleed pool: two spells feed one enemy's bleed; ticks split by what each added.
	session.damage_by_spell.clear()
	session.damage_by_effect.clear()
	var shared = fresh()
	hit(shared, 100.0, "cross_blade")
	hit(shared, 300.0, "earth_shield")
	var before_ticks = float(session.damage_by_spell.get("cross_blade", 0.0))
	shared.status.tick(1.0)
	var cb = float(session.damage_by_effect.get("cross_blade", {}).get("bleed", 0.0))
	var es = float(session.damage_by_effect.get("earth_shield", {}).get("bleed", 0.0))
	check(cb > 0.0 and near(es / maxf(cb, 0.001), 3.0, 0.05), "Shared bleed ticks split 1:3 by contribution")
	# Overload lands the leftover bleed credited to the bleeders, not to Bolt.
	session.damage_by_spell.clear()
	session.damage_by_effect.clear()
	var popped = fresh()
	hit(popped, 100.0, "cross_blade")
	hit(popped, 10.0, "bolt")
	check(popped.status.reactions_fired.has("overload"), "Overload fired")
	check(float(session.damage_by_effect.get("cross_blade", {}).get("overload", 0.0)) > 0.0, "Overload is credited to Cross Blade")
	check(near(float(session.damage_by_spell.get("bolt", 0.0)), 10.0), "Bolt is credited only its own hit")
	# Chart.
	var chart = load("res://scripts/DamageChart.gd").new()
	game.add_child(chart)
	var shown = chart.populate({"damage_by_spell": {"cross_blade": 8040.0, "bolt": 3120.0, "earth_shield": 600.0}, "damage_by_effect": {"cross_blade": {"bleed": 2100.0}, "earth_shield": {"bleed": 500.0}}, "kills_by_spell": {"cross_blade": 54}, "casts_by_spell": {"cross_blade": 31}})
	check(shown and chart.rows.size() == 4, "Chart has three spell bars and one bleed bar")
	check(str(chart.rows[0].get_meta("detail")).contains("cast 31 times · 259 per cast") and str(chart.rows[0].get_meta("detail")).contains("54 kills"), "Spell detail shows casts, per cast and kills")
	check(str(chart.rows[3].get_meta("detail")) == "Bleed: 2,600 total · Cross Blade 2,100 · Earth Shield 500", "Effect detail lists the spells that fed it")
	chart.rows[1].grab_focus()
	await process_frame
	check(chart.detail.text.begins_with("Bolt: 3,120"), "Focusing a bar shows its detail")
	check(not chart.populate({}), "No damage, no chart")
	chart.queue_free()
	# Element display.
	var TypeChart = preload("res://scripts/engine/TypeChart.gd")
	check(TypeChart.matchup_line("fire") == "Fire · strong vs Plague/Death, weak to Water/Ice", "Fire matchup line")
	check(TypeChart.matchup_line("earth") == "Earth/Steel · strong vs Storm, weak to Life", "Earth matchup line")
	check(SpellDamage.mix_line("ember_spear") == "75% raw · 25% Fire · trail burns", "Ember Spear damage mix")
	check(SpellDamage.mix_line("cross_blade").ends_with("bleeds"), "Cross Blade shows its bleed")
	check(SpellDamage.status_line("ember_spear") == "trail burns", "Ember Spear shows only its trail burns")
	check(SpellDamage.mix_line("life") == "", "Heals show no damage mix")
	var book = load("res://scripts/SpellCollection.gd").new()
	game.add_child(book)
	await process_frame
	var text = ""
	for label in book.find_children("*", "Label", true, false):
		text += label.text + "\n"
	check(text.contains("ELEMENTS") and text.contains("Storm · strong vs Water/Ice, weak to Earth/Steel"), "Necronomicon has the element chart")
	check(text.contains("Damage: 100% Arcane"), "Necronomicon shows spell damage mixes")
	book.queue_free()
	var prep = load("res://scripts/PreparationScreen.gd").new()
	game.add_child(prep)
	await process_frame
	check(prep.element_line("ember_spear") == "Fire  ·  75% raw  ·  trail burns", "Preparation cards show element, raw share and statuses")
	check(prep.element_line("bolt") == "Arcane", "Pure-element spells show just the element")
	check(prep.element_line("cross_blade") == "Earth/Steel  ·  90% raw  ·  bleeds", "Cross Blade card shows its bleed")
	prep.queue_free()
	print("element_damage_regression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
