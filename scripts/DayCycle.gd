extends Node
## EXPERIMENT (experiment/day-cycle): a run is a four-day expedition.
## Each day is DAY_SECONDS of daylight running 3 pm to dusk (the wizard sleeps in).
## When daylight runs out the sky turns to night and that day's boss emerges; the day
## clock stops while the run timer keeps counting. Killing the boss opens camp (the game
## pauses, combo is kept). Waking up starts the next day with a short no-decay grace.
## The fourth boss leads to extraction; continuing into endless keeps the days going.

const DAY_SECONDS = 300.0
const DAYS = 4
## Fraction of the day at which the dusk warning shows.
const DUSK_AT = 0.8
const SUNRISE_SECONDS = 2.5
## Seconds of no combo decay after waking.
const WAKE_GRACE = 10.0
## After the boss falls: the other monsters flee, every XP orb on the map flies to the
## player, and the field stays quiet this long (time to grab the chest) before camp opens.
const AFTERMATH_SECONDS = 6.0
## One boss per night; past the list it repeats, tougher each cycle.
const BOSSES = [
	{"variant": "juggernaut", "name": "The Gatekeeper", "health": 1000.0},
	{"variant": "charger", "name": "The Pursuer", "health": 5000.0},
	{"variant": "shieldbearer", "name": "The Iron Guard", "health": 9000.0},
	{"variant": "juggernaut", "name": "The Warden", "health": 18000.0},
]
## The sky: keyframes over the day (t = day_clock / DAY_SECONDS; night is t = 1).
## Each key is a grade for shaders/day_grade.gdshader: gain = colour of the light,
## shadow / highlight = split toning, sat, contrast, bright, keep = how much spells and
## other bright lights keep their own colour. Edit these to retune the look.
const SKY_KEYS = [
	{"t": 0.0, "gain": Vector3(1.0, 1.0, 1.0), "shadow": Vector3(0, 0, 0), "highlight": Vector3(0, 0, 0), "sat": 1.0, "contrast": 1.0, "bright": 1.0, "keep": 0.0, "hue": 0.0, "sky_top": Vector3(0, 0, 0), "sky_bottom": Vector3(0, 0, 0)},
	{"t": 0.45, "gain": Vector3(1.03, 1.01, 0.94), "shadow": Vector3(0, 0, 0), "highlight": Vector3(0.02, 0.015, 0), "sat": 1.05, "contrast": 1.0, "bright": 1.0, "keep": 0.2, "hue": -3.0, "sky_top": Vector3(0.03, 0.02, 0.0), "sky_bottom": Vector3(0, 0, 0)},
	{"t": 0.7, "gain": Vector3(1.12, 1.03, 0.8), "shadow": Vector3(0.01, 0.0, 0.02), "highlight": Vector3(0.08, 0.045, -0.02), "sat": 1.1, "contrast": 1.04, "bright": 1.02, "keep": 0.4, "hue": -7.0, "sky_top": Vector3(0.14, 0.08, 0.0), "sky_bottom": Vector3(0.03, 0.01, 0.0)},
	{"t": 0.84, "gain": Vector3(1.18, 0.94, 0.86), "shadow": Vector3(0.03, -0.01, 0.06), "highlight": Vector3(0.1, 0.03, 0.0), "sat": 1.15, "contrast": 1.06, "bright": 1.0, "keep": 0.55, "hue": -12.0, "sky_top": Vector3(0.24, 0.09, 0.04), "sky_bottom": Vector3(0.05, 0.0, 0.04)},
	{"t": 0.94, "gain": Vector3(0.88, 0.78, 1.02), "shadow": Vector3(0.04, 0.0, 0.09), "highlight": Vector3(0.08, 0.02, 0.02), "sat": 1.14, "contrast": 1.08, "bright": 0.92, "keep": 0.7, "hue": 18.0, "sky_top": Vector3(0.13, 0.03, 0.1), "sky_bottom": Vector3(0.0, 0.0, 0.05)},
	{"t": 1.0, "gain": Vector3(0.62, 0.82, 1.12), "shadow": Vector3(0.0, 0.02, 0.1), "highlight": Vector3(0.02, 0.05, 0.09), "sat": 1.02, "contrast": 1.05, "bright": 0.97, "keep": 0.85, "hue": 22.0, "sky_top": Vector3(0.04, 0.06, 0.12), "sky_bottom": Vector3(0.0, 0.0, 0.03)},
]
const GRADE = preload("res://shaders/day_grade.gdshader")
## Nightfall: the world dips darker for a beat as the boss arrives, then settles.
const NIGHTFALL_DIP_SECONDS = 2.0
const NIGHTFALL_DIP = 0.35

