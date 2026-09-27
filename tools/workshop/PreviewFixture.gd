extends RefCounted

const RECIPES = preload("res://scripts/SynergyCatalog.gd").RECIPES
const ART = "res://assets/typecast/"
var game
var tree: SceneTree
var selected = "bolt"
var elapsed = 0.0
var duration = 2.0
var scenery: Node2D
var targets: Array = []
var settings = {"wizard": 1.0, "enemy": 1.0, "enemy_sizes": {}, "tree": 1.0, "bush": 1.0, "projectile": 1.0, "particle": 1.0, "zoom": 1.5, "variant": "pursuer", "comparison": false, "scenery": true}

func catalog() -> Array:
	var result = [{"id": "mana_bolt", "name": "Mana Bolt", "group": "Spells", "bonus": false}]
	var data = tree.root.get_node("DataManager")
	for id in game.spell_manager.BASE_SPELL_IDS:
		result.append({"id": id, "name": data.get_spell_data(id).get("name", id), "group": "Spells", "bonus": false})
	for id in RECIPES:
		if RECIPES[id].get("enabled", true):
			result.append({"id": id, "name": RECIPES[id].name, "group": "Spells", "bonus": true})
	for method in game.particle_manager.get_method_list():
		if method.name.begins_with("create_") and method.name != "create_tween":
			result.append({"id": method.name, "name": method.name.trim_prefix("create_").replace("_", " ").capitalize(), "group": "Particles", "bonus": false})
	return result

