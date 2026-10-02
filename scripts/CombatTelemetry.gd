extends Node
## Records combat over time for debugging and balance: one sample per second of game time with damage, kills
## and casts per spell, spell ranks, enemies alive and enemy health scaling. Feeds the F4 debug panel, and writes
## a JSON log at the end of a run when started with --telemetry=<path> (bots) or in debug builds (user://telemetry/).

const SAMPLE_SECONDS = 1.0
const SCHEMA_VERSION = 1

var game: Node
var samples: Array = []
var casts_by_spell: Dictionary = {}
var _last_damage: Dictionary = {}
var _last_kills: Dictionary = {}
var _last_casts: Dictionary = {}
var _next_sample = SAMPLE_SECONDS
var _written = false
var log_path = ""
var _spawned_this_sample = 0
var _kill_lifetimes: Array = []  # [{"type", "boss", "lifetime"}] for kills since the last sample
var _last_xp_total = 0.0
var level_ups: Array = []  # [{"t", "level"}]

func _ready():
	game = get_parent()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--telemetry="):
			log_path = argument.trim_prefix("--telemetry=")
	if log_path.is_empty() and OS.is_debug_build():
		log_path = "user://telemetry/run-%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
	if game.has_node("SpellManager"):
		game.get_node("SpellManager").manual_spell_released.connect(_on_spell_released)
	tree_exiting.connect(write_log)

func on_enemy_spawned(_enemy: Node):
	_spawned_this_sample += 1

func on_enemy_killed(enemy: Node):
	var born = float(enemy.get("spawned_at_game_time")) if enemy.get("spawned_at_game_time") != null else -1.0
	if born < 0.0:
		return
	var type = str(enemy.get("variant")) if enemy.get("variant") != null else str(enemy.get("enemy_type"))
	_kill_lifetimes.append({"type": type, "boss": enemy.is_in_group("bosses"), "lifetime": game_time() - born})

## Total XP earned so far: XP in completed levels plus progress in the current one (level L→L+1 costs base + increment × (L−1)).
func xp_total() -> float:
	var level = int(game.player.level)
	var base = float(game.player.BASE_XP_REQUIREMENT)
	var step = float(game.player.XP_LEVEL_INCREMENT)
	return base * (level - 1) + step * (level - 1) * (level - 2) / 2.0 + float(game.player.xp)

func _on_spell_released(spell_id: String, _incantation: String, _typed: String):
	casts_by_spell[spell_id] = int(casts_by_spell.get(spell_id, 0)) + 1

func game_time() -> float:
	return float(game.get_node("MonsterManager").game_time) if game.has_node("MonsterManager") else 0.0

func health_multiplier() -> float:
	var manager = game.get_node_or_null("MonsterManager")
	if not manager:
		return 1.0
	var scaling = manager.encounter_config.get("scaling", {})
	var elapsed = maxf(0.0, game_time() - float(scaling.get("grace_seconds", 0.0)))
	return pow(float(scaling.get("health_growth_per_120_seconds", 1.0)), elapsed / 120.0)

func _process(_delta):
	if not game or not game.get("style_session"):
		return
	if game.current_state == game.GameState.GAME_OVER:
		write_log()
		return
	while game_time() >= _next_sample:
		take_sample(_next_sample)
		_next_sample += SAMPLE_SECONDS

func take_sample(seconds: float):
	var session = game.style_session
	var ranks = {}
	for id in game.spell_manager.get_unlocked_spell_names():
		ranks[id] = game.spell_manager.get_spell_rank(id)
	samples.append({
		"t": seconds,
		"damage": _delta(session.damage_by_spell, _last_damage),
		"kills": _delta(session.get("kills_by_spell") if session.get("kills_by_spell") != null else {}, _last_kills),
		"casts": _delta(casts_by_spell, _last_casts),
		"ranks": ranks,
		"enemies": get_tree().get_nodes_in_group("enemies").size(),
		"level": game.player.level,
		"xp": snappedf(xp_total() - _last_xp_total, 0.1),
		"spawned": _spawned_this_sample,
		"time_to_kill": _summarize_lifetimes(),
		"health_multiplier": snappedf(health_multiplier(), 0.001),
		"spell_power": game.player.spell_damage_multiplier,
	})
	if not samples.is_empty() and samples.size() > 1 and samples[-1].level > samples[-2].level:
		level_ups.append({"t": seconds, "level": samples[-1].level})
	_last_xp_total = xp_total()
	_spawned_this_sample = 0
	_kill_lifetimes.clear()

func _summarize_lifetimes() -> Dictionary:
	var by_type = {}
	for kill in _kill_lifetimes:
		var key = "boss" if kill.boss else kill.type
		var entry = by_type.get(key, {"count": 0, "total": 0.0})
		entry.count += 1
		entry.total += kill.lifetime
		by_type[key] = entry
	var result = {}
	for key in by_type:
		result[key] = {"count": by_type[key].count, "avg": snappedf(by_type[key].total / by_type[key].count, 0.01)}
	return result

func _delta(current: Dictionary, last: Dictionary) -> Dictionary:
	var result = {}
	for key in current:
		var change = float(current[key]) - float(last.get(key, 0.0))
		if change > 0.0:
			result[key] = snappedf(change, 0.1)
		last[key] = float(current[key])
	return result

## Average time to kill (seconds alive) and XP per minute over the last `window` seconds of samples.
func recent_flow(window: float = 60.0) -> Dictionary:
	var kills = 0
	var lifetime = 0.0
	var xp = 0.0
	var spawned = 0
	var count = 0
	for i in range(samples.size() - 1, -1, -1):
		if count >= int(window / SAMPLE_SECONDS):
			break
		count += 1
		xp += float(samples[i].get("xp", 0.0))
		spawned += int(samples[i].get("spawned", 0))
		for type in samples[i].get("time_to_kill", {}):
			var entry = samples[i].time_to_kill[type]
			kills += int(entry.count)
			lifetime += float(entry.avg) * int(entry.count)
	var minutes = maxf(1.0, count * SAMPLE_SECONDS) / 60.0
	return {"ttk": lifetime / maxf(1, kills), "kills_per_min": kills / minutes, "xp_per_min": xp / minutes, "spawned_per_min": spawned / minutes}

## Damage per second for each spell over the last `window` seconds of samples.
func recent_dps(window: float = 10.0) -> Dictionary:
	var totals = {}
	var count = 0
	for i in range(samples.size() - 1, -1, -1):
		if count >= int(window / SAMPLE_SECONDS):
			break
		count += 1
		for spell in samples[i].damage:
			totals[spell] = float(totals.get(spell, 0.0)) + float(samples[i].damage[spell])
	for spell in totals:
		totals[spell] = totals[spell] / maxf(1.0, count * SAMPLE_SECONDS)
	return totals

func write_log():
	if _written or log_path.is_empty() or samples.is_empty():
		return
	_written = true
	if log_path.begins_with("user://"):
		DirAccess.make_dir_recursive_absolute(log_path.get_base_dir())
	var file = FileAccess.open(log_path, FileAccess.WRITE)
	if not file:
		printerr("Cannot write telemetry: ", log_path)
		return
	file.store_string(JSON.stringify({"schema_version": SCHEMA_VERSION, "sample_seconds": SAMPLE_SECONDS, "version": ProjectSettings.get_setting("application/config/version", ""), "level_ups": level_ups, "samples": samples}))
	file.close()
	print("Telemetry written: ", ProjectSettings.globalize_path(log_path))
