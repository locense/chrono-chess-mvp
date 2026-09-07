class_name WorldView
extends RefCounted

var pieces_by_id: Dictionary = {}
var pieces_by_square: Dictionary = {}
var legal_moves_by_piece: Dictionary = {}
var frozen_piece_ids: Dictionary = {}
var overlaps: Dictionary = {}
var explanations: Array = []
var status: StringName = &"playing"
var winning_reason := ""


func add_piece(piece: PieceState) -> void:
	pieces_by_id[piece.piece_id] = piece
	var square_key := BoardCoords.key(piece.square)
	if not pieces_by_square.has(square_key):
		pieces_by_square[square_key] = []
	pieces_by_square[square_key].append(piece.piece_id)


func get_piece_ids_at(square: Vector2i) -> Array:
	return pieces_by_square.get(BoardCoords.key(square), []).duplicate()


func get_primary_piece_at(square: Vector2i) -> PieceState:
	var ids := get_piece_ids_at(square)
	if ids.is_empty():
		return null
	return pieces_by_id.get(ids[0], null)

