extends Node
## Ley lines (cut-down M3): a few sites per run. Stand in one to start a ritual — type a
## sequence of long words against a per-word timer while a ring of enemies closes in.
## Success grants one extra upgrade pick. Later the reward becomes a permanent discovery.

const LeySite = preload("res://scripts/LeySite.gd")
const SITE_COUNT = 3
const SITE_DISTANCE_MIN = 1500.0
const SITE_DISTANCE_MAX = 2200.0
const WORDS_PER_RITUAL = 3
## Seconds allowed per word: a base plus a per-letter allowance.
const WORD_BASE_SECONDS = 1.5
const WORD_SECONDS_PER_LETTER = 0.4
const DWELL_SECONDS = 0.6
const RETRY_SECONDS = 10.0
## Enemies summoned when a ritual starts: base plus one per minute of run time.
const AMBUSH_BASE = 6
const AMBUSH_MAX = 16
## Casting slowdown does not apply while typing a ritual.
const RITUAL_TIME_SCALE = 1.0
const WORDS = ["incandescent", "quintessence", "conflagration", "resplendent", "labyrinthine", "thunderstorm", "phosphorescent", "evanescent", "luminescence", "archmagister", "invocation", "transmutation", "everburning", "tempestuous", "kaleidoscope", "crystalline", "spellbinding", "abjuration", "enchantment", "starforged", "moonwhisper", "thunderclap", "nightingale", "illumination"]

var game: Node
var sites: Array = []
var active = null
var words: Array[String] = []
var word_index := 0
var typed := ""
var word_time_left := 0.0
var word_time_total := 1.0
var rng := RandomNumberGenerator.new()
var hud: Control
var prompt: RichTextLabel
var arrows: Control

func _ready():
	name = "LeyLines"
	add_to_group("ley_lines")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rng.randomize()
	build_hud()
	place_sites.call_deferred()

func place_sites():
	var origin = game.player.global_position
	var terrain = game.get_node_or_null("Background")
	var start = rng.randf() * TAU
	for i in SITE_COUNT:
		var angle = start + i * TAU / SITE_COUNT + rng.randf_range(-0.35, 0.35)
		var point = origin + Vector2.from_angle(angle) * rng.randf_range(SITE_DISTANCE_MIN, SITE_DISTANCE_MAX)
		for attempt in 12:
			if not terrain or not terrain.has_method("is_spawn_clear") or terrain.is_spawn_clear(point, LeySite.RADIUS):
				break
			point += Vector2.from_angle(angle) * 80.0
		var site = LeySite.new()
		site.global_position = point
		game.add_child(site)
		sites.append(site)

func ritual_active() -> bool:
	return active != null

func _process(delta):
	if game.current_state != game.GameState.PLAYING:
		return
	var real = delta / maxf(Engine.time_scale, 0.01)
	var player_pos = game.player.global_position
	for site in sites:
		if site.state == LeySite.State.COOLING:
			site.cooldown -= real
			if site.cooldown <= 0.0:
				site.state = LeySite.State.DORMANT
		if site.state != LeySite.State.DORMANT:
			continue
		if not site.contains(player_pos):
			site.needs_exit = false
			site.dwell = 0.0
			continue
		if site.needs_exit or active or game.spell_manager.is_typing or game.spell_manager.space_casting:
			continue
		site.dwell += real
		if site.dwell >= DWELL_SECONDS:
			start_ritual(site)
	if active:
		word_time_left -= real
		if word_time_left <= 0.0:
			fail_ritual("Too slow")
	refresh_hud()

func start_ritual(site):
	active = site
	site.state = LeySite.State.RITUAL
	site.dwell = 0.0
	var pool = WORDS.duplicate()
	words.clear()
	for i in WORDS_PER_RITUAL:
		words.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	word_index = 0
	begin_word()
	Engine.time_scale = RITUAL_TIME_SCALE
	summon_ambush()
	game.show_gameplay_feedback("Ley line awakens · Type the words")

func begin_word():
	typed = ""
	word_time_total = WORD_BASE_SECONDS + WORD_SECONDS_PER_LETTER * words[word_index].length()
	word_time_left = word_time_total

func summon_ambush():
	var monsters = game.get_node_or_null("MonsterManager")
	if not monsters:
		return
	var count = mini(AMBUSH_MAX, AMBUSH_BASE + int(game.game_time / 60.0))
	var offset = rng.randf() * TAU
	for i in count:
		monsters.spawn_monster({}, false, true, offset + i * TAU / count)

func fail_ritual(reason: String):
	if not active:
		return
	active.state = LeySite.State.COOLING
	active.cooldown = RETRY_SECONDS
	active.needs_exit = true
	active = null
	if AudioManager:
		AudioManager.on_typing_error()
	game.show_gameplay_feedback("Ley line fades · %s · It wakes again in %ds" % [reason, int(RETRY_SECONDS)])

func complete_ritual():
	active.state = LeySite.State.ATTUNED
	active = null
	if AudioManager:
		AudioManager.on_typing_complete()
	game.show_gameplay_feedback("Ley line attuned · Choose a blessing")
	game.queue_boss_reward()

func _input(event):
	if not active or not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if game.current_state != game.GameState.PLAYING or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		fail_ritual("Cancelled")
		return
	if event.keycode == KEY_BACKSPACE:
		typed = typed.substr(0, maxi(0, typed.length() - 1))
		return
	var letter = char(event.unicode).to_lower()
	if letter.length() != 1 or not letter.is_valid_identifier():
		return
	var word = words[word_index]
	if word.begins_with(typed + letter):
		typed += letter
		if AudioManager:
			AudioManager.play_typing_sound(letter)
		if typed == word:
			word_index += 1
			if word_index >= words.size():
				complete_ritual()
			else:
				begin_word()
	else:
		# A wrong letter resets only the current word.
		typed = ""
		if AudioManager:
			AudioManager.on_typing_error()

func build_hud():
	hud = Control.new()
	hud.name = "LeyLinesHUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(hud)
	prompt = RichTextLabel.new()
	prompt.bbcode_enabled = true
	prompt.fit_content = true
	prompt.scroll_active = false
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.add_theme_font_size_override("normal_font_size", 34)
	prompt.add_theme_constant_override("outline_size", 8)
	prompt.add_theme_color_override("font_outline_color", Color("17101f"))
	prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt.custom_minimum_size = Vector2(720, 0)
	prompt.position = Vector2(-360, 130)
	prompt.hide()
	hud.add_child(prompt)
	arrows = preload("res://scripts/LeyDirection.gd").new()
	arrows.ley = self
	arrows.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(arrows)

func refresh_hud():
	if not active:
		prompt.hide()
		return
	var word = words[word_index]
	var bar_cells = 24
	var filled = int(round(bar_cells * clampf(word_time_left / word_time_total, 0.0, 1.0)))
	var bar_color = "#b48cff" if word_time_left > word_time_total * 0.3 else "#ff8175"
	prompt.text = "[center][font_size=22][color=#b48cff]LEY RITUAL %d/%d[/color][/font_size]\n[color=#f7d87a]%s[/color][color=#8a8496]%s[/color]\n[font_size=12][color=%s]%s[/color][color=#3a3248]%s[/color][/font_size][/center]" % [word_index + 1, words.size(), typed.to_upper(), word.substr(typed.length()).to_upper(), bar_color, "█".repeat(filled), "█".repeat(bar_cells - filled)]
	prompt.show()
