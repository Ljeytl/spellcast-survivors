extends RefCounted
## Turns a spell definition + parsed keywords into a frozen cast plan (doc 18 §3–4, §8.4).
## Keywords bind by delivery. A word that changes nothing is rejected with a reason (the rune cracks).

const SIZE_KEYS = ["radius", "thickness", "length", "width", "reach"]

static func plan(def: Dictionary, bundle: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var parts: Dictionary = def.parts.duplicate(true)
	var root_name = str(def.root)
	var root: Dictionary = parts[root_name]
	var root_delivery = str(root.delivery)
	var flags: Dictionary = bundle.get("flags", {})
	var words: Dictionary = bundle.get("words", {})
	var bound := {}
	var rejected := []
	var element = str(def.get("element", ""))
	var elements: Array = bundle.get("elements", []).duplicate(true)
	var rng: RandomNumberGenerator = opts.get("rng", RandomNumberGenerator.new())
	if flags.has("chaotic"):
		var pool = ["arcane", "fire", "water", "storm", "earth", "plague", "life"]
		var picked = pool[rng.randi() % pool.size()]
		var status = str(preload("res://scripts/engine/KeywordParser.gd").data().get("element_status", {}).get(picked, ""))
		elements.append({"element": picked, "share": 0.3, "status": status})
		bound["chaotic"] = true

	var has_damage := false
	var has_motion := false
	var has_duration := false
	for n in parts:
		for item in parts[n].get("payload", []):
			if str(item.type) == "damage":
				has_damage = true
		if parts[n].has("motion") or parts[n].has("propagation"):
			has_motion = true
		if parts[n].get("timing", {}).has("duration") or parts[n].get("limits", {}).has("lifetime"):
			has_duration = true

	var power = float(bundle.get("power", 1.0)) * float(opts.get("rank_power", 1.0))
	var size = float(bundle.get("size", 1.0)) * float(opts.get("size_stat", 1.0))
	var speed_mult = float(opts.get("speed_stat", 1.0))
	var duration_mult = float(opts.get("duration_stat", 1.0))
	for t in ["delayed", "charged", "sanguine"]:
		if flags.has(t):
			power *= float(flags[t].get("power", 1.0))
			bound[t] = true
	if flags.has("swift"):
		speed_mult *= float(flags.swift.speed)
	if flags.has("lasting"):
		duration_mult *= float(flags.lasting.duration)
	var copies = int(bundle.get("copies", 1))
	var per_copy = float(bundle.get("per_copy", 1.0))
	if copies > 1 and root_delivery == "self":
		rejected.append({"word": _word_for(words, "count"), "reason": "there is only one of you"})
		copies = 1
		per_copy = 1.0
	if flags.has("piercing"):
		if root_delivery == "projectile":
			power *= float(flags.piercing.get("power", 1.0))

	# Synthetic parts for on-hit keywords (built from the root before it is scaled).
	if root_delivery != "self" and has_damage:
		if flags.has("splitting") and root_delivery == "projectile":
			var split = root.duplicate(true)
			split.erase("events")
			split.origin = "parent"
			split.geometry = split.get("geometry", {}).duplicate()
			split.geometry.radius = float(split.geometry.get("radius", 12)) * 0.6
			split.motion = [{"type": "straight", "speed": _first_speed(root) * 0.9, "range": 300}]
			split.limits = {"pierce": 0}
			split["_power"] = float(flags.splitting.get("power", 0.5))
			parts["_split"] = split
			_add_event(root, "on_first_hit", {"part": "_split", "copies": int(flags.splitting.get("copies", 3)), "spread": 40.0, "exclude_hit": true})
			bound["splitting"] = true
		if flags.has("exploding"):
			var boom = {"delivery": "volume", "origin": "parent", "geometry": {"type": "disk", "radius": float(flags.exploding.get("radius", 70.0))},
				"payload": [{"type": "damage", "amount": _first_damage(root), "raw_share": float(_first_raw_share(root))}], "_power": float(flags.exploding.get("power", 0.5))}
			parts["_explode"] = boom
			_add_event(root, "on_hit" if root_delivery == "projectile" else "on_expire", {"part": "_explode"})
			bound["exploding"] = true
		if flags.has("chaining") and root_delivery == "projectile":
			var chain = root.duplicate(true)
			chain.erase("events")
			chain.origin = "parent"
			chain.motion = [{"type": "guided", "speed": maxf(700.0, _first_speed(root)), "turn": 14.0, "range": float(flags.chaining.get("range", 220.0)) * 1.5}]
			chain.limits = {"pierce": 0}
			chain["_power"] = float(flags.chaining.get("power", 0.5))
			chain.events = {"on_hit": {"part": "_chain", "exclude_hit": true, "chain": true}}
			parts["_chain"] = chain
			_add_event(root, "on_first_hit", {"part": "_chain", "exclude_hit": true, "chain": true, "hops": int(flags.chaining.get("hops", 3)), "range": float(flags.chaining.get("range", 220.0))})
			bound["chaining"] = true
		if flags.has("cascading"):
			var copy = root.duplicate(true)
			copy.erase("events")
			copy.origin = "parent"
			copy["_power"] = float(flags.cascading.get("power", 0.5))
			parts["_cascade"] = copy
			_add_event(root, "on_kill", {"part": "_cascade"})
			bound["cascading"] = true

	if flags.has("orbiting") and root_delivery == "projectile":
		var hold = {"type": "orbit", "speed": 3.0, "radius": 70.0, "until": "enemy_in_range", "range": float(flags.orbiting.get("range", 420.0)), "hold": float(flags.orbiting.get("hold", 2.5))}
		root.motion = [hold] + root.get("motion", [])
		bound["orbiting"] = true

	for n in parts:
		var p: Dictionary = parts[n]
		var delivery = str(p.delivery)
		var part_power = power * per_copy * float(p.get("_power", 1.0))
		var periodic = delivery in ["field", "aura"]
		# Geometry
		if p.has("geometry"):
			for k in SIZE_KEYS:
				if p.geometry.has(k):
					p.geometry[k] = float(p.geometry[k]) * size
		# Motion
		var new_motion := []
		for phase in p.get("motion", []):
			var ph: Dictionary = phase.duplicate()
			if ph.has("speed") and str(ph.type) != "orbit":
				ph.speed = float(ph.speed) * speed_mult
			if flags.has("homing") and str(ph.type) == "straight" and n == root_name:
				ph.type = "guided"
				ph.speed = float(ph.get("speed", 600)) * float(flags.homing.get("speed", 0.85))
				ph.turn = float(flags.homing.get("turn", 7.0))
				bound["homing"] = true
			new_motion.append(ph)
		if p.has("motion"):
			p.motion = new_motion
		if p.has("propagation") and p.propagation.has("speed"):
			p.propagation.speed = float(p.propagation.speed) * speed_mult
		# Durations
		if p.has("timing") and p.timing.has("duration"):
			p.timing.duration = float(p.timing.duration) * duration_mult
		if p.has("limits") and p.limits.has("lifetime"):
			p.limits.lifetime = float(p.limits.lifetime) * duration_mult
		# Piercing
		if flags.has("piercing") and n == root_name and delivery == "projectile":
			var pierce = int(p.get("limits", {}).get("pierce", 0))
			if not p.has("limits"):
				p.limits = {}
			p.limits.pierce = -1 if pierce < 0 else pierce + int(flags.piercing.get("pierce", 2))
			bound["piercing"] = true
		# Homing on non-projectiles
		if flags.has("homing") and n == root_name and delivery != "projectile":
			match delivery:
				"volume":
					p.aim = {"type": "densest"}
					bound["homing"] = true
				"field", "trap":
					p.drift = {"speed": 40.0 * speed_mult}
					bound["homing"] = true
		# Payload
		var payload := []
		var main_hit := 0.0
		for item in p.get("payload", []):
			if str(item.type) == "damage":
				var amount = float(item.amount) * part_power
				main_hit = maxf(main_hit, amount)
				var raw_share = clampf(float(item.get("raw_share", 1.0 if element == "" else 0.0)), 0.0, 1.0)
				var entries := []
				var own_type = element if element != "" else "raw"
				if raw_share > 0.0:
					entries.append({"amount": amount * raw_share, "damage_type": "raw"})
				if raw_share < 1.0:
					entries.append({"amount": amount * (1.0 - raw_share), "damage_type": own_type})
				for e in elements:
					entries.append({"amount": amount * float(e.share), "damage_type": str(e.element), "chart_element": str(e.element)})
				payload.append({"type": "damage", "entries": entries, "element": element if element != "" else "raw", "hit": amount})
		for item in p.get("payload", []):
			match str(item.type):
				"status":
					var s = item.duplicate()
					s.hit = float(item.get("hit", main_hit))
					if periodic and str(s.status) == "chilled":
						s.no_freeze = true
					payload.append(s)
				"impulse":
					payload.append(item.duplicate())
				"heal":
					payload.append({"type": "heal", "amount": float(item.amount) * part_power})
		if main_hit > 0.0:
			for e in elements:
				if str(e.status) != "":
					payload.append({"type": "status", "status": str(e.status), "hit": main_hit * float(e.share), "no_freeze": periodic, "from_word": true})
			if flags.has("pulling"):
				payload.append({"type": "impulse", "force": float(flags.pulling.force), "direction": "toward"})
				bound["pulling"] = true
			if flags.has("repulsing"):
				payload.append({"type": "impulse", "force": float(flags.repulsing.force), "direction": "away"})
				bound["repulsing"] = true
		p.payload = payload

	# Arrangement and release of the root
	var arrangement: Dictionary = def.get("arrangement", {"type": "single", "count": 1}).duplicate()
	var release: Dictionary = def.get("release", {"type": "together"}).duplicate()
	if copies > 1:
		if str(arrangement.type) == "ring":
			arrangement.count = int(arrangement.get("count", 1)) * copies
		else:
			match root_delivery:
				"projectile":
					arrangement = {"type": "fan", "count": copies, "spread": 14.0}
				"volume":
					arrangement = {"type": "single", "count": copies}
					release = {"type": "staggered", "interval": 0.15}
				"field", "aura", "trap":
					arrangement = {"type": "ring", "count": copies, "radius": 80.0 * size}
		bound[_word_for(words, "count")] = true
	if str(bundle.get("arrangement", "")) != "":
		if root_delivery == "self":
			rejected.append({"word": _word_for(words, "arrangement"), "reason": "nothing to arrange"})
		else:
			arrangement.type = str(bundle.arrangement)
			arrangement.count = maxi(int(arrangement.get("count", 1)), 3 if copies <= 1 else copies)
			arrangement.radius = float(arrangement.get("radius", 80.0))
			bound[_word_for(words, "arrangement")] = true

	# Casts: main, twinned, repeating; delayed/charged shift the first.
	var first_delay = float(bundle.get("charge", 0.0))
	for t in ["delayed", "charged"]:
		if flags.has(t):
			first_delay += float(flags[t].get("delay", 0.0))
	var casts := [{"delay": first_delay, "power": 1.0, "size": 1.0}]
	if flags.has("twinned"):
		casts.append({"delay": first_delay + float(flags.twinned.get("delay", 0.15)), "power": float(flags.twinned.get("power", 0.8)), "size": 1.0})
		bound["twinned"] = true
	if flags.has("repeating"):
		casts.append({"delay": first_delay + float(flags.repeating.get("delay", 0.6)), "power": float(flags.repeating.get("power", 0.4)), "size": float(flags.repeating.get("size", 0.75))})
		bound["repeating"] = true

	# Word-level rejections
	for w in words:
		var cat = str(words[w])
		var flag = str(preload("res://scripts/engine/KeywordParser.gd").data().words[w].get("flag", w))
		var reason := ""
		match cat:
			"tier", "power":
				if not has_damage and not _has_heal(parts):
					reason = "nothing to strengthen"
			"size":
				if root_delivery == "self":
					reason = "nothing to grow"
			"element":
				if not has_damage:
					reason = "it deals no damage"
			"motion":
				if flag == "swift" and not has_motion:
					reason = "it does not move"
				elif flag in ["homing", "orbiting"] and not bound.has(flag):
					reason = "it cannot steer" if flag == "homing" else "it is not a projectile"
			"duration":
				if not has_duration:
					reason = "it is instant"
			"contact":
				if not bound.has(flag):
					reason = "it has no hit to change" if root_delivery == "self" or not has_damage else "it is not a projectile"
			"force":
				if not bound.has(flag):
					reason = "it does not hit enemies"
			"target":
				if root_delivery == "self":
					reason = "it has no target"
			"self":
				if flag == "warding":
					reason = "warding is not built yet"
		if reason != "":
			rejected.append({"word": w, "reason": reason})

	return {
		"id": str(def.id), "name": str(def.get("name", def.id)), "element": element, "root": root_name,
		"parts": parts, "arrangement": arrangement, "release": release, "casts": casts,
		"flags": flags, "elements": elements, "rejected": rejected, "bundle": bundle,
		"quick": bool(opts.get("quick", false))
	}

static func _word_for(words: Dictionary, category: String) -> String:
	for w in words:
		if str(words[w]) == category:
			return w
	return category

static func _add_event(part: Dictionary, event: String, value: Dictionary) -> void:
	if not part.has("events"):
		part.events = {}
	if part.events.has(event):
		# Keep the original event and chain the new one under an alias key.
		var alias = event + "#" + str(value.part)
		part.events[alias] = value
	else:
		part.events[event] = value

static func _first_speed(part: Dictionary) -> float:
	for ph in part.get("motion", []):
		if ph.has("speed") and str(ph.type) != "orbit":
			return float(ph.speed)
	return 600.0

static func _first_damage(part: Dictionary) -> float:
	for item in part.get("payload", []):
		if str(item.type) == "damage":
			return float(item.amount)
	return 0.0

static func _first_raw_share(part: Dictionary) -> float:
	for item in part.get("payload", []):
		if str(item.type) == "damage":
			return float(item.get("raw_share", 1.0))
	return 1.0

static func _has_heal(parts: Dictionary) -> bool:
	for n in parts:
		for item in parts[n].get("payload", []):
			if str(item.type) == "heal":
				return true
	return false