enum Phase { DAY, NIGHT, CAMP, EXTRACTION, AFTERMATH }

var game: Node
var monsters: Node
var day := 1
var day_clock := 0.0
var phase := Phase.DAY
var boss: Node = null
var dusk_announced := false
var sunrise := 0.0
var nightfall_dip := 0.0
var aftermath := 0.0
var grade_layer: CanvasLayer
var grade: ShaderMaterial
var clock_label: Label
var banner: Label
var banner_tween: Tween
var camp: Control
var camp_title: Label
var camp_body: Label
var wake_button: Button

func _ready():
	name = "DayCycle"
	add_to_group("day_cycle")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	monsters = game.get_node("MonsterManager")
	monsters.day_cycle_driven = true
	monsters.phase_clock = 0.0
	# The grade sits above the world and below the HUD: HUD text is never tinted.
	grade_layer = CanvasLayer.new()
	grade_layer.name = "DaySky"
	grade_layer.layer = game.get_node("UI").layer
	game.add_child(grade_layer)
	game.move_child(grade_layer, game.get_node("UI").get_index())
	grade = ShaderMaterial.new()
	grade.shader = GRADE
	var rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = grade
	grade_layer.add_child(rect)
	build_hud()
	apply_sky()
	update_clock_label()

func _process(delta):
	if phase == Phase.EXTRACTION and monsters.endless_mode and not monsters.awaiting_extraction:
		wake()
	if game.current_state != game.GameState.PLAYING:
		return
	# Timers that run down first, so a sunrise or nightfall dip starting this frame keeps its full length.
	sunrise = maxf(0.0, sunrise - delta)
	nightfall_dip = maxf(0.0, nightfall_dip - delta)
	match phase:
		Phase.DAY:
			day_clock = minf(DAY_SECONDS, day_clock + delta)
			monsters.phase_clock = day_clock
			if not dusk_announced and day_clock >= DAY_SECONDS * DUSK_AT:
				dusk_announced = true
				announce("Dusk falls", "Something is coming")
			if day_clock >= DAY_SECONDS:
				nightfall()
		Phase.NIGHT:
			if not is_instance_valid(boss) or boss.dying:
				boss_defeated()
		Phase.AFTERMATH:
			# Keep pulling: the boss's own XP drops a moment after it dies.
			monsters.vacuum_xp()
			aftermath -= delta
			if aftermath <= 0.0:
				open_camp()
	apply_sky()
	update_clock_label()

## Where the sky is between 3 pm (0) and night (1), including the sunrise blend after camp.
func sky_time() -> float:
	var t = clampf(day_clock / DAY_SECONDS, 0.0, 1.0) if phase == Phase.DAY else 1.0
	return lerpf(t, 1.0, sunrise / SUNRISE_SECONDS) if sunrise > 0.0 else t

func sky_progress() -> float:
	return sky_time()

