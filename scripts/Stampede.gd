extends RefCounted
## The stampede (doc 22 §8): a set piece outside the director. A herd crosses the screen in a
## straight, telegraphed lane through where you stand. It ignores you: step out of the lane, or
## blast it for free XP. Timing, herd size and lane shape are data/events.json "stampede".

const GameData = preload("res://scripts/core/GameData.gd")
const Lane = preload("res://scripts/vfx/StampedeLane.gd")

var host                      # MonsterManager
var rng: RandomNumberGenerator
var seen := {}
var state := "idle"           # idle, warning, running
var timer := 0.0
var direction := Vector2.RIGHT
var origin := Vector2.ZERO
var length := 0.0
var to_spawn := 0
var spawn_interval := 0.1
var spawn_acc := 0.0
var shake_acc := 0.0
var lane: Node2D = null
var started := 0              # how many stampedes this run (tests, telemetry)

func _init(p_host, p_rng: RandomNumberGenerator = null):
	host = p_host
	rng = p_rng if p_rng != null else preload("res://scripts/core/Rng.gd").stream("stampede")

static func config() -> Dictionary:
	return GameData.file("events").get("stampede", {})

func day_cycle() -> Node:
	return host.get_tree().get_first_node_in_group("day_cycle") if host.is_inside_tree() else null

## How big the herd is on a given day (1-based); past the list the last size repeats.
func herd_size(day: int) -> int:
	var counts: Array = config().get("counts", [40])
	return int(counts[clampi(day - 1, 0, counts.size() - 1)])

func update(delta: float) -> void:
	if delta <= 0.0 or delta > 5.0:
		return
	match state:
		"idle":
			check_schedule()
		"warning":
			timer -= delta
			rumble(delta)
			if timer <= 0.0:
				state = "running"
				spawn_acc = spawn_interval
		"running":
			run(delta)

func check_schedule() -> void:
	var cfg := config()
	var cycle = day_cycle()
	if cycle and host.get("day_cycle_driven"):
		if str(host.phase_override) != "":
			return   # night, rest, camp: no stampede
		var by_day: Array = cfg.get("by_day", [])
		if by_day.is_empty():
			return
		var day := int(cycle.day)
		var times: Array = by_day[clampi(day - 1, 0, by_day.size() - 1)]
		for i in times.size():
			var key = "%d:%d" % [day, i]
			if seen.has(key) or float(cycle.day_clock) < float(times[i]):
				continue
			seen[key] = true
			if float(cycle.day_clock) - float(times[i]) <= 5.0:   # a time jump past it skips it
				start(herd_size(day))
				return
	else:
		var run_times: Array = cfg.get("run_times", [])
		for i in run_times.size():
			var key = "r:%d" % i
			if seen.has(key) or float(host.game_time) < float(run_times[i]):
				continue
			seen[key] = true
			if float(host.game_time) - float(run_times[i]) <= 5.0:
				start(herd_size(i + 1))
				return

## Begin a stampede now (schedule, or the console `stampede` command).
func start(count: int) -> void:
	var player = host.get("player")
	if not is_instance_valid(player) or state != "idle":
		return
	var cfg := config()
	direction = Vector2.from_angle(rng.randf() * TAU)
	var offset = direction.orthogonal() * rng.randf_range(-float(cfg.get("lane_offset", 140.0)), float(cfg.get("lane_offset", 140.0)))
	var view: Rect2 = host.encounter_director.visible_world_rect()
	var half = maxf(view.size.length() * 0.5, 500.0) + 120.0
	var center = player.global_position + offset
	origin = center - direction * half
	length = half * 2.0
	to_spawn = count
	spawn_interval = float(cfg.get("spawn_seconds", 2.0)) / maxf(1.0, float(count))
	timer = float(cfg.get("warning_seconds", 2.5))
	shake_acc = 0.0
	state = "warning"
	started += 1
	lane = Lane.new()
	lane.setup(origin, direction, length, float(cfg.get("lane_width", 260.0)), timer)
	host.get_parent().add_child(lane)
	var cycle = day_cycle()
	if cycle and cycle.has_method("announce"):
		cycle.announce(str(cfg.get("title", "Stampede")), str(cfg.get("line", "")))

func rumble(delta: float) -> void:
	shake_acc -= delta
	if shake_acc <= 0.0:
		shake_acc = float(config().get("shake_every", 0.6))
		var game = host.get_parent()
		if game and game.has_method("shake_light"):
			game.shake_light()

func run(delta: float) -> void:
	var cfg := config()
	spawn_acc += delta
	var definition = host.encounter_config.variants.get(str(cfg.get("variant", "swarmer")), {}).duplicate(true)
	if definition.is_empty():
		to_spawn = 0
	definition["id"] = str(cfg.get("variant", "swarmer"))
	var speed = float(cfg.get("speed", 330.0))
	var width = float(cfg.get("lane_width", 260.0))
	while to_spawn > 0 and spawn_acc >= spawn_interval:
		spawn_acc -= spawn_interval
		to_spawn -= 1
		var monster = host.spawn_monster(definition, false, true)
		if monster:
			monster.global_position = origin + direction.orthogonal() * rng.randf_range(-width * 0.5, width * 0.5) - direction * rng.randf_range(0.0, 60.0)
			monster.start_stampede(direction * speed, length + 120.0)
	if to_spawn <= 0:
		if is_instance_valid(lane):
			lane.release(length / speed + 0.4)
		lane = null
		state = "idle"

func stop() -> void:
	to_spawn = 0
	state = "idle"
	if is_instance_valid(lane):
		lane.release(0.3)
	lane = null
