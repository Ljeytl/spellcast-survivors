extends Node2D

const ART = preload("res://scripts/TowerArt.gd")
const PORTAL_COUNT = 12
const RADIUS = Vector2(450, 300)
const STEP = TAU / PORTAL_COUNT
const SPEED = 190.0
var wizard: CharacterBody2D
var room: Node2D
var camera: Camera2D
var masonry: Node2D
var arches: Array[Node2D] = []
var selected = 0
var angle = 0.0
var target_angle = 0.0
var orb_active = false
var transitioning = false
var archive: Control
var label: Label
var hud: CanvasLayer
var ui: Control
var tome_position = Vector2(-155, 15)
var obstacles: Array[Dictionary] = []

func _ready():
	RenderingServer.set_default_clear_color(Color("151722"))
	room = Node2D.new()
	add_child(room)
	var floor_sprite = ART.sprite(0, 950)
	floor_sprite.scale.y *= 0.78
	floor_sprite.z_index = -100
	room.add_child(floor_sprite)
	var carpet = ART.sprite(1, 850)
	carpet.scale.y *= 0.78
	carpet.z_index = -99
	room.add_child(carpet)
	masonry = preload("res://scripts/TowerRing.gd").new()
	masonry.z_index = -90
	room.add_child(masonry)
	add_prop(2, Vector2.ZERO, 60, Vector2(24, 17))
	add_prop(3, tome_position, 60, Vector2(24, 17))
	add_prop(14, Vector2(220, 80), 80, Vector2(34, 24))
	add_prop(15, Vector2(240, -80), 100, Vector2(35, 48))
	for i in PORTAL_COUNT:
		var portal = Node2D.new()
		var arch = ART.sprite(4, 170)
		arch.name = "Arch"
		portal.add_child(arch)
		if i != 0:
			var blocker = ART.sprite(12 if i % 3 == 0 else 13, 65)
			blocker.name = "Blocker"
			blocker.position.y = -10
			portal.add_child(blocker)
		arches.append(portal)
		room.add_child(portal)
	wizard = CharacterBody2D.new()
	wizard.name = "TowerWizard"
	wizard.collision_layer = 1
	wizard.collision_mask = 32
	wizard.position = Vector2(0, 115)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	wizard.add_child(shape)
	var visual = Sprite2D.new()
	visual.texture = ART.WIZARD
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * 75 / visual.texture.get_height()
	visual.position.y = -30
	wizard.add_child(visual)
	room.add_child(wizard)
	camera = Camera2D.new()
	add_child(camera)
	camera.position.y = -60
	hud = CanvasLayer.new()
	add_child(hud)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ui)
	preload("res://scripts/GameplayReadability.gd").apply_theme(ui)
	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	ui.add_child(label)
	preload("res://scripts/BuildVersion.gd").attach(ui)
	get_viewport().size_changed.connect(fit_camera)
	fit_camera()
	update_ring()
	update_prompt()
	AudioManager.play_music(AudioManager.SoundType.MUSIC_MENU, true, 1.0)

func add_prop(index: int, at: Vector2, width: float, collision_size: Vector2):
	var prop = StaticBody2D.new()
	prop.position = at
	prop.collision_layer = 32
	prop.collision_mask = 0
	var shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = collision_size * 2
	shape.shape = rectangle
	prop.add_child(shape)
	var art = ART.sprite(index, width)
	art.position.y = -art.texture.get_height() * art.scale.y / 2 + 10
	prop.add_child(art)
	prop.z_index = int(at.y + 400)
	room.add_child(prop)
	obstacles.append({"position": at, "size": collision_size})

func fit_camera():
	var viewport = get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(viewport.x / 1220.0, viewport.y / 960.0)
	if is_instance_valid(ui):
		preload("res://scripts/GameplayReadability.gd").fit_root(ui)
		label.position = Vector2(16, ui.size.y - 125)
		label.size = Vector2(ui.size.x - 32, 80)

