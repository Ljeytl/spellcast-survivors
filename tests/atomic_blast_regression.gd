extends SceneTree

const Atomic = preload("res://scripts/AtomicBlast.gd")
class LockedOverlay extends Atomic:
	func overlay_bounds() -> Rect2:
		return footprint

class UnpaddedOverlay extends Atomic:
	func overlay_bounds() -> Rect2:
		var viewport := get_viewport()
		return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()

const Hazard = preload("res://scripts/EnemyProjectile.gd")
var checks := 0
var failures := 0
var game
var manager

func _initialize() -> void:
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func spawn(id: String, position: Vector2, boss: bool = false):
	var definition: Dictionary = manager.encounter_config.variants[id].duplicate(true)
	definition.id = id
	var enemy = manager.spawn_monster(definition, boss, true)
	enemy.set_physics_process(false)
	enemy.set_process(false)
	enemy.global_position = position
	enemy.max_health = 1000.0
	enemy.current_health = 1000.0
	return enemy

func run() -> void:
	root.get_node("AudioManager").quitting = true
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.spell_manager.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_invincible = true
	manager = game.get_node("MonsterManager")
	manager.spawn_timer.stop()
	manager.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()
	game.particle_manager.reduced_effects = true
	game.camera_shake.shake_timer = 0.0
	game.camera_shake.shake_intensity = 0.0
	var blast = LockedOverlay.new() if "--known-bad-locked-overlay" in OS.get_cmdline_user_args() else Atomic.new()
	if "--known-bad-unpadded-overlay" in OS.get_cmdline_user_args():
		blast = UnpaddedOverlay.new()
	blast.configure(game)
	var bounds: Rect2 = blast.footprint
	var committed_origin: Vector2 = game.player.global_position
	check(blast.origin == committed_origin, "Warning originates at caster position")
	game.player.global_position += Vector2(80, 40)
	check(blast.origin == committed_origin, "Caster movement cannot move committed pressure origin")
	check(blast.reach >= blast.origin.distance_to(bounds.end), "Pressure reaches far corner of locked footprint")
	var center := bounds.get_center()
	game.add_child(blast)
	if "--known-bad-clipped-pulse" in OS.get_cmdline_user_args():
		blast.pulse.position = bounds.position
		blast.pulse.size = bounds.size
		blast.pulse_material.set_shader_parameter("extent", bounds.size)
		blast.pulse_material.set_shader_parameter("center", committed_origin - bounds.position)
	var render_bounds := Rect2(blast.pulse.position, blast.pulse.size)
	check(render_bounds.has_point(committed_origin + Vector2(blast.reach + 150.0, 0.0)) and render_bounds.has_point(committed_origin - Vector2(blast.reach + 150.0, 0.0)), "Pulse retains Gaussian falloff beyond radial reach on both sides")
	var shader_center: Vector2 = blast.pulse_material.get_shader_parameter("center")
	check(blast.pulse.position + shader_center == committed_origin, "Expanded shader bounds preserve committed world origin")
	check(blast.pulse_material.get_shader_parameter("extent") == blast.pulse.size and blast.pulse_material.get_shader_parameter("reach") == blast.reach, "Expanded UV extent preserves radial reach")
	check(blast.footprint == bounds, "Visual support does not expand committed damage footprint")
	var ordinary = spawn("pursuer", center + Vector2(100, 0))
	var armored = spawn("pursuer", center + Vector2(120, 0))
	armored.is_elite = true
	armored.elite_type = armored.EliteType.ARMORED
	armored.resistances = {"raw": 0.5, "arcane": 0.5}
	var shield = spawn("shieldbearer", center + Vector2(140, 0))
	shield.facing = Vector2.LEFT
	var boss = spawn("pursuer", center + Vector2(160, 0), true)
	var outside = spawn("pursuer", bounds.end + Vector2(100, 100))
	check(render_bounds.has_point(outside.global_position), "Outside damage probe remains inside visual support")
	var projectile = Hazard.new()
	game.add_child(projectile)
	projectile.set_physics_process(false)
	projectile.global_position = center
	var outside_projectile = Hazard.new()
	game.add_child(outside_projectile)
	outside_projectile.set_physics_process(false)
	outside_projectile.global_position = bounds.end + Vector2(100, 100)
	paused = true
	var before: float = blast.elapsed
	await create_timer(0.08, true, false, true).timeout
	check(blast.elapsed == before and not blast.impacted, "Paused warning does not advance")
	paused = false
	blast.set_process(false)
	blast._process(0.64)
	check(ordinary.current_health == 1000.0, "Warning causes no early damage")
	root.canvas_transform.origin += Vector2(400, 400)
	check(blast.footprint == bounds, "Release footprint remains locked after camera change")
	for displacement in [Vector2(400, 400), Vector2(-173, 92), Vector2(8, -6)]:
		root.canvas_transform.origin = displacement
		var visible: Rect2 = root.get_visible_rect().grow(32.0)
		var rendered: Rect2 = root.canvas_transform * blast.overlay_bounds()
		check(rendered.position.distance_to(visible.position) < 0.01 and rendered.end.distance_to(visible.end) < 0.01, "Overlay covers current viewport under translated and shaken camera")
	var before_render: Rect2 = root.canvas_transform * blast.overlay_bounds()
	for late_delta in [Vector2(30, 0), Vector2(-30, 0), Vector2(0, 30), Vector2(0, -30)]:
		var shifted := Rect2(before_render.position + late_delta, before_render.size)
		check(shifted.encloses(root.get_visible_rect()), "Visual overscan covers late camera and shake displacement")
	check(blast.footprint == bounds and blast.origin == committed_origin, "Overlay tracking leaves committed damage and pressure origin unchanged")
	blast._process(0.02)
	check(ordinary.current_health == 0.0 and ordinary.dying, "Real regular enemy dies through damage API")
	check(armored.current_health == 0.0 and armored.dying, "Real armored enemy dies: Atomic is pure damage")
	check(shield.current_health == 0.0 and shield.dying, "Real shieldbearer cannot directionally block full-area blast")
	check(is_equal_approx(boss.current_health, 400.0) and not boss.dying, "Real boss loses sixty percent maximum health")
	check(outside.current_health == 1000.0, "Enemy outside footprint is untouched")
	check(projectile.is_queued_for_deletion(), "Real hostile projectile inside is removed")
	check(not outside_projectile.is_queued_for_deletion(), "Outside projectile remains")
	check(blast.reduced_effects and game.camera_shake.shake_timer == 0.0, "Reduced effect setting suppresses Atomic shake")
	blast._impact()
	check(boss.current_health == 400.0, "Duplicate impact cannot apply damage twice")
	check(blast.process_mode == Node.PROCESS_MODE_PAUSABLE, "Atomic explicitly follows pause")
	var known_bad := "--known-bad-double-impact" in OS.get_cmdline_user_args()
	if known_bad:
		blast.impacted = false
		blast._impact()
	check(boss.current_health == 400.0, "Control detects a doubled blast against real boss")
	game.queue_free()
	await process_frame
	await create_timer(0.2, true, false, true).timeout
	print("Atomic blast regression: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
