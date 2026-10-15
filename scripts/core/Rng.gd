extends RefCounted
## Seeded random streams (doc 19 §6.1 rule 5).
##
## All gameplay randomness comes from here so a run is reproducible from its seed:
##   Rng.begin_run(seed)            once per run (a random seed is chosen if never called)
##   Rng.stream("spawn").randf()    named stream for a system (spawn director, loot, offers...)
##   Rng.for_cast(cast_id)          fresh generator for one cast; same seed + cast id = same rolls
## Presentation (VFX, camera shake, audio variation) may keep using the global functions.
## Each stream's seed is derived from the run seed and the stream's name, so adding a new
## stream never shifts the rolls of an existing one.

static var _run_seed: int = 0
static var _has_seed: bool = false
static var _streams: Dictionary = {}

static func begin_run(run_seed: int) -> void:
	_run_seed = run_seed
	_has_seed = true
	_streams.clear()

static func run_seed() -> int:
	if not _has_seed:
		var seeder = RandomNumberGenerator.new()
		seeder.randomize()
		begin_run(seeder.randi())
	return _run_seed

## The named stream for a system; created on first use from the run seed.
static func stream(name: String) -> RandomNumberGenerator:
	var base = run_seed()
	if not _streams.has(name):
		var rng = RandomNumberGenerator.new()
		rng.seed = derive(base, name)
		_streams[name] = rng
	return _streams[name]

## A new generator for one cast. Not cached: replaying a cast message rebuilds the same rolls.
static func for_cast(cast_id: int, salt: String = "") -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = derive(run_seed(), "cast:%d:%s" % [cast_id, salt])
	return rng

## Stable 64-bit seed from a base seed and a name (FNV-1a over both).
static func derive(base: int, name: String) -> int:
	var h: int = -3750763034362895579  # FNV offset basis 14695981039346656037 as signed 64-bit
	for b in (str(base) + "/" + name).to_utf8_buffer():
		h = (h ^ b) * 1099511628211
	return h
