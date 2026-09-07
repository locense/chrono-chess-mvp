class_name MoveEvent
extends RefCounted

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")

var event_id := ""
var absolute_turn := 0
var actor_id := ""
var side: StringName = &"white"
var kind: StringName = &"move"
var from_square := Vector2i(-1, -1)
var to_square := Vector2i(-1, -1)
var captured_piece_id := ""


static func from_dict(data: Dictionary) -> MoveEvent:
	var event := MoveEvent.new()
	event.event_id = str(data.get("event_id", ""))
	event.absolute_turn = int(data.get("absolute_turn", 0))
	event.actor_id = str(data.get("actor", data.get("actor_id", "")))
	event.side = StringName(str(data.get("side", "white")))
	event.kind = StringName(str(data.get("kind", "move")))
	event.from_square = BoardCoordsRef.from_algebraic(str(data.get("from", "")))
	event.to_square = BoardCoordsRef.from_algebraic(str(data.get("to", "")))
	var captured = data.get("captured_piece_id", null)
	event.captured_piece_id = "" if captured == null else str(captured)
	return event


func copy_event() -> MoveEvent:
	var result := MoveEvent.new()
	result.event_id = event_id
	result.absolute_turn = absolute_turn
	result.actor_id = actor_id
	result.side = side
	result.kind = kind
	result.from_square = from_square
	result.to_square = to_square
	result.captured_piece_id = captured_piece_id
	return result


func is_capture() -> bool:
	return not captured_piece_id.is_empty()


func to_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"absolute_turn": absolute_turn,
		"actor": actor_id,
		"side": String(side),
		"kind": String(kind),
		"from": BoardCoordsRef.to_algebraic(from_square),
		"to": BoardCoordsRef.to_algebraic(to_square),
		"captured_piece_id": captured_piece_id if is_capture() else null,
	}

