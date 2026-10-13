extends SceneTree
## Tower → preparation screen: Woodland opens it, slot rules hold, Back returns and saves.
const PREP = preload("res://scripts/Preparation.gd")
var failures = 0
func check(c, m):
	if not c:
		failures += 1
		printerr("FAIL: ", m)
func _initialize():
	run.call_deferred()
func run():
	PREP.save_slots(PREP.DEFAULT_SLOTS)
	var tower = load("res://scenes/Tower.tscn").instantiate()
	root.add_child(tower)
	current_scene = tower
	await process_frame
	tower.selected = 0
	tower.depart()
	await process_frame
	var screen = tower.archive
	check(screen != null and screen.get_script() == preload("res://scripts/PreparationScreen.gd"), "Woodland opens preparation")
	check(not tower.transitioning, "Not departing yet")
	screen.select_slot(0)
	screen.assign_spell("life")
	check(screen.slots[0] == "bolt", "Slot 1 rejects Life")
	screen.assign_spell("seeker")
	check(screen.slots[0] == "seeker" and screen.selected_slot == 1, "Assign + advance")
	screen.assign_spell("seeker")
	check(screen.slots[1] == "seeker" and screen.slots[0] == "ice_blast", "Re-pick swaps")
	screen.select_slot(1)
	screen.move_selected(1)
	check(screen.slots[2] == "seeker", "Move later")
	screen.clear_selected()
	check(screen.slots[2] == "", "Clear")
	screen.close_screen()
	await process_frame
	check(tower.archive == null and tower.wizard.position.y > -298, "Back returns to room")
	check(PREP.load_slots()[2] == "", "Back saves kit")
	PREP.save_slots(PREP.DEFAULT_SLOTS)  # other tests share this save folder and expect Bolt in slot 1
	print("smoke failures: ", failures)
	quit(1 if failures else 0)
