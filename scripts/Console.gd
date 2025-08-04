extends Control

# Developer console system for SpellCast Survivors
# Toggle with ~ key, provides debugging and cheat commands

@onready var console_panel: Panel = $ConsolePanel
@onready var input_field: LineEdit = $ConsolePanel/VBox/InputField
@onready var output_label: RichTextLabel = $ConsolePanel/VBox/OutputLabel
@onready var suggestions_list: ItemList = $ConsolePanel/VBox/SuggestionsList

var is_console_open: bool = false
var command_history: Array[String] = []
var history_index: int = -1
var game_node: Node2D = null

# Available console commands
var commands: Dictionary = {
	"help": {
		"description": "Show all available commands",
		"usage": "help [command]"
	},
	"invincibility": {
		"description": "Toggle player invincibility",
		"usage": "invincibility [on/off/toggle]"
	},
	"unlock_spells": {
		"description": "Unlock all spells immediately", 
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
		"description": "Jump to difficulty level or add time",
		"usage": "difficulty <level/+time>"
	},
	"kill_all": {
		"description": "Kill all enemies on screen",
		"usage": "kill_all"
	},
	"god_mode": {
		"description": "Enable god mode (invincibility + infinite mana)",
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
		"description": "Set player damage multiplier",
		"usage": "damage <multiplier>"
	},
	"spawn_chest": {
		"description": "Spawn treasure chest at mouse position",
		"usage": "spawn_chest"
	},
	"bighead": {
		"description": "Make all enemies have big heads",
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
		"description": "Freeze all enemies in place",
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
		"description": "Show all available spells in freeform mode",
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
	# Hide console initially
	visible = false
	console_panel.visible = false
	
	# Setup input field
	input_field.placeholder_text = "Enter console command..."
	input_field.text_submitted.connect(_on_command_submitted)
	
	# Setup suggestions list
	suggestions_list.visible = false
	suggestions_list.item_selected.connect(_on_suggestion_selected)
	
	# Find game node
	game_node = get_tree().get_first_node_in_group("game")

func _input(event):
	# Toggle console with tilde key
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT:  # Tilde key (~)
			toggle_console()
			get_viewport().set_input_as_handled()
		elif is_console_open:
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
	is_console_open = true
	visible = true
	console_panel.visible = true
	
	# Pause game
	get_tree().paused = true
	
	# Focus input field
	input_field.grab_focus()
	
	# Show welcome message if first time
	if output_label.text.is_empty():
		add_output("[color=cyan]SpellCast Survivors Developer Console[/color]")
		add_output("Type 'help' for available commands")
		add_output("Press ~ to close, Tab to autocomplete, Up/Down for history")
		add_output("")

func close_console():
	is_console_open = false
	visible = false
	console_panel.visible = false
	suggestions_list.visible = false
	
	# Unpause game
	get_tree().paused = false

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
	var parts = command_text.split(" ")
	var command = parts[0].to_lower()
	var args = parts.slice(1)
	
	match command:
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
	if not game_node or not game_node.has_method("toggle_invincibility"):
		add_output("[color=red]Invincibility not available[/color]")
		return
		
	game_node.toggle_invincibility()
	add_output("[color=green]Invincibility toggled[/color]")

func unlock_all_spells():
	var spell_manager = get_tree().get_first_node_in_group("spell_manager")
	if not spell_manager:
		spell_manager = game_node.get_node_or_null("SpellManager") if game_node else null
		
	if spell_manager and spell_manager.has_method("unlock_all_spells"):
		spell_manager.unlock_all_spells()
		add_output("[color=green]All spells unlocked![/color]")
	else:
		add_output("[color=red]Could not unlock spells[/color]")

func trigger_level_up():
	if game_node and game_node.has_method("trigger_level_up"):
		game_node.trigger_level_up()
		add_output("[color=green]Level up triggered![/color]")
		close_console()  # Close console since level up pauses game
	else:
		add_output("[color=red]Could not trigger level up[/color]")

func add_experience(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: add_xp <amount>[/color]")
		return
		
	var amount = args[0].to_int()
	if amount <= 0:
		add_output("[color=red]XP amount must be positive[/color]")
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_experience"):
		player.add_experience(amount)
		add_output("[color=green]Added " + str(amount) + " XP[/color]")
	else:
		add_output("[color=red]Could not add XP[/color]")

func heal_player(args: Array):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		add_output("[color=red]Player not found[/color]")
		return
		
	if args.size() > 0:
		var amount = args[0].to_int()
		if player.has_method("heal"):
			player.heal(amount)
			add_output("[color=green]Healed " + str(amount) + " HP[/color]")
	else:
		if player.has_method("heal_to_full"):
			player.heal_to_full()
		elif player.has_property("current_health") and player.has_property("max_health"):
			player.current_health = player.max_health
		add_output("[color=green]Player healed to full health[/color]")

func change_difficulty(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: difficulty <level/+time>[/color]")
		return
		
	if game_node and game_node.has_method("add_game_time"):
		var arg = args[0]
		if arg.begins_with("+"):
			var time_add = arg.substr(1).to_int()
			game_node.add_game_time(time_add)
			add_output("[color=green]Added " + str(time_add) + " seconds to game time[/color]")
		else:
			var level = arg.to_int()
			var time_needed = level * 60  # 60 seconds per level
			game_node.add_game_time(time_needed)
			add_output("[color=green]Jumped to difficulty level " + str(level) + "[/color]")
	else:
		add_output("[color=red]Could not change difficulty[/color]")

func kill_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
			
	add_output("[color=green]Killed " + str(count) + " enemies[/color]")

func set_time_scale(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: time_scale <multiplier>[/color]")
		return
		
	var scale = args[0].to_float()
	if scale <= 0:
		add_output("[color=red]Time scale must be positive[/color]")
		return
		
	Engine.time_scale = scale
	add_output("[color=green]Time scale set to " + str(scale) + "[/color]")

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
	# Could add infinite mana here if implemented
	add_output("[color=green]God mode toggled[/color]")

func set_player_health(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: set_health <amount>[/color]")
		return
		
	var amount = args[0].to_int()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_property("current_health"):
		player.current_health = amount
		add_output("[color=green]Player health set to " + str(amount) + "[/color]")
	else:
		add_output("[color=red]Could not set player health[/color]")

func teleport_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var mouse_pos = get_global_mouse_position()
		player.global_position = mouse_pos
		add_output("[color=green]Player teleported to mouse position[/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func spawn_enemy(args: Array):
	add_output("[color=yellow]Enemy spawning not yet implemented[/color]")

# ========== ADVANCED CHEAT COMMANDS ==========

func toggle_noclip(args: Array):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("toggle_collision"):
			player.toggle_collision()
		elif player.has_property("collision_layer"):
			player.collision_layer = 0 if player.collision_layer != 0 else 1
		add_output("[color=cyan]Noclip toggled![/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func set_player_speed(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: speed <multiplier>[/color]")
		return
		
	var multiplier = args[0].to_float()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_property("base_speed"):
		var original_speed = 200.0  # Assume default speed
		player.base_speed = original_speed * multiplier
		add_output("[color=green]Player speed set to " + str(multiplier) + "x[/color]")
	else:
		add_output("[color=red]Could not set player speed[/color]")

func set_player_damage(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: damage <multiplier>[/color]")
		return
		
	var multiplier = args[0].to_float()
	var spell_manager = get_tree().get_first_node_in_group("spell_manager")
	if not spell_manager:
		spell_manager = game_node.get_node_or_null("SpellManager") if game_node else null
		
	if spell_manager and spell_manager.has_property("damage_multiplier"):
		spell_manager.damage_multiplier = multiplier
		add_output("[color=green]Damage multiplier set to " + str(multiplier) + "x[/color]")
	else:
		add_output("[color=red]Could not set damage multiplier[/color]")

func spawn_chest_at_mouse():
	var chest_manager = get_tree().get_first_node_in_group("chest_manager")
	if not chest_manager and game_node:
		chest_manager = game_node.get_node_or_null("ChestManager")
		
	if chest_manager and chest_manager.has_method("spawn_chest_at_position"):
		var mouse_pos = get_global_mouse_position()
		chest_manager.spawn_chest_at_position(mouse_pos)
		add_output("[color=green]Chest spawned at mouse position![/color]")
	else:
		add_output("[color=red]Could not spawn chest[/color]")

func toggle_bighead_mode(args: Array):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var sprite = enemy.get_node_or_null("Sprite2D")
			if sprite:
				sprite.scale = Vector2(2.0, 2.0) if sprite.scale.x <= 1.0 else Vector2(1.0, 1.0)
	add_output("[color=magenta]Big head mode toggled! " + str(enemies.size()) + " enemies affected[/color]")

func toggle_disco_mode(args: Array):
	# Apply rainbow effects to everything
	var all_sprites = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		all_sprites.append(player)
		
	for node in all_sprites:
		if node and is_instance_valid(node):
			var sprite = node.get_node_or_null("Sprite2D")
			if sprite:
				var tween = create_tween()
				tween.set_loops()
				tween.tween_method(func(color): sprite.modulate = color, Color.RED, Color.BLUE, 1.0)
				tween.tween_method(func(color): sprite.modulate = color, Color.BLUE, Color.GREEN, 1.0)
				tween.tween_method(func(color): sprite.modulate = color, Color.GREEN, Color.RED, 1.0)
	
	add_output("[color=rainbow]🕺 DISCO MODE ACTIVATED! 🕺[/color]")

func toggle_matrix_mode(args: Array):
	# Apply green tint to everything
	var camera = get_tree().get_first_node_in_group("camera")
	if not camera and game_node:
		camera = game_node.get_node_or_null("Camera2D")
		
	if camera:
		camera.modulate = Color.GREEN if camera.modulate != Color.GREEN else Color.WHITE
		add_output("[color=green]Matrix mode toggled - Welcome to the Matrix![/color]")
	else:
		add_output("[color=red]Could not enable matrix mode[/color]")

func trigger_earthquake(args: Array):
	var intensity = args[0].to_float() if args.size() > 0 else 10.0
	var duration = args[1].to_float() if args.size() > 1 else 3.0
	
	if game_node and game_node.has_method("trigger_screen_shake"):
		game_node.trigger_screen_shake(intensity, duration)
		add_output("[color=yellow]🌍 EARTHQUAKE! Intensity: " + str(intensity) + " Duration: " + str(duration) + "s[/color]")
	else:
		add_output("[color=red]Could not trigger earthquake[/color]")

func spell_rain(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: rain <spell_type> [count] [duration][/color]")
		return
		
	var spell_type = args[0]
	var count = args[1].to_int() if args.size() > 1 else 50
	var duration = args[2].to_float() if args.size() > 2 else 5.0
	
	# Create spell rain effect
	for i in count:
		await get_tree().create_timer(randf() * duration).timeout
		var spawn_pos = Vector2(
			randf_range(-500, 500), 
			randf_range(-300, -100)
		)
		if game_node and game_node.has_method("create_spell_projectile"):
			game_node.create_spell_projectile(spawn_pos, Vector2.DOWN, spell_type)
	
	add_output("[color=cyan]🌧️ It's raining " + spell_type + "! Count: " + str(count) + "[/color]")

func freeze_enemies(args: Array):
	var duration = args[0].to_float() if args.size() > 0 else 5.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.has_property("speed"):
			enemy.set_meta("original_speed", enemy.speed)
			enemy.speed = 0
			
	# Unfreeze after duration
	await get_tree().create_timer(duration).timeout
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.has_meta("original_speed"):
			enemy.speed = enemy.get_meta("original_speed")
			
	add_output("[color=cyan]❄️ All enemies frozen for " + str(duration) + " seconds![/color]")

func toggle_enemy_magnet(args: Array):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		add_output("[color=red]Player not found[/color]")
		return
		
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.set_meta("magnet_mode", not enemy.get_meta("magnet_mode", false))
			
	add_output("[color=magenta]🧲 Enemy magnet toggled![/color]")

func make_player_giant(args: Array):
	var scale = args[0].to_float() if args.size() > 0 else 3.0
	var duration = args[1].to_float() if args.size() > 1 else 10.0
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.scale = Vector2(scale, scale)
		add_output("[color=green]🦣 Player is now GIANT! Scale: " + str(scale) + "x[/color]")
		
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			player.scale = Vector2(1.0, 1.0)
			add_output("[color=yellow]Player returned to normal size[/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func make_player_tiny(args: Array):
	var scale = args[0].to_float() if args.size() > 0 else 0.3
	var duration = args[1].to_float() if args.size() > 1 else 10.0
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.scale = Vector2(scale, scale)
		add_output("[color=green]🐭 Player is now TINY! Scale: " + str(scale) + "x[/color]")
		
		if duration > 0:
			await get_tree().create_timer(duration).timeout
			player.scale = Vector2(1.0, 1.0)
			add_output("[color=yellow]Player returned to normal size[/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func toggle_rainbow_trail(args: Array):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Add rainbow particle trail
		add_output("[color=rainbow]🌈 Rainbow trail activated![/color]")
	else:
		add_output("[color=red]Player not found[/color]")

func explode_all_enemies(args: Array):
	var damage = args[0].to_float() if args.size() > 0 else 100.0
	var radius = args[1].to_float() if args.size() > 1 else 200.0
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# Create explosion effect
			if game_node and game_node.has_method("create_explosion_effect"):
				game_node.create_explosion_effect(enemy.global_position, radius)
			enemy.queue_free()
			
	add_output("[color=red]💥 BOOM! All enemies exploded! Damage: " + str(damage) + "[/color]")

func spawn_enemy_army(args: Array):
	if args.size() < 2:
		add_output("[color=red]Usage: army <enemy_type> <count>[/color]")
		return
		
	var enemy_type = args[0]
	var count = args[1].to_int()
	
	add_output("[color=yellow]Spawning army of " + str(count) + " " + enemy_type + "s... (not fully implemented)[/color]")

func launch_homing_missiles(args: Array):
	var count = args[0].to_int() if args.size() > 0 else 10
	var damage = args[1].to_float() if args.size() > 1 else 50.0
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_first_node_in_group("player")
	
	if not player or enemies.is_empty():
		add_output("[color=red]No targets found[/color]")
		return
		
	for i in min(count, enemies.size()):
		var target = enemies[i % enemies.size()]
		if game_node and game_node.has_method("create_homing_missile"):
			game_node.create_homing_missile(player.global_position, target, damage)
			
	add_output("[color=red]🚀 Launched " + str(count) + " homing missiles![/color]")

func create_blackhole(args: Array):
	var duration = args[0].to_float() if args.size() > 0 else 5.0
	var strength = args[1].to_float() if args.size() > 1 else 500.0
	
	var mouse_pos = get_global_mouse_position()
	add_output("[color=purple]🕳️ Black hole created at mouse position! Duration: " + str(duration) + "s[/color]")

func toggle_laser_mode(args: Array):
	var damage = args[1].to_float() if args.size() > 1 else 100.0
	add_output("[color=red]🔴 Laser mode toggled! Damage: " + str(damage) + "/sec[/color]")

# ========== EASTER EGG COMMANDS ==========

func thanos_snap():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var half_count = enemies.size() / 2
	
	# Randomly select half the enemies to remove
	enemies.shuffle()
	for i in half_count:
		if enemies[i] and is_instance_valid(enemies[i]):
			# Add dust effect before removing
			enemies[i].modulate = Color.TRANSPARENT
			enemies[i].queue_free()
	
	add_output("[color=purple]💜 *SNAP* 💜[/color]")
	add_output("[color=gray]Perfectly balanced, as all things should be...[/color]")
	add_output("[color=yellow]" + str(half_count) + " enemies have been dusted[/color]")

func konami_code():
	# Ultimate cheat mode activation
	add_output("[color=gold]🎮 KONAMI CODE ACTIVATED! 🎮[/color]")
	add_output("[color=cyan]↑↑↓↓←→←→BA[/color]")
	
	# Enable multiple cheats at once
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.scale = Vector2(1.5, 1.5)  # Slightly larger
		if player.has_method("toggle_invincibility"):
			player.toggle_invincibility()
	
	# Unlock all spells
	unlock_all_spells()
	
	# Add massive XP
	add_experience(["10000"])
	
	# Set high damage multiplier
	set_player_damage(["5.0"])
	
	add_output("[color=rainbow]LEGENDARY MODE UNLOCKED![/color]")

func party_mode():
	add_output("[color=magenta]🎉🎊 PARTY TIME! 🎊🎉[/color]")
	add_output("[color=cyan]🎈 Everyone's invited! 🎈[/color]")
	
	# Make everything colorful and fun
	toggle_disco_mode([])
	
	# Spawn some chests for party gifts
	for i in 5:
		spawn_chest_at_mouse()
	
	# Make enemies dance (freeze them in place briefly)
	freeze_enemies(["3.0"])
	
	add_output("[color=yellow]🍰 Party favors distributed! 🍰[/color]")

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
	if args.size() == 0:
		add_output("[color=red]Usage: rerolls <amount>[/color]")
		return
		
	var amount = args[0].to_int()
	var level_up_screen = get_tree().get_first_node_in_group("level_up_screen")
	
	if not level_up_screen:
		# Try to find it in the game node
		if game_node:
			level_up_screen = game_node.get_node_or_null("LevelUpScreen")
	
	if level_up_screen and level_up_screen.has_property("rerolls_remaining"):
		level_up_screen.rerolls_remaining = amount
		if level_up_screen.has_method("update_reroll_button_texts"):
			level_up_screen.update_reroll_button_texts()
		add_output("[color=green]Rerolls set to " + str(amount) + "[/color]")
	else:
		add_output("[color=red]Could not find level up screen[/color]")

func set_banish_resources(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: banishes <amount>[/color]")
		return
		
	var amount = args[0].to_int()
	var level_up_screen = get_tree().get_first_node_in_group("level_up_screen")
	
	if not level_up_screen:
		if game_node:
			level_up_screen = game_node.get_node_or_null("LevelUpScreen")
	
	if level_up_screen and level_up_screen.has_property("banishes_remaining"):
		level_up_screen.banishes_remaining = amount
		if level_up_screen.has_method("update_reroll_button_texts"):
			level_up_screen.update_reroll_button_texts()
		add_output("[color=green]Banishes set to " + str(amount) + "[/color]")
	else:
		add_output("[color=red]Could not find level up screen[/color]")

func set_lock_resources(args: Array):
	if args.size() == 0:
		add_output("[color=red]Usage: locks <amount>[/color]")
		return
		
	var amount = args[0].to_int()
	var level_up_screen = get_tree().get_first_node_in_group("level_up_screen")
	
	if not level_up_screen:
		if game_node:
			level_up_screen = game_node.get_node_or_null("LevelUpScreen")
	
	if level_up_screen and level_up_screen.has_property("locks_remaining"):
		level_up_screen.locks_remaining = amount
		if level_up_screen.has_method("update_reroll_button_texts"):
			level_up_screen.update_reroll_button_texts()
		add_output("[color=green]Locks set to " + str(amount) + "[/color]")
	else:
		add_output("[color=red]Could not find level up screen[/color]")

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
	var spell_manager = get_spell_manager()
	if not spell_manager:
		add_output("[color=red]Could not find spell manager[/color]")
		return
	
	if not spell_manager.get("freeform_mode"):
		add_output("[color=yellow]Freeform mode is not enabled[/color]")
		add_output("[color=cyan]Use 'freeform on' to enable free-form spell casting[/color]")
		return
	
	add_output("[color=cyan]Available spells in freeform mode:[/color]")
	
	# Show basic spells (current system)
	add_output("[color=green]Basic Spells:[/color]")
	add_output("  bolt (4) - Lightning projectile")
	add_output("  life (4) - Heal over time")  
	add_output("  ice blast (9) - Freezing explosion")
	add_output("  earth shield (12) - Protective barrier")
	add_output("  lightning arc (13) - Chain lightning")
	add_output("  meteor shower (13) - Multiple meteor strikes")
	add_output("  magic missile (13) - Basic auto-attack spell")
	
	# Show expanded test spells
	add_output("[color=yellow]Test Spells:[/color]")
	add_output("  fireball (8) - Fire projectile")
	add_output("  heal (4) - Instant healing")
	add_output("  lightning (9) - Single lightning strike")
	add_output("  explosion (9) - Area blast")
	add_output("  barrier (7) - Shield effect")
	add_output("  teleport (8) - Move to cursor")
	add_output("  slow (4) - Slow all enemies")
	add_output("  haste (5) - Speed boost")

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
	
	var amount = args[0].to_int()
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
	
	CharacterManager.select_character(found_char)
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
	
	var slot = args[0].to_int()
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
	
	var slot = args[0].to_int()
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