extends SceneTree
## Prints what the threat director (data/director.json) spends over a full four-day expedition,
## minute by minute, next to what the 0.3 timer spawner would have spawned. Nothing is spawned: a
## stub host stands in for the monster manager and the cap is ignored (monsters die as they come).
## godot --headless --path . --script tools/simulate_director.gd -- [night_seconds=60] [seed=1]

const DAY_SECONDS := 300.0
const DAYS := 4
const STEP := 0.25

class Host:
	extends RefCounted
	var game_time := 0.0
	var phase_override := ""
	var ambient_share := 1.0
	var phase_clock := 0.0
	var config: Dictionary
	var spawned := {"monsters": 0, "elites": 0, "champions": 0, "credits": 0.0}
	var old_manager
	func current_spawn_phase() -> Dictionary:
		old_manager.game_time = game_time
		old_manager.phase_clock = phase_clock
		old_manager.phase_override = phase_override
		return old_manager.current_spawn_phase()
	func get_available_variants(t: float) -> Array:
		old_manager.game_time = t
		return old_manager.get_available_variants(t)
	func director_spawn(_definition: Dictionary, count: int, words: Array, champion: bool, _at_angle: float = NAN):
		if champion:
			spawned.champions += 1
		elif not words.is_empty():
			spawned.elites += 1
		else:
			spawned.monsters += count
	func champions_alive() -> int:
		return 0
	func room() -> int:
		return 999
	func capacity() -> int:
		return 999

func _initialize():
	var args = OS.get_cmdline_user_args()
	var night_seconds := float(args[0]) if args.size() > 0 else 60.0
	var rng = RandomNumberGenerator.new()
	rng.seed = int(args[1]) if args.size() > 1 else 1
	var host = Host.new()
	var manager = load("res://scripts/MonsterManager.gd").new()
	manager.encounter_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	manager.day_cycle_driven = true
	host.old_manager = manager
	var director = load("res://scripts/ThreatDirector.gd").new(host, rng)
	print("minute | phase  | income/s | director: monsters elites champs | old timer: monsters | health x")
	var minute_mark := 60.0
	var old_count := 0.0
	var last := {"monsters": 0, "elites": 0, "champions": 0}
	for day in range(1, DAYS + 1):
		for stage in ["day", "night"]:
			var length := DAY_SECONDS if stage == "day" else night_seconds
			var t := 0.0
			while t < length:
				host.phase_override = "night" if stage == "night" else ""
				host.phase_clock = t if stage == "day" else 0.0
				manager.phase_override = host.phase_override
				manager.phase_clock = host.phase_clock
				manager.game_time = host.game_time
				director.update(STEP)
				var interval: float = manager.calculate_spawn_interval()
				old_count += STEP / maxf(0.01, interval) * manager.spawn_batch_amount()
				host.game_time += STEP
				t += STEP
				if host.game_time >= minute_mark:
					var stats = manager.calculate_monster_stats({"health": 1.0, "speed": 1.0, "damage": 1.0, "xp": 1.0})
					print("%5d  | %-6s | %8.2f | %17d %6d %6d | %19d | %.2f" % [int(minute_mark / 60.0), "D%d %s" % [day, stage], director.income_per_second(),
						host.spawned.monsters - last.monsters, host.spawned.elites - last.elites, host.spawned.champions - last.champions, int(round(old_count)), stats.health])
					last = host.spawned.duplicate()
					old_count = 0.0
					minute_mark += 60.0
		# aftermath and camp: no income, no time (camp pauses the run)
	print("total: %d monsters, %d elites, %d champions, %.0f credits spent" % [host.spawned.monsters, host.spawned.elites, host.spawned.champions, director.spent])
	manager.free()
	quit(0)
