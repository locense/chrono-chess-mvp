class_name TemporalState
extends RefCounted

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")

var piece_id := ""
var side: StringName = &"white"
var role: StringName = &"rook"
var square := Vector2i(-1, -1)
var alive := true
var changed_at_absolute_turn := 0
var projection_start_turn := 0


static func from_piece(piece: PieceState, changed_at_turn := 0) -> TemporalState:
	var state := TemporalState.new()
	state.piece_id = piece.piece_id
	state.side = piece.side
	state.role = piece.role
	state.square = piece.square
	state.alive = piece.alive
	state.changed_at_absolute_turn = changed_at_turn
	return state


func copy_state() -> TemporalState:
	var result := TemporalState.new()
	result.piece_id = piece_id
	result.side = side
	result.role = role
	result.square = square
	result.alive = alive
	result.changed_at_absolute_turn = changed_at_absolute_turn
	result.projection_start_turn = projection_start_turn
	return result


func as_piece() -> PieceState:
	var piece := PieceState.new()
	piece.piece_id = piece_id
	piece.side = side
	piece.role = role
	piece.square = square
	piece.alive = alive
	piece.is_temporal = true
	return piece


func to_dict() -> Dictionary:
	return {
		"piece_id": piece_id,
		"side": String(side),
		"role": String(role),
		"square": BoardCoordsRef.to_algebraic(square),
		"alive": alive,
		"changed_at_absolute_turn": changed_at_absolute_turn,
		"projection_start_turn": projection_start_turn,
	}

