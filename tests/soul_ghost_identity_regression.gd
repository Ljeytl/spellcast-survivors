extends SceneTree

const GHOST = preload("res://scripts/SoulGhost.gd")
var checks := 0
var failures := 0
class Player extends Node2D:
	var health := 50.0
	var max_health := 100.0
	func heal(amount):
		health = minf(max_health, health + amount)
class Enemy extends Node2D:
	var dying := false
	var current_health := 100.0
	func take_damage(amount, _position = Vector2.ZERO, _source = {}):
		current_health -= amount

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr(label)
func run():
	if not root.is_node_ready():
		await root.ready
	await process_frame
	var vfx = root.get_node("Vfx")
	vfx.set_process(false)
	vfx.clear()
	var player := Player.new()
	root.add_child(player)
	var enemy := Enemy.new()
	root.add_child(enemy)
	enemy.position = Vector2(500, 0)
	enemy.add_to_group("enemies")
	var ghost = GHOST.new()
	ghost.player_ref = weakref(player)
	ghost.position = Vector2(250, 0)
	root.add_child(ghost)
	ghost.set_physics_process(false)
	ghost._physics_process(0.05)
	var visual = ghost.get_child(0)
	visual._process(0.05)
	check(visual.form == "wisp", "Soul defaults to a faceless painted wisp")
	vfx.spirit_form_override = "ghost"
	visual._process(0.0)
	check(visual.form == "ghost", "Soul can use the painted ghost without recasting")
	vfx.spirit_form_override = "auto"
	visual._process(0.0)
	check(visual.soul and visual.healing and visual.radius == 22.0, "Soul has a substantial healing spirit renderer")
	check(ghost.healing and ghost.heading.x < 0, "Hurt caster gets healing intent and return direction")
	check(ghost.trail.size() == 1, "Moving spirit records its wake")
	player.health = 100
	ghost._physics_process(0.05)
	visual._process(0.05)
	check(not visual.healing, "Spirit palette follows a change in healing intent")
	check(not ghost.healing and ghost.heading.x > 0, "Healing caster switches spirit to hunting")
	ghost.position = enemy.position - Vector2(10, 0)
	ghost._physics_process(0.01)
	check(enemy.current_health == 94.0 and ghost.is_queued_for_deletion(), "Hunting arrival still delivers one six-damage hit")
	check(vfx._rings.size() == 1 and vfx._stars.size() == 1, "Hunting arrival emits one ring and one core flash")
	await process_frame
	player.health = 50
	ghost = GHOST.new()
	ghost.player_ref = weakref(player)
	ghost.position = Vector2(10, 0)
	root.add_child(ghost)
	ghost.set_physics_process(false)
	ghost._physics_process(0.01)
	check(player.health == 56.0 and ghost.is_queued_for_deletion(), "Healing arrival still delivers six health")
	check(vfx._rings.size() == 2 and vfx._stars.size() == 2, "Healing arrival emits one ring and one core flash")
	await process_frame
	ghost = GHOST.new()
	ghost.player_ref = weakref(player)
	root.add_child(ghost)
	ghost.set_physics_process(false)
	ghost._physics_process(4.0)
	check(vfx._rings.size() == 2 and vfx._stars.size() == 2, "Natural spirit expiry does not imitate a successful arrival")
	await process_frame
	vfx.clear()
	check(get_nodes_in_group("spirit_visuals").is_empty(), "Spirit visuals disappear with their gameplay hosts")
	check(vfx._rings.is_empty() and vfx._stars.is_empty(), "World reset clears spirit arrival effects")
	enemy.free()
	player.free()
	print("Soul spirit: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
