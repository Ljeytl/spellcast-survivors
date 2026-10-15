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
	root.add_child(ghost)
	ghost.position = Vector2(250, 0)
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
	check(visual.body.mesh != null and visual.body.points.size() == 11, "Spirit body uses a deforming mesh instead of a rigid sprite")
	check(visual.wake_samples.is_empty(), "Production spawn order never leaves a wake from world origin")
	ghost.position += Vector2(20, 0)
	visual._process(0.01)
	check(not visual.wake_samples.is_empty(), "Travel produces interpolated wake samples between frames")
	var wake_point = visual.wake_samples[0][0]
	ghost.position += Vector2(20, 0)
	visual._process(0.01)
	check(visual.wake_samples[0][0].distance_to(wake_point) > 0.0 and visual.wake_samples[0][0].distance_to(wake_point) < 2.0, "Shed material drifts independently instead of following the host or remaining static")
	check(visual.wake_samples.size() <= 64, "Wake samples have a bounded particle budget")
	player.health = 100
	ghost._physics_process(0.05)
	visual._process(0.05)
	check(not visual.healing, "Spirit palette follows a change in healing intent")
	check(not ghost.healing and ghost.heading.x > 0, "Healing caster switches spirit to hunting")
	ghost.position = enemy.position - Vector2(10, 0)
	ghost._physics_process(0.01)
	check(enemy.current_health == 94.0 and ghost.is_queued_for_deletion(), "Hunting arrival still delivers one six-damage hit")
	check(visual.released and visual.get_parent() == root, "Arrival preserves its visual after gameplay host retires")
	var samples_at_arrival = visual.wake_samples.size()
	visual._process(0.01)
	check(visual.wake_samples.size() <= samples_at_arrival, "Arrival stops creating wake particles")
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
	var healing_visual = get_nodes_in_group("spirit_remnants").back()
	healing_visual._process(0.2)
	check(healing_visual.body.modulate.a > 0.0, "Short-distance soul remains visible after immediate heal")
	check(player.health == 56.0, "Visual continuation cannot heal again")
	healing_visual._process(0.7)
	check(healing_visual.is_queued_for_deletion(), "Remnant expires after its bounded lifetime")
	check(vfx._rings.size() == 2 and vfx._stars.size() == 2, "Healing arrival emits one ring and one core flash")
	await process_frame
	ghost = GHOST.new()
	ghost.player_ref = weakref(player)
	root.add_child(ghost)
	ghost.set_physics_process(false)
	var expired_visual = ghost.get_child(0)
	ghost._physics_process(4.0)
	expired_visual._process(0.01)
	check(expired_visual.body.modulate.a == 0.0, "Expired soul cannot reappear when the visual detaches")
	check(vfx._rings.size() == 2 and vfx._stars.size() == 2, "Natural spirit expiry does not imitate a successful arrival")
	await process_frame
	vfx.clear()
	await process_frame
	check(get_nodes_in_group("spirit_visuals").is_empty(), "Spirit visuals disappear with their gameplay hosts")
	check(vfx._rings.is_empty() and vfx._stars.is_empty(), "World reset clears spirit arrival effects")
	for i in range(4):
		var capped = GHOST.new()
		capped.player_ref = weakref(player)
		capped.position = Vector2(300, 100)
		root.add_child(capped)
		capped.set_physics_process(false)
	check(get_nodes_in_group("soul_ghosts").filter(func(g): return not g.is_queued_for_deletion()).size() == 3, "Visual remnants do not consume active soul capacity")
	check(get_nodes_in_group("spirit_remnants").size() == 1, "Cap retirement leaves one bounded visual remnant")
	check(player.health == 56.0, "Cap retirement does not deliver healing")
	var remnant = get_nodes_in_group("spirit_remnants")[0]
	var before = remnant.release_age
	paused = true
	await create_timer(0.05, true).timeout
	check(remnant.release_age == before, "Detached remnant respects game pause")
	paused = false
	for active in get_nodes_in_group("soul_ghosts"):
		active.queue_free()
	vfx.clear()
	await process_frame
	enemy.free()
	player.free()
	print("Soul spirit: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
