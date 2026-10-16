extends Node
## Training Grounds: a safe Game-scene mode with infinite-HP dummies, a free spell
## loadout with rank control, and a live damage readout. Nothing here touches score,
## progression, discoveries or the leaderboard.

const SpellManagerScript = preload("res://scripts/SpellManager.gd")
static var RECIPES: Dictionary = preload("res://scripts/SynergyCatalog.gd").RECIPES  # data/recipes.json
const READABILITY = preload("res://scripts/GameplayReadability.gd")
const DUMMY_HEALTH = 1.0e12
const MAX_RANK = 8
const CLUSTER_SIZE = 10
## Dummies "die" (playtest 0.3.4: unkillable slimes looked broken): after POP_DAMAGE damage a dummy
## bursts like a real kill and pops back at its spot a moment later. Their health is still huge
## underneath, so damage readouts, statuses and knockback are measured exactly as before.
const POP_DAMAGE = 300.0
const POP_RESPAWN = 0.6

var game: Node
var equipped: Array[String] = []
var combos: Array[String] = []
var ranks: Dictionary = {}
var static_dummies: Array = []
var cluster: Array = []
var cluster_offsets: Array[Vector2] = []
var center := Vector2.ZERO
var path_time := 0.0
var history: Array = []
var sample_timer := 0.0
var panel: PanelContainer
var rows: VBoxContainer
var readout: Label
var row_widgets: Dictionary = {}

## Everything the Necronomicon lists. When discovery gating arrives, filter this list.
static func available_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in SpellManagerScript.BASE_SPELL_IDS:
		ids.append(id)
	for id in RECIPES:
		if RECIPES[id].get("enabled", true):
			ids.append(id)
	return ids

func _ready():
	name = "TrainingGrounds"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var monsters = game.get_node("MonsterManager")
	monsters.spawn_timer.stop()
	monsters.set_process(false)
	if is_instance_valid(game.chest_manager):
		game.chest_manager.set_process(false)
	game.player.is_invincible = true
	game.style_session.exclude("Training")
	center = game.player.global_position
	# Every spell is equipped at once: 1-6 cast the first six, Space casts anything by name.
	game.spell_manager.slot_limit = 99
	for id in available_ids():
		ranks[id] = 1
		if RECIPES.has(id):
			combos.append(id)
		else:
			equipped.append(id)
	apply_loadout()
	build_panel()
	spawn_dummies.call_deferred()
	game.show_gameplay_feedback("Training Grounds · Tab hides the spell bench")

func make_dummy(at: Vector2):
	var monsters = game.get_node("MonsterManager")
	var dummy = monsters.spawn_monster(monsters.get_available_variants(0)[0], false, true)
	if not is_instance_valid(dummy):
		return null
	dummy.global_position = at
	# Physics stays on so slows, knockback and their tints play out; the dummy walks home.
	dummy.training_anchor = at
	dummy.collision_mask = 0
	dummy.max_health = DUMMY_HEALTH
	dummy.current_health = DUMMY_HEALTH
	dummy.base_damage = 0.0
	dummy.collision_mask = 2   # dummies keep apart instead of stacking into one magnified blob
	dummy.normal_collision_mask = 2
	dummy.set_meta("training_dummy", true)
	dummy.add_to_group("training_dummies")
	if dummy.has_node("HealthBar"):
		dummy.get_node("HealthBar").show()   # the pop-progress bar is always visible
	return dummy

