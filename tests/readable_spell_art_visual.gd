extends SceneTree

var checks = 0
var failures = 0
var stage: Node2D
var known_bad = false

class ArtCanvas extends Node2D:
	var known_bad = false
	func _draw():
		var art = preload("res://scripts/EffectArt.gd")
		draw_rect(Rect2(0, 0, 1200, 800), Color("26382d"))
		for row in range(2):
			for column in range(3):
				draw_rect(Rect2(column * 400 + 8, row * 400 + 8, 384, 384), Color("314335"))
		art.stamp(self, "bolt", Vector2(140, 130), Vector2(42, 36))
		art.stamp(self, "mana", Vector2(240, 130), Vector2(40, 34))
		art.stamp(self, "impact" if not known_bad else "heal", Vector2(100, 265), Vector2.ONE * 38)
		art.stamp(self, "heal", Vector2(200, 265), Vector2.ONE * 38)
		art.stamp(self, "shard", Vector2(300, 265), Vector2.ONE * 38)

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	known_bad = "--known-bad-healing-impact" in OS.get_cmdline_user_args()
	run.call_deferred()

func check(value, message):
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func label_at(text, point):
	var label = Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", 19)
	stage.add_child(label)

func projectile(kind, point, radius = 0.0, progress = 0.0):
	var node = preload("res://scenes/SpellProjectile.tscn").instantiate()
	stage.add_child(node)
	node.setup_effect(point, Color.WHITE, kind, 1)
	node.effect_radius = radius
	node.lifetime_timer = 1 - progress
	node.set_process(false)
	return node

func run():
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	root.position = Vector2i(5000, 5000)
	root.size = Vector2i(1200, 800)
	root.content_scale_size = Vector2i(1200, 800)
	root.get_node("AudioManager").quitting = true
	stage = ArtCanvas.new()
	stage.known_bad = known_bad
	root.add_child(stage)
	current_scene = stage
	label_at("BOLT / MANA BOLT", Vector2(28, 25))
	label_at("Damage       Heal       Slow / ice", Vector2(40, 310))
	label_at("STEAM FIELD · DAMAGE + SLOW", Vector2(425, 25))
	label_at("LIGHTNING", Vector2(828, 25))
	label_at("METEOR · WARNING / DESCENT", Vector2(25, 425))
	label_at("METEOR · IMPACT", Vector2(425, 425))
	label_at("PLAGUE SEED · SPREAD", Vector2(825, 425))
	var player = Node2D.new()
	stage.add_child(player)
	var steam = preload("res://scripts/BuildSpellEffect.gd").new()
	stage.add_child(steam)
	steam.configure({"type": "field", "radius": 132, "slow": 0.4}, 0, player, null)
	steam.position = Vector2(600, 230)
	steam.elapsed_time = 0.6
	steam.set_physics_process(false)
	var lightning = preload("res://scripts/LightningArea.gd").new()
	lightning.configure(Vector2(1000, 240), {"radius": 130}, 0, player)
	stage.add_child(lightning)
	lightning.set_physics_process(false)
	projectile("warning", Vector2(200, 645), 120, 0.68)
	projectile("meteor", Vector2(600, 640), 130, 0.45)
	var plague = preload("res://scripts/BuildSpellEffect.gd").new()
	stage.add_child(plague)
	plague.configure({"type": "plague"}, 0, player, null)
	plague.infection_links = [{"from": Vector2(860, 640), "position": Vector2(980, 585)}, {"from": Vector2(980, 585), "position": Vector2(1100, 670)}]
	plague.set_physics_process(false)
	for point in [Vector2(100, 172), Vector2(480, 260), Vector2(910, 280), Vector2(860, 650), Vector2(980, 595), Vector2(1100, 680)]:
		var wizard = Sprite2D.new()
		wizard.texture = preload("res://assets/typecast/Main Character/Wizard 2.0.png")
		wizard.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wizard.position = point
		wizard.scale = Vector2.ONE * 2
		stage.add_child(wizard)
	await process_frame
	await RenderingServer.frame_post_draw
	var capture = root.get_texture().get_image()
	var art = preload("res://scripts/EffectArt.gd")
	check(art.PARTICLE_STAMPS.get_width() <= 128, "Particle atlas import stays bounded to 128 pixels")
	var texture_image = art.PARTICLE_STAMPS.get_image()
	check(texture_image.get_pixel(0, 0).a == 0, "Particle atlas preserves transparent background")
	var warm_impact_pixels = 0
	var bolt_body_pixels = 0
	for y in range(248, 283):
		for x in range(83, 118):
			var color = capture.get_pixel(x, y)
			if color.r > color.g and color.r > 0.6:
				warm_impact_pixels += 1
	for y in range(116, 144):
		for x in range(124, 156):
			var color = capture.get_pixel(x, y)
			if color.r > 0.65 and color.g > 0.5:
				bolt_body_pixels += 1
	check(warm_impact_pixels > 70, "Damage flash has a warm solid silhouette, never a green healing cross")
	check(bolt_body_pixels > 280, "Bolt has a substantial filled body at gameplay scale")
	DirAccess.make_dir_recursive_absolute("res://builds/evidence")
	capture.save_png("res://builds/evidence/readable-spell-art" + ("-negative" if known_bad else "") + ".png")
	print("Readable spell art: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
