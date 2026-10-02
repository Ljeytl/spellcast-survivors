extends Node
## Ley lines (cut-down M3). Each run has a few sites. Walking into one wakes it and
## reveals its words. Waves attack while the site is awake; words can only be typed
## (Space, then the word, Enter) while standing in the circle. Leaving pauses the
## site without losing progress. Binding every word summons a guardian boss, whose
## death attunes the site; the boss drops the usual chest, potion and style runes.

const LeySite = preload("res://scripts/LeySite.gd")
const SITE_COUNT = 3
const SITE_DISTANCE_MIN = 1500.0
const SITE_DISTANCE_MAX = 2200.0
const WORDS_PER_SITE = 4
const DWELL_SECONDS = 0.4
## Waves only advance while the player is this close to an awake site.
const ENGAGE_RADIUS = 900.0
const WAVE_INTERVAL = 8.0
## Enemies per wave: base plus one per two minutes of run time.
const WAVE_BASE = 4
const WAVE_MAX = 12
## Standing in an attuned circle: Spell Power bonus, and combo does not decay.
const ATTUNED_POWER_BONUS = 0.20
const GUARDIAN_VARIANT = "juggernaut"
const GUARDIAN_NAME = "Ley Guardian"
const GUARDIAN_HEALTH = 900.0
const GUARDIAN_HEALTH_PER_MINUTE = 100.0
## Ley words are made-up incantations built from these syllables, fresh every run.
## Set GENERATED_WORDS false to draw from WORDS instead.
const GENERATED_WORDS = true
const WORD_LENGTH_MIN = 6
const WORD_LENGTH_MAX = 11
const ONSETS = ["v", "th", "k", "qu", "z", "dr", "m", "s", "r", "gr", "x", "l", "n", "br", "sh", "kr", "t", "f", "g", "vr"]
const NUCLEI = ["a", "e", "i", "o", "u", "a", "e", "o", "ae", "ei"]
const CODAS = ["r", "n", "x", "th", "l", "k", "s", "m", "rn", "sh"]
const WORDS = ["kindle", "awaken", "entwine", "restore", "temper", "conjure", "radiance", "starfall", "moonwell", "everglow", "thornwood", "emberheart", "stormcall", "wellspring", "runestone", "nightbloom", "skyforge", "spellbind", "lodestar", "evensong", "brightwater", "ironroot", "sunspire", "wildheart"]

