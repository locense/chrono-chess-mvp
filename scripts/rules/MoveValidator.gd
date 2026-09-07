class_name MoveValidator
extends RefCounted

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")


func legal_moves(world, actor: PieceState) -> Array:
	if actor == null or not actor.alive or actor.is_temporal:
		return []
	if world.frozen_piece_ids.has(actor.piece_id):
		return []
	match actor.role:
		&"rook":
			return _sliding_moves(world, actor, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)])
		&"bishop":
			return _sliding_moves(world, actor, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)])
		&"knight":
			return _jump_moves(world, actor, [
				Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
				Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2),
			])
		&"king":
			return _jump_moves(world, actor, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
			])
		_:
			return []


func _sliding_moves(world, actor: PieceState, directions: Array) -> Array:
	var moves: Array = []
	for direction_value in directions:
		var direction: Vector2i = direction_value
		var target: Vector2i = actor.square + direction
		while BoardCoordsRef.is_on_board(target):
			if world.overlaps.has(BoardCoordsRef.key(target)):
				break
			var blocker = world.get_primary_piece_at(target)
			if blocker == null:
				moves.append(target)
			else:
				if blocker.side != actor.side:
					moves.append(target)
				break
			target += direction
	return moves


func _jump_moves(world, actor: PieceState, deltas: Array) -> Array:
	var moves: Array = []
	for delta_value in deltas:
		var delta: Vector2i = delta_value
		var target: Vector2i = actor.square + delta
		if not BoardCoordsRef.is_on_board(target):
			continue
		if world.overlaps.has(BoardCoordsRef.key(target)):
			continue
		var blocker = world.get_primary_piece_at(target)
		if blocker == null or blocker.side != actor.side:
			moves.append(target)
	return moves
