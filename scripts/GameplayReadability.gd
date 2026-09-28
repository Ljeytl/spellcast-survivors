extends Node

const INK = Color("17231c")
const PANEL = Color("25382b")
const PAPER = Color("eee8d8")
const MUTED = Color("b8c5aa")
const GOLD = Color("dfbd76")
const CYAN = Color("79d9e8")
const CORAL = Color("ff8175")

static var body_font: FontFile

var game: Node
var passive_label: Label
var focus_label: Label
var focus_bar: ProgressBar
var last_size = Vector2.ZERO
var guidance: Label
var feedback_remaining = 0.0
var feedback_copy = ""

static func panel_style(accent: Color = Color("66705b"), fill: Color = PANEL) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func apply_theme(control: Control):
	var theme = preload("res://themes/medieval_theme.tres").duplicate()
	theme.default_font_size = 18
	if body_font == null:
		body_font = ThemeDB.fallback_font.duplicate()
		body_font.multichannel_signed_distance_field = true
	theme.default_font = body_font
	for type_name in ["Label", "Button", "CheckBox"]:
		theme.set_font_size("font_size", type_name, 18)
	theme.set_font_size("normal_font_size", "RichTextLabel", 18)
	theme.set_font_size("bold_font_size", "RichTextLabel", 18)
	theme.set_color("default_color", "RichTextLabel", PAPER)
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_stylebox("panel", "Panel", panel_style())
	theme.set_stylebox("normal", "Button", panel_style())
	theme.set_stylebox("hover", "Button", panel_style(GOLD, Color("24374c")))
	theme.set_stylebox("pressed", "Button", panel_style(CYAN, INK))
	theme.set_stylebox("focus", "Button", panel_style(CYAN, Color.TRANSPARENT))
	theme.set_stylebox("focus", "HSlider", panel_style(CYAN, Color.TRANSPARENT))
	preload("res://scripts/AuthoredInterface.gd").apply_buttons(theme)
	control.theme = theme
	preload("res://scripts/AuthoredInterface.gd").decorate_menu(control)

static func fit_root(control: Control):
	var viewport_size = control.get_viewport_rect().size
	var window_size = Vector2(control.get_window().size)
	if OS.has_feature("web"):
		window_size = Vector2(float(JavaScriptBridge.eval("window.innerWidth")), float(JavaScriptBridge.eval("window.innerHeight")))
	if DisplayServer.get_name() == "headless" and window_size == Vector2(64, 64):
		window_size = Vector2(1280, 720)
	var factor = maxf(1.0, minf(viewport_size.x / maxf(window_size.x, 1), viewport_size.y / maxf(window_size.y, 1)))
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.scale = Vector2.ONE * factor
	control.size = viewport_size / factor

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = get_parent()
	var hud = game.get_node("UI/HUD")
	for root_control in game.get_node("UI").get_children():
		if root_control is Control:
			apply_theme(root_control)
	for node_name in ["StatsPanel", "TimerPanel", "SpellSlotsPanel", "TypingPanel"]:
		hud.get_node(node_name).add_theme_stylebox_override("panel", panel_style(CYAN if node_name == "TypingPanel" else Color("66705b")))
	for bar_name in ["HealthBar", "XPBar"]:
		var bar = hud.get_node("StatsPanel/" + bar_name)
		bar.add_theme_stylebox_override("background", panel_style(Color.TRANSPARENT, INK))
		bar.add_theme_stylebox_override("fill", panel_style(Color.TRANSPARENT, CORAL if bar_name == "HealthBar" else GOLD))
	var authored_health = preload("res://scripts/AuthoredHealthBar.gd").new()
	authored_health.name = "AuthoredHealth"
	var health = hud.get_node("StatsPanel/HealthBar")
	health.add_child(authored_health)
	health.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	health.get_theme_stylebox("fill").bg_color.a = 0.0
	for name in ["HealthLabel", "XPLabel"]:
		hud.get_node("StatsPanel/" + name).add_theme_font_size_override("font_size", 17)
	passive_label = Label.new()
	passive_label.name = "PassiveSpell"
	passive_label.add_theme_font_size_override("font_size", 16)
	passive_label.add_theme_color_override("font_color", MUTED)
	hud.add_child(passive_label)
	focus_label = Label.new()
	focus_label.name = "FocusStatus"
	focus_label.add_theme_font_size_override("font_size", 16)
	focus_label.add_theme_color_override("font_color", CYAN)
	hud.add_child(focus_label)
	focus_bar = ProgressBar.new()
	focus_bar.name = "FocusBar"
	focus_bar.show_percentage = false
	focus_bar.add_theme_stylebox_override("background", panel_style(Color.TRANSPARENT, INK))
	focus_bar.add_theme_stylebox_override("fill", panel_style(Color.TRANSPARENT, CYAN))
	hud.add_child(focus_bar)
	guidance = Label.new()
	guidance.name = "GameplayGuidance"
	guidance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guidance.add_theme_font_size_override("font_size", 16)
	guidance.add_theme_color_override("font_color", PAPER)
	hud.add_child(guidance)
	layout()

