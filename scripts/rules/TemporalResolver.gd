class_name TemporalResolver
extends RefCounted

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")


func legal_moves(world, temporal: TemporalState) -> Array:
	if temporal == null or not temporal.alive or temporal.role != &"rook":
		return []
	var moves: Array = []
	for direction in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var target: Vector2i = temporal.square + direction
		while BoardCoordsRef.is_on_board(target):
			var ordinary = _ordinary_piece_at(world, target)
			if ordinary == null:
				moves.append(target)
			else:
				if not (ordinary.side == temporal.side and ordinary.role == &"king"):
					moves.append(target)
				break
			target += direction
	return moves


func project(level, state: GameState, view: WorldView) -> Dictionary:
	var result := {
		"temporal_pieces": [],
		"frozen_piece_ids": {},
		"overlaps": {},
		"temporal_hits": [],
		"allied_king_conflict": false,
		"explanations": [],
	}
	if not level.temporal_enabled():
		return result
	var temporal_ids: Array = state.temporal_states.keys()
	temporal_ids.sort()
	for temporal_id in temporal_ids:
		var temporal: TemporalState = state.temporal_states[temporal_id]
		if not temporal.alive:
			continue
		var piece := temporal.as_piece()
		var ordinary = _ordinary_piece_at(view, piece.square)
		if ordinary != null:
			if ordinary.role == &"king":
				if ordinary.side != piece.side:
					result["temporal_hits"].append({
						"king_id": ordinary.piece_id,
						"king_side": ordinary.side,
						"temporal_side": piece.side,
						"action_turn": temporal.changed_at_absolute_turn,
					})
					result["explanations"].append("Temporal annihilation at %s." % BoardCoordsRef.to_algebraic(piece.square))
				else:
					result["allied_king_conflict"] = true
					result["explanations"].append("Temporal projection conflicts with the allied king.")
			elif level.overlap_enabled():
				var square_key := BoardCoordsRef.key(piece.square)
				result["frozen_piece_ids"][ordinary.piece_id] = true
				result["overlaps"][square_key] = {
					"ordinary_piece_id": ordinary.piece_id,
					"temporal_piece_id": piece.piece_id,
				}
				result["explanations"].append("Reality overlap at %s freezes %s." % [square_key, ordinary.piece_id])
		result["temporal_pieces"].append(piece)
	return result


func _ordinary_piece_at(view: WorldView, square: Vector2i):
	for piece_id in view.get_piece_ids_at(square):
		var piece = view.pieces_by_id[piece_id]
		if not piece.is_temporal:
			return piece
	return null