## Health bar shows progress toward the next pop; a popped dummy bursts, hides, then returns.
func update_pops(delta: float) -> void:
	for dummy in static_dummies + cluster:
		if not is_instance_valid(dummy) or dummy.dying:
			continue
		var hidden_for = float(dummy.get_meta("pop_hidden", 0.0))
		if hidden_for > 0.0:
			hidden_for -= delta
			dummy.set_meta("pop_hidden", hidden_for)
			if hidden_for <= 0.0:
				dummy.global_position = dummy.training_anchor
				dummy.current_health = DUMMY_HEALTH
				dummy.visible = true
				dummy.get_node("HurtBox").set_deferred("monitorable", true)
				dummy.remove_from_group("training_popped")
				dummy.add_to_group("enemies")
			continue
		var taken = DUMMY_HEALTH - dummy.current_health
		var fill = dummy.get_node_or_null("HealthBar/Fill")
		if fill:
			fill.scale.x = clampf(1.0 - taken / POP_DAMAGE, 0.0, 1.0)
		if taken >= POP_DAMAGE:
			if game.has_method("create_enemy_death_effect"):
				game.create_enemy_death_effect(dummy.global_position, false)
			if AudioManager:
				AudioManager.on_enemy_death()
			dummy.visible = false
			dummy.remove_from_group("enemies")   # spells stop targeting it while it is gone
			dummy.add_to_group("training_popped")
			dummy.get_node("HurtBox").set_deferred("monitorable", false)
			dummy.set_meta("pop_hidden", POP_RESPAWN)
			dummy.current_health = DUMMY_HEALTH

func spawn_dummies():
	for dummy in static_dummies + cluster:
		if is_instance_valid(dummy):
			dummy.queue_free()
	static_dummies.clear()
	cluster.clear()
	cluster_offsets.clear()
	# One single target and a tight trio for area spells.
	for offset in [Vector2(230, 0), Vector2(-230, -60), Vector2(-290, 0), Vector2(-230, 60)]:
		var dummy = make_dummy(center + offset)
		if dummy:
			static_dummies.append(dummy)
	# A loose moving blob that drifts on a figure-eight around the arena.
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	for i in CLUSTER_SIZE:
		cluster_offsets.append(Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 110.0)
		var dummy = make_dummy(cluster_point(0.0) + cluster_offsets[i])
		cluster.append(dummy)

func cluster_point(t: float) -> Vector2:
	return center + Vector2(360.0 * sin(t * 0.32), 170.0 * sin(t * 0.64) - 40.0)

func _process(delta):
	layout()
	if game.current_state != game.GameState.PLAYING:
		return
	path_time += delta
	var anchor = cluster_point(path_time)
	for i in cluster.size():
		var dummy = cluster[i]
		if is_instance_valid(dummy):
			var wobble = Vector2(sin(path_time * 1.7 + i), cos(path_time * 1.3 + i * 0.7)) * 10.0
			dummy.training_anchor = anchor + cluster_offsets[i] + wobble
	update_pops(delta)
	for dummy in static_dummies + cluster:
		if is_instance_valid(dummy) and dummy.current_health < DUMMY_HEALTH * 0.5:
			dummy.current_health = DUMMY_HEALTH
	# Atomic or a console kill can remove dummies; bring the set back.
	if (static_dummies + cluster).any(func(d): return not is_instance_valid(d) or d.is_queued_for_deletion() or d.dying):
		spawn_dummies()
	sample_timer -= delta
	if sample_timer <= 0.0:
		sample_timer = 0.25
		sample()

func total_damage() -> float:
	var total = 0.0
	for value in game.style_session.damage_by_spell.values():
		total += float(value)
	return total

func sample():
	var clock = float(game.style_session.clock)
	var total = total_damage()
	history.append([clock, total])
	while history.size() > 1 and clock - float(history[0][0]) > 5.0:
		history.pop_front()
	var window = maxf(0.25, clock - float(history[0][0]))
	var recent = (total - float(history[0][1])) / window
	var lines: Array[String] = ["Last 5s: %d damage/s" % int(round(recent)), "Total: %d" % int(round(total))]
	var totals = game.style_session.damage_by_spell
	var ids = totals.keys()
	ids.sort_custom(func(a, b): return float(totals[a]) > float(totals[b]))
	for id in ids.slice(0, 6):
		lines.append("%s  %d" % [spell_name(id), int(round(float(totals[id])))])
	readout.text = "\n".join(lines)

func reset_damage():
	game.style_session.damage_by_spell.clear()
	history.clear()
	sample()

func spell_name(id: String) -> String:
	if id == "mana_bolt":
		return "Magic Missile"
	if RECIPES.has(id):
		return str(RECIPES[id].name)
	var data = get_tree().root.get_node("DataManager").get_spell_data(id)
	return str(data.get("name", id))