func setup(parent: Node, id: String):
	tree = parent.get_tree()
	if is_instance_valid(game):
		game.free()
	selected = id
	elapsed = 0.0
	seed(41)
	game = load("res://scenes/Game.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	parent.add_child(game)
	await tree.process_frame
	game.set_process(false)
	game.get_node("UI").hide()
	game.get_node("PauseInput").set_process_unhandled_input(false)
	game.spell_manager.set_process(false)
	game.spell_manager.set_process_input(false)
	game.spell_manager.set_process_unhandled_input(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	game.player.health = 30
	game.camera_shake.set_process(false)
	game.camera.position = game.player.position + Vector2(160, 0)
	game.camera.reset_smoothing()
	game.camera.force_update_scroll()
	game.chest_manager.set_process(false)
	var manager = game.get_node("MonsterManager")
	manager.set_process(false)
	manager.spawn_timer.stop()
	var background = game.get_node("Background")
	background.set_process(false)
	for holder in background.decorations.values():
		holder.hide()
	targets.clear()
	var variants = manager.encounter_config.variants
	var offsets = [Vector2(210, 0), Vector2(285, 0), Vector2(300, -85), Vector2(300, 85)]
	var ids = variants.keys() if settings.comparison else [settings.variant]
	for index in range(ids.size() if settings.comparison else offsets.size()):
		var variant = ids[index % ids.size()]
		var definition = variants[variant].duplicate(true)
		definition.id = variant
		var enemy = manager.spawn_monster(definition, false, true)
		enemy.global_position = game.player.global_position + (Vector2(170 + (index % 4) * 100, -150 + (index / 4) * 120) if settings.comparison else offsets[index])
		enemy.current_health = 10000
		enemy.max_health = 10000
		enemy.set_physics_process(false)
		enemy.get_node("HealthBar").hide()
		if settings.comparison:
			var label = Label.new()
			label.text = definition.name
			label.position = Vector2(-45, 40) / enemy.scale
			label.scale = Vector2.ONE / enemy.scale
			label.add_theme_font_size_override("font_size", 12)
			enemy.add_child(label)
		targets.append(enemy)
	scenery = Node2D.new()
	game.add_child(scenery)
	for index in range(2):
		var sprite = Sprite2D.new()
		sprite.name = "Tree" if index == 0 else "Bush"
		sprite.texture = load(ART + ("Level Tiles/Level Deco/Fir Tree 1 shaded.png" if index == 0 else "Level Tiles/Level Deco/Bush v1.png"))
		sprite.position = game.player.position + (Vector2(-150, 30) if index == 0 else Vector2(-100, 150))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2.ONE * 2
		scenery.add_child(sprite)
	await tree.process_frame
	apply_sizes()
	cast()

func cast():
	var manager = game.spell_manager
	if selected.begins_with("create_"):
		particle(selected)
		duration = 1.0
		for effect in game.particle_manager.get_children():
			duration = maxf(duration, effect.duration + 0.3)
	elif selected == "mana_bolt":
		manager.fire_mana_bolt()
		duration = 2.0
	else:
		if RECIPES.has(selected):
			for ingredient in RECIPES[selected].ingredients:
				var learned = manager.learn_spell(ingredient)
				if not learned and ingredient != "bolt":
					push_error("Preview could not learn ingredient " + ingredient)
					return
		var learned = manager.learn_spell(selected)
		if not learned and selected != "bolt":
			push_error("Preview could not learn spell " + selected)
			return
		var slot = manager.find_spell_slot(selected)
		var info = manager.get_spell_info(slot)
		duration = maxf(2.0, float(info.get("duration", 0.0)) + 0.8)
		if selected == "ember_trail":
			duration = 12.8
		if selected == "life_bolt":
			duration = 11.0
		if not manager.cast_spell_by_type(slot):
			push_error("Preview could not cast " + selected)

func particle(method: String):
	var origin = game.player.global_position + Vector2(120, 0)
	var args = [origin]
	match method:
		"create_spell_effect": args = [origin, "mana"]
		"create_directional_effect": args = [origin, Vector2.RIGHT, "ice", 160.0, 0.6]
		"create_link_effect": args = [origin, origin + Vector2(150, 0), "lightning"]
		"create_persistent_life_circle", "create_persistent_shield_circle":
			game.player.overheal = 20
			args = [game.player, 2.0]
		"create_persistent_lightning_arc": args = [game.player, origin + Vector2(150, 0), 1.0]
		"create_expanding_circle": args = [origin, 100.0, Color.ORANGE, 1.0]
		"create_powerful_spell_effect": args = [origin, "meteor shower"]
		"create_elite_spawn_effect": args = [origin, "elite"]
		"create_attack_warning": args = [origin, 95.0, 1.0]
		"create_aoe_telegraph": args = [origin, 220.0, 1.0]
		"create_projectile_warning": args = [origin, origin + Vector2(150, 0), 1.0]
	game.particle_manager.callv(method, args)

func advance(delta: float):
	elapsed += delta
	game.spell_manager.process_healing_effects(delta)
	if selected == "ember_trail" and elapsed < 4.5:
		game.player.position.x += delta * 50.0
	apply_sizes()

func scaled(node: Node2D, multiplier: float):
	if not node.has_meta("preview_original_scale"):
		node.set_meta("preview_original_scale", node.scale)
	node.scale = node.get_meta("preview_original_scale") * multiplier

func apply_sizes():
	game.camera.zoom = Vector2.ONE * settings.zoom
	scaled(game.player.get_node("Sprite2D"), settings.wizard)
	for enemy in targets:
		if is_instance_valid(enemy):
			scaled(enemy.get_node("Sprite2D"), settings.enemy_sizes.get(enemy.variant, settings.enemy if not settings.comparison else 1.0))
	scenery.visible = settings.scenery
	scaled(scenery.get_node("Tree"), settings.tree)
	scaled(scenery.get_node("Bush"), settings.bush)
	for projectile in tree.get_nodes_in_group("spell_projectiles"):
		scaled(projectile, settings.projectile)
		for shape in projectile.find_children("*", "CollisionShape2D", true, false):
			shape.scale = Vector2.ONE / settings.projectile
	for effect in tree.get_nodes_in_group("effect_bursts"):
		if not effect.has_meta("preview_original_particle"):
			effect.set_meta("preview_original_particle", effect.particle_size)
		effect.particle_size = effect.get_meta("preview_original_particle") * settings.particle
		effect.queue_redraw()
