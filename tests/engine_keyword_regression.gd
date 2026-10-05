extends SceneTree
## Keyword parser, spell definitions and the cast planner (doc 18 §3–4, §8). Pure data, no scene.

const KP = preload("res://scripts/engine/KeywordParser.gd")
const Defs = preload("res://scripts/engine/SpellDefs.gd")
const Planner = preload("res://scripts/engine/CastPlanner.gd")

var checks = 0
var failures = 0
const NAMES = ["spear", "nova", "field", "orbit", "trap", "slash", "fireball", "frost nova", "tsunami", "flame wall",
	"lightning rod", "meteor ring", "regrowth", "ember spear", "earth spear", "bolt", "lightning", "frost sigil"]

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func near(a, b, eps = 0.001) -> bool:
	return absf(float(a) - float(b)) <= eps

func p(text):
	return KP.parse(text, NAMES)

func mk(text, opts = {}):
	var parsed = KP.parse(text, Defs.by_incantation().keys())
	return Planner.plan(Defs.get_def(Defs.by_incantation()[parsed.spell]), parsed.bundle, opts)

func entries_of(pl, part = ""):
	var part_name = part if part != "" else str(pl.root)
	for item in pl.parts[part_name].payload:
		if item.type == "damage":
			return item.entries
	return []

func total(entries) -> float:
	var t = 0.0
	for e in entries:
		t += float(e.amount)
	return t

func status_of(pl, id, part = ""):
	var part_name = part if part != "" else str(pl.root)
	for item in pl.parts[part_name].payload:
		if item.type == "status" and item.status == id:
			return item
	return null

func rejected_words(pl) -> Array:
	return pl.rejected.map(func(r): return r.word)

func run():
	parser()
	bundles()
	definitions()
	planner_basics()
	planner_keywords()
	planner_rejections()
	print("engine_keyword_regression: ", checks, " checks, ", failures, " failures")
	quit(1 if failures > 0 else 0)

func parser():
	var r = p("spear")
	check(r.ok and r.spell == "spear" and r.keywords.is_empty(), "Bare spear parses")
	r = p("triple mega icy ember spear")
	check(r.ok and r.spell == "ember spear" and r.keywords == ["triple", "mega", "icy"], "Longest spell name wins over the bare form it contains")
	var a = p("mega ember spear")
	var b = p("ember spear mega")
	check(a.ok and b.ok and near(a.bundle.power, b.bundle.power) and a.spell == b.spell, "Word order is free")
	check(p("lightning rod").spell == "lightning rod" and p("lightning").spell == "lightning", "Lightning Rod and Lightning are told apart")
	check(p("frost nova").spell == "frost nova" and p("mega nova").spell == "nova", "Frost Nova vs bare Nova")
	r = p("mega mega spear")
	check(r.rejected.size() == 1 and r.rejected[0].reason == "used twice" and r.keywords == ["mega"], "A word twice is rejected")
	r = p("double triple spear")
	check(r.rejected.size() == 1 and r.rejected[0].word == "triple" and r.bundle.copies == 2, "One count word only")
	r = p("pulling repulsing nova")
	check(r.rejected.size() == 1 and r.rejected[0].word == "repulsing", "Force words are exclusive")
	r = p("delayed charged spear")
	check(r.rejected.size() == 1, "Timing words are exclusive")
	r = p("blorp spear")
	check(not r.ok and r.unknown == ["blorp"] and r.error.begins_with("unknown word"), "Unknown words fail the parse")
	r = p("mega")
	check(not r.ok and r.error == "no spell", "Keywords alone are not a spell")
	r = p("")
	check(not r.ok and r.error == "empty", "Empty text")
	r = p("  MEGA   Spear  ")
	check(r.ok and r.spell == "spear" and r.keywords == ["mega"], "Case and spacing are ignored")
	r = p("quick fn")
	check(r.ok and r.quick and r.spell == "frost nova" and near(r.bundle.power, 0.35), "Quick cast by initials at 35% power")
	r = p("quick es")
	check(not r.ok and r.error.contains("more than one"), "Ambiguous initials fail (ember spear / earth spear)")
	r = p("quick zz")
	check(not r.ok and r.error.contains("no spell"), "Unknown initials fail")
	r = p("quick s")
	check(r.ok and r.spell == "spear" or r.error.contains("more than one"), "Single-letter quick cast resolves or reports ambiguity")
	# No keyword may share a name with a spell.
	var all_names = Defs.by_incantation().keys()
	for w in KP.data().words:
		check(not all_names.has(w), "Keyword " + w + " is not a spell name")
	for name in all_names:
		for part in str(name).split(" "):
			if KP.is_keyword(part):
				check(false, "Spell word " + part + " in " + name + " is also a keyword")
	check(KP.words_in("tier").size() == 4 and KP.words_in("tier").has("powerful"), "Four tier words incl. POWERFUL")
	check(not KP.is_keyword("duper") and not KP.is_keyword("holy") and not KP.is_keyword("radiant"), "Dropped words stay dropped")

