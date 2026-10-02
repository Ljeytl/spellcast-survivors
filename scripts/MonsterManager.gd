extends Node2D

signal monster_spawned(monster_data: Dictionary)
signal monster_died(monster_data: Dictionary)
signal boss_arrived(boss_name: String)
signal run_completed

var run_finished: bool = false
var awaiting_extraction: bool = false
## Set by DayCycle: bosses and extraction follow the days instead of fixed run times.
var day_cycle_driven: bool = false
var endless_mode: bool = false

const EnemyScene = preload("res://scenes/EncounterEnemy.tscn")
var encounter_config: Dictionary = {}
var spawn_timer: Timer
var game_time: float = 0.0
var monsters_alive: int = 0
var max_monsters: int = 160
var spawned_bosses: Dictionary = {}
var spawn_attempts = 0
var actual_spawns = 0
var cap_rejections = 0
var encounter_director
var spawn_batch_fraction := 0.0
var spawn_pressure = preload("res://scripts/SpawnPressure.gd").new()
@onready var player: CharacterBody2D = get_parent().get_node("Player")

func _ready():
	encounter_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	max_monsters = int(encounter_config.scaling.maximum_enemies)
	encounter_director = preload("res://scripts/EncounterDirector.gd").new(self)
	add_to_group("monster_manager")
	spawn_timer = Timer.new()
	spawn_timer.wait_time = calculate_spawn_interval()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.autostart = true
	add_child(spawn_timer)

func _process(delta):
	advance_time(delta)

func get_available_variants(at_time: float) -> Array:
	var available: Array = []
	for id in encounter_config.variants:
		var definition = encounter_config.variants[id]
		if float(definition.unlock_time) > at_time:
			continue
		if definition.family == "shooter" and at_time < float(encounter_config.ranged_start):
			continue
		var entry = definition.duplicate(true)
		entry["id"] = id
		available.append(entry)
	return available

func select_monster(_difficulty_level: int = 1) -> Dictionary:
	var available = get_available_variants(game_time)
	var total: float = 0.0
	for definition in available:
		total += variant_spawn_weight(definition)
	var roll = randf() * total
	for definition in available:
		roll -= variant_spawn_weight(definition)
		if roll <= 0.0:
			return definition
	return {}

func adaptive_clear_pressure() -> float:
	return spawn_pressure.level * clampf(float(encounter_config.get("scaling", {}).get("adaptive_clear_pressure_strength", 0.0)), 0.0, 1.0)

func variant_spawn_weight(definition: Dictionary) -> float:
	var specialist = definition.get("id", "") not in ["pursuer", "sprinter", "swarmer"]
	return float(definition.weight) * (1.0 + adaptive_clear_pressure() * 0.75 if specialist else 1.0)

func refill_population_target() -> int:
	return mini(max_monsters, int(lerpf(6.0, 24.0, clampf(game_time / 600.0, 0.0, 1.0))) + int(adaptive_clear_pressure() * 8.0))

func replenish_population(delta: float):
	if run_finished or awaiting_extraction:
		return
	var target = refill_population_target()
	spawn_pressure.advance(delta, monsters_alive, target)
	if delta > 5.0 or delta <= 0.0:
		return
	var count = spawn_pressure.refill_count(monsters_alive, target)
	var angle = randf() * TAU
	for index in range(count):
		spawn_monster({}, false, true, angle + float(index) / maxf(1.0, count) * TAU, 64.0)

func calculate_monster_stats(definition: Dictionary, _difficulty_level: int = 1) -> Dictionary:
	var scaling = encounter_config.scaling
	var elapsed = maxf(0.0, game_time - float(scaling.grace_seconds))
	var health_multiplier = pow(float(scaling.health_growth_per_120_seconds), elapsed / 120.0)
	return {
		"health": float(definition.health) * health_multiplier,
		"speed": float(definition.speed),
		"damage": float(definition.damage) * (1.0 + maxf(0.0, game_time - 300.0) * float(scaling.damage_growth_per_second)),
		"xp": float(definition.xp) * sqrt(health_multiplier)
	}

func _on_spawn_timer_timeout():
	for index in range(consume_spawn_batch_size()):
		spawn_monster()
	spawn_timer.wait_time = calculate_spawn_interval()

