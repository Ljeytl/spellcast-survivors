extends Node2D
## Camp (doc 23): after a night's boss falls, the field goes quiet and a campfire is pitched where you
## stand. You can walk around, rest by the fire to heal, and when you are ready you type the wake word
## (data/events.json "camp", "onward") to set out into the next day. Run time and the combo hold while
## you are here; nothing spawns.

const GameData = preload("res://scripts/core/GameData.gd")
const ART = "res://assets/typecast/Camp/"
const SCALE = 2.5

var cycle: Node
var player: Node2D
var flame: Sprite2D
var flame_frames: Array = []
var age := 0.0
var heal_acc := 0.0
var healed := 0.0

static func config() -> Dictionary:
	return GameData.file("events").get("camp", {})

func setup(p_cycle: Node, p_player: Node2D) -> void:
	cycle = p_cycle
	player = p_player

func _ready():
	name = "Camp"
	add_to_group("world_words")
	add_to_group("camp_site")
	z_index = 0
	for i in 4:
		flame_frames.append(load(ART + "Campfire Flame %d.png" % (i + 1)))
	_prop("Tent.png", Vector2(-120, -46))
	_prop("Bedroll.png", Vector2(-58, 36))
	_prop("Log Seat.png", Vector2(78, 26))
	_prop("Campfire Base.png", Vector2.ZERO)
	flame = Sprite2D.new()
	flame.texture = flame_frames[0]
	flame.scale = Vector2.ONE * SCALE
	flame.position = Vector2(0, -26)
	flame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(flame)

func _prop(file: String, at: Vector2) -> Sprite2D:
	var s = Sprite2D.new()
	s.texture = load(ART + file)
	s.scale = Vector2.ONE * SCALE
	s.position = at
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)
	return s

func wake_word() -> String:
	return str(config().get("wake_word", "onward")).to_lower()

## Typed words the world answers to (SpellManager checks "world_words" before spells).
func available_words() -> Array:
	return [wake_word()]

func try_word(word: String) -> bool:
	if word.strip_edges().to_lower() != wake_word():
		return false
	if is_instance_valid(cycle):
		cycle.wake()
	return true

func _process(delta):
	age += delta
	flame.texture = flame_frames[int(age / 0.12) % flame_frames.size()]
	queue_redraw()
	# The combo is kept while you rest.
	var style = cycle.game.get("style_session") if is_instance_valid(cycle) else null
	if is_instance_valid(style):
		style.score.grace_remaining = maxf(style.score.grace_remaining, 1.0)
	# Resting by the fire heals, a little at a time.
	if not is_instance_valid(player) or player.health <= 0.0:
		return
	var cfg := config()
	if player.global_position.distance_to(global_position) <= float(cfg.get("heal_radius", 150.0)):
		heal_acc += float(player.max_health) * float(cfg.get("heal_fraction_per_second", 0.06)) * delta
		if heal_acc >= 1.0 and player.health < player.max_health:
			var amount = minf(heal_acc, player.max_health - player.health)
			player.heal(heal_acc, 0.6, "heal")
			healed += amount
			heal_acc = 0.0

func _draw():
	# Warm firelight on the ground, flickering.
	var flicker = 0.85 + 0.15 * sin(age * 11.0) * sin(age * 4.3)
	var r = float(config().get("heal_radius", 150.0))
	for i in 6:
		var t = float(i) / 6.0
		draw_circle(Vector2(0, 6), r * (1.0 - t * 0.8) * flicker, Color(1.0, 0.6, 0.25, 0.035 + 0.02 * t))