func bundles():
	check(near(p("mega spear").bundle.power, 1.5) and near(p("mega spear").bundle.size, 1.5), "MEGA = 1 + 0.125 × 4")
	check(near(p("omega spear").bundle.power, 1.625), "OMEGA = 1.625")
	check(near(p("powerful spear").bundle.power, 2.0), "POWERFUL = 2.0 (longer is stronger)")
	check(near(p("mega super spear").bundle.power, 1.625 * 1.25), "Tier words stack with diminishing returns")
	check(near(p("super mega spear").bundle.power, p("mega super spear").bundle.power), "Stacking is order independent")
	check(p("mega spear").bundle.charge > 0.0 and p("powerful spear").bundle.charge > p("mega spear").bundle.charge, "Longer tier words charge longer")
	check(near(p("big spear").bundle.size, 1.21) and near(p("big spear").bundle.power, 1.0), "Size words change size only")
	check(p("gigantic spear").bundle.size > p("massive spear").bundle.size, "GIGANTIC > MASSIVE")
	var r = p("triple spear").bundle
	check(r.copies == 3 and near(r.per_copy, 0.45), "TRIPLE = 3 copies at 45%")
	r = p("icy spear").bundle
	check(r.elements.size() == 1 and r.elements[0].element == "water" and near(r.elements[0].share, 0.15) and r.elements[0].status == "chilled", "ICY adds 15% water + chill")
	check(near(p("glacial spear").bundle.elements[0].share, 0.35), "GLACIAL (7 letters) adds 35%")
	check(near(p("icy frosty spear").bundle.elements[0].share, 0.30 + 0.15 * 0.5), "Same-element words stack with diminishing returns")
	r = p("icy fiery spear").bundle
	check(r.elements.size() == 2, "Different elements are separate shares")
	var statuses = {}
	for w in ["arcane", "fiery", "icy", "stormy", "iron", "toxic", "living"]:
		statuses[p(w + " spear").bundle.elements[0].status] = true
	check(statuses.keys().size() == 7 and statuses.has("bleed") and statuses.has("poison") and statuses.has("entangled") and statuses.has("vulnerable"), "Each element word carries its element's status")
	r = p("homing swift lasting spear").bundle
	check(r.flags.has("homing") and r.flags.has("swift") and r.flags.has("lasting"), "Behaviour flags")
	check(p("ringed spear").bundle.arrangement == "ring" and p("lined spear").bundle.arrangement == "line", "Arrangement words")
	check(p("mega spear").bundle.words == {"mega": "tier"}, "Bundle records words by category")

func definitions():
	var all = Defs.all()
	check(all.size() >= 13, "At least 13 generic spells load")
	for id in all:
		var errors = Defs.validate(all[id])
		check(errors.is_empty(), "Definition " + str(id) + " validates: " + str(errors))
	var bare = Defs.bare_incantations()
	for n in ["spear", "nova", "field", "orbit", "trap", "slash"]:
		check(bare.has(n), "Bare form " + n)
	check(not bare.has("fireball"), "Data-only spells are not bare")
	var bad = {"id": "bad", "name": "Bad", "incantation": "bad", "root": "x", "parts": {"x": {"delivery": "teleport", "payload": [{"type": "status", "status": "holy_fire"}], "events": {"on_hit": {"part": "nope"}}}}}
	var errors = Defs.validate(bad)
	check(errors.size() >= 3, "Validator catches bad delivery, status and event target: " + str(errors))
	check(Defs.register(bad).size() > 0 and Defs.get_def("bad").is_empty(), "Invalid definitions are not registered")
	var good = {"id": "test_dart", "name": "Dart", "incantation": "dart", "element": "", "acquire": "bare", "root": "d",
		"parts": {"d": {"delivery": "projectile", "motion": [{"type": "straight", "speed": 500, "range": 300}], "payload": [{"type": "damage", "amount": 5}]}}}
	check(Defs.register(good).is_empty() and Defs.by_incantation().has("dart"), "A new spell is pure data")
	Defs.unregister("test_dart")
	check(not Defs.by_incantation().has("dart"), "Unregister")

