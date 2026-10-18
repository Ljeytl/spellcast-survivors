extends "res://tests/vfx_presenter_regression.gd"

func raster(tagged: bool, visible: bool, status_layer: bool = true) -> PackedByteArray:
	var elements = preload("res://scripts/vfx/VfxElements.gd").new(vfx)
	elements.poison_status_visible = visible
	elements.bubbles = [[12.17,12.31,-2.0,1.2,0.1,0.3,0.42,tagged]]
	var buffer := PackedByteArray()
	buffer.resize(vfx._size.x * vfx._size.y * 4)
	if tagged and status_layer:
		elements.draw_poison_status(buffer)
	else:
		elements.draw_over(buffer)
	return buffer

func profile(buffer: PackedByteArray) -> Dictionary:
	var result := {"visible":0,"dark_outline":0,"alpha_levels":{},"max_alpha":0}
	for index in range(0,buffer.size(),4):
		if buffer[index + 3] == 0:
			continue
		result.visible += 1
		result.dark_outline += int(buffer[index + 2] > buffer[index + 1])
		result.alpha_levels[buffer[index + 3]] = true
		result.max_alpha = maxi(result.max_alpha,buffer[index + 3])
	return result

func poison_damage_profile(visible: bool) -> Array:
	clear()
	vfx.elements.poison_status_visible = visible
	var enemy = foe(Vector2.ZERO)
	enemy.status = preload("res://scripts/engine/StatusComponent.gd").new()
	enemy.add_child(enemy.status)
	enemy.status.apply("poison",{"hit":40.0,"duration":3.0},{"spell":"seeker","cast_id":1})
	for index in 180:
		enemy.status.tick(DT)
		vfx.presenter._poisoned(DT)
	check(not vfx.elements.bubbles.is_empty(), "Actual poison emits feedback regardless of diagnostic drawing toggle")
	check(vfx.elements.bubbles.all(func(bubble): return bubble.size() > 7 and bubble[7]), "Only poison status producer tags its bubbles")
	return enemy.received.duplicate()

func run():
	root.get_node("AudioManager").quitting = true
	vfx = root.get_node("Vfx")
	vfx._size = Vector2i(48,48)
	vfx._origin = Vector2i.ZERO
	var ordinary := raster(false,true)
	check(ordinary == raster(false,false), "Poison-only drawing suppression preserves ordinary bubbles byte-for-byte")
	check(profile(raster(true,true,false)).visible == 0, "Poison never paints the air layer above spirits")
	check(vfx._poison_status_layer.z_index == 5 and not vfx._poison_status_layer.z_as_relative, "Poison layer sits above enemies and below spirit z6")
	check(vfx._poison_status_layer.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Poison layer smooths its own raster only")
	check(vfx._air_layer.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Generic air retains nearest filtering")
	var candidate := profile(raster(true,true))
	check(candidate.visible > 0, "Poison status remains visible")
	check(candidate.dark_outline == 0, "Poison status removes dark checker rim")
	check(candidate.alpha_levels.size() > 2 and candidate.max_alpha >= 140 and candidate.max_alpha <= 180, "Poison coverage has soft translucent edge")
	check(profile(raster(true,false)).visible == 0, "Diagnostic disables only tagged status raster")
	var rejected := profile(ordinary)
	check(rejected.dark_outline > 0, "CONTROL old bubble raster fails dark-outline invariant")
	check(rejected.visible > candidate.visible, "Poison raster occupies less area than old outlined stamp")
	var visible_damage := poison_damage_profile(true)
	var hidden_damage := poison_damage_profile(false)
	check(visible_damage.size() == 3 and visible_damage.all(func(amount): return amount > 0), "Poison delivers three actual positive ticks")
	check(visible_damage == hidden_damage, "Status presentation does not alter actual poison damage")
	var stale_image := Image.create(2,2,false,Image.FORMAT_RGBA8)
	stale_image.fill(Color.GREEN)
	vfx._tex["poison_status"] = ImageTexture.create_from_image(stale_image)
	vfx._poison_status_layer.texture = vfx._tex.poison_status
	clear()
	check(vfx._poison_status_layer.texture == null and not vfx._tex.has("poison_status"), "Clear invalidates both displayed and cached poison texture")
	vfx._render(false)
	check(vfx._poison_status_layer.texture == null or profile(vfx._poison_status_layer.texture.get_image().get_data()).visible == 0, "Non-stepped render cannot revive cleared poison")
	print("Poison status readability: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
