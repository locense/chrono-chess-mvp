class_name TimelineService
extends RefCounted


func create_initial_state(level) -> GameState:
	var state := GameState.new()
	state.level_id = level.id
	state.focus_turn = level.start_focus_turn
	state.active_side = &"white"
	state.chronal_energy = level.chronal_energy
	state.white_actions_used = 0
	state.status = &"playing"
	for event in level.preplayed_events:
		state.current_events.append(event.copy_event())
	state.next_event_serial = state.current_events.size()
	return state


func try_rewind(level, state: GameState, target_turn: int) -> Dictionary:
	if state.status == &"won":
		return {"state": state, "error": "The puzzle is already complete."}
	if not level.rewind_targets.has(target_turn):
		return {"state": state, "error": "That timeline node is not a rewind target."}
	if target_turn >= state.focus_turn:
		return {"state": state, "error": "Rewind targets must be earlier than the current turn."}
	if state.chronal_energy < level.rewind_cost():
		return {"state": state, "error": "Not enough chronal energy."}
	var next := state.deep_copy()
	next.chronal_energy -= level.rewind_cost()
	next.current_events.clear()
	for event in state.current_events:
		if event.absolute_turn >= target_turn:
			next.archived_future_events.append(event.copy_event())
		else:
			next.current_events.append(event.copy_event())
	next.focus_turn = target_turn
	next.active_side = &"white"
	next.status = &"playing"
	return {"state": next, "error": ""}

