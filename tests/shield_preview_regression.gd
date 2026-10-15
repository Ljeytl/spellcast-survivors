extends SceneTree

var checks = 0
var failures = 0

func _initialize():
	if not OS.get_user_data_dir().ends_with("SpellCast Survivors Synergy Test"):
		quit(2)
		return
	run.call_deferred()

func check(ok, label):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

## Earth Shield's eruption runs on the generic engine (doc 18 phase 2).
func eruptions() -> Array:
	return get_nodes_in_group("generic_casts").filter(func(c): return str(c.plan.get("id", "")) == "earth_shield" and not c.is_queued_for_deletion() and not c.finished)

func run():
	root.get_node("AudioManager").quitting = true
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	await fixture.setup(root,"earth_shield")
	check(fixture.game.player.earth_shield.charges.size()==1,"Workshop creates charge")
	fixture.advance(0.81)
	await process_frame
	check(fixture.game.player.earth_shield.charges.is_empty(),"Workshop trigger bypasses fixture invincibility intentionally")
	check(fixture.game.player.health==30,"Preview block leaves health unchanged")
	check(eruptions().size()==1,"Workshop shows eruption")
	var eruption=eruptions()[0] if not eruptions().is_empty() else null
	check(eruption != null and eruption.get_parent()==fixture.game,"Eruption owned by fixture game")
	var spawned = get_nodes_in_group("generic_casts").filter(func(c): return str(c.plan.get("id", "")) == "earth_shield").size()
	if eruption != null:
		eruption.advance(0.22)
	check(fixture.targets[0].current_health<10000,"Workshop target is within damage footprint")
	fixture.advance(0.1)
	check(get_nodes_in_group("generic_casts").filter(func(c): return str(c.plan.get("id", "")) == "earth_shield").size()==spawned,"Workshop trigger fires once")
	await fixture.setup(root,"earth_shield")
	await fixture.setup(root,"bolt")
	fixture.advance(1)
	await process_frame
	check(fixture.game.player.health==30,"Switching preview cannot inherit delayed damage")
	check(eruptions().is_empty(),"Switching removes old shield effects")
	fixture.game.free()
	print("SHIELD_PREVIEW checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
