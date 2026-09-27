extends RefCounted

const PATH = "user://presentation.cfg"

static func reduced() -> bool:
	var config = ConfigFile.new()
	if config.load(PATH) != OK:
		return false
	return bool(config.get_value("effects", "reduced", false))

static func save_reduced(value: bool) -> Error:
	var config = ConfigFile.new()
	config.load(PATH)
	config.set_value("effects", "reduced", value)
	return config.save(PATH)

static func apply(game: Node, value: bool):
	if not is_instance_valid(game) or not game.has_method("setup_particle_manager"):
		return
	game.particle_manager.reduced_effects = value
	game.camera_shake.reduced_effects = value
	if value:
		game.camera_shake.shake_timer = 0.0
		game.camera_shake.shake_intensity = 0.0
		if game.camera_shake.camera:
			game.camera_shake.camera.offset = game.camera_shake.original_offset