## The grade at sky time t, interpolated between keyframes (smoothstepped so it eases).
func sky_grade(t: float) -> Dictionary:
	for i in range(1, SKY_KEYS.size()):
		var a = SKY_KEYS[i - 1]
		var b = SKY_KEYS[i]
		if t <= b.t:
			var w = smoothstep(a.t, b.t, t)
			var result = {}
			for key in a:
				result[key] = lerp(a[key], b[key], w)
			return result
	return SKY_KEYS.back().duplicate()

func apply_sky():
	var g = sky_grade(sky_time())
	var dip = 0.0
	if nightfall_dip > 0.0:
		# A quick dip that eases back: darkest a third of the way in.
		var p = 1.0 - nightfall_dip / NIGHTFALL_DIP_SECONDS
		dip = NIGHTFALL_DIP * (p / 0.33 if p < 0.33 else 1.0 - (p - 0.33) / 0.67)
	grade.set_shader_parameter("strength", 0.0 if g.t <= 0.001 and dip <= 0.0 else 1.0)
	grade.set_shader_parameter("gain", g.gain)
	grade.set_shader_parameter("shadow", g.shadow)
	grade.set_shader_parameter("highlight", g.highlight)
	grade.set_shader_parameter("saturation", g.sat)
	grade.set_shader_parameter("contrast", g.contrast)
	grade.set_shader_parameter("brightness", g.bright * (1.0 - dip))
	grade.set_shader_parameter("light_keep", g.keep)
	grade.set_shader_parameter("hue_shift", g.hue)
	grade.set_shader_parameter("sky_top", g.sky_top)
	grade.set_shader_parameter("sky_bottom", g.sky_bottom)

func nightfall():
	phase = Phase.NIGHT
	monsters.phase_override = "night"
	var entry = BOSSES[(day - 1) % BOSSES.size()]
	var cycle = (day - 1) / BOSSES.size()
	var definition = monsters.encounter_config.variants[entry.variant].duplicate(true)
	definition["id"] = entry.variant
	definition["name"] = entry.name
	definition["boss_health"] = float(entry.health) * (1.0 + 0.5 * cycle)
	boss = monsters.spawn_monster(definition, true)
	# The arrival is a moment: the world dips dark, the ground shakes, the boss is named.
	nightfall_dip = NIGHTFALL_DIP_SECONDS
	if game.has_method("shake_heavy"):
		game.shake_heavy()
	announce("Night falls", entry.name)
	if boss:
		monsters.boss_arrived.emit(entry.name)

func boss_defeated():
	boss = null
	monsters.rout()
	monsters.phase_override = "rest"
	if day >= DAYS and not monsters.endless_mode:
		phase = Phase.EXTRACTION
		var title = game.extraction_screen.find_child("Title", true, false) if is_instance_valid(game.extraction_screen) else null
		if title:
			title.text = "%d DAYS SURVIVED" % day
		monsters.begin_extraction()
		return
	phase = Phase.AFTERMATH
	aftermath = AFTERMATH_SECONDS
	monsters.vacuum_xp()
	announce("The night goes quiet", "Everything else fled")

func open_camp():
	phase = Phase.CAMP
	game.spell_manager.cancel_typing()
	banner.modulate.a = 0.0
	camp_title.text = "NIGHT %d · CAMP" % day
	camp_body.text = "You made it through day %d.\nRun time %s · Combo kept\n\nTomorrow: day %d" % [day, format_time(monsters.game_time), day + 1]
	camp.show()
	game.change_state(game.GameState.CAMP)
	wake_button.grab_focus.call_deferred()

func wake():
	camp.hide()
	day += 1
	day_clock = 0.0
	monsters.phase_clock = 0.0
	monsters.phase_override = ""
	dusk_announced = false
	sunrise = SUNRISE_SECONDS
	phase = Phase.DAY
	var style = game.get("style_session")
	if is_instance_valid(style):
		style.score.grace_remaining = maxf(style.score.grace_remaining, WAKE_GRACE)
	if game.current_state == game.GameState.CAMP:
		game.change_state(game.GameState.PLAYING)
	announce("Day %d" % day, "3:00 pm · You slept in again")

