extends PanelContainer
## Console `director` overlay (doc 23): live threat director state, top-left under the stats panel.

var monsters
var label: Label
var refresh := 0.0

func _init(p_monsters = null):
	monsters = p_monsters
	name = "DirectorOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(12, 120)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.78)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.75, 1.0, 0.8))
	add_child(label)

func _ready():
	update_text()

func _process(delta):
	refresh -= delta
	if refresh <= 0.0:
		refresh = 0.2
		update_text()

func update_text():
	if not is_instance_valid(monsters) or monsters.threat_director == null:
		label.text = "DIRECTOR  off (pacing: %s)" % (monsters.pacing() if is_instance_valid(monsters) else "-")
		return
	label.text = monsters.threat_director.report()