func _physics_process(delta):
	if transitioning or is_instance_valid(archive):
		return
	if not settled():
		angle = move_toward(angle, target_angle, delta * 1.9)
		update_ring()
	if not orb_active:
		var motion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		motion += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		move_wizard(motion.limit_length(), delta)
	if not orb_active and settled() and selected == 0 and wizard.position.y < -298 and absf(wizard.position.x) < 48:
		depart()
	update_prompt()

func depart():
	if transitioning or selected != 0 or not settled():
		return
	transitioning = true
	SceneManager.goto_scene("res://scenes/Game.tscn")

func move_wizard(direction: Vector2, _delta: float):
	var before = wizard.position
	wizard.velocity = direction * SPEED
	wizard.move_and_slide()
	if selected == 0 and settled() and before.y < 0 and (before / Vector2(370,245)).length() > 1 and absf(before.x) <= 48:
		wizard.position.x = clampf(wizard.position.x, -47.9, 47.9)
	var normalized = wizard.position / Vector2(370, 245)
	var exit_corridor = selected == 0 and settled() and absf(wizard.position.x) < 48 and wizard.position.y < 0
	if normalized.length() > 1 and not exit_corridor:
		wizard.position = normalized.normalized() * Vector2(370, 245)
	wizard.z_index = int(wizard.position.y + 400)

func update_ring():
	masonry.angle = angle
	masonry.queue_redraw()
	for i in PORTAL_COUNT:
		var phase = i * STEP + angle
		var point = Vector2(sin(phase), -cos(phase)) * RADIUS
		var portal = arches[i]
		portal.position = point
		portal.z_index = int(point.y + 400)
		var view = 3 if point.y > 60 else (1 if point.x < -100 else (2 if point.x > 100 else 0))
		var sprite = portal.get_node("Arch")
		sprite.texture = ART.texture((8 if i == 0 else 4) + view)
		sprite.scale = Vector2.ONE * 170 / sprite.texture.get_width()
		sprite.position.y = -sprite.texture.get_height() * sprite.scale.y / 2 + 10

	selected = posmod(roundi(-angle / STEP), PORTAL_COUNT)

func settled() -> bool:
	return is_equal_approx(angle, target_angle)

func turn(direction: int):
	if orb_active and settled():
		target_angle += direction * STEP

func interact():
	if transitioning or is_instance_valid(archive):
		return
	if orb_active:
		if settled():
			orb_active = false
	elif wizard.position.distance_to(Vector2.ZERO) < 95:
		orb_active = true
	elif wizard.position.distance_to(tome_position) < 85:
		open_archive()

	update_prompt()

func open_archive():
	archive = preload("res://scripts/SpellCollection.gd").new()
	hud.add_child(archive)
	archive.closed.connect(func(): archive = null)

func update_prompt():
	if orb_active:
		label.text = "Turn: Left / Right   ·   E: Leave orb\n" + ("WOODLAND · Level 1" if selected == 0 else "Sealed doorway")
	elif wizard.position.distance_to(Vector2.ZERO) < 95:
		label.text = "E · Turn the tower"
	elif wizard.position.distance_to(tome_position) < 85:
		label.text = "E · Necronomicon"
	elif wizard.position.distance_to(Vector2(0, -280)) < 75:
		label.text = "Walk through · Woodland" if selected == 0 and settled() else "Sealed doorway"
	else:
		label.text = ""

func _unhandled_key_input(event):
	if not event.pressed or event.echo or is_instance_valid(archive) or transitioning:
		return
	var viewport = get_viewport()
	if event.keycode == KEY_E:
		interact()
	elif orb_active and event.keycode in [KEY_LEFT, KEY_A]:
		turn(1)
	elif orb_active and event.keycode in [KEY_RIGHT, KEY_D]:
		turn(-1)
	elif event.keycode == KEY_ESCAPE:
		if orb_active:
			if settled(): orb_active = false
		else:
			SceneManager.goto_scene("res://scenes/MainMenu.tscn")
	else:
		return
	viewport.set_input_as_handled()
