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

func run():
	root.get_node("AudioManager").quitting = true
	var fixture = preload("res://tools/workshop/PreviewFixture.gd").new()
	await fixture.setup(root,"earth_shield")
	check(fixture.game.player.earth_shield.charges.size()==1,"Workshop creates charge")
	fixture.advance(0.81)
	await process_frame
	check(fixture.game.player.earth_shield.charges.is_empty(),"Workshop trigger bypasses fixture invincibility intentionally")
	check(fixture.game.player.health==30,"Preview block leaves health unchanged")
	check(get_nodes_in_group("earth_shield_eruptions").size()==1,"Workshop shows eruption")
	var eruption=get_nodes_in_group("earth_shield_eruptions")[0]
	check(eruption.get_parent()==fixture.game,"Eruption owned by fixture game")
	eruption.set_physics_process(false)
	eruption.advance(0.22)
	check(fixture.targets[0].current_health<10000,"Workshop target is within damage footprint")
	fixture.advance(0.1)
	check(get_nodes_in_group("earth_shield_eruptions").size()==1,"Workshop trigger fires once")
	await fixture.setup(root,"earth_shield")
	await fixture.setup(root,"bolt")
	fixture.advance(1)
	await process_frame
	check(fixture.game.player.health==30,"Switching preview cannot inherit delayed damage")
	check(get_nodes_in_group("earth_shield_eruptions").is_empty(),"Switching removes old shield effects")
	fixture.game.free()
	print("SHIELD_PREVIEW checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