## Console "day" command. "dusk" = a few seconds before the dusk warning, "night" = the boss
## now, a number = the start of that day. Run time only moves forward: a later day sets it to
## where that day would start (a 30 s boss each night); difficulty follows run time.
## Returns a line for the console, or "" if the argument is not understood.
func debug_jump(target: String) -> String:
	if phase == Phase.EXTRACTION:
		return "The expedition is over."
	if target == "dusk" or target == "night":
		if phase != Phase.DAY:
			return "It is already night; kill the boss first."
		day_clock = DAY_SECONDS if target == "night" else DAY_SECONDS * DUSK_AT - 3.0
		monsters.phase_clock = day_clock
		if target == "night":
			nightfall()
		return "Day %d · %s" % [day, "the boss emerges" if target == "night" else "dusk in 3 s"]
	if not target.is_valid_int() or int(target) < 1:
		return ""
	var target_day = int(target)
	if is_instance_valid(boss) and not boss.dying:
		boss.queue_free()
		monsters.monsters_alive = maxi(0, monsters.monsters_alive - 1)
	boss = null
	camp.hide()
	if game.current_state == game.GameState.CAMP:
		game.change_state(game.GameState.PLAYING)
	day = target_day - 1
	wake()
	var start_time = float(target_day - 1) * (DAY_SECONDS + 30.0)
	if monsters.game_time < start_time:
		monsters.add_game_time(start_time - monsters.game_time)
	return "Day %d · run time %s" % [day, format_time(monsters.game_time)]

func format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func time_of_day() -> String:
	if phase != Phase.DAY:
		return "Night"
	var minutes = 15 * 60 + int(day_clock / DAY_SECONDS * 5.0 * 60.0)
	var hour = minutes / 60 - 12
	return "%d:%02d pm" % [hour, minutes % 60]

func update_clock_label():
	clock_label.text = "DAY %d" % day

func announce(title: String, line: String):
	banner.text = "%s\n%s" % [title.to_upper(), line]
	banner.modulate.a = 1.0
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	banner_tween = banner.create_tween()
	banner_tween.tween_interval(2.4)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.8)

func build_hud():
	clock_label = Label.new()
	clock_label.name = "DayClock"
	clock_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_label.position = Vector2(-160, 14)
	clock_label.custom_minimum_size = Vector2(320, 0)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 18)
	clock_label.add_theme_constant_override("outline_size", 6)
	clock_label.add_theme_color_override("font_outline_color", Color("17101f"))
	clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(clock_label)
	banner = Label.new()
	banner.name = "DayBanner"
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-400, 150)
	banner.custom_minimum_size = Vector2(800, 0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 34)
	banner.add_theme_constant_override("outline_size", 9)
	banner.add_theme_color_override("font_outline_color", Color("17101f"))
	banner.add_theme_color_override("font_color", Color("f7d87a"))
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.add_child(banner)
	camp = Control.new()
	camp.name = "CampScreen"
	camp.process_mode = Node.PROCESS_MODE_ALWAYS
	camp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.03, 0.03, 0.08, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camp.add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camp.add_child(center)
	var column = VBoxContainer.new()
	column.custom_minimum_size.x = 420
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	camp_title = Label.new()
	camp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camp_title.add_theme_font_size_override("font_size", 30)
	camp_title.add_theme_color_override("font_color", Color("f7a95a"))
	column.add_child(camp_title)
	camp_body = Label.new()
	camp_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camp_body.add_theme_font_size_override("font_size", 18)
	column.add_child(camp_body)
	wake_button = Button.new()
	wake_button.name = "WakeButton"
	wake_button.text = "WAKE UP"
	wake_button.custom_minimum_size = Vector2(0, 52)
	wake_button.pressed.connect(wake)
	column.add_child(wake_button)
	camp.hide()
	game.get_node("UI").add_child(camp)
