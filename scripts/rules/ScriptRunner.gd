class_name ScriptRunner
extends RefCounted

const MoveEventRef = preload("res://scripts/domain/MoveEvent.gd")
const FateResolverRef = preload("res://scripts/rules/FateResolver.gd")


func apply_after_white_turn(level, state: GameState, white_turn: int) -> GameState:
	for script in level.scripts:
		if int(script.get("after_white_turn", -1)) != white_turn:
			continue
		var script_id := str(script.get("script_id", "script"))
		if _has_event(state, script_id):
			continue
		var event_data: Dictionary = script.get("event", {})
		var response = MoveEventRef.from_dict(event_data)
		response.event_id = script_id
		response.absolute_turn = state.focus_turn
		response.actor_id = str(event_data.get("actor", ""))
		response.side = StringName(str(event_data.get("side", "black")))
		response.kind = StringName(str(event_data.get("kind", "move")))
		state.current_events.append(response)
		state.next_event_serial += 1
		if response.is_capture():
			FateResolverRef.new().register_capture(level, state, response)
		state.focus_turn += 1
		state.active_side = &"white"
	return state


func _has_event(state: GameState, event_id: String) -> bool:
	for event in state.current_events:
		if event.event_id == event_id:
			return true
	return false

