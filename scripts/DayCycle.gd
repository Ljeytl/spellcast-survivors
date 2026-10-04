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
## The sky grade: 0 = 3 pm, 1 = night. Each stop's colour is the hue the world shifts
## toward and its alpha is how strongly. Edit data/day_sky.tres in the Godot editor.
const SKY = preload("res://data/day_sky.tres")
const GRADE = preload("res://shaders/day_grade.gdshader")
## Brightness at 3 pm and at night: night is bluer, only slightly dimmer.
const DAY_BRIGHTNESS = 1.0
const NIGHT_BRIGHTNESS = 0.9

enum Phase { DAY, NIGHT, CAMP, EXTRACTION, AFTERMATH }

var game: Node
var monsters: Node
var day := 1
var day_clock := 0.0
var phase := Phase.DAY
var boss: Node = null
var dusk_announced := false
var sunrise := 0.0
var aftermath := 0.0
var grade_layer: CanvasLayer
var grade: ShaderMaterial
var clock_label: Label
var banner: Label
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
			monsters.night_clock += delta
			if not is_instance_valid(boss) or boss.dying:
				boss_defeated()
		Phase.AFTERMATH:
			# Keep pulling: the boss's own XP drops a moment after it dies.
			monsters.vacuum_xp()
			aftermath -= delta
			if aftermath <= 0.0:
				open_camp()
	sunrise = maxf(0.0, sunrise - delta)
	apply_sky()
	update_clock_label()

func sky_color() -> Color:
	var night = SKY.sample(1.0)
	var color = SKY.sample(clampf(day_clock / DAY_SECONDS, 0.0, 1.0)) if phase == Phase.DAY else night
	return color.lerp(night, sunrise / SUNRISE_SECONDS) if sunrise > 0.0 else color

func sky_progress() -> float:
	return clampf(day_clock / DAY_SECONDS, 0.0, 1.0) if phase == Phase.DAY else 1.0

func apply_sky():
	grade.set_shader_parameter("hue", sky_color())
	var night_amount = lerpf(sky_progress(), 1.0, sunrise / SUNRISE_SECONDS) if sunrise > 0.0 else sky_progress()
	grade.set_shader_parameter("brightness", lerpf(DAY_BRIGHTNESS, NIGHT_BRIGHTNESS, night_amount))

func nightfall():
	phase = Phase.NIGHT
	monsters.phase_override = "night"
	monsters.night_clock = 0.0
	var entry = BOSSES[(day - 1) % BOSSES.size()]
	var cycle = (day - 1) / BOSSES.size()
	var definition = monsters.encounter_config.variants[entry.variant].duplicate(true)
	definition["id"] = entry.variant
	definition["name"] = entry.name
	definition["boss_health"] = float(entry.health) * (1.0 + 0.5 * cycle)
	boss = monsters.spawn_monster(definition, true)
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
	var tween = banner.create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(banner, "modulate:a", 0.0, 0.8)

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
