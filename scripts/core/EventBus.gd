extends RefCounted
## Gameplay event bus (doc 19 §5.4).
##
## Producers emit small facts; consumers (style score, stats, audio, HUD, VFX, achievements,
## debug overlay, later networking) subscribe. Producers never know consumers.
##
## Rules:
## - Every event is declared in EVENTS with its required fields. Unknown events and missing
##   fields are reported in debug builds.
## - Payloads carry ids (actor_id, cast_id, spell_id), never node references kept past the frame.
## - Dispatch is synchronous, in subscription order. Gameplay must not depend on a listener's
##   side effects: listeners observe, they do not decide outcomes.
##
## Usage:
##   const EventBus = preload("res://scripts/core/EventBus.gd")
##   EventBus.on("kill", _on_kill)
##   EventBus.emit("kill", {"target_id": id, "source_id": caster, "cast_id": cast, "position": pos})

const EVENTS = {
	"cast_released": ["caster_id", "spell_id", "cast_id"],
	"part_spawned": ["cast_id", "part"],
	"hit": ["cast_id", "target_id"],
	"damage_dealt": ["source_id", "cast_id", "target_id", "per_type", "total", "killed"],
	"hit_taken": ["target_id", "amount", "source_id"],
	"heal": ["target_id", "amount", "source_id"],
	"block": ["target_id", "source_id"],
	"status_applied": ["target_id", "status", "cast_id"],
	"status_expired": ["target_id", "status"],
	"reaction": ["target_id", "reaction", "cast_id"],
	"kill": ["target_id", "source_id", "cast_id", "position"],
	"pickup": ["collector_id", "kind", "amount"],
	"level_up": ["actor_id", "level"],
	"upgrade_taken": ["actor_id", "upgrade_id"],
	"objective_changed": ["objective_id", "state"],
	"run_state_changed": ["from", "to"],
}

static var _listeners: Dictionary = {}

## Subscribes callable(payload: Dictionary) to an event.
static func on(event: String, callable: Callable) -> void:
	if not _known(event):
		return
	if not _listeners.has(event):
		_listeners[event] = []
	if not _listeners[event].has(callable):
		_listeners[event].append(callable)

static func off(event: String, callable: Callable) -> void:
	if _listeners.has(event):
		_listeners[event].erase(callable)

## Delivers payload to every listener of event, in subscription order. Returns how many ran.
static func emit(event: String, payload: Dictionary = {}) -> int:
	if not _known(event):
		return 0
	if OS.is_debug_build():
		for field in EVENTS[event]:
			if not payload.has(field):
				push_error("EventBus: '%s' is missing '%s'" % [event, field])
	var delivered := 0
	var listeners: Array = _listeners.get(event, [])
	for callable in listeners.duplicate():
		if not callable.is_valid():
			listeners.erase(callable)  # listener's object was freed
			continue
		callable.call(payload)
		delivered += 1
	return delivered

static func listener_count(event: String) -> int:
	return _listeners.get(event, []).size()

## Drops every subscription (new run, tests).
static func reset() -> void:
	_listeners.clear()

static func _known(event: String) -> bool:
	if EVENTS.has(event):
		return true
	push_error("EventBus: unknown event '%s'; declare it in EventBus.EVENTS" % event)
	return false
