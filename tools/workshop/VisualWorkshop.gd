extends Node

const Fixture = preload("res://tools/workshop/PreviewFixture.gd")
var fixture = Fixture.new()
var bridge
var busy = false
var looping = true
var playing = true
var time_scale = 1.0
var selected = "bolt"
var report_time = 0.0
var rebuild_requested = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
		push_error("Workshop requires its isolated profile")
		get_tree().quit(2)
		return
	get_tree().root.get_node("AudioManager").quitting = true
	if OS.has_feature("web"):
		bridge = JavaScriptBridge.create_callback(command)
		JavaScriptBridge.get_interface("window").workshopCommand = bridge
	await replay()
	publish("ready", {"catalog": fixture.catalog(), "variants": fixture.game.get_node("MonsterManager").encounter_config.variants, "settings": fixture.settings})

func replay():
	busy = true
	rebuild_requested = false
	get_tree().paused = false
	Engine.time_scale = time_scale
	await fixture.setup(self, selected)
	busy = false
	if rebuild_requested or selected != fixture.selected:
		replay()
		return
	get_tree().paused = not playing
	Engine.time_scale = time_scale if playing else 0.0
	publish("state", state())

func _process(delta):
	if busy or not is_instance_valid(fixture.game):
		return
	if playing:
		fixture.advance(delta)
		if fixture.elapsed >= fixture.duration:
			if looping:
				replay()
			else:
				playing = false
				get_tree().paused = true
				Engine.time_scale = 0.0
	report_time += delta
	if report_time >= 0.1:
		report_time = 0
		publish("state", state())

func state() -> Dictionary:
	var hits = fixture.targets.filter(func(target): return is_instance_valid(target) and target.current_health < 10000).size()
	return {"targets_hit": hits, "active_effects": get_tree().get_nodes_in_group("effect_bursts").size() + get_tree().get_nodes_in_group("projectile_visuals").size(), "id": selected, "time": fixture.elapsed, "duration": fixture.duration, "playing": playing, "busy": busy, "settings": fixture.settings, "speed": time_scale}

func command(arguments: Array):
	if arguments.is_empty():
		return
	var request = JSON.parse_string(str(arguments[0]))
	if not request is Dictionary:
		return
	match request.get("action", ""):
		"select":
			for entry in fixture.catalog():
				if entry.id == request.get("id"):
					selected = entry.id
					playing = true
					if not busy:
						replay()
					break
		"settings":
			var values = request.get("values", {})
			if values.has("enemy_sizes") and values.enemy_sizes is Dictionary:
				fixture.settings.enemy_sizes.clear()
				for id in values.enemy_sizes:
					if fixture.game.get_node("MonsterManager").encounter_config.variants.has(id):
						fixture.settings.enemy_sizes[id] = clampf(float(values.enemy_sizes[id]), 0.5, 3.0)
			for key in ["wizard", "enemy", "tree", "bush", "spell_size", "projectile", "particle", "zoom"]:
				if values.has(key):
					fixture.settings[key] = clampf(float(values[key]), 0.5, 3.0)
			for key in ["comparison", "scenery"]:
				if values.has(key):
					fixture.settings[key] = bool(values[key])
			if values.has("variant") and fixture.game.get_node("MonsterManager").encounter_config.variants.has(values.variant):
				fixture.settings.variant = values.variant
				fixture.settings.enemy = fixture.settings.enemy_sizes.get(values.variant, 1.0)
			if values.has("enemy"):
				fixture.settings.enemy_sizes[fixture.settings.variant] = fixture.settings.enemy
			if busy and (values.has("variant") or values.has("comparison") or values.has("spell_size")):
				rebuild_requested = true
			if not busy:
				if values.has("variant") or values.has("comparison") or values.has("spell_size"):
					replay()
				else:
					fixture.apply_sizes()
		"play":
			playing = bool(request.get("value", true))
			get_tree().paused = not playing
			Engine.time_scale = time_scale if playing else 0.0
		"replay":
			playing = true
			if not busy:
				replay()
			else:
				rebuild_requested = true
		"speed":
			time_scale = clampf(float(request.get("value", 1.0)), 0.25, 2.0)
			Engine.time_scale = time_scale if playing else 0.0
		"loop": looping = bool(request.get("value", true))
		"step":
			if not busy:
				busy = true
				playing = false
				Engine.time_scale = time_scale
				get_tree().paused = false
				await get_tree().process_frame
				await get_tree().process_frame
				fixture.advance(get_process_delta_time())
				busy = false
				if rebuild_requested or selected != fixture.selected:
					replay()
				else:
					get_tree().paused = not playing
					Engine.time_scale = time_scale if playing else 0.0
	publish("state", state())

func publish(kind: String, payload: Dictionary):
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.postMessage(" + JSON.stringify({"source": "spellcast-workshop", "kind": kind, "payload": payload}) + ", window.location.origin)")