func spawn_monster(definition: Dictionary = {}, is_boss: bool = false, single: bool = false, entry_angle: float = NAN, entry_margin: float = -1.0) -> Node2D:
	if run_finished or awaiting_extraction:
		return null
	spawn_attempts += 1
	if monsters_alive >= max_monsters and not is_boss:
		cap_rejections += 1
	if not is_instance_valid(player) or (monsters_alive >= max_monsters and not is_boss):
		return null
	if definition.is_empty():
		definition = select_monster()
	if definition.is_empty():
		return null
	var count = 3 if definition.id == "swarmer" and not is_boss and not single else 1
	var first: Node2D = null
	var angle = randf() * TAU if is_nan(entry_angle) else entry_angle
	for index in range(count):
		if monsters_alive >= max_monsters and not is_boss:
			break
		var monster = EnemyScene.instantiate()
		var stats = calculate_monster_stats(definition)
		if is_boss:
			stats.health = float(definition.get("boss_health", stats.health * 12.0))
			stats.damage *= 1.5
			stats.xp *= 12.0
		monster.configure(definition, stats, is_boss)
		var point = encounter_director.entry_position(angle + index * 0.06, 29.0 * monster.scale.x, entry_margin)
		if not point.is_finite():
			monster.free()
			continue
		monster.position = get_parent().to_local(point)
		monster.enemy_died.connect(_on_monster_died)
		var damage_manager = get_parent().get_node_or_null("DamageManager")
		if damage_manager:
			monster.enemy_damaged.connect(damage_manager._on_enemy_damaged)
		get_parent().add_child(monster)
		monsters_alive += 1
		actual_spawns += 1
		monster_spawned.emit(definition)
		if not first:
			first = monster
	return first

func check_boss_milestones():
	if run_finished:
		return
	for milestone in encounter_config.bosses:
		var at_time = int(milestone.time)
		if game_time < at_time or spawned_bosses.has(at_time):
			continue
		var definition = encounter_config.variants[milestone.variant].duplicate(true)
		definition["id"] = milestone.variant
		definition["name"] = milestone.name
		if milestone.has("health"):
			definition["boss_health"] = milestone.health
		var boss = spawn_monster(definition, true)
		if boss:
			spawned_bosses[at_time] = true
			boss_arrived.emit(milestone.name)
			print("Boss milestone: %ds, %s" % [at_time, milestone.name])

func spawn_phase_interval(at_time: float) -> float:
	var scaling = encounter_config.get("scaling", {})
	var interval = maxf(0.01, float(scaling.get("opening_spawn_interval", 3.0)))
	var cycle = float(scaling.get("spawn_cycle_seconds", 0.0))
	var phase_time = fposmod(at_time, cycle) if cycle > 0.0 else at_time
	var latest_start = -INF
	for phase in scaling.get("spawn_phases", []):
		if not phase is Dictionary:
			continue
		var start = float(phase.get("start", -1.0))
		var candidate = float(phase.get("interval", 0.0))
		if is_finite(start) and is_finite(candidate) and start >= 0.0 and start <= phase_time and start > latest_start and candidate > 0.0:
			latest_start = start
			interval = candidate
	return interval

func spawn_difficulty_multiplier() -> float:
	return minf(float(encounter_config.get("scaling", {}).get("maximum_spawn_difficulty", INF)), timed_spawn_difficulty_multiplier())

func timed_spawn_difficulty_multiplier() -> float:
	var scaling = encounter_config.get("scaling", {})
	var points = scaling.get("spawn_difficulty_points", [])
	if not points.is_empty():
		var previous = points[0]
		if game_time <= float(previous.time):
			return maxf(1.0, float(previous.multiplier))
		for index in range(1, points.size()):
			var point = points[index]
			if game_time <= float(point.time):
				var weight = clampf((game_time - float(previous.time)) / maxf(0.001, float(point.time) - float(previous.time)), 0.0, 1.0)
				return exp(lerpf(log(maxf(1.0, float(previous.multiplier))), log(maxf(1.0, float(point.multiplier))), weight))
			previous = point
		var multiplier = maxf(1.0, float(previous.multiplier))
		if points.size() > 1:
			var earlier = points[points.size() - 2]
			var growth = maxf(0.0, log(multiplier / maxf(1.0, float(earlier.multiplier))))
			var periods = maxf(0.0, game_time - float(previous.time)) / maxf(1.0, float(previous.time) - float(earlier.time))
			var cap = 1.0
			for phase in scaling.get("spawn_phases", []):
				cap = maxf(cap, float(phase.interval) / maxf(0.01, float(scaling.get("minimum_spawn_interval", 0.1))))
			return minf(cap, exp(minf(log(cap), log(multiplier) + growth * periods)))
		return multiplier
	var elapsed = maxf(0.0, game_time - float(scaling.get("spawn_growth_start_seconds", 180.0)))
	return pow(maxf(1.0, float(scaling.get("spawn_growth_factor", 1.28))), elapsed / maxf(1.0, float(scaling.get("spawn_growth_period_seconds", 180.0))))