func _process(_delta):
	var current_size = Vector2(game.get_window().size)
	if current_size != last_size:
		layout()
	var typing = game.get_node("UI/HUD/TypingPanel")
	var timer = game.get_node("UI/HUD/TimerPanel")
	var diagnostics_top = maxf(138, timer.get_rect().end.y + 12) if timer.position.y > 18 else 138.0
	passive_label.position.y = diagnostics_top
	focus_label.position.y = diagnostics_top + 25
	focus_bar.position.y = diagnostics_top + 54
	for supplemental in [passive_label, focus_label, focus_bar]:
		supplemental.visible = game.interface_debug and not (typing.visible and typing.get_global_rect().intersects(supplemental.get_global_rect()))
	var manager = game.spell_manager
	if game.current_state == game.GameState.PLAYING and not manager.is_typing:
		feedback_remaining = maxf(0, feedback_remaining - _delta)
	guidance.text = feedback_copy if feedback_remaining > 0 else "WASD / arrows move · Mana Bolt fires automatically\nClick a spell or press 1–6, then type · Space chooses any learned spell"
	guidance.visible = game.current_state == game.GameState.PLAYING and not manager.is_typing and game.interface_debug
	var spells_panel = game.get_node("UI/HUD/SpellSlotsPanel")
	spells_panel.visible = game.interface_debug
	guidance.size = Vector2(minf(560, game.get_node("UI/HUD").size.x - 36), maxf(32, guidance.get_minimum_size().y))
	guidance.position = Vector2((game.get_node("UI/HUD").size.x - guidance.size.x) / 2, game.get_node("UI/HUD").size.y - guidance.size.y - 34)
	if game.hud.size.x < 700:
		guidance.size.x = maxf(180, game.hud.size.x - 222)
		guidance.position.x = 210
		guidance.position.y = game.hud.size.y - guidance.get_minimum_size().y - 34
	var reference = game.hud.get_node_or_null("CastingReference")
	if is_instance_valid(reference) and not game.interface_debug:
		guidance.position.y = reference.position.y - guidance.size.y - 8
	passive_label.text = "AUTO · Mana Bolt · Rank %d" % manager.get_spell_rank("mana_bolt")
	var remaining = manager.typing_slowdown_remaining
	var capacity = manager.typing_slowdown_capacity
	focus_bar.max_value = capacity
	focus_bar.value = remaining
	if manager.is_typing:
		focus_label.text = "SLOWDOWN · %.1fs" % remaining if remaining > 0 else "CAST WINDOW ENDED · normal speed"
	else:
		focus_label.text = "PER CAST · %.1fs at 20%% speed" % capacity

func show_feedback(text: String):
	feedback_copy = text
	feedback_remaining = 6.0

