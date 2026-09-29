extends Node

signal updated
signal feedback(text: String, promoted: bool)

const Score = preload("res://scripts/StyleScore.gd")
const Store = preload("res://scripts/StyleScoreStore.gd")
var score = Score.new()
var settings: Dictionary = {}
var game: Node
var clock = 0.0
var first_letter = -1.0
var completed_at = -1.0
var mistakes = 0
var invalid_episode = false
var previous_text = ""
var completed_text = ""
var receipt = 0
var eligible = true
var exclusion_reason = ""
var run_id = ""
var special_casts = 0
var finalized = false
var result: Dictionary = {}

func _ready():
	name = "StyleSession"
	settings = {"reduced_effects": game.particle_manager.reduced_effects, "mode": "roguelike", "opening_spell": "bolt"}
	run_id = "%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	var manager = game.spell_manager
	manager.typing_started.connect(begin_attempt)
	manager.typing_ended.connect(end_attempt)
	manager.style_input_changed.connect(observe_text)
	manager.manual_spell_released.connect(on_release)
	manager.style_clock_advanced.connect(advance)
	game.player.style_health_damaged.connect(on_hit)
	if game.get_meta("bot_run", false):
		exclude("Bot run")
	if OS.has_feature("editor") and "--style-test" in OS.get_cmdline_user_args():
		exclude("Test run")

func exclude(reason: String):
	eligible = false
	exclusion_reason = reason
	updated.emit()

func begin_attempt():
	receipt += 1
	first_letter = -1.0
	completed_at = -1.0
	mistakes = 0
	invalid_episode = false
	previous_text = ""
	completed_text = ""

func end_attempt():
	first_letter = -1.0
	completed_at = -1.0
	previous_text = ""
	completed_text = ""

func advance(seconds: float):
	if finalized or game.current_state != game.GameState.PLAYING:
		return
	clock += seconds
	score.advance(seconds)
	if game.player.is_invincible:
		exclude_if_needed("Invincibility")
	updated.emit()

func exclude_if_needed(reason: String):
	if eligible:
		exclude(reason)

func observe_text(text: String):
	if not game.spell_manager.is_typing or text == previous_text:
		return
	previous_text = text
	var normalized = text.strip_edges().to_lower().replace("_", " ")
	if first_letter < 0.0:
		for letter in normalized:
			if letter >= "a" and letter <= "z":
				first_letter = clock
				break
	var candidates: Array = []
	var manager = game.spell_manager
	if not manager.target_spell.is_empty():
		candidates.append(manager.target_spell)
	else:
		for slot in manager.get_all_spells():
			if manager.is_spell_unlocked(slot):
				var info = manager.get_spell_info(slot)
				candidates.append(str(info.display_name).to_lower())
				candidates.append(str(info.name).to_lower().replace("_", " "))
	if atomic_available():
		candidates.append("atomic")
	var valid_prefix = normalized.is_empty()
	var complete = false
	for candidate in candidates:
		valid_prefix = valid_prefix or str(candidate).begins_with(normalized)
		complete = complete or str(candidate) == normalized
	if not valid_prefix and not invalid_episode:
		mistakes += 1
	invalid_episode = not valid_prefix
	completed_at = clock if complete else -1.0
	completed_text = normalized if complete else ""
	updated.emit()

func on_release(family: String, canonical: String, typed: String):
	if finalized or first_letter < 0.0 or completed_at < first_letter:
		return
	if completed_text != typed.strip_edges().to_lower().replace("_", " "):
		return
	var before = score.rank_index()
	var award = score.award_cast(family, canonical, completed_at - first_letter, mistakes, receipt)
	if award.is_empty():
		return
	var promoted = score.rank_index() > before
	var text = "%s RANK" % Score.RANKS[score.rank_index()] if promoted else "CLEAN +%d" % award.points if mistakes == 0 else "+%d" % award.points
	feedback.emit(text, promoted)
	updated.emit()

func on_hit(_health_loss: float):
	if finalized:
		return
	score.take_hit()
	feedback.emit("HIT", false)
	updated.emit()

func finish(stats: Dictionary) -> Dictionary:
	if finalized:
		return result
	finalized = true
	if game.player.is_invincible:
		exclude("Invincibility")
	result = score.summary()
	result["special_casts"] = special_casts
	result["run_id"] = run_id
	result["eligible"] = eligible
	result["exclusion_reason"] = exclusion_reason
	result["build_version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	result["outcome"] = "victory" if stats.get("won", false) else "death"
	result["duration"] = stats.get("survival_time", 0.0)
	result["build"] = stats.get("final_kit", [])
	result["level"] = stats.get("level", 1)
	result["gameplay_settings"] = settings.duplicate(true)
	result["recorded_at"] = Time.get_datetime_string_from_system()
	result["saved"] = Store.submit(result) if eligible else false
	return result

func atomic_available() -> bool:
	return not finalized and score.rank_index() >= 6

func cast_atomic() -> bool:
	if not atomic_available() or game.current_state != game.GameState.PLAYING:
		return false
	score.combo -= 1500.0
	special_casts += 1
	var blast = load("res://scripts/AtomicBlast.gd").new()
	blast.configure(game)
	game.add_child(blast)
	feedback.emit("ATOMIC", true)
	updated.emit()
	return true
