extends RefCounted
## "infection" delivery (doc 18 §11.1 Infestation, Soul Bloom): a plague that jumps between enemies.
## The old BuildSpellEffect plague rules, moved onto the generic runner so hits go through the
## part's payload (keywords, statuses, VFX events):
##  - a spore travels to the first host; on arrival the host is infected for `duration`
##  - every tick an infected host takes the payload and (once while alive) sends a spore to the
##    nearest enemy never infected by this cast, within the spread radius
##  - a host that dies sends one more spore, or leaves a resting spore that waits on the ground
##    (reach x resting multiplier) for the spore lifetime; Soul Bloom also drops a healing bloom
## The part lives as long as anything of it does.

const STEP := 0.025
const JUMPS_PER_HOST := 1
const JUMPS_ON_DEATH := 1

var part                      # the SpellPart this runs for
var cfg: Dictionary = {}      # def.infection
var elapsed := 0.0
var end_at := 0.0
var tick_left := 0.0
var hosts: Array = []         # [{ref, id, at, expires, pos}]
var links: Array = []         # [{from, position, ref, id, range, expires}]
var spores: Array = []        # [{position, expires, fresh}]
var touched: Dictionary = {}  # enemy id -> true (ever targeted by this cast)
var jumps: Dictionary = {}
var death_jumps: Dictionary = {}
var death_done: Dictionary = {}
var hosts_started := 0

func _init(p_part, p_cfg: Dictionary) -> void:
	part = p_part
	cfg = p_cfg
	end_at = float(cfg.get("duration", 3.0))
	tick_left = float(cfg.get("interval", 0.5))

func start(first_host, from: Vector2) -> void:
	if first_host != null:
		infect(first_host, from, float(cfg.get("cast_range", 600.0)))

func spread_radius() -> float:
	return float(cfg.get("spread_radius", 130.0))

func resting_radius() -> float:
	return spread_radius() * float(cfg.get("resting_multiplier", 1.3))

func spore_life() -> float:
	return float(cfg.get("spore_life", 1.5))

func remaining() -> float:
	return end_at - elapsed

func step(delta: float) -> void:
	var budget := maxf(0.0, delta)
	while budget > 0.000001 and not part.done:
		var dt := minf(budget, STEP)
		budget -= dt
		elapsed += dt
		_advance(dt)
		tick_left -= dt
		while tick_left <= 0.000001:
			tick_left += float(cfg.get("interval", 0.5))
			_tick()
		_refresh()
		if elapsed >= end_at:
			part.finish(true)
			return

func _alive(e) -> bool:
	return part._alive(e)

func _advance(dt: float) -> void:
	for h in hosts.duplicate():
		var e = h.ref.get_ref()
		if e == null or not is_instance_valid(e):
			hosts.erase(h)
			_host_died(h)
		elif not _alive(e):
			hosts.erase(h)
			_host_died(h)
		elif elapsed >= float(h.expires):
			hosts.erase(h)
		else:
			h.pos = e.global_position
	for s in spores.duplicate():
		if elapsed >= float(s.expires):
			spores.erase(s)
			continue
		var host = nearest_host(s.position, resting_radius())
		if host:
			spores.erase(s)
			infect(host, s.position, resting_radius(), elapsed + spore_life() if s.fresh else float(s.expires))
	for l in links.duplicate():
		if elapsed >= float(l.expires):
			links.erase(l)
			continue
		var e = l.ref.get_ref()
		if not _alive(e):
			links.erase(l)
			var replacement = nearest_host(l.position, float(l.range))
			if replacement:
				infect(replacement, l.position, float(l.range), float(l.expires))
			else:
				rest_spore(l.position, float(l.expires))
			continue
		l.position = Vector2(l.position).move_toward(e.global_position, float(cfg.get("spread_speed", 460.0)) * dt)
		if Vector2(l.position).distance_to(e.global_position) <= 0.001:
			hosts_started += 1
			hosts.append({"ref": weakref(e), "id": e.get_instance_id(), "at": elapsed, "expires": elapsed + float(cfg.get("duration", 3.0)), "pos": e.global_position})
			links.erase(l)

func _tick() -> void:
	for h in hosts.duplicate():
		var e = h.ref.get_ref()
		if not _alive(e) or elapsed - float(h.at) + 0.000001 < float(cfg.get("interval", 0.5)):
			continue
		var center: Vector2 = e.global_position
		part.hit(e)
		if _alive(e):
			if int(jumps.get(h.id, 0)) < JUMPS_PER_HOST and spread_from(center):
				jumps[h.id] = int(jumps.get(h.id, 0)) + 1
		else:
			hosts.erase(h)
			h.pos = center
			_host_died(h)

func _host_died(h: Dictionary) -> void:
	var id = int(h.id)
	if death_done.has(id):
		return
	death_done[id] = true
	var at: Vector2 = h.pos
	if cfg.has("bloom"):
		# Soul Bloom (doc 21 §5.6): a ghost leaves the body: it heals you if you are hurt, otherwise it
		# hunts an enemy for the same amount.
		part.cast.spawn_ghost(at, float(cfg.bloom.get("amount", 6.0)))
	if int(death_jumps.get(id, 0)) >= JUMPS_ON_DEATH:
		return
	death_jumps[id] = int(death_jumps.get(id, 0)) + 1
	if not spread_from(at):
		rest_spore(at)

func spread_from(center: Vector2) -> bool:
	var other = nearest_host(center, spread_radius())
	if other:
		infect(other, center, spread_radius())
		return true
	return false

func infect(enemy, from: Vector2, reach: float, expires: float = -1.0) -> void:
	if not _alive(enemy) or touched.has(enemy.get_instance_id()):
		return
	touched[enemy.get_instance_id()] = true
	links.append({"from": from, "position": from, "ref": weakref(enemy), "id": enemy.get_instance_id(), "range": reach,
		"expires": elapsed + spore_life() if expires < 0.0 else expires})
	_refresh()

func nearest_host(center: Vector2, reach: float):
	var best = null
	var d_best = reach
	for e in part.cast.enemies():
		if touched.has(e.get_instance_id()):
			continue
		var d = center.distance_to(e.global_position)
		if d <= d_best:
			d_best = d
			best = e
	return best

func rest_spore(center: Vector2, expires: float = -1.0) -> void:
	spores.append({"position": center, "expires": elapsed + spore_life() if expires < 0.0 else expires, "fresh": expires < 0.0})
	_refresh()

## The plague lives as long as its last host, spore in flight or resting spore.
func _refresh() -> void:
	var end = elapsed
	for h in hosts:
		end = maxf(end, float(h.expires))
	for l in links:
		end = maxf(end, float(l.expires))
	for s in spores:
		end = maxf(end, float(s.expires))
	if end > elapsed:
		end_at = maxf(end_at, end + 0.025)
