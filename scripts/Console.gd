extends Control

# Developer console system for SpellCast Survivors
# Toggle with ~ key, provides debugging and cheat commands

@onready var console_panel: Panel = $ConsolePanel
@onready var input_field: LineEdit = $ConsolePanel/VBox/InputField
@onready var output_label: RichTextLabel = $ConsolePanel/VBox/OutputLabel
@onready var suggestions_list: ItemList = $ConsolePanel/VBox/SuggestionsList

var is_console_open: bool = false
var console_tween: Tween
var previous_focus: WeakRef
var command_history: Array[String] = []
var history_index: int = -1
var game_node: Node2D = null
var noclip_enabled := false
var collision_snapshot := Vector2i.ZERO
var bighead_enabled := false
const UNAVAILABLE = ["disco", "matrix", "rain", "magnet", "rainbow", "explode", "army", "missile", "blackhole", "laser", "konami", "party", "giant", "tiny", "time_scale", "earthquake"]

# Available console commands
var commands: Dictionary = {
	"ui_debug": {"description": "Toggle full interface diagnostics (F3)", "usage": "ui_debug [on/off]"},
	"ui_details": {"description": "Show encounter, upgrade, spell, recipe and run details", "usage": "ui_details"},
	"help": {
		"description": "Show all available commands",
		"usage": "help [command]"
	},
	"invincibility": {
		"description": "Toggle player invincibility",
		"usage": "invincibility [on/off/toggle]"
	},
	"unlock_spells": {
		"description": "Fill empty manual spell slots (maximum six)",
		"usage": "unlock_spells"
	},
	"level_up": {
		"description": "Trigger level up screen",
		"usage": "level_up"
	},
	"add_xp": {
		"description": "Add experience points",
		"usage": "add_xp <amount>"
	},
	"heal": {
		"description": "Heal player to full health",
		"usage": "heal [amount]"
	},
	"spawn_enemy": {
		"description": "Spawn a specific enemy type",
		"usage": "spawn_enemy <type> [count]"
	},
	"difficulty": {
		"description": "Advance to minute or add seconds (no rewind)",
		"usage": "difficulty <minute/+seconds>"
	},
	"day": {
		"description": "Day cycle: jump to a day, to dusk, or straight to the boss night (run time moves forward to match)",
		"usage": "day <1-4> | day dusk | day night"
	},
	"kill_all": {
		"description": "Kill all currently spawned enemies",
		"usage": "kill_all"
	},
	"god_mode": {
		"description": "Alias for invincibility",
		"usage": "god_mode [on/off/toggle]"
	},
	"set_health": {
		"description": "Set player health",
		"usage": "set_health <amount>"
	},
	"teleport": {
		"description": "Teleport player to mouse position",
		"usage": "teleport"
	},
	"time_scale": {
		"description": "Change game time scale",
		"usage": "time_scale <multiplier>"
	},
	"clear": {
		"description": "Clear console output",
		"usage": "clear"
	},
	"noclip": {
		"description": "Toggle player collision (walk through walls)",
		"usage": "noclip [on/off/toggle]"
	},
	"speed": {
		"description": "Set player movement speed multiplier",
		"usage": "speed <multiplier>"
	},
	"damage": {
		"description": "Set Spell Power multiplier (also healing/protection)",
		"usage": "damage <multiplier>"
	},
	"spawn_chest": {
		"description": "Spawn treasure chest at mouse position",
		"usage": "spawn_chest"
	},
	"bighead": {
		"description": "Double current enemy art size; off restores original sizes",
		"usage": "bighead [on/off/toggle]"
	},
	"disco": {
		"description": "Enable disco mode (rainbow effects)",
		"usage": "disco [on/off/toggle]"
	},
	"matrix": {
		"description": "Enable matrix mode (green tint + effects)",
		"usage": "matrix [on/off/toggle]"
	},
	"earthquake": {
		"description": "Shake the screen violently",
		"usage": "earthquake [intensity] [duration]"
	},
	"rain": {
		"description": "Make it rain spell projectiles",
		"usage": "rain <spell_type> [count] [duration]"
	},
	"freeze": {
		"description": "Apply maximum slow to current enemies",
		"usage": "freeze [duration]"
	},
	"magnet": {
		"description": "Attract all enemies to player",
		"usage": "magnet [on/off/toggle]"
	},
	"giant": {
		"description": "Make player giant sized",
		"usage": "giant [scale] [duration]"
	},
	"tiny": {
		"description": "Make player tiny sized", 
		"usage": "tiny [scale] [duration]"
	},
	"rainbow": {
		"description": "Give player rainbow trail effect",
		"usage": "rainbow [on/off/toggle]"
	},
	"explode": {
		"description": "Make all enemies explode",
		"usage": "explode [damage] [radius]"
	},
	"army": {
		"description": "Spawn army of specific enemy type",
		"usage": "army <enemy_type> <count>"
	},
	"missile": {
		"description": "Launch homing missiles at all enemies",
		"usage": "missile [count] [damage]"
	},
	"blackhole": {
		"description": "Create black hole that sucks in enemies",
		"usage": "blackhole [duration] [strength]"
	},
	"laser": {
		"description": "Player shoots continuous laser beam",
		"usage": "laser [on/off/toggle] [damage]"
	},
	"thanos": {
		"description": "Snap fingers - remove half of all enemies",
		"usage": "thanos"
	},
	"konami": {
		"description": "Activate legendary cheat mode",
		"usage": "konami"
	},
	"party": {
		"description": "Throw a party! 🎉",
		"usage": "party"
	},
	"rickroll": {
		"description": "Never gonna give you up...",
		"usage": "rickroll"
	},
	"cake": {
		"description": "The cake is a lie",
		"usage": "cake"
	},
	"42": {
		"description": "Answer to life, universe, and everything",
		"usage": "42"
	},
	"rerolls": {
		"description": "Set reroll resource count",
		"usage": "rerolls <amount>"
	},
	"banishes": {
		"description": "Set banish resource count", 
		"usage": "banishes <amount>"
	},
	"locks": {
		"description": "Set lock resource count",
		"usage": "locks <amount>"
	},
	"freeform": {
		"description": "Toggle free-form spell casting mode",
		"usage": "freeform [on/off/toggle]"
	},
	"spell_list": {
		"description": "Show currently learned manual and combination spells",
		"usage": "spell_list"
	},
	"persistent_xp": {
		"description": "Set or show persistent XP for character progression",
		"usage": "persistent_xp [amount]"
	},
	"character": {
		"description": "Show or select character",
		"usage": "character [character_name]"
	},
	"unlock_character": {
		"description": "Unlock a specific character",
		"usage": "unlock_character <character_name>"
	},
	"progression": {
		"description": "Show current progression stats",
		"usage": "progression"
	},
	"reset_progression": {
		"description": "Reset all character progression data",
		"usage": "reset_progression"
	},
	"save_slots": {
		"description": "Show information about all save slots",
		"usage": "save_slots"
	},
	"switch_slot": {
		"description": "Switch to a different save slot",
		"usage": "switch_slot <1-3>"
	},
	"delete_slot": {
		"description": "Delete a save slot",
		"usage": "delete_slot <1-3>"
	}
}