func calculate_spawn_interval() -> float:
	var scaling = encounter_config.get("scaling", {})
	var difficulty = minf(float(scaling.get("maximum_spawn_difficulty", INF)), spawn_difficulty_multiplier() * (1.0 + 0.3 * adaptive_clear_pressure()))
	return maxf(maxf(0.01, float(scaling.get("minimum_spawn_interval", 0.1))), spawn_phase_interval(game_time) / difficulty)

func spawn_batch_amount() -> float:
	var scaling = encounter_config.get("scaling", {})
	var amount := 1.0
	var points = scaling.get("spawn_batch_points", [])
	if not points.is_empty():
		var previous = points[0]
		amount = float(previous.count)
		for index in range(1, points.size()):
			var point = points[index]
			if game_time <= float(point.time):
				var weight = clampf((game_time - float(previous.time)) / maxf(0.001, float(point.time) - float(previous.time)), 0.0, 1.0)
				amount = lerpf(float(previous.count), float(point.count), weight)
				break
			previous = point
			amount = float(previous.count)
		if game_time > float(points.back().time):
			amount += (game_time - float(points.back().time)) / 120.0 * float(scaling.get("endless_batch_growth_per_120_seconds", 0.5))
	else:
		var difficulty = spawn_difficulty_multiplier()
		for batch in scaling.get("spawn_batches", []):
			if float(batch.get("difficulty", 1.0)) <= difficulty:
				amount = maxf(amount, float(batch.get("count", 1)))
	return clampf(amount + floorf(adaptive_clear_pressure() + 0.5), 1.0, max_monsters)

func calculate_spawn_batch_size() -> int:
	return int(floorf(spawn_batch_amount()))

func consume_spawn_batch_size() -> int:
	var amount = spawn_batch_amount()
	var count = int(floorf(amount))
	spawn_batch_fraction += amount - count
	if spawn_batch_fraction >= 1.0 - 0.000001:
		count += 1
		spawn_batch_fraction = maxf(0.0, spawn_batch_fraction - 1.0)
	return mini(max_monsters, count)

func get_current_difficulty_level() -> int:
	return mini(4, int(game_time / 300.0) + 1)

func get_monster_count() -> int:
	return monsters_alive

func _on_monster_died(monster: CharacterBody2D):
	monsters_alive = maxi(0, monsters_alive - 1)
	if not monster.boss:
		spawn_pressure.record_kill()
	if get_parent().has_method("increment_enemies_killed"):
		get_parent().increment_enemies_killed()
	if monster.boss and not run_finished and not monster.has_meta("boss_reward_dropped"):
		monster.set_meta("boss_reward_dropped", true)
		var reward = preload("res://scripts/BossReward.gd").new()
		reward.position = monster.global_position
		get_parent().add_child(reward)
		preload("res://scripts/HealthPotion.gd").try_drop(get_parent(), monster.global_position + Vector2(48, 0), -1.0, true)
		# Bosses always drop three style runes around the chest.
		for offset in [Vector2(-48, 0), Vector2(0, 48), Vector2(0, -48)]:
			preload("res://scripts/StylePickup.gd").try_drop(get_parent(), monster.global_position + offset, -1.0, true)
	monster_died.emit({"variant": monster.variant, "boss": monster.boss})

func add_game_time(additional_time: float):
	advance_time(additional_time)

func begin_extraction():
	if run_finished or awaiting_extraction:
		return
	awaiting_extraction = true
	spawn_timer.stop()
	run_completed.emit()

func continue_endless():
	if run_finished or not awaiting_extraction:
		return
	awaiting_extraction = false
	endless_mode = true
	spawn_timer.start(calculate_spawn_interval())

func advance_time(delta: float):
	if run_finished or awaiting_extraction:
		return
	var previous_phase = spawn_phase_interval(game_time)
	game_time = maxf(0.0, game_time + delta)
	if not endless_mode and not day_cycle_driven and game_time >= float(encounter_config.run_duration):
		game_time = float(encounter_config.run_duration)
		awaiting_extraction = true
		spawn_timer.stop()
		run_completed.emit()
		return
	if not is_equal_approx(previous_phase, spawn_phase_interval(game_time)) and not spawn_timer.is_stopped():
		spawn_timer.start(calculate_spawn_interval())
	if not day_cycle_driven:
		check_boss_milestones()
	encounter_director.update(delta)
	if not spawn_timer.is_stopped():
		replenish_population(delta)
