class_name PieceState
extends RefCounted

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")

var piece_id := ""
var side: StringName = &"white"
var role: StringName = &"king"
var square := Vector2i(-1, -1)
var alive := true
var is_fate_echo := false
var is_temporal := false


static func from_dict(data: Dictionary) -> PieceState:
	var piece := PieceState.new()
	piece.piece_id = str(data.get("piece_id", ""))
	piece.side = StringName(str(data.get("side", "white")))
	piece.role = StringName(str(data.get("role", "king")))
	piece.square = BoardCoordsRef.from_algebraic(str(data.get("square", "")))
	piece.alive = bool(data.get("alive", true))
	piece.is_temporal = bool(data.get("is_temporal", false))
	return piece


func copy_state() -> PieceState:
	var result := PieceState.new()
	result.piece_id = piece_id
	result.side = side
	result.role = role
	result.square = square
	result.alive = alive
	result.is_fate_echo = is_fate_echo
	result.is_temporal = is_temporal
	return result


func to_dict() -> Dictionary:
	return {
		"piece_id": piece_id,
		"side": String(side),
		"role": String(role),
		"square": BoardCoordsRef.to_algebraic(square),
		"alive": alive,
		"is_fate_echo": is_fate_echo,
		"is_temporal": is_temporal,
	}

