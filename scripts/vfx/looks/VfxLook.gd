extends RefCounted
## One element's look for the VFX presenter (docs/VFX_EVENTS.md). The presenter routes engine
## events by shape (projectile, burst, field, nova...) and calls the look; the look decides how it
## reads. Subclass per look in scripts/vfx/looks/ and register it in VfxPresenter.LOOK_SCRIPTS.
##
## Every method has a quiet default, so a new look only fills in what it draws. A shape the look
## does not support (supports() false) keeps the engine's placeholder art: nothing goes invisible.
## Looks only READ gameplay objects; they never change them.

const WPS := 1280.0 / 192.0
const MAX_STATUS := 24           # enemies drawn with a status at once (nearest the camera for burns)
const ELEMENTS := preload("res://scripts/vfx/VfxElements.gd")

var vfx                          # the Vfx autoload
var p                            # the presenter (shared helpers: staff position, family tables)

# --- identity and palettes (override in the subclass) -------------------------------------------
func id() -> String: return ""
## Body: core, light, mid, dark, outline (sandbox MAT.*.body).
func body() -> Array: return [Color.WHITE, Color.WHITE, Color.GRAY, Color.DIM_GRAY, Color.BLACK]
## Sparks: bright to dark.
func spark() -> Array: return body().slice(0, 4)
## Accent rim on bodies; nova front dashes (empty = no drawn rim); slash smear core/light/mid.
func rim() -> Color: return body()[2]
func nova_rim() -> Array: return []
func smear() -> Array: return body().slice(0, 3)

## Which shapes this look draws. Unsupported shapes keep the placeholder.
## kinds: projectile, burst, slash, trap, nova, wave, self, charge, zone, field, beam, infection, eruption
func supports(kind: String) -> bool:
	return kind in ["projectile", "burst", "slash", "trap", "nova", "field", "beam", "infection", "eruption"]

# --- projectiles ------------------------------------------------------------------------------
## Particles behind a moving body. native = this look is the spell's own (else a keyword accent).
func trail(_part, _st: Dictionary, _pos: Vector2, _vel: Vector2, _dist: float, _dt: float, _native: bool) -> void:
	pass

## Draw the body; return false to fall back to the presenter's shaded body in this palette.
func draw_body(_buf: PackedByteArray, _part, _st: Dictionary, _pos: Vector2, _dir: Vector2, _sc: float) -> bool:
	return false

## A projectile touched an enemy. spear = piercing family; own = this look is the native one;
## bursts = the part spawns its own burst on hit (so skip the big impact).
func hit(st: Dictionary, x: float, y: float, _own: bool, _bursts: bool) -> void:
	for i in 8:
		var ang := randf() * TAU
		vfx.spark(x, y, cos(ang) * 30.0, sin(ang) * 30.0, 0.3, spark())
	vfx.star(x, y, 2.4, 0.07, 4, body()[0])

## A projectile ran out without hitting anything.
func fizzle(x: float, y: float) -> void:
	for i in 4:
		vfx.spark(x, y, (randf() - 0.5) * 20.0, -(6.0 + randf() * 12.0), 0.3 + randf() * 0.2, spark())

## Goo for the water shaders (water / plague bodies, pools); default none.
func goo(_st: Dictionary, _part, _t: float) -> void:
	pass

# --- bursts and contacts ----------------------------------------------------------------------
## Instant area of radius r_su (sandbox units) at pos.
func burst(pos: Vector2, r_su: float) -> void:
	contact(pos.x, pos.y)

## Small per-contact pop (spears, keyword accents).
func contact(x: float, y: float) -> void:
	for i in 6:
		var a := randf() * TAU
		vfx.spark(x, y, cos(a) * 24.0, sin(a) * 20.0, 0.3, spark())

## Particles along a moving edge (slash smear, wave crest).
func emit_at(_x: float, _y: float, _fx: float, _fy: float) -> void:
	pass

# --- fields -----------------------------------------------------------------------------------
## vfx.field options for this look's ground (floor shader look, goo layer). Empty = no field.
func field_options() -> Dictionary:
	return {"look": vfx.field_look(id())}
func field_start(_A: Dictionary) -> void:
	pass
func field_step(_A: Dictionary, _dt: float) -> void:
	pass
## As a keyword accent over another look's field: own particles at half rate.
func accent_field(A: Dictionary, dt: float) -> void:
	field_step(A, dt * 0.5)
func draw_field(_buf: PackedByteArray, _A: Dictionary) -> void:
	pass

# --- novas ------------------------------------------------------------------------------------
func nova_start(_part, _c: Vector2, _R: float) -> void:
	pass
## k = front / full radius.
func nova_step(_c: Vector2, _r: float, _k: float, _st: Dictionary, _dt: float) -> void:
	pass
func nova_end(_c: Vector2, _R: float) -> void:
	pass
func accent_nova(c: Vector2, r: float, k: float, dt: float) -> void:
	nova_step(c, r, k, {"seed": randf() * 6.0}, dt * 0.5)

# --- other shapes -----------------------------------------------------------------------------
## Self-targeted cast at the caster (Life).
func self_cast(_at: Vector2) -> void:
	pass
## Cone growing from the caster (Earth Shield's eruption): spray along the front.
func eruption_at(x: float, y: float, a: float) -> void:
	vfx.spark(x, y, cos(a) * 20.0, sin(a) * 20.0, 0.3, spark())

# --- statuses on enemies (reads StatusComponent, never changes it) ----------------------------
func status_step(_dt: float) -> void:
	pass
func draw_status(_buf: PackedByteArray) -> void:
	pass

# --- shared helpers ---------------------------------------------------------------------------
static func in_disk(x: float, y: float, r: float) -> Vector2:
	var a := randf() * TAU
	var d := sqrt(randf()) * r * 0.9
	return Vector2(x + cos(a) * d, y + sin(a) * d)

## Enemies carrying any of these statuses (capped), in group order.
func enemies_with(statuses: Array, cap: int = MAX_STATUS) -> Array:
	var tree = vfx.get_tree()
	var out := []
	if tree == null:
		return out
	for e in tree.get_nodes_in_group("enemies"):
		if out.size() >= cap:
			break
		if not is_instance_valid(e) or e.get("status") == null:
			continue
		var s = e.status
		if not s.has_method("has"):
			continue
		for name in statuses:
			if s.has(name):
				out.append(e)
				break
	return out
