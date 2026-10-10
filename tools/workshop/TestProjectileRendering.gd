extends SceneTree
const Fixture = preload("res://tools/workshop/PreviewFixture.gd")
var fixture = Fixture.new()
func _initialize():
 run.call_deferred()
func run():
 root.set_flag(Window.FLAG_NO_FOCUS, true)
 root.position = Vector2i(5000,5000)
 root.size = Vector2i(960,600)
 root.content_scale_size = Vector2i(1280,800)
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.get_node("AudioManager").quitting = true
 var output = "res://builds/comparison-negative" if "--known-bad-sizing" in OS.get_cmdline_user_args() else "res://builds/comparison"
 DirAccess.make_dir_recursive_absolute(output)
 if not OS.get_user_data_dir().ends_with("SpellCast Survivors Visual Workshop"):
  quit(2)
  return
 var checks = 0
 var failures = 0
 for id in ["mana_bolt","bolt","lightning_bolt","life_bolt","ice_blast","ember_spear","meteor_spear","cross_blade","seeker","arcane_orbit","infestation","soul_bloom","meteor_shower"]:
  paused = false
  Engine.time_scale = 1.0
  fixture.settings.projectile = 1.0
  fixture.settings.scenery = false
  await fixture.setup(root,id)
  paused = true
  Engine.time_scale = 0.0
  for effect in get_nodes_in_group("projectile_visuals"):
   if effect.has_method("advance"):
    effect.advance(0.15)
   elif effect.get("projectile_type") == "warning":
    effect.lifetime_timer = effect.lifetime * 0.35
    effect.queue_redraw()
  var before: Image
  for factor in [1.0,2.5]:
   fixture.settings.projectile = factor
   fixture.apply_sizes()
   if "--known-bad-sizing" in OS.get_cmdline_user_args():
    for effect in get_nodes_in_group("projectile_visuals"):
     preload("res://scripts/ProjectileVisual.gd").apply(effect,1.0)
   await process_frame
   await RenderingServer.frame_post_draw
   var frame = root.get_texture().get_image()
   var err = frame.save_png(output+"/"+id+"-"+str(factor)+".png")
   assert(err == OK)
   if factor == 1.0:
    before = frame
   else:
    if before.get_data() == frame.get_data():
     printerr("FAIL unchanged rendering: ",id)
     failures += 1
    checks += 1
 print("RENDER COMPARISONS ",checks," FAILURES ",failures)
 Engine.time_scale = 1.0
 quit(1 if failures else 0)
