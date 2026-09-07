class_name WorldResolver
extends RefCounted

const MoveValidatorRef = preload("res://scripts/rules/MoveValidator.gd")
const FateResolverRef = preload("res://scripts/rules/FateResolver.gd")


func resolve(level, state: GameState) -> WorldView:
	var ordinary_pieces: Dictionary = {}
	for source_piece in level.initial_pieces:
		if not source_piece.is_temporal:
			ordinary_pieces[source_piece.piece_id] = source_piece.copy_state()
	var events := state.current_events.duplicate()
	events.sort_custom(func(left, right):
		if left.absolute_turn == right.absolute_turn:
			return left.event_id < right.event_id
		return left.absolute_turn < right.absolute_turn
	)
	for event in events:
		if event.absolute_turn >= state.focus_turn:
			continue
		_apply_event(ordinary_pieces, event)
	var view := WorldView.new()
	view.explanations.append_array(FateResolverRef.new().apply_to_pieces(level, state, ordinary_pieces))
	for piece_id in ordinary_pieces:
		var piece = ordinary_pieces[piece_id]
		if piece.alive:
			view.add_piece(piece)
	view.status = _derive_status(level, state)
	view.winning_reason = _winning_reason(level, state, view.status)
	if view.status == &"playing":
		var validator = MoveValidatorRef.new()
		for piece_id in view.pieces_by_id:
			var piece = view.pieces_by_id[piece_id]
			if not piece.is_temporal:
				view.legal_moves_by_piece[piece_id] = validator.legal_moves(view, piece)
	return view


func _apply_event(pieces: Dictionary, event) -> void:
	var actor = pieces.get(event.actor_id, null)
	if actor == null or not actor.alive:
		return
	actor.square = event.to_square
	if event.is_capture():
		var captured = pieces.get(event.captured_piece_id, null)
		if captured != null:
			captured.alive = false


func _derive_status(level, state: GameState) -> StringName:
	if state.status == &"won":
		return &"won"
	if _captured_target_in_window(level, state):
		return &"won"
	if state.status == &"lost":
		return &"lost"
	if state.white_actions_used >= level.white_action_budget:
		return &"lost"
	return &"playing"


func _captured_target_in_window(level, state: GameState) -> bool:
	var target_id := str(level.victory.get("target_king_id", ""))
	var window: Array = level.victory.get("turn_window", [])
	if target_id.is_empty() or window.size() != 2:
		return false
	var first_turn := int(window[0])
	var last_turn := int(window[1])
	for event in state.current_events:
		if event.absolute_turn < state.focus_turn and event.captured_piece_id == target_id:
			return event.absolute_turn >= first_turn and event.absolute_turn <= last_turn
	return false


func _winning_reason(level, state: GameState, status: StringName) -> String:
	if status == &"won":
		return "Target king captured in the required turn window."
	if status == &"lost" and state.white_actions_used >= level.white_action_budget:
		return "The white action budget was exhausted."
	return ""