var game: Node
var sites: Array = []
var rng := RandomNumberGenerator.new()
var hud: Control
var panel: RichTextLabel
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
	var pool = WORDS.duplicate()
	for i in SITE_COUNT:
		var angle = start + i * TAU / SITE_COUNT + rng.randf_range(-0.35, 0.35)
		var point = origin + Vector2.from_angle(angle) * rng.randf_range(SITE_DISTANCE_MIN, SITE_DISTANCE_MAX)
		for attempt in 12:
			if not terrain or not terrain.has_method("is_spawn_clear") or terrain.is_spawn_clear(point, LeySite.RADIUS):
				break
			point += Vector2.from_angle(angle) * 80.0
		var site = LeySite.new()
		site.global_position = point
		for w in WORDS_PER_SITE:
			site.words.append(make_word() if GENERATED_WORDS else pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		game.add_child(site)
		sites.append(site)

var used_words: Dictionary = {}

## A pronounceable nonsense word, e.g. "vorthaxil". Never repeats within a run
## and never matches a spell incantation.
func make_word() -> String:
	var taken = game.spell_manager.get_owned_incantations() if game.spell_manager.has_method("get_owned_incantations") else []
	for attempt in 50:
		var word = ""
		var syllables = rng.randi_range(2, 3)
		for i in syllables:
			word += ONSETS[rng.randi() % ONSETS.size()] + NUCLEI[rng.randi() % NUCLEI.size()]
			# Closing consonants mostly at the end, so the word does not jam up.
			if i == syllables - 1 or rng.randf() < 0.25:
				word += CODAS[rng.randi() % CODAS.size()]
		if word.length() < WORD_LENGTH_MIN or word.length() > WORD_LENGTH_MAX or used_words.has(word) or word in taken or word in ["atomic", "mega"]:
			continue
		used_words[word] = true
		return word
	return "vorthaxil%d" % used_words.size()

## Spell Power multiplier from standing in an attuned circle (SpellManager applies it).
func power_multiplier() -> float:
	for site in sites:
		if site.state == LeySite.State.ATTUNED and site.contains(game.player.global_position):
			return 1.0 + ATTUNED_POWER_BONUS
	return 1.0

## The awake site whose circle the player is standing in, if any.
func site_under_player():
	for site in sites:
		if site.state == LeySite.State.SIEGE and site.contains(game.player.global_position):
			return site
	return null

## The site the HUD should describe: the nearest awake one within engage range.
func engaged_site():
	var best = null
	var best_distance = ENGAGE_RADIUS
	for site in sites:
		if site.state in [LeySite.State.SIEGE, LeySite.State.GUARDIAN]:
			var distance = site.global_position.distance_to(game.player.global_position)
			if distance <= best_distance:
				best = site
				best_distance = distance
	return best

func _process(delta):
	if game.current_state != game.GameState.PLAYING:
		return
	var real = delta / maxf(Engine.time_scale, 0.01)
	var player_pos = game.player.global_position
	for site in sites:
		match site.state:
			LeySite.State.DORMANT:
				if site.contains(player_pos):
					site.dwell += real
					if site.dwell >= DWELL_SECONDS:
						wake(site)
				else:
					site.dwell = 0.0
			LeySite.State.SIEGE:
				# Leaving pauses the site: no waves, no progress lost.
				if site.global_position.distance_to(player_pos) <= ENGAGE_RADIUS:
					site.wave_timer -= real
					if site.wave_timer <= 0.0:
						site.wave_timer = WAVE_INTERVAL
						summon_wave(site)
			LeySite.State.GUARDIAN:
				if not is_instance_valid(site.guardian) or site.guardian.dying:
					attune(site)
	refresh_hud()

func wake(site):
	site.state = LeySite.State.SIEGE
	site.wave_timer = 0.0
	game.show_gameplay_feedback("Ley line awakens · In the circle, press Space and type its words")

func summon_wave(site):
	var monsters = game.get_node_or_null("MonsterManager")
	if not monsters:
		return
	var count = mini(WAVE_MAX, WAVE_BASE + int(game.game_time / 120.0))
	var offset = rng.randf() * TAU
	for i in count:
		monsters.spawn_monster({}, false, true, offset + i * TAU / count)

## Called by SpellManager with a submitted Space-cast text. True if it bound a word.
func try_word(text: String) -> bool:
	var site = site_under_player()
	if site == null:
		return false
	var word = text.strip_edges().to_lower()
	if word not in site.words or word in site.bound:
		return false
	site.bound.append(word)
	if AudioManager:
		AudioManager.on_typing_complete()
	if site.bound.size() >= site.words.size():
		summon_guardian(site)
	else:
		game.show_gameplay_feedback("Ley word bound · %d/%d" % [site.bound.size(), site.words.size()])
	return true

func summon_guardian(site):
	site.state = LeySite.State.GUARDIAN
	var monsters = game.get_node_or_null("MonsterManager")
	if not monsters:
		attune(site)
		return
	var definition = monsters.encounter_config.variants[GUARDIAN_VARIANT].duplicate(true)
	definition["id"] = GUARDIAN_VARIANT
	definition["name"] = GUARDIAN_NAME
	definition["boss_health"] = GUARDIAN_HEALTH + GUARDIAN_HEALTH_PER_MINUTE * game.game_time / 60.0
	site.guardian = monsters.spawn_monster(definition, true, true, rng.randf() * TAU)
	if site.guardian:
		monsters.boss_arrived.emit(GUARDIAN_NAME)
	game.show_gameplay_feedback("Every word bound · The %s rises" % GUARDIAN_NAME)

func attune(site):
	site.state = LeySite.State.ATTUNED
	site.guardian = null
	game.show_gameplay_feedback("Ley line attuned · Stand in it for +%d%% Spell Power and no combo decay" % int(ATTUNED_POWER_BONUS * 100))

func build_hud():
	hud = Control.new()
	hud.name = "LeyLinesHUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(hud)
	panel = RichTextLabel.new()
	panel.bbcode_enabled = true
	panel.fit_content = true
	panel.scroll_active = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_font_size_override("normal_font_size", 22)
	panel.add_theme_constant_override("outline_size", 7)
	panel.add_theme_color_override("font_outline_color", Color("17101f"))
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.custom_minimum_size = Vector2(640, 0)
	panel.position = Vector2(-320, 96)
	panel.hide()
	hud.add_child(panel)
	arrows = preload("res://scripts/LeyDirection.gd").new()
	arrows.ley = self
	arrows.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(arrows)

func refresh_hud():
	var site = engaged_site()
	if site == null:
		panel.hide()
		return
	if site.state == LeySite.State.GUARDIAN:
		panel.text = "[center][color=#ff8175]LEY LINE · DEFEAT THE %s[/color][/center]" % GUARDIAN_NAME.to_upper()
	else:
		var parts: Array[String] = []
		for word in site.words:
			parts.append(("[color=#f7d87a]✓ %s[/color]" if word in site.bound else "[color=#e2d0ff]%s[/color]") % word.to_upper())
		var hint = "Space, then type a word" if site.contains(game.player.global_position) else "Stand in the circle to type"
		panel.text = "[center][color=#b48cff]LEY LINE %d/%d · %s[/color]\n%s[/center]" % [site.bound.size(), site.words.size(), hint, "   ".join(parts)]
	panel.show()
