extends RefCounted

static func collect(manager: Node) -> Dictionary:
	var states = {}
	for effect in manager.get_tree().get_nodes_in_group("build_spell_effects"):
		if effect.is_queued_for_deletion() or effect.remaining <= 0 or not effect.caster or effect.caster.get_ref() != manager.player:
			continue
		var kind = str(effect.info.type)
		if kind in ["piercing", "returning"]:
			continue
		var seconds = float(effect.remaining)
		var phase = "active"
		if kind == "trail":
			seconds = maxf(0, effect.emission_deadline - effect.age)
			if seconds <= 0:
				phase = "ground"
				seconds = 0.0
				for point in effect.trail_points:
					seconds = maxf(seconds, float(effect.info.get("patch_duration", 6.0)) - point.age)
				if seconds <= 0:
					continue
		elif kind == "trap":
			if effect.triggered:
				continue
			phase = "arming" if effect.age < float(effect.info.get("arm_delay", 0.8)) else "armed"
		elif kind == "plague":
			if effect.infections.is_empty() and effect.infection_links.is_empty() and effect.resting_spores.is_empty():
				continue
		add(states, effect.info.id, seconds, phase)
	for effect in manager.active_healing_effects:
		if effect.has("spell_id") and effect.remaining_time > 0:
			add(states, effect.spell_id, effect.remaining_time)
	if is_instance_valid(manager.player) and is_instance_valid(manager.player.earth_shield):
		for charge in manager.player.earth_shield.charges:
			add(states, "earth_shield", charge.remaining, "charges")
	return states

static func add(states: Dictionary, id: String, seconds: float, phase: String = "active"):
	if not states.has(id):
		states[id] = {"seconds": seconds, "count": 1, "phase": phase}
	else:
		if phase == "active" and states[id].phase == "ground":
			states[id].seconds = seconds
		elif not (phase == "ground" and states[id].phase == "active"):
			states[id].seconds = minf(states[id].seconds, seconds) if phase == "charges" else maxf(states[id].seconds, seconds)
		states[id].count += 1
		if phase == "armed" or (phase == "active" and states[id].phase == "ground"):
			states[id].phase = phase

static func caption(state: Dictionary) -> String:
	if state.phase == "charges":
		return "%d charge%s · %ds" % [state.count, "s" if state.count != 1 else "", ceili(state.seconds)]
	var suffix = " ×%d" % state.count if state.count > 1 else ""
	if state.phase in ["armed", "arming"]:
		return str(state.phase) + suffix
	var prefix = "ground " if state.phase == "ground" else ""
	return prefix + "%ds" % ceili(state.seconds) + suffix