func planner_basics():
	var pl = mk("spear")
	var e = entries_of(pl)
	check(e.size() == 1 and e[0].damage_type == "raw" and near(e[0].amount, 22), "Bare spear: 22 raw")
	check(pl.casts.size() == 1 and near(pl.casts[0].delay, 0.0), "One immediate cast")
	pl = mk("fireball")
	e = entries_of(pl)
	check(near(total(e), 30) and e.any(func(x): return x.damage_type == "fire" and near(x.amount, 15)), "Fireball orb 50/50 raw/fire")
	check(near(total(entries_of(pl, "blast")), 60) and entries_of(pl, "blast").any(func(x): return x.damage_type == "raw" and near(x.amount, 12)), "Blast 20% raw")
	pl = mk("fireball", {"rank_power": 2.0, "size_stat": 1.5})
	check(near(total(entries_of(pl)), 60) and near(pl.parts.blast.geometry.radius, 135), "Player stats scale power and size")
	pl = mk("flame wall")
	check(status_of(pl, "burn") != null and near(status_of(pl, "burn").hit, 30), "Status payload carries the hit it scales from")
	pl = mk("icy flame wall")
	check(status_of(pl, "chilled") != null and status_of(pl, "chilled").no_freeze == true, "Chill from a periodic part never freezes")
	pl = mk("frost nova")
	check(status_of(pl, "chilled").get("no_freeze", false) == false and int(status_of(pl, "chilled").stacks) == 3, "Frost Nova: 3 chill stacks, can freeze")
	pl = mk("quick fb" if false else "fireball", {"quick": true})
	check(pl.quick, "Quick flag carried")

