extends SceneTree

var checks := 0
var failures := 0

class ObservedShield extends "res://scripts/EarthShield.gd":
	var releases := 0
	func release_eruption(_charge: Dictionary, _origin: Vector2, _aim: Vector2):
		releases += 1

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func run():
	var vfx = root.get_node("Vfx")
	vfx.set_process(false)
	vfx._active = true
	var player = Node2D.new()
	root.add_child(player)
	var shield = ObservedShield.new()
	player.add_child(shield)
	shield.set_physics_process(false)
	shield.add_charge({"remaining": 5.0})
	shield.add_charge({"remaining": 2.0})
	var origin: Vector2 = vfx.presenter._stone_at(shield, 1, Vector2.ZERO)
	check(shield.block({"source_position": Vector2(-100, 0)}), "charged hit blocks")
	await process_frame
	check(shield.releases == 1, "block schedules one retaliation")
	if OS.get_cmdline_user_args().has("known-bad-fracture"):
		vfx.presenter._shield_fractures.clear()
	check(vfx.presenter._shield_fractures.size() == 1, "block creates exactly one visual fracture")
	if not vfx.presenter._shield_fractures.is_empty():
		var fracture = vfx.presenter._shield_fractures[0]
		check(fracture.origin.is_equal_approx(origin), "fracture begins at actual earliest-expiry stone")
		check(fracture.direction.is_equal_approx(Vector2.LEFT), "fracture follows incoming source")
		check(fracture.at.x < 0 and is_zero_approx(fracture.at.y), "guard sits on incoming side")
	check(shield.charges.size() == 1 and shield.charges[0].remaining == 5.0, "other charge survives unchanged")
	vfx.presenter._advance_transients(0.33)
	check(vfx.presenter._shield_fractures.is_empty(), "fracture fully ends")
	var debris_before: int = vfx._debris.size()
	shield.advance(5.0)
	if OS.get_cmdline_user_args().has("known-bad-expiry"):
		shield.release_eruption.call_deferred({}, Vector2.ZERO, Vector2.RIGHT)
	await process_frame
	check(shield.charges.is_empty(), "natural expiry removes protection")
	check(vfx.presenter._shield_fractures.is_empty(), "expiry never creates violent fracture")
	check(vfx._debris.size() == debris_before + 3, "expiry emits only quiet crumble")
	check(shield.releases == 1, "expiry never schedules retaliation")
	shield.add_charge({"remaining": 1.0})
	vfx.presenter.enabled = false
	shield.block({"incoming_direction": Vector2.UP})
	check(vfx.presenter._shield_fractures.is_empty(), "disabled presenter suppresses fracture")
	vfx.presenter.enabled = true
	shield.add_charge({"remaining": 1.0})
	shield.block({"incoming_direction": Vector2.DOWN})
	check(vfx.presenter._shield_fractures[0].direction.is_equal_approx(Vector2.UP), "missing attacker falls back to incoming direction")
	vfx.presenter.clear_transients()
	check(vfx.presenter._shield_fractures.is_empty(), "scene clearing removes residual guard")
	player.free()
	print("SHIELD_PRESENTATION checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
