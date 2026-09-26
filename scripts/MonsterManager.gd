extends Node2D

signal monster_spawned(monster_data: Dictionary)
signal monster_died(monster_data: Dictionary)
signal boss_arrived(boss_name: String)
signal run_completed

var run_finished: bool = false

const EnemyScene = preload("res://scenes/EncounterEnemy.tscn")
var encounter_config: Dictionary = {}
var spawn_timer: Timer
var game_time: float = 0.0
var monsters_alive: int = 0
var max_monsters: int = 160
var spawned_bosses: Dictionary = {}
@onready var player: CharacterBody2D = get_parent().get_node("Player")

func _ready():
	encounter_config = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	max_monsters = int(encounter_config.scaling.maximum_enemies)
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
		total += float(definition.weight)
	var roll = randf() * total
	for definition in available:
		roll -= float(definition.weight)
		if roll <= 0.0:
			return definition
	return {}

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
	spawn_monster()
	spawn_timer.wait_time = calculate_spawn_interval()

func spawn_monster(definition: Dictionary = {}, is_boss: bool = false) -> Node2D:
	if run_finished:
		return null
	if not is_instance_valid(player) or (monsters_alive >= max_monsters and not is_boss):
		return null
	if definition.is_empty():
		definition = select_monster()
	if definition.is_empty():
		return null
	var count = 3 if definition.id == "swarmer" and not is_boss else 1
	var first: Node2D = null
	var angle = randf() * TAU
	var viewport = get_viewport_rect().size
	var direction = Vector2.from_angle(angle)
	var half_size = viewport * 0.5
	var distance = minf(half_size.x / maxf(absf(direction.x), 0.01), half_size.y / maxf(absf(direction.y), 0.01)) + 80.0
	for index in range(count):
		if monsters_alive >= max_monsters and not is_boss:
			break
		var monster = EnemyScene.instantiate()
		var stats = calculate_monster_stats(definition)
		if is_boss:
			stats.health *= 12.0
			stats.damage *= 1.5
			stats.xp *= 12.0
		monster.configure(definition, stats, is_boss)
		monster.position = player.global_position + Vector2.from_angle(angle) * distance + Vector2(index * 38, 0)
		var terrain = get_parent().get_node_or_null("Background")
		if terrain and terrain.has_method("clear_spawn"):
			monster.position = terrain.clear_spawn(monster.position, 29.0 * monster.scale.x)
		monster.enemy_died.connect(_on_monster_died)
		var damage_manager = get_parent().get_node_or_null("DamageManager")
		if damage_manager:
			monster.enemy_damaged.connect(damage_manager._on_enemy_damaged)
		get_parent().add_child(monster)
		monsters_alive += 1
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
		var boss = spawn_monster(definition, true)
		if boss:
			spawned_bosses[at_time] = true
			boss_arrived.emit(milestone.name)
			print("Boss milestone: %ds, %s" % [at_time, milestone.name])

func calculate_spawn_interval() -> float:
	var elapsed = maxf(0.0, game_time - 180.0)
	return maxf(float(encounter_config.get("scaling", {}).get("minimum_spawn_interval", 0.6)), float(encounter_config.get("scaling", {}).get("opening_spawn_interval", 3.0)) / pow(1.28, elapsed / 180.0))

func get_current_difficulty_level() -> int:
	return mini(4, int(game_time / 300.0) + 1)

func get_monster_count() -> int:
	return monsters_alive

func _on_monster_died(monster: CharacterBody2D):
	monsters_alive = maxi(0, monsters_alive - 1)
	if get_parent().has_method("increment_enemies_killed"):
		get_parent().increment_enemies_killed()
	monster_died.emit({"variant": monster.variant, "boss": monster.boss})

func add_game_time(additional_time: float):
	advance_time(additional_time)

func advance_time(delta: float):
	if run_finished:
		return
	game_time = clampf(game_time + delta, 0.0, float(encounter_config.run_duration))
	if game_time >= float(encounter_config.run_duration):
		run_finished = true
		spawn_timer.stop()
		run_completed.emit()
		return
	check_boss_milestones()