## Rebuilds the run's spells from the bench: every base spell switched on, plus any
## combination whose ingredients are both on. Discoveries are not recorded.
func apply_loadout():
	var manager = game.spell_manager
	if manager.is_typing:
		manager.cancel_typing()
	manager.spells.clear()
	manager.bonus_spells.clear()
	manager.acquired_spells.clear()
	for id in equipped:
		if manager.learn_spell(id):
			manager.get_spell_info(manager.find_spell_slot(id)).level = int(ranks[id])
	combos = combos.filter(func(id): return RECIPES[id].ingredients.all(func(part): return part in equipped))
	for id in combos:
		if manager.learn_spell(id, false):
			manager.get_spell_info(manager.find_spell_slot(id)).level = int(ranks[id])
	manager.rebuild_freeform_library()
	game.update_spell_slot_lock_status()
	refresh_rows()

func toggle(id: String):
	if RECIPES.has(id):
		if id in combos:
			combos.erase(id)
		elif RECIPES[id].ingredients.all(func(part): return part in equipped):
			combos.append(id)
	elif id in equipped:
		equipped.erase(id)
	else:
		equipped.append(id)
	apply_loadout()

func change_rank(id: String, step: int):
	ranks[id] = clampi(int(ranks[id]) + step, 1, MAX_RANK)
	apply_loadout()

func build_panel():
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	panel = PanelContainer.new()
	panel.name = "TrainingBench"
	panel.add_theme_stylebox_override("panel", READABILITY.panel_style(READABILITY.GOLD))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var title = Label.new()
	title.text = "TRAINING GROUNDS"
	title.add_theme_color_override("font_color", READABILITY.GOLD)
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	readout = Label.new()
	readout.name = "DamageReadout"
	readout.add_theme_font_size_override("font_size", 15)
	column.add_child(readout)
	var actions = HBoxContainer.new()
	column.add_child(actions)
	actions.add_child(small_button("Reset damage", reset_damage))
	actions.add_child(small_button("Return home", return_home))
	var hint = Label.new()
	hint.text = "All spells are on. Space, then type any name; 1-6 cast the first six. Click a name to switch it off."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", READABILITY.MUTED)
	column.add_child(hint)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for id in available_ids():
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var pick = small_button(spell_name(id), toggle.bind(id))
		pick.name = "Pick_" + id
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(pick)
		row.add_child(small_button("−", change_rank.bind(id, -1)))
		var rank = Label.new()
		rank.custom_minimum_size.x = 26
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.add_theme_font_size_override("font_size", 14)
		row.add_child(rank)
		row.add_child(small_button("+", change_rank.bind(id, 1)))
		rows.add_child(row)
		row_widgets[id] = {"pick": pick, "rank": rank}
	get_window().size_changed.connect(layout)
	layout()
	refresh_rows()
	sample()

func small_button(text: String, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(action)
	return button

func layout():
	if not is_instance_valid(panel):
		return
	# Right edge, below the style meter and above the casting reference.
	var view = get_viewport().get_visible_rect().size
	var style = game.hud.get_node_or_null("StyleHUD")
	var top = 200.0
	if style:
		top = maxf(top, style.get_global_rect().end.y + 30.0)
	panel.size = Vector2(minf(300, view.x * 0.4), maxf(220, view.y - top - 110))
	panel.position = Vector2(view.x - panel.size.x - 12, top)

func refresh_rows():
	for id in row_widgets:
		var widgets = row_widgets[id]
		var on = id in equipped or id in combos
		var usable = not RECIPES.has(id) or RECIPES[id].ingredients.all(func(part): return part in equipped)
		widgets.pick.text = ("● " if on else "○ ") + spell_name(id)
		widgets.pick.modulate = Color.WHITE if on else (Color(1, 1, 1, 0.75) if usable else Color(1, 1, 1, 0.35))
		widgets.rank.text = str(ranks[id])

func _unhandled_key_input(event):
	if event.pressed and not event.echo and event.keycode == KEY_TAB and not game.spell_manager.is_typing:
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()

func return_home():
	preload("res://scripts/RunMode.gd").training = false
	game.get_tree().paused = false
	Engine.time_scale = 1.0
	SceneManager.goto_scene("res://scenes/Tower.tscn")