func planner_keywords():
	var pl = mk("mega spear")
	check(near(total(entries_of(pl)), 33) and near(pl.parts.spear.geometry.radius, 18) and near(pl.casts[0].delay, 0.35), "MEGA spear: ×1.5 power and size, charges")
	pl = mk("triple spear")
	check(pl.arrangement.type == "fan" and int(pl.arrangement.count) == 3 and near(total(entries_of(pl)), 22 * 0.45), "TRIPLE spear fans 3 at 45%")
	pl = mk("triple nova")
	check(int(pl.arrangement.count) == 3 and pl.release.type == "staggered", "TRIPLE nova: three staggered rings")
	pl = mk("triple field")
	check(pl.arrangement.type == "ring" and int(pl.arrangement.count) == 3, "TRIPLE field: three patches around the target")
	pl = mk("double meteor ring")
	check(int(pl.arrangement.count) == 16, "DOUBLE meteor ring doubles the ring")
	pl = mk("icy spear")
	var e = entries_of(pl)
	check(e.size() == 2 and e[1].damage_type == "water" and e[1].chart_element == "water" and near(e[1].amount, 3.3), "ICY adds water damage keyed on its own element")
	check(status_of(pl, "chilled") != null and near(status_of(pl, "chilled").hit, 3.3), "ICY applies chill")
	pl = mk("homing spear")
	var m = pl.parts.spear.motion[0]
	check(m.type == "guided" and near(m.speed, 900 * 0.85) and near(m.turn, 7.0), "HOMING turns straight motion into guided")
	pl = mk("swift spear")
	check(near(pl.parts.spear.motion[0].speed, 900 * 1.35), "SWIFT speeds motion")
	pl = mk("swift nova")
	check(near(pl.parts.ring.propagation.speed, 700 * 1.35), "SWIFT speeds propagation")
	pl = mk("lasting field")
	check(near(pl.parts.patch.timing.duration, 3.0 * 1.4), "LASTING extends duration")
	pl = mk("piercing fireball")
	check(int(pl.parts.orb.limits.pierce) == 2 and near(total(entries_of(pl)), 27), "PIERCING adds pierce at 90% power")
	pl = mk("piercing spear")
	check(int(pl.parts.spear.limits.pierce) == -1, "Unlimited pierce stays unlimited")
	pl = mk("splitting fireball")
	check(pl.parts.has("_split") and pl.parts.orb.events.has("on_first_hit") and near(total(entries_of(pl, "_split")), 30 * 0.3), "SPLITTING adds 3 splinters at 30%")
	pl = mk("exploding spear")
	check(pl.parts.has("_explode") and pl.parts.spear.events.has("on_hit") and near(total(entries_of(pl, "_explode")), 11), "EXPLODING adds a 50% blast on hit")
	pl = mk("exploding fireball")
	check(pl.parts.orb.events.has("on_hit") and pl.parts.orb.events.has("on_hit#_explode"), "EXPLODING keeps the spell's own on_hit event")
	pl = mk("exploding field")
	check(pl.parts.patch.events.has("on_expire"), "EXPLODING field bursts when it ends")
	pl = mk("chaining spear")
	check(pl.parts.has("_chain") and int(pl.parts.spear.events.on_first_hit.hops) == 3, "CHAINING: 3 hops")
	pl = mk("cascading spear")
	check(pl.parts.has("_cascade") and pl.parts.spear.events.has("on_kill"), "CASCADING copies on kill")
	pl = mk("orbiting fireball")
	check(pl.parts.orb.motion[0].type == "orbit" and pl.parts.orb.motion[0].until == "enemy_in_range" and pl.parts.orb.motion[1].type == "straight", "ORBITING holds first, then flies")
	pl = mk("twinned spear")
	check(pl.casts.size() == 2 and near(pl.casts[1].delay, 0.15) and near(pl.casts[1].power, 0.8), "TWINNED casts twice")
	pl = mk("repeating nova")
	check(pl.casts.size() == 2 and near(pl.casts[1].power, 0.4) and near(pl.casts[1].size, 0.75), "REPEATING echoes weaker")
	pl = mk("charged spear")
	check(near(pl.casts[0].delay, 1.2) and near(total(entries_of(pl)), 55), "CHARGED: 1.2 s for ×2.5")
	pl = mk("delayed trap")
	check(near(pl.casts[0].delay, 0.8), "DELAYED waits")
	pl = mk("ringed spear")
	check(pl.arrangement.type == "ring" and int(pl.arrangement.count) == 3, "RINGED spear")
	pl = mk("lined trap")
	check(pl.arrangement.type == "line", "LINED trap")
	pl = mk("pulling nova")
	check(pl.parts.ring.payload.any(func(x): return x.type == "impulse" and x.direction == "toward"), "PULLING adds a pull")
	pl = mk("sanguine spear")
	check(near(total(entries_of(pl)), 22 * 1.6), "SANGUINE: ×1.6")
	pl = mk("homing slash")
	check(pl.parts.cut.aim.type == "densest", "HOMING volume aims at the densest pack")
	pl = mk("homing field")
	check(pl.parts.patch.has("drift"), "HOMING field drifts toward enemies")
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	pl = mk("chaotic spear", {"rng": rng})
	check(pl.elements.size() == 1 and entries_of(pl).size() == 2, "CHAOTIC adds a random element")
	pl = mk("mega regrowth")
	check(near(pl.parts.heal.payload[0].amount, 18), "MEGA strengthens healing")
	pl = mk("triple mega icy homing spear")
	check(pl.rejected.is_empty() and int(pl.arrangement.count) == 3 and pl.parts.spear.motion[0].type == "guided" and entries_of(pl).size() == 2, "Everything composes")

func planner_rejections():
	check(rejected_words(mk("triple regrowth")).has("triple"), "Count on self is rejected")
	check(rejected_words(mk("icy regrowth")).has("icy"), "Element on a heal is rejected")
	check(rejected_words(mk("lasting spear")).has("lasting"), "LASTING on an instant spell is rejected")
	check(rejected_words(mk("swift field")).has("swift"), "SWIFT on a still field is rejected")
	check(rejected_words(mk("piercing nova")).has("piercing"), "PIERCING needs a projectile")
	check(rejected_words(mk("splitting slash")).has("splitting"), "SPLITTING needs a projectile")
	check(rejected_words(mk("orbiting nova")).has("orbiting"), "ORBITING needs a projectile")
	check(rejected_words(mk("warding spear")).has("warding"), "WARDING is not built yet")
	check(rejected_words(mk("pulling regrowth")).has("pulling"), "Force needs a hit")
	check(rejected_words(mk("hunting regrowth")).has("hunting"), "Targeting needs a target")
	check(rejected_words(mk("ringed regrowth")).has("ringed"), "Arrangement needs something to arrange")
	check(mk("exploding nova").rejected.is_empty(), "EXPLODING works on volumes (on expire)")
	check(mk("mega icy nova").rejected.is_empty() and mk("homing triple field").rejected.is_empty(), "Sensible combinations are accepted")
