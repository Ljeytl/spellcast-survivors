extends Node
## In-game VFX showcase (dev tool, not shipped): the real Game scene with every shipping spell cast
## in turn by the real SpellManager, so the VFX layer is seen exactly as in play.
## Space / Right: next spell · Left: previous · P: pause the cycle · M: MEGA next cast · K: clear enemies.
## URL ?spell=<id> starts on that spell; &words=fiery+double casts with keywords (+ is a space).

const CYCLE := 2.6
const HORDE := 14

var game
var manager
var monsters
var order: Array = []
var index := 0
var timer := 0.0
var paused := false
var mega := false
var locked := false               # ?spell=<id>: keep recasting that one spell
var words := ""                    # ?words=fiery+double: cast every spell with these keywords
var label: Label
var walk_t := 0.0
var horde := HORDE
var home := Vector2.ZERO
var previous_spirit_form := "auto"
var previous_time_scale := 1.0

func _ready():
	previous_time_scale = Engine.time_scale
	previous_spirit_form = get_node("/root/Vfx").spirit_form_override
	game = load("res://scenes/Game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = game
	manager = game.spell_manager
	monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	monsters.set_process(false)
	game.player.is_invincible = true
	game.player.set_physics_process(false)   # the showcase walks the wizard itself
	home = game.player.global_position
	order = manager.BASE_SPELL_IDS.duplicate()
	for id in preload("res://scripts/SynergyCatalog.gd").RECIPES:
		if preload("res://scripts/SynergyCatalog.gd").RECIPES[id].get("enabled", true):
			order.append(id)
	for bare in preload("res://scripts/engine/SpellDefs.gd").bare_incantations():
		if not order.has(bare):
			order.append(bare)
	if OS.has_feature("web"):
		var form = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('form') || 'auto'"))
		if form in ["auto", "ghost", "wisp"]:
			get_node("/root/Vfx").spirit_form_override = form
		var wanted = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('spell') || ''"))
		if order.has(wanted):
			index = order.find(wanted)
			locked = true
		mega = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('mega') || ''")) != ""
		words = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('words') || ''")).strip_edges()
		if str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('empty') || ''")) != "":
			horde = 0
		var slow = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('slow') || ''"))
		if slow != "":
			Engine.time_scale = clampf(float(slow), 0.05, 1.0)
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	label = Label.new()
	label.position = Vector2(12, 8)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	timer = 0.4

func _process(delta: float):
	if manager == null:
		return
	# The wizard strolls a slow circle so trails (Fire Walk) and following effects read.
	walk_t += delta * 0.6
	game.player.global_position = home + Vector2(cos(walk_t), sin(walk_t) * 0.6) * 70.0
	game.player.xp = 0.0
	game.player.xp_to_next_level = 1e12   # no level-up screens in the showcase
	_top_up()
	if paused:
		_label()
		return
	timer -= delta
	if timer <= 0.0:
		timer = CYCLE
		_cast(order[index])
		if not locked:
			index = (index + 1) % order.size()
	_label()

func _label():
	var current = order[index] if locked else order[(index - 1 + order.size()) % order.size()]
	label.text = "VFX SHOWCASE (real game)   now: %s%s   next: %s\nSpace/Right next · Left back · P %s · M MEGA next · S slow-mo · K defeat enemies\nG spirit form: %s (applies to Seeker and Soul Bloom)" % [
		current, (" (MEGA)" if mega else "") + ((" [" + words + "]") if words != "" else ""), order[index], "resume" if paused else "pause", get_node("/root/Vfx").spirit_form_override]

func _cast(id: String):
	var recipes = preload("res://scripts/SynergyCatalog.gd").RECIPES
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	if recipes.has(id):
		for ingredient in recipes[id].ingredients:
			manager.learn_spell(ingredient)
			manager.get_spell_info(manager.find_spell_slot(ingredient)).level = manager.COMBINATION_RANK
	if preload("res://scripts/engine/SpellDefs.gd").bare_incantations().has(id):
		manager.last_spell_cast_time = -1e9
		manager.cast_keyword_spell((("mega " if mega and not "mega" in words.split(" ") else "") + words + " " + id).strip_edges())
		return
	manager.learn_spell(id)
	var slot = manager.find_spell_slot(id)
	if slot < 0:
		return
	if words != "":
		manager.last_spell_cast_time = -1e9
		manager.cast_keyword_spell(("mega " if mega and not "mega" in words.split(" ") else "") + words + " " + str(manager.get_spell_info(slot).display_name).to_lower())
	else:
		manager.cast_spell_by_type(slot, 1.5 if mega else 1.0)
	if id == "earth_shield":
		_block_later()

## Earth Shield only shows its eruption when something hits the wizard: poke it once.
func _block_later():
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(game) and is_instance_valid(game.player.earth_shield):
		game.player.earth_shield.block({"source_position": game.player.global_position + Vector2(140, -20)})

func _top_up():
	var alive = get_tree().get_nodes_in_group("enemies").filter(func(e): return is_instance_valid(e) and not e.get("dying"))
	for i in range(alive.size(), horde):
		var enemy = monsters.spawn_monster(monsters.get_available_variants(0)[0])
		if enemy == null:
			return
		var a = randf_range(-0.9, 0.9) + (PI if randf() < 0.3 else 0.0)
		enemy.global_position = game.player.global_position + Vector2.from_angle(a) * randf_range(170.0, 330.0)
		enemy.max_health = 120
		enemy.current_health = 120
		enemy.base_speed = 14.0       # a slow creep keeps the horde in view instead of on the wizard
		enemy.speed = 14.0

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_SPACE, KEY_RIGHT:
			if locked:
				index = (index + 1) % order.size()
			timer = 0.0
			paused = false
		KEY_LEFT:
			index = (index - 2 + order.size() * 2) % order.size()
			timer = 0.0
		KEY_P:
			paused = not paused
		KEY_M:
			mega = not mega
		KEY_S:
			Engine.time_scale = 0.25 if Engine.time_scale > 0.5 else 1.0
		KEY_G:
			var forms := ["auto", "ghost", "wisp"]
			var vfx = get_node("/root/Vfx")
			vfx.spirit_form_override = forms[(forms.find(vfx.spirit_form_override) + 1) % forms.size()]
		KEY_K:
			for e in get_tree().get_nodes_in_group("enemies"):
				if not e.dying:
					e.take_damage(e.current_health + 1.0, game.player.global_position, {"spell": "showcase", "cast_id": 0})

func _exit_tree():
	Engine.time_scale = previous_time_scale
	var vfx = get_node_or_null("/root/Vfx")
	if vfx != null:
		vfx.spirit_form_override = previous_spirit_form
