extends Node

const INTERVAL = 2.0
const CELL_SIZE = 220.0
const MIN_DISTANCE = 600.0
const SCREEN_MARGIN = 100.0
var remaining = INTERVAL
var merged_pickups = 0

func _process(delta):
	remaining -= delta
	if remaining <= 0:
		remaining = INTERVAL
		consolidate()

func eligible(orb, player) -> bool:
	if not is_instance_valid(orb) or orb.is_queued_for_deletion() or orb.collected or orb.is_moving_to_player:
		return false
	var attraction = orb.collection_distance * player.xp_range_multiplier
	if orb.global_position.distance_to(player.global_position) <= maxf(MIN_DISTANCE, attraction + CELL_SIZE):
		return false
	var screen = orb.get_global_transform_with_canvas().origin
	return not get_viewport().get_visible_rect().grow(SCREEN_MARGIN).has_point(screen)

func consolidate():
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var buckets: Dictionary = {}
	for orb in get_tree().get_nodes_in_group("xp_orbs"):
		if not eligible(orb, player):
			continue
		var cell = Vector2i(floori(orb.global_position.x / CELL_SIZE), floori(orb.global_position.y / CELL_SIZE))
		var anchor = buckets.get(cell)
		if anchor == null:
			buckets[cell] = orb
		elif eligible(anchor, player) and anchor.global_position.distance_to(orb.global_position) <= CELL_SIZE:
			anchor.xp_value += orb.xp_value
			orb.collected = true
			orb.queue_free()
			merged_pickups += 1
