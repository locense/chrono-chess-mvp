class_name FateResolver
extends RefCounted


func rebuild_from_events(level, state: GameState) -> void:
	if not level.fate_locks_enabled():
		return
	for event in state.current_events:
		register_capture(level, state, event)


func register_capture(level, state: GameState, event) -> void:
	if not level.fate_locks_enabled() or not event.is_capture() or event.captured_piece_id.is_empty():
		return
	if state.temporal_states.has(event.captured_piece_id):
		return
	if state.fate_locks.has(event.captured_piece_id):
		return
	var lock := FateLock.new()
	lock.piece_id = event.captured_piece_id
	lock.death_turn = event.absolute_turn
	lock.source_event_id = event.event_id
	lock.cause = &"normal_capture"
	state.fate_locks[lock.piece_id] = lock


func apply_to_pieces(level, state: GameState, pieces: Dictionary) -> Array:
	var explanations: Array = []
	if not level.fate_locks_enabled():
		return explanations
	var piece_ids: Array = state.fate_locks.keys()
	piece_ids.sort()
	for piece_id in piece_ids:
		var lock: FateLock = state.fate_locks[piece_id]
		var piece = pieces.get(piece_id, null)
		if piece == null or not piece.alive:
			continue
		if state.focus_turn <= lock.death_turn:
			piece.is_fate_echo = true
			explanations.append("Fate lock: %s will vanish after T%02d." % [piece_id, lock.death_turn])
		else:
			piece.alive = false
			explanations.append("Fate resolved at T%02d: %s vanished." % [lock.death_turn, piece_id])
	return explanations