func _ready():
	for command in UNAVAILABLE:
		commands.erase(command)
	console_panel.add_theme_stylebox_override("panel", preload("res://scripts/GameplayReadability.gd").panel_style(Color("79d9e8"), Color("17231c")))
	# Hide console initially and position it off-screen
	visible = false
	console_panel.visible = false
	console_panel.position.y = -300.0  # Start off-screen
	
	# Ensure input field is properly configured
	if input_field:
		input_field.placeholder_text = "Enter console command..."
		input_field.text_submitted.connect(_on_command_submitted)
		input_field.editable = true
		input_field.focus_mode = Control.FOCUS_ALL
	else:
		print("ERROR: Console input_field not found!")
	
	# Setup suggestions list
	if suggestions_list:
		suggestions_list.visible = false
		suggestions_list.item_selected.connect(_on_suggestion_selected)
	
	# Find game node
	game_node = get_tree().get_first_node_in_group("game")

func _input(event):
	# Toggle console with tilde key (backtick ` or tilde ~)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F3 and not event.echo:
			game_node.set_interface_debug(not game_node.interface_debug)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_QUOTELEFT:  # Backtick/Tilde key (`/~)
			toggle_console()
			get_viewport().set_input_as_handled()
		elif visible:
			if not is_console_open:
				get_viewport().set_input_as_handled()
				return
			if event.keycode == KEY_ESCAPE:
				close_console()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_UP:
				navigate_history(-1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_DOWN:
				navigate_history(1)
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_TAB:
				auto_complete()
				get_viewport().set_input_as_handled()

func toggle_console():
	if is_console_open:
		close_console()
	else:
		open_console()

func open_console():
	get_parent().move_child(self, -1)
	if console_tween:
		console_tween.kill()
	var focused = get_viewport().gui_get_focus_owner()
	if focused != input_field:
		previous_focus = weakref(focused) if focused else null
	is_console_open = true
	visible = true
	console_panel.visible = true
	input_field.grab_focus()
	
	# Pause game (like Minecraft)
	get_tree().paused = true
	
	# Smooth slide-down animation (Minecraft style)
	console_panel.position.y = -300.0  # Start off-screen
	console_tween = create_tween()
	console_tween.tween_property(console_panel, "position:y", 0.0, 0.15)
	
	# Focus input field after animation
	console_tween.tween_callback(func(): input_field.grab_focus())
	
	# Show minimal welcome message (Minecraft style)
	if output_label.text.is_empty():
		add_output("[color=gray]Developer Console - Type 'help' for commands[/color]")
		add_output("")

func close_console():
	if console_tween:
		console_tween.kill()
	is_console_open = false
	suggestions_list.visible = false
	
	# Smooth slide-up animation (Minecraft style)
	console_tween = create_tween()
	console_tween.tween_property(console_panel, "position:y", -300.0, 0.15)
	
	# Hide console completely after animation and unpause game
	console_tween.tween_callback(func():
		visible = false
		console_panel.visible = false
		game_node.sync_pause_state()
		var focused = previous_focus.get_ref() if previous_focus else null
		if is_instance_valid(focused) and focused.is_visible_in_tree():
			focused.grab_focus()
		elif game_node.current_state == game_node.GameState.LEVEL_UP:
			game_node.level_up_screen.focus_first_choice()
	)

func _on_command_submitted(command_text: String):
	if command_text.strip_edges().is_empty():
		return
		
	# Add to history
	command_history.append(command_text)
	history_index = command_history.size()
	
	# Show command in output
	add_output("[color=yellow]> " + command_text + "[/color]")
	
	# Execute command
	execute_command(command_text.strip_edges())
	
	# Clear input
	input_field.text = ""
	suggestions_list.visible = false

func execute_command(command_text: String):
	var parts = command_text.strip_edges().split(" ", false)
	if parts.is_empty():
		return
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	if command in UNAVAILABLE:
		add_output("[color=yellow]" + command + " is unavailable in this build; no effect applied.[/color]")
		return
	var read_only = command in ["help", "ui_debug", "ui_details", "clear", "spell_list", "progression", "save_slots", "reset_progression", "rickroll"] or (command in ["character", "persistent_xp", "unlock_character"] and args.is_empty())
	if (commands.has(command) or command == "reset_progression_confirm") and not read_only and is_instance_valid(game_node) and is_instance_valid(game_node.style_session):
		game_node.style_session.exclude("Console command: " + command)
	
	match command:
		"ui_debug":
			var enabled = toggle_value(args, game_node.interface_debug)
			if enabled == null:
				return
			game_node.set_interface_debug(enabled)
			add_output("Interface diagnostics: " + str(game_node.interface_debug))
		"ui_details":
			add_output(game_node.interface_debug_report())
		"help":
			show_help(args)
		"invincibility":
			toggle_invincibility(args)
		"unlock_spells":
			unlock_all_spells()
		"level_up":
			trigger_level_up()
		"add_xp":
			add_experience(args)
		"heal":
			heal_player(args)
		"spawn_enemy":
			spawn_enemy(args)
		"difficulty":
			change_difficulty(args)
		"day":
			jump_day(args)
		"kill_all":
			kill_all_enemies()
		"god_mode":
			toggle_god_mode(args)
		"set_health":
			set_player_health(args)
		"teleport":
			teleport_player()
		"time_scale":
			set_time_scale(args)
		"clear":
			clear_console()
		"noclip":
			toggle_noclip(args)
		"speed":
			set_player_speed(args)
		"damage":
			set_player_damage(args)
		"spawn_chest":
			spawn_chest_at_mouse()
		"bighead":
			toggle_bighead_mode(args)
		"disco":
			toggle_disco_mode(args)
		"matrix":
			toggle_matrix_mode(args)
		"earthquake":
			trigger_earthquake(args)
		"rain":
			spell_rain(args)
		"freeze":
			freeze_enemies(args)
		"magnet":
			toggle_enemy_magnet(args)
		"giant":
			make_player_giant(args)
		"tiny":
			make_player_tiny(args)
		"rainbow":
			toggle_rainbow_trail(args)
		"explode":
			explode_all_enemies(args)
		"army":
			spawn_enemy_army(args) 
		"missile":
			launch_homing_missiles(args)
		"blackhole":
			create_blackhole(args)
		"laser":
			toggle_laser_mode(args)
		"thanos":
			thanos_snap()
		"konami":
			konami_code()
		"party":
			party_mode()
		"rickroll":
			rickroll_easter_egg()
		"cake":
			cake_easter_egg()
		"42":
			answer_to_everything()
		"rerolls":
			set_reroll_resources(args)
		"banishes":
			set_banish_resources(args)
		"locks":
			set_lock_resources(args)
		"freeform":
			toggle_freeform_mode(args)
		"spell_list":
			show_spell_list()
		"persistent_xp":
			manage_persistent_xp(args)
		"character":
			manage_character(args)
		"unlock_character":
			unlock_character_cmd(args)
		"progression":
			show_progression()
		"reset_progression":
			reset_progression_cmd()
		"reset_progression_confirm":
			reset_progression_confirm()
		"save_slots":
			show_save_slots()
		"switch_slot":
			switch_save_slot_cmd(args)
		"delete_slot":
			delete_save_slot_cmd(args)
		_:
			add_output("[color=red]Unknown command: " + command + "[/color]")
			add_output("Type 'help' for available commands")

func show_help(args: Array):
	if args.size() > 0:
		var cmd = args[0].to_lower()
		if commands.has(cmd):
			add_output("[color=cyan]" + cmd + "[/color] - " + commands[cmd].description)
			add_output("Usage: " + commands[cmd].usage)
		else:
			add_output("[color=red]Unknown command: " + cmd + "[/color]")
	else:
		add_output("[color=cyan]Available Commands:[/color]")
		for cmd in commands.keys():
			add_output("  [color=white]" + cmd + "[/color] - " + commands[cmd].description)

func toggle_invincibility(args: Array):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		add_output("[color=red]Player not found[/color]")
		return
	var enabled = toggle_value(args, player.is_invincible)
	if enabled == null:
		return
	if enabled != player.is_invincible:
		player.toggle_invincibility()
	add_output("Invincibility: " + str(player.is_invincible))

func unlock_all_spells():
	var spell_manager = get_tree().get_first_node_in_group("spell_manager")
	if not spell_manager:
		spell_manager = game_node.get_node_or_null("SpellManager") if game_node else null
		
	if spell_manager and spell_manager.has_method("unlock_all_spells"):
		spell_manager.unlock_all_spells()
		add_output("[color=green]Manual loadout: %d/6 slots equipped. Existing spells and evolutions preserved.[/color]" % spell_manager.spells.size())
	else:
		add_output("[color=red]Could not unlock spells[/color]")

func trigger_level_up():
	if game_node and game_node.current_state != game_node.GameState.GAME_OVER:
		game_node.player.add_xp(game_node.player.xp_to_next_level - game_node.player.xp)
		add_output("[color=green]Level up triggered![/color]")
		close_console()  # Close console since level up pauses game
	else:
		add_output("[color=red]Could not trigger level up[/color]")

func add_experience(args: Array):
	var amount = numeric_value(args, 1.0, 100000.0, true)
	if amount == null:
		return
	var player = living_player()
	if player:
		player.add_xp(amount)
		add_output("Added %d XP" % amount)

func heal_player(args: Array):
	var player = living_player()
	if not player:
		return
	var amount = player.max_health if args.is_empty() else numeric_value(args, 0.0, 100000.0)
	if amount == null:
		return
	var before = player.health
	player.heal(amount)
	add_output("Healed %.1f HP" % (player.health - before))

func change_difficulty(args: Array):
	if args.size() != 1:
		add_output("Usage: difficulty <minute/+seconds>")
		return
	var additive = args[0].begins_with("+")
	var value = numeric_value([args[0].substr(1) if additive else args[0]], 0.0, 1200.0)
	if value == null:
		return
	var manager = game_node.get_node("MonsterManager")
	var seconds = value if additive else value * 60.0 - manager.game_time
	if seconds < 0.0:
		add_output("Cannot rewind encounter time; start a new run.")
		return
	manager.add_game_time(seconds)
	game_node.game_time = manager.game_time
	add_output("Encounter time: %.1f seconds" % manager.game_time)

func jump_day(args: Array):
	var cycle = get_tree().get_first_node_in_group("day_cycle")
	if not is_instance_valid(cycle):
		add_output("No day cycle in this run.")
		return
	if args.size() != 1:
		add_output("Usage: day <1-4> | day dusk | day night")
		return
	var result = cycle.debug_jump(str(args[0]).to_lower())
	if result.is_empty():
		add_output("Usage: day <1-4> | day dusk | day night")
		return
	game_node.game_time = game_node.get_node("MonsterManager").game_time
	add_output(result)

func kill_all_enemies():
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.dying:
			enemy.die()
			count += 1
	add_output("Killed %d enemies through normal death/reward handling" % count)

func set_time_scale(_args: Array):
	add_output("time_scale is unavailable in this build; no effect applied.")

func clear_console():
	output_label.text = ""

func add_output(text: String):
	output_label.text += text + "\n"
	# Auto-scroll to bottom
	call_deferred("scroll_to_bottom")

func scroll_to_bottom():
	if output_label.get_v_scroll_bar():
		output_label.get_v_scroll_bar().value = output_label.get_v_scroll_bar().max_value

func navigate_history(direction: int):
	if command_history.is_empty():
		return
		
	history_index += direction
	history_index = clamp(history_index, 0, command_history.size())
	
	if history_index < command_history.size():
		input_field.text = command_history[history_index]
		input_field.caret_column = input_field.text.length()
	else:
		input_field.text = ""

func auto_complete():
	var current_text = input_field.text.to_lower()
	if current_text.is_empty():
		return
		
	var matches = []
	for cmd in commands.keys():
		if cmd.begins_with(current_text):
			matches.append(cmd)
			
	if matches.size() == 1:
		input_field.text = matches[0]
		input_field.caret_column = input_field.text.length()
	elif matches.size() > 1:
		show_suggestions(matches)

func show_suggestions(matches: Array):
	suggestions_list.clear()
	for match in matches:
		suggestions_list.add_item(match)
	suggestions_list.visible = true

func _on_suggestion_selected(index: int):
	var selected_text = suggestions_list.get_item_text(index)
	input_field.text = selected_text
	input_field.caret_column = input_field.text.length()
	suggestions_list.visible = false
	input_field.grab_focus()

# Additional helper commands
func toggle_god_mode(args: Array):
	toggle_invincibility(args)

func set_player_health(args: Array):
	var amount = numeric_value(args, 0.0, 100000.0)
	if amount == null:
		return
	var player = living_player()
	if not player:
		return
	player.health = minf(amount, player.max_health)
	player.overheal = 0.0
	player.health_changed.emit(player.health, player.max_health, player.overheal)
	add_output("Player health: %.1f" % player.health)
	if player.health <= 0.0:
		player.player_died.emit()

func teleport_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var mouse_pos = player.get_global_mouse_position()
		player.global_position = mouse_pos
		add_output("[color=green]Player teleported to mouse position[/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func spawn_enemy(args: Array):
	var manager = game_node.get_node("MonsterManager")
	if args.is_empty() or not manager.encounter_config.variants.has(args[0]):
		add_output("Usage: spawn_enemy <type> [count]. Types: " + ", ".join(manager.encounter_config.variants.keys()))
		return
	var count = 1.0 if args.size() == 1 else numeric_value(args.slice(1), 1.0, 100.0, true)
	if count == null:
		return
	var definition = manager.encounter_config.variants[args[0]].duplicate(true)
	definition.id = args[0]
	var spawned = 0
	for i in int(count):
		if manager.spawn_monster(definition, false, true):
			spawned += 1
	add_output("Spawned %d/%d enemies (normal population cap applies)" % [spawned, count])

func toggle_noclip(args: Array):
	var player = living_player()
	if not player:
		return
	var enabled = toggle_value(args, noclip_enabled)
	if enabled == null:
		return
	if enabled and not noclip_enabled:
		collision_snapshot = Vector2i(player.collision_layer, player.collision_mask)
		player.collision_layer = 0
		player.collision_mask = 0
	elif not enabled and noclip_enabled:
		player.collision_layer = collision_snapshot.x
		player.collision_mask = collision_snapshot.y
	noclip_enabled = enabled
	add_output("Noclip: " + str(noclip_enabled))

func set_player_speed(args: Array):
	set_player_multiplier(args, "movement_speed_multiplier", "Movement speed")

func set_player_damage(args: Array):
	set_player_multiplier(args, "spell_damage_multiplier", "Spell Power")

func spawn_chest_at_mouse():
	var manager = game_node.chest_manager
	if not manager or not living_player():
		return
	var previous_count = manager.active_chests.size()
	manager.spawn_chest()
	var chest = manager.active_chests.back() if manager.active_chests.size() > previous_count else null
	if is_instance_valid(chest):
		chest.global_position = game_node.player.get_global_mouse_position()
		add_output("Chest spawned at mouse position")
	else:
		add_output("Could not spawn chest")

func toggle_bighead_mode(args: Array):
	var enabled = toggle_value(args, bighead_enabled)
	if enabled == null:
		return
	var count = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var sprite = enemy.get_node_or_null("Sprite2D")
		if not sprite:
			continue
		if enabled and not sprite.has_meta("console_original_scale"):
			sprite.set_meta("console_original_scale", sprite.scale)
			sprite.scale *= 2.0
		elif not enabled and sprite.has_meta("console_original_scale"):
			sprite.scale = sprite.get_meta("console_original_scale")
			sprite.remove_meta("console_original_scale")
		count += 1
	bighead_enabled = enabled
	add_output("Bighead: %s (%d current enemy sprites)" % [enabled, count])

func toggle_disco_mode(_args: Array):
	add_output("disco is unavailable in this build; no effect applied.")

func toggle_matrix_mode(_args: Array):
	add_output("matrix is unavailable in this build; no effect applied.")

func trigger_earthquake(_args: Array):
	add_output("earthquake is unavailable in this build; no effect applied.")

func spell_rain(_args: Array):
	add_output("rain is unavailable in this build; no effect applied.")

func freeze_enemies(args: Array):
	var duration = 5.0 if args.is_empty() else numeric_value(args, 0.1, 60.0)
	if duration == null:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.apply_slow(0.0, duration)
	add_output("Applied maximum slow to current enemies for %.1f seconds" % duration)

func toggle_enemy_magnet(_args: Array):
	add_output("magnet is unavailable in this build; no effect applied.")

func make_player_giant(_args: Array):
	add_output("giant is unavailable in this build; no effect applied.")

func make_player_tiny(_args: Array):
	add_output("tiny is unavailable in this build; no effect applied.")

func toggle_rainbow_trail(_args: Array):
	add_output("rainbow is unavailable in this build; no effect applied.")

func explode_all_enemies(_args: Array):
	add_output("explode is unavailable in this build; no effect applied.")

func spawn_enemy_army(_args: Array):
	add_output("army is unavailable in this build; no effect applied.")

func launch_homing_missiles(_args: Array):
	add_output("missile is unavailable in this build; no effect applied.")

func create_blackhole(_args: Array):
	add_output("blackhole is unavailable in this build; no effect applied.")

func toggle_laser_mode(_args: Array):
	add_output("laser is unavailable in this build; no effect applied.")

func thanos_snap():
	var enemies = get_tree().get_nodes_in_group("enemies").filter(func(enemy): return not enemy.dying)
	enemies.shuffle()
	var count = int(enemies.size() / 2)
	for i in count:
		enemies[i].die()
	add_output("Killed %d enemies through normal death/reward handling" % count)

func konami_code():
	add_output("konami is unavailable in this build; no effect applied.")

func party_mode():
	add_output("party is unavailable in this build; no effect applied.")

func rickroll_easter_egg():
	add_output("[color=red]🎵 We're no strangers to love... 🎵[/color]")
	add_output("[color=orange]🎵 You know the rules and so do I... 🎵[/color]")
	add_output("[color=yellow]🎵 A full commitment's what I'm thinking of... 🎵[/color]")
	add_output("[color=green]🎵 You wouldn't get this from any other guy... 🎵[/color]")
	add_output("[color=blue]🎵 I just wanna tell you how I'm feeling... 🎵[/color]")
	add_output("[color=purple]🎵 Gotta make you understand... 🎵[/color]")
	add_output("[color=pink]🎵 NEVER GONNA GIVE YOU UP! 🎵[/color]")
	add_output("[color=cyan]🎵 NEVER GONNA LET YOU DOWN! 🎵[/color]")
	add_output("[color=white]🎵 NEVER GONNA RUN AROUND AND DESERT YOU! 🎵[/color]")
	add_output("[color=red]You just got rickrolled! 😄[/color]")

func cake_easter_egg():
	add_output("[color=pink]🍰 The cake is a lie. 🍰[/color]")
	add_output("[color=cyan]But you can still have it![/color]")
	
	# Give player some health as "cake"
	heal_player([])
	
	add_output("[color=yellow]🎂 Delicious and moist! 🎂[/color]")
	add_output("[color=gray]- GLaDOS probably[/color]")

func answer_to_everything():
	add_output("[color=green]🤖 Deep Thought has calculated...[/color]")
	add_output("[color=cyan]After 7.5 million years of computation...[/color]")
	add_output("[color=yellow]The Answer to the Ultimate Question of Life,[/color]")
	add_output("[color=yellow]the Universe, and Everything is...[/color]")
	add_output("[color=gold]✨ 42 ✨[/color]")
	add_output("[color=gray]Now if only we knew what the question was...[/color]")
	
	# Give 42 of something as easter egg
	if game_node and game_node.has_method("add_game_time"):
		game_node.add_game_time(42.0)
		add_output("[color=green]Bonus: Added 42 seconds to game time![/color]")

# ========== REROLL RESOURCE COMMANDS ==========

func set_reroll_resources(args: Array):
	var amount = numeric_value(args, 0.0, 1000.0, true)
	if amount == null:
		return
	var screen = game_node.level_up_screen
	screen.rerolls_remaining = int(amount)
	screen.update_reroll_button_texts()
	add_output("Rerolls: %d" % amount)

func set_banish_resources(args: Array):
	var amount = numeric_value(args, 0.0, 1000.0, true)
	if amount == null:
		return
	var screen = game_node.level_up_screen
	screen.banishes_remaining = int(amount)
	screen.update_reroll_button_texts()
	add_output("Banishes: %d" % amount)

func set_lock_resources(args: Array):
	var amount = numeric_value(args, 0.0, 1000.0, true)
	if amount == null:
		return
	var screen = game_node.level_up_screen
	screen.locks_remaining = int(amount)
	screen.update_reroll_button_texts()
	add_output("Locks: %d" % amount)

func toggle_freeform_mode(args: Array):
	var spell_manager = get_spell_manager()
	if not spell_manager:
		add_output("[color=red]Could not find spell manager[/color]")
		return
	
	var action = "toggle"
	if args.size() > 0:
		action = args[0].to_lower()
	
	if not spell_manager.has_method("toggle_freeform_mode"):
		add_output("[color=red]Freeform mode not implemented in spell manager yet[/color]")
		return
	
	if toggle_value(args, spell_manager.freeform_mode) == null:
		return
	spell_manager.toggle_freeform_mode(action)
	
	# Check if freeform mode is now enabled
	if spell_manager.get("freeform_mode"):
		add_output("[color=green]Freeform spell casting enabled![/color]")
		add_output("[color=yellow]Start typing any spell name to cast it[/color]")
		add_output("[color=cyan]Use 'spell_list' to see available spells[/color]")
	else:
		add_output("[color=green]Freeform spell casting disabled[/color]")
		add_output("[color=yellow]Returned to normal slot-based casting[/color]")

func show_spell_list():
	var manager = get_spell_manager()
	if not manager:
		return
	add_output("Learned spells this run:")
	for id in manager.acquired_spells:
		var data = DataManager.get_spell_data(id)
		add_output("  " + str(data.get("incantation", id.replace("_", " "))))

func get_spell_manager():
	if not game_node:
		game_node = get_tree().get_first_node_in_group("game")
	
	if game_node:
		return game_node.get_node_or_null("SpellManager")
	
	return null

# ========== CHARACTER PROGRESSION COMMANDS ==========

func manage_persistent_xp(args: Array):
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	if args.size() == 0:
		# Show current persistent XP
		add_output("[color=cyan]Current persistent XP: " + str(CharacterManager.persistent_xp) + "[/color]")
		return
	
	var amount = numeric_value(args, 0.0, 1000000.0, true)
	if amount == null:
		return
	if amount < 0:
		add_output("[color=red]XP amount cannot be negative[/color]")
		return
	
	CharacterManager.set_persistent_xp(amount)
	add_output("[color=green]Persistent XP set to: " + str(amount) + "[/color]")

func manage_character(args: Array):
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	if args.size() == 0:
		# Show current character and available characters
		var current = CharacterManager.get_current_character()
		add_output("[color=cyan]Current character: " + current.icon + " " + current.name + "[/color]")
		add_output("[color=yellow]Starting spells: " + str(current.starting_spells) + "[/color]")
		
		add_output("[color=white]Available characters:[/color]")
		for char_id in CharacterManager.unlocked_characters:
			var char_data = CharacterManager.characters.get(char_id, {})
			var icon = char_data.get("icon", "❓")
			var name = char_data.get("name", char_id)
			var active_marker = " [ACTIVE]" if char_id == CharacterManager.current_character else ""
			add_output("  " + icon + " " + name + active_marker)
		return
	
	var character_id = args[0].to_lower()
	
	# Try to find matching character
	var found_char = null
	for char_id in CharacterManager.characters.keys():
		if char_id == character_id or CharacterManager.characters[char_id].name.to_lower() == character_id:
			found_char = char_id
			break
	
	if not found_char:
		add_output("[color=red]Character not found: " + character_id + "[/color]")
		return
	
	if not CharacterManager.select_character(found_char):
		add_output("Character is locked; selection unchanged")
		return
	var char_data = CharacterManager.characters[found_char]
	add_output("[color=green]Selected character: " + char_data.icon + " " + char_data.name + "[/color]")

func unlock_character_cmd(args: Array):
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	if args.size() == 0:
		add_output("[color=red]Usage: unlock_character <character_name>[/color]")
		add_output("[color=cyan]Available characters to unlock:[/color]")
		for char_id in CharacterManager.characters.keys():
			var char_data = CharacterManager.characters[char_id]
			var locked = char_id not in CharacterManager.unlocked_characters
			if locked:
				add_output("  " + char_data.icon + " " + char_data.name + " (locked)")
		return
	
	var character_id = args[0].to_lower()
	
	# Try to find matching character
	var found_char = null
	for char_id in CharacterManager.characters.keys():
		if char_id == character_id or CharacterManager.characters[char_id].name.to_lower() == character_id:
			found_char = char_id
			break
	
	if not found_char:
		add_output("[color=red]Character not found: " + character_id + "[/color]")
		return
	
	CharacterManager.unlock_character(found_char)
	var char_data = CharacterManager.characters[found_char]
	add_output("[color=green]Unlocked character: " + char_data.icon + " " + char_data.name + "[/color]")

func show_progression():
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	add_output("[color=cyan]===== CHARACTER PROGRESSION =====[/color]")
	add_output("[color=yellow]Persistent XP: " + str(CharacterManager.persistent_xp) + "[/color]")
	add_output("[color=yellow]Games Played: " + str(CharacterManager.total_games_played) + "[/color]")
	add_output("[color=yellow]Best Survival Time: " + str(int(CharacterManager.best_survival_time)) + "s[/color]")
	add_output("[color=yellow]Total Enemies Killed: " + str(CharacterManager.total_enemies_killed) + "[/color]")
	add_output("[color=yellow]Total Spells Cast: " + str(CharacterManager.total_spells_cast) + "[/color]")
	
	add_output("")
	add_output("[color=white]Unlocked Characters:[/color]")
	for char_id in CharacterManager.unlocked_characters:
		var char_data = CharacterManager.characters.get(char_id, {})
		var icon = char_data.get("icon", "❓")
		var name = char_data.get("name", char_id)
		var active_marker = " [ACTIVE]" if char_id == CharacterManager.current_character else ""
		add_output("  " + icon + " " + name + active_marker)
	
	add_output("")
	add_output("[color=white]Unlocked Spells:[/color]")
	var spell_count = 0
	for spell in CharacterManager.unlocked_spells:
		add_output("  🔮 " + spell)
		spell_count += 1
		if spell_count % 3 == 0:  # Line break every 3 spells for readability
			add_output("")
	
	if CharacterManager.achievements.size() > 0:
		add_output("")
		add_output("[color=white]Achievements: " + str(CharacterManager.achievements.size()) + "[/color]")

func reset_progression_cmd():
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	add_output("[color=yellow]⚠️  WARNING: This will reset ALL character progression![/color]")
	add_output("[color=yellow]⚠️  This includes persistent XP, unlocked characters, spells, and stats![/color]")
	add_output("[color=red]Type 'reset_progression_confirm' to confirm this action[/color]")

func reset_progression_confirm():
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	CharacterManager.reset_progression()
	add_output("[color=green]✅ Character progression has been reset to defaults[/color]")
	add_output("[color=cyan]All characters except Wizard are now locked[/color]")
	add_output("[color=cyan]Persistent XP and stats have been reset to 0[/color]")

func show_save_slots():
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	add_output("[color=cyan]===== SAVE SLOTS =====[/color]")
	add_output("[color=yellow]Current save slot: " + str(CharacterManager.current_save_slot) + "[/color]")
	add_output("")
	
	for slot in range(1, CharacterManager.max_save_slots + 1):
		var slot_info = CharacterManager.get_save_slot_info(slot)
		var active_marker = " [ACTIVE]" if slot == CharacterManager.current_save_slot else ""
		
		if slot_info.exists:
			var char_data = CharacterManager.characters.get(slot_info.character, {})
			var char_icon = char_data.get("icon", "❓")
			var char_name = char_data.get("name", slot_info.character)
			var time_text = ""
			
			if slot_info.best_survival_time > 0:
				var minutes = int(slot_info.best_survival_time) / 60
				var seconds = int(slot_info.best_survival_time) % 60
				time_text = " | Best: " + str(minutes) + ":" + "%02d" % seconds
			
			add_output("[color=white]Slot " + str(slot) + active_marker + ": " + char_icon + " " + char_name + "[/color]")
			add_output("  XP: " + str(slot_info.persistent_xp) + " | Games: " + str(slot_info.total_games_played) + time_text)
		else:
			add_output("[color=gray]Slot " + str(slot) + active_marker + ": [Empty][/color]")
		
		add_output("")

func switch_save_slot_cmd(args: Array):
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	if args.size() == 0:
		add_output("[color=red]Usage: switch_slot <1-3>[/color]")
		return
	
	var parsed = numeric_value(args, 1.0, CharacterManager.max_save_slots, true)
	if parsed == null:
		return
	var slot = int(parsed)
	if slot < 1 or slot > CharacterManager.max_save_slots:
		add_output("[color=red]Invalid save slot. Must be between 1 and " + str(CharacterManager.max_save_slots) + "[/color]")
		return
	
	if CharacterManager.switch_save_slot(slot):
		var slot_info = CharacterManager.get_save_slot_info(slot)
		if slot_info.exists:
			var char_data = CharacterManager.characters.get(slot_info.character, {})
			var char_icon = char_data.get("icon", "❓")
			var char_name = char_data.get("name", slot_info.character)
			add_output("[color=green]Switched to save slot " + str(slot) + ": " + char_icon + " " + char_name + "[/color]")
		else:
			add_output("[color=green]Switched to save slot " + str(slot) + " (new save)[/color]")
	else:
		add_output("[color=red]Failed to switch to save slot " + str(slot) + "[/color]")

func delete_save_slot_cmd(args: Array):
	if not CharacterManager:
		add_output("[color=red]CharacterManager not available[/color]")
		return
	
	if args.size() == 0:
		add_output("[color=red]Usage: delete_slot <1-3>[/color]")
		return
	
	var parsed = numeric_value(args, 1.0, CharacterManager.max_save_slots, true)
	if parsed == null:
		return
	var slot = int(parsed)
	if slot < 1 or slot > CharacterManager.max_save_slots:
		add_output("[color=red]Invalid save slot. Must be between 1 and " + str(CharacterManager.max_save_slots) + "[/color]")
		return
	
	if slot == CharacterManager.current_save_slot:
		add_output("[color=red]Cannot delete the currently active save slot[/color]")
		add_output("[color=yellow]Switch to a different slot first with 'switch_slot <number>'[/color]")
		return
	
	var slot_info = CharacterManager.get_save_slot_info(slot)
	if not slot_info.exists:
		add_output("[color=yellow]Save slot " + str(slot) + " is already empty[/color]")
		return
	
	if CharacterManager.delete_save_slot(slot):
		add_output("[color=green]Save slot " + str(slot) + " deleted successfully[/color]")
	else:
		add_output("[color=red]Failed to delete save slot " + str(slot) + "[/color]")
func numeric_value(args: Array, minimum: float, maximum: float, integer: bool = false):
	if args.size() != 1 or not str(args[0]).is_valid_float() or (integer and not str(args[0]).is_valid_int()):
		add_output("[color=red]Expected one valid %s[/color]" % ("integer" if integer else "number"))
		return null
	var value = float(args[0])
	if not is_finite(value) or value < minimum or value > maximum:
		add_output("[color=red]Value must be between %s and %s[/color]" % [minimum, maximum])
		return null
	return value

func toggle_value(args: Array, current: bool):
	if args.is_empty() or (args.size() == 1 and args[0].to_lower() == "toggle"):
		return not current
	if args.size() == 1 and args[0].to_lower() in ["on", "off"]:
		return args[0].to_lower() == "on"
	add_output("[color=red]Expected on, off or toggle[/color]")
	return null

func living_player():
	var player = get_tree().get_first_node_in_group("player")
	if not player or player.health <= 0.0:
		add_output("[color=red]No living player; start a new run[/color]")
		return null
	return player

func set_player_multiplier(args: Array, property: String, label: String):
	var multiplier = numeric_value(args, 0.1, 20.0)
	if multiplier == null:
		return
	var player = living_player()
	if player:
		player.set(property, multiplier)
		add_output("%s: %.2fx base (replaces the current stat multiplier)" % [label, multiplier])
