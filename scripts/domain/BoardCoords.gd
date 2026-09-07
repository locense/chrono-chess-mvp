class_name BoardCoords
extends RefCounted

const BOARD_SIZE := 8
const FILES := "abcdefgh"


static func from_algebraic(value: String) -> Vector2i:
	var raw := value.strip_edges().to_lower()
	if raw.length() != 2:
		return Vector2i(-1, -1)
	var file := FILES.find(raw.substr(0, 1))
	var rank_text := raw.substr(1, 1)
	if file < 0 or not rank_text.is_valid_int():
		return Vector2i(-1, -1)
	var rank := int(rank_text) - 1
	var square := Vector2i(file, rank)
	return square if is_on_board(square) else Vector2i(-1, -1)


static func to_algebraic(square: Vector2i) -> String:
	if not is_on_board(square):
		return "--"
	return "%s%d" % [FILES.substr(square.x, 1), square.y + 1]


static func key(square: Vector2i) -> String:
	return to_algebraic(square)


static func is_on_board(square: Vector2i) -> bool:
	return square.x >= 0 and square.x < BOARD_SIZE and square.y >= 0 and square.y < BOARD_SIZE

