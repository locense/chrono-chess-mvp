class_name StateHasher
extends RefCounted


func hash_world(state: GameState, view: WorldView) -> String:
	var pieces: Array = []
	var piece_ids: Array = view.pieces_by_id.keys()
	piece_ids.sort()
	for piece_id in piece_ids:
		pieces.append(view.pieces_by_id[piece_id].to_dict())
	var locks: Array = []
	var lock_ids: Array = state.fate_locks.keys()
	lock_ids.sort()
	for piece_id in lock_ids:
		locks.append(state.fate_locks[piece_id].to_dict())
	var temporal_states: Array = []
	var temporal_ids: Array = state.temporal_states.keys()
	temporal_ids.sort()
	for piece_id in temporal_ids:
		temporal_states.append(state.temporal_states[piece_id].to_dict())
	var events: Array = []
	for event in state.current_events:
		events.append(event.to_dict())
	var payload := {
		"focus_turn": state.focus_turn,
		"chronal_energy": state.chronal_energy,
		"white_actions_used": state.white_actions_used,
		"status": String(view.status),
		"pieces": pieces,
		"fate_locks": locks,
		"temporal_states": temporal_states,
		"overlaps": view.overlaps,
		"events": events,
	}
	var canonical := JSON.stringify(payload, "", true)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical.to_utf8_buffer())
	return context.finish().hex_encode()
