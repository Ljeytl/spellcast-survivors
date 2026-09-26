extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_parent().toggle_pause()
		get_viewport().set_input_as_handled()
