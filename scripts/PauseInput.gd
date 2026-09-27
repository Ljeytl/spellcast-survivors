extends Node

var spellbook: Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var column = get_parent().get_node("UI/PauseOverlay/PauseMenu/VBoxContainer")
	var button = Button.new()
	button.name = "SpellbookButton"
	button.text = "SPELLBOOK"
	button.custom_minimum_size.y = 45
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.pressed.connect(open_spellbook)
	column.add_child(button)
	column.move_child(button, column.get_node("ResumeButton").get_index() + 1)

func open_spellbook():
	var game = get_parent()
	if game.current_state != game.GameState.PAUSED or is_instance_valid(spellbook):
		return
	spellbook = preload("res://scripts/RunSpellbook.gd").new()
	spellbook.name = "RunSpellbook"
	spellbook.game = game
	spellbook.closed.connect(close_spellbook)
	spellbook.cast_requested.connect(cast_from_book)
	game.pause_overlay.hide()
	game.get_node("UI").add_child(spellbook)

func close_spellbook():
	spellbook = null
	var game = get_parent()
	if game.current_state == game.GameState.PAUSED:
		game.pause_overlay.show()
		game.get_node("UI/PauseOverlay/PauseMenu/VBoxContainer/SpellbookButton").grab_focus()

func cast_from_book(slot: int):
	var game = get_parent()
	if game.spell_manager.get_spell_info(slot).is_empty():
		return
	if is_instance_valid(spellbook):
		spellbook.queue_free()
	spellbook = null
	game.change_state(game.GameState.PLAYING)
	game.spell_manager.activate_spell_slot(slot)

func _unhandled_input(event):
	if is_instance_valid(spellbook):
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_parent().toggle_pause()
		get_viewport().set_input_as_handled()
