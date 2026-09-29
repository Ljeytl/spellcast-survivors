extends RefCounted

var manager
var seen_waves: Dictionary = {}
var active_wave: Dictionary = {}
var wave_remaining = 0
var wave_angle = 0.0
var wave_elapsed = 0.0
var recycle_elapsed = 0.0
var recycled_count = 0
var wave_spawn_count = 0

func _init(owner_manager):
	manager = owner_manager

func visible_world_rect() -> Rect2:
	var viewport = manager.get_viewport()
	var inverse = viewport.get_canvas_transform().affine_inverse()
	var size = viewport.get_visible_rect().size
	var bounds = Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	for corner in [Vector2(size.x, 0), size, Vector2(0, size.y)]:
		bounds = bounds.expand(inverse * corner)
	return bounds

func entry_position(angle: float, radius: float, entry_margin: float = -1.0) -> Vector2:
	var settings = manager.encounter_config.get("recycling", {})
	var margin = maxf(float(settings.get("entry_margin", 160)), radius * 4.0) if entry_margin < 0.0 else maxf(entry_margin, radius * 1.5)
	var bounds = visible_world_rect().grow(margin)
	var direction = Vector2.from_angle(angle)
	var half_size = bounds.size * 0.5
	var distance = minf(half_size.x / maxf(absf(direction.x), 0.0001), half_size.y / maxf(absf(direction.y), 0.0001))
	var terrain = manager.get_parent().get_node_or_null("Background")
	for attempt in range(16):
		var candidate = bounds.get_center() + direction * (distance + attempt * 48.0)
		if not terrain or not terrain.has_method("is_spawn_clear") or terrain.is_spawn_clear(candidate, radius):
			return candidate
	return Vector2(INF, INF)

func update(delta: float):
	if manager.run_finished:
		active_wave.clear()
		wave_remaining = 0
		return
	var jump = delta > 5.0 or delta < 0.0
	if jump:
		active_wave.clear()
		wave_remaining = 0
	for index in range(manager.encounter_config.get("waves", []).size()):
		var wave = manager.encounter_config.waves[index]
		if seen_waves.has(index) or manager.game_time < float(wave.time):
			continue
		seen_waves[index] = true
		if jump or manager.game_time - float(wave.time) > 5.0:
			continue
		var available = manager.get_available_variants(manager.game_time)
		for definition in available:
			if definition.id == wave.variant:
				active_wave = definition
				wave_remaining = int(wave.count)
				wave_angle = randf() * TAU
				wave_elapsed = 0.0
				break
	if jump:
		return
	wave_elapsed -= delta
	if wave_remaining > 0 and wave_elapsed <= 0.0:
		wave_elapsed = float(manager.encounter_config.get("wave_spacing", 0.35))
		wave_remaining -= 1
		var enemy = manager.spawn_monster(active_wave, false, true, wave_angle + randf_range(-0.44, 0.44))
		if enemy:
			wave_spawn_count += 1
	recycle_elapsed += delta
	if recycle_elapsed >= 0.5:
		recycle_elapsed = 0.0
		recycle_distant()

func recycle_distant():
	if manager.run_finished:
		return
	var settings = manager.encounter_config.get("recycling", {})
	var bounds = visible_world_rect()
	var distant = bounds.grow(float(settings.get("distance_beyond_view", 600)))
	var moved = 0
	for enemy in manager.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get_parent() != manager.get_parent():
			continue
		if enemy.get("boss") != false or enemy.get("dying") != false or enemy.get("current_health") == null or enemy.current_health <= 0:
			continue
		if distant.has_point(enemy.global_position):
			continue
		var old_angle = (enemy.global_position - bounds.get_center()).angle()
		var point = entry_position(old_angle + randf_range(PI * 0.5, PI * 1.5), 29.0 * enemy.scale.x)
		if not point.is_finite():
			continue
		enemy.global_position = point
		recycled_count += 1
		moved += 1
		if moved >= int(settings.get("maximum_per_check", 2)):
			break
