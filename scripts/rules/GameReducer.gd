class_name GameReducer
extends RefCounted

const TimelineServiceRef = preload("res://scripts/rules/TimelineService.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")
const FateResolverRef = preload("res://scripts/rules/FateResolver.gd")
const ScriptRunnerRef = preload("res://scripts/rules/ScriptRunner.gd")
const TemporalResolverRef = preload("res://scripts/rules/TemporalResolver.gd")


func create_initial_state(level) -> GameState:
	return TimelineServiceRef.new().create_initial_state(level)


func try_rewind(level, state: GameState, target_turn: int) -> Dictionary:
	return TimelineServiceRef.new().try_rewind(level, state, target_turn)


func try_move(level, state: GameState, actor_id: String, destination: Vector2i) -> Dictionary:
	var resolver = WorldResolverRef.new()
	var view = resolver.resolve(level, state)
	if view.status != &"playing":
		return {"state": state, "view": view, "error": "The current puzzle state cannot accept a move."}
	var actor = view.pieces_by_id.get(actor_id, null)
	if actor == null or state.active_side != &"white" or actor.side != &"white" or actor.is_temporal:
		return {"state": state, "view": view, "error": "That piece cannot act now."}
	var legal_moves: Array = view.legal_moves_by_piece.get(actor_id, [])
	if not legal_moves.has(destination):
		return {"state": state, "view": view, "error": "That destination is not legal."}
	var next := state.deep_copy()
	var event := MoveEvent.new()
	event.event_id = "%s_t%02d_%03d" % [actor_id, state.focus_turn, state.next_event_serial]
	event.absolute_turn = state.focus_turn
	event.actor_id = actor_id
	event.side = actor.side
	event.kind = &"move"
	event.from_square = actor.square
	event.to_square = destination
	var target = view.get_primary_piece_at(destination)
	if target != null:
		event.kind = &"temporal_capture" if target.is_temporal else &"capture"
		event.captured_piece_id = target.piece_id
		if target.is_temporal:
			next.temporal_states[target.piece_id].alive = false
	next.current_events.append(event)
	next.next_event_serial += 1
	if event.is_capture():
		FateResolverRef.new().register_capture(level, next, event)
	next.focus_turn += 1
	next.active_side = &"black" if actor.side == &"white" else &"white"
	if actor.side == &"white":
		next.white_actions_used += 1
	var next_view = resolver.resolve(level, next)
	if actor.side == &"white" and next_view.status == &"playing":
		next = ScriptRunnerRef.new().apply_after_white_turn(level, next, event.absolute_turn)
		next_view = resolver.resolve(level, next)
	next.status = next_view.status
	return {"state": next, "view": next_view, "error": ""}


func try_temporal_move(level, state: GameState, temporal_id: String, destination: Vector2i) -> Dictionary:
	var resolver = WorldResolverRef.new()
	var view = resolver.resolve(level, state)
	if not level.temporal_enabled() or view.status != &"playing":
		return {"state": state, "view": view, "error": "Temporal movement is unavailable."}
	if state.active_side != &"white":
		return {"state": state, "view": view, "error": "It is not the player's turn."}
	var temporal = state.temporal_states.get(temporal_id, null)
	if temporal == null or temporal.side != &"white" or not temporal.alive:
		return {"state": state, "view": view, "error": "That temporal piece cannot act now."}
	var legal_moves: Array = TemporalResolverRef.new().legal_moves(view, temporal)
	if not legal_moves.has(destination):
		return {"state": state, "view": view, "error": "That temporal destination is illegal."}
	if _would_conflict_with_allied_king(level, state, temporal_id, destination, resolver):
		return {"state": state, "view": view, "error": "That temporal projection conflicts with the allied king in recorded history."}
	var next := state.deep_copy()
	next.temporal_states[temporal_id].square = destination
	next.temporal_states[temporal_id].changed_at_absolute_turn = state.focus_turn
	next.focus_turn += 1
	next.active_side = &"black"
	next.white_actions_used += 1
	var next_view = resolver.resolve(level, next)
	if next_view.status == &"playing":
		next = ScriptRunnerRef.new().apply_after_white_turn(level, next, state.focus_turn)
		next_view = resolver.resolve(level, next)
	next.status = next_view.status
	return {"state": next, "view": next_view, "error": ""}


func _would_conflict_with_allied_king(level, state: GameState, temporal_id: String, destination: Vector2i, resolver) -> bool:
	var candidate := state.deep_copy()
	candidate.temporal_states[temporal_id].square = destination
	var projection_start: int = int(candidate.temporal_states[temporal_id].projection_start_turn)
	for historical_turn in range(projection_start, state.focus_turn + 1):
		candidate.focus_turn = historical_turn
		var historical_view = resolver.resolve(level, candidate)
		if historical_view.temporal_allied_king_conflict:
			return true
	return false