func layout():
	last_size = Vector2(game.get_window().size)
	for root_control in game.get_node("UI").get_children():
		if root_control is Control:
			fit_root(root_control)
	var hud = game.get_node("UI/HUD")
	var width = hud.size.x
	var height = hud.size.y
	var stats = hud.get_node("StatsPanel")
	stats.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	stats.position = Vector2(18, 18)
	stats.size = Vector2(minf(280 if game.interface_debug else 240, width * 0.55), 92 if game.interface_debug else 84)
	for spec in [["HealthLabel", 6, 27], ["HealthBar", 30, 45], ["XPLabel", 46, 68], ["XPBar", 69, 75]]:
		var item = stats.get_node(spec[0])
		item.offset_top = spec[1]
		item.offset_bottom = spec[2]
		if item is Label:
			item.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var timer = hud.get_node("TimerPanel")
	timer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	timer.size = Vector2(minf(340, width * 0.48), 92) if game.interface_debug else Vector2(112, 48)
	timer.position = Vector2(width - timer.size.x - 18, 18)
	var clock = timer.get_node("TimerLabel")
	clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	clock.offset_top = 4
	clock.offset_bottom = 40
	clock.add_theme_font_size_override("font_size", 28)
	var difficulty = timer.get_node("DifficultyLabel")
	difficulty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	difficulty.offset_left = 12
	difficulty.offset_right = -12
	difficulty.offset_top = 47
	difficulty.offset_bottom = -6
	difficulty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	difficulty.add_theme_font_size_override("font_size", 16)
	var tooltip = hud.get_node("DifficultyTooltip")
	tooltip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tooltip.position = Vector2(maxf(18, timer.position.x + timer.size.x - 360), timer.position.y + timer.size.y + 8)
	tooltip.size = Vector2(minf(360, width - 36), 220)
	var spells = hud.get_node("SpellSlotsPanel")
	spells.anchor_left = 0.5
	spells.anchor_right = 0.5
	spells.offset_left = -minf(680, width - 36) / 2
	spells.offset_right = minf(680, width - 36) / 2
	game._resize_spell_hud()
	passive_label.position = Vector2(20, 138)
	focus_label.position = Vector2(20, 163)
	focus_bar.position = Vector2(20, 192)
	focus_bar.size = Vector2(240, 6)
	var pause_panel = game.get_node("UI/PauseOverlay/PauseMenu")
	pause_panel.size = Vector2(minf(520, width - 36), minf(450, height - 36))
	pause_panel.position = (Vector2(width, height) - pause_panel.size) / 2
	var typing = hud.get_node("TypingPanel")
	typing.size.x = minf(620, width - 36)
	typing.get_node("SlowdownStatus").offset_top = 8
	typing.get_node("SlowdownStatus").offset_bottom = 30
	typing.get_node("SlowdownStatus").add_theme_font_size_override("font_size", 14)
	typing.get_node("TypingArea").offset_top = 34
	typing.get_node("TypingArea").offset_bottom = -10
	game._fit_typing_content()
	for screen in [game.level_up_screen, game.game_over_screen]:
		if is_instance_valid(screen):
			var panel = screen.panel
			var compact_ending = screen == game.game_over_screen and not game.interface_debug
			panel.size = Vector2(minf(560 if compact_ending else 680, width - 36), minf(360 if compact_ending else 650, height - 36))
			panel.position = (Vector2(width, height) - panel.size) / 2
			panel.add_theme_stylebox_override("panel", panel_style(GOLD))

static func setup_menu(control: Control, panel_name: String):
	apply_theme(control)
	control.get_node("Background").color = INK
	if control.has_node("GradientOverlay"):
		control.get_node("GradientOverlay").color = Color.TRANSPARENT
	control.get_window().size_changed.connect(control._layout_readable_menu)
	layout_menu(control, panel_name)

static func layout_menu(control: Control, panel_name: String):
	fit_root(control)
	var panel = control.get_node(panel_name)
	panel.size = Vector2(minf(700 if panel_name == "HowToPlayPanel" else 560, control.size.x - 36), minf(650 if panel_name == "HowToPlayPanel" else 500, control.size.y - 36))
	panel.position = (control.size - panel.size) / 2
	panel.add_theme_stylebox_override("panel", panel_style(GOLD))
