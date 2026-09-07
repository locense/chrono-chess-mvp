class_name GameReducer
extends RefCounted

const TimelineServiceRef = preload("res://scripts/rules/TimelineService.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")


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
	if actor == null or actor.side != state.active_side or actor.is_temporal:
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
		event.kind = &"capture"
		event.captured_piece_id = target.piece_id
	next.current_events.append(event)
	next.next_event_serial += 1
	next.focus_turn += 1
	next.active_side = &"black" if actor.side == &"white" else &"white"
	if actor.side == &"white":
		next.white_actions_used += 1
	var next_view = resolver.resolve(level, next)
	next.status = next_view.status
	return {"state": next, "view": next_view, "error": ""}

