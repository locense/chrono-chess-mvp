extends Control

signal action_requested(piece_id: String, destination: Vector2i, is_temporal: bool)
signal selection_changed(piece_id: String)
signal rewind_hotkey_requested
signal undo_hotkey_requested
signal cancel_requested

const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")

const LIGHT_SQUARE := Color("D8D3C7")
const DARK_SQUARE := Color("6F7C78")
const LIGHT_SQUARE_HIGH_CONTRAST := Color("F0E9D7")
const DARK_SQUARE_HIGH_CONTRAST := Color("425253")
const SELECTED_COLOR := Color("E3B858")
const LEGAL_COLOR := Color("2FC4B1")
const OVERLAP_COLOR := Color("D84B87")
const WHITE_PIECE := Color("F1F3EA")
const BLACK_PIECE := Color("22292B")
const TEMPORAL_COLOR := Color("51B8D5")
const FATE_COLOR := Color("D8A64B")

var world: WorldView = null
var selected_piece_id := ""
var _selected_moves: Array = []
var _focus_square := Vector2i(0, 0)
var high_contrast := false
var interaction_enabled := true


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(384, 384)
	tooltip_text = "Board: select a white piece, then select a highlighted square."
	queue_redraw()


func set_world(next_world: WorldView) -> void:
	world = next_world
	# Legal targets belong to one resolved snapshot and must never survive a reset.
	clear_selection()
	queue_redraw()


func set_selected_moves(moves: Array) -> void:
	_selected_moves = moves.duplicate()
	queue_redraw()


func clear_selection() -> void:
	if selected_piece_id.is_empty():
		return
	selected_piece_id = ""
	_selected_moves.clear()
	selection_changed.emit("")
	queue_redraw()


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled
	if not enabled:
		clear_selection()


func get_selected_piece_id() -> String:
	return selected_piece_id


func _draw() -> void:
	var board_rect := _board_rect()
	var cell := board_rect.size.x / float(BoardCoordsRef.BOARD_SIZE)
	draw_rect(board_rect.grow(4.0), Color("0B0F11"), true)
	draw_rect(board_rect.grow(2.0), Color("B8A466"), false, 2.0)
	for display_row in range(BoardCoordsRef.BOARD_SIZE):
		for file_index in range(BoardCoordsRef.BOARD_SIZE):
			var square := Vector2i(file_index, BoardCoordsRef.BOARD_SIZE - 1 - display_row)
			var rect := Rect2(board_rect.position + Vector2(file_index * cell, display_row * cell), Vector2(cell, cell))
			var light := (file_index + square.y) % 2 == 0
			var color := _square_color(light)
			draw_rect(rect, color, true)
			_draw_square_markers(square, rect, cell)
	if world == null:
		return
	var piece_ids: Array = world.pieces_by_id.keys()
	piece_ids.sort_custom(func(left, right):
		var left_piece = world.pieces_by_id[left]
		var right_piece = world.pieces_by_id[right]
		if left_piece.is_temporal == right_piece.is_temporal:
			return String(left) < String(right)
		return not left_piece.is_temporal and right_piece.is_temporal
	)
	for piece_id in piece_ids:
		_draw_piece(world.pieces_by_id[piece_id], _square_rect(world.pieces_by_id[piece_id].square, board_rect, cell), cell)


func _draw_square_markers(square: Vector2i, rect: Rect2, cell: float) -> void:
	if world == null:
		return
	if world.overlaps.has(BoardCoordsRef.key(square)):
		draw_rect(rect.grow(-cell * 0.08), OVERLAP_COLOR, false, maxf(2.0, cell * 0.045))
		draw_line(rect.position + Vector2(cell * 0.18, cell * 0.18), rect.end - Vector2(cell * 0.18, cell * 0.18), OVERLAP_COLOR, maxf(2.0, cell * 0.035))
		draw_line(Vector2(rect.end.x - cell * 0.18, rect.position.y + cell * 0.18), Vector2(rect.position.x + cell * 0.18, rect.end.y - cell * 0.18), OVERLAP_COLOR, maxf(2.0, cell * 0.035))
	if _selected_moves.has(square):
		var target_piece = world.get_primary_piece_at(square)
		var center := rect.get_center()
		if target_piece == null:
			draw_circle(center, cell * 0.12, LEGAL_COLOR)
		else:
			draw_arc(center, cell * 0.34, 0.0, TAU, 28, LEGAL_COLOR, maxf(2.0, cell * 0.045), true)
	if not selected_piece_id.is_empty() and world.pieces_by_id.has(selected_piece_id):
		if world.pieces_by_id[selected_piece_id].square == square:
			draw_rect(rect.grow(-cell * 0.06), SELECTED_COLOR, false, maxf(2.0, cell * 0.045))
	if _focus_square == square:
		draw_rect(rect.grow(-cell * 0.18), Color("E8EFF0", 0.55), false, 1.0)


func _draw_piece(piece, rect: Rect2, cell: float) -> void:
	var center := rect.get_center()
	var radius := cell * 0.28
	var fill := WHITE_PIECE if piece.side == &"white" else BLACK_PIECE
	var outline := Color("1D2527") if piece.side == &"white" else Color("E2E9E3")
	if piece.is_fate_echo:
		fill.a = 0.56
		outline.a = 0.7
	if piece.is_temporal:
		draw_arc(center, radius * 1.23, 0.0, TAU, 32, TEMPORAL_COLOR, maxf(2.0, cell * 0.052), true)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 24, outline, maxf(1.5, cell * 0.032), true)
	_draw_role_mark(piece.role, center, radius, outline)
	if piece.is_fate_echo:
		draw_arc(center, radius * 1.45, 0.16, 1.78, 14, FATE_COLOR, maxf(1.5, cell * 0.03), true)
		draw_arc(center, radius * 1.45, 3.3, 4.92, 14, FATE_COLOR, maxf(1.5, cell * 0.03), true)
	if piece.is_temporal:
		draw_circle(center, radius * 0.14, TEMPORAL_COLOR)


func _draw_role_mark(role: StringName, center: Vector2, radius: float, color: Color) -> void:
	var stroke := maxf(1.5, radius * 0.16)
	match role:
		&"rook":
			var rook_rect := Rect2(center - Vector2(radius * 0.46, radius * 0.42), Vector2(radius * 0.92, radius * 0.84))
			draw_rect(rook_rect, color, false, stroke)
			draw_line(Vector2(rook_rect.position.x, rook_rect.position.y + radius * 0.2), Vector2(rook_rect.end.x, rook_rect.position.y + radius * 0.2), color, stroke)
		&"bishop":
			draw_line(center + Vector2(-radius * 0.36, radius * 0.42), center + Vector2(radius * 0.36, -radius * 0.42), color, stroke)
			draw_circle(center, radius * 0.14, color, false, stroke)
		&"knight":
			var points := PackedVector2Array([
				center + Vector2(-radius * 0.42, radius * 0.42),
				center + Vector2(-radius * 0.18, -radius * 0.45),
				center + Vector2(radius * 0.42, radius * 0.1),
				center + Vector2(radius * 0.2, radius * 0.42),
			])
			draw_polyline(points, color, stroke, true)
		&"king":
			draw_line(center + Vector2(0, -radius * 0.48), center + Vector2(0, radius * 0.42), color, stroke)
			draw_line(center + Vector2(-radius * 0.3, -radius * 0.18), center + Vector2(radius * 0.3, -radius * 0.18), color, stroke)
		_:
			draw_circle(center, radius * 0.18, color)


func _gui_input(event: InputEvent) -> void:
	if world == null or not interaction_enabled:
		return
	if event is InputEventMouseButton and event.pressed:
		grab_focus()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			clear_selection()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			_activate_square(_square_at(get_local_mouse_position()))
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				rewind_hotkey_requested.emit()
			KEY_Z:
				undo_hotkey_requested.emit()
			KEY_ESCAPE:
				cancel_requested.emit()
			KEY_LEFT:
				_focus_square.x = maxi(0, _focus_square.x - 1)
				queue_redraw()
			KEY_RIGHT:
				_focus_square.x = mini(BoardCoordsRef.BOARD_SIZE - 1, _focus_square.x + 1)
				queue_redraw()
			KEY_UP:
				_focus_square.y = mini(BoardCoordsRef.BOARD_SIZE - 1, _focus_square.y + 1)
				queue_redraw()
			KEY_DOWN:
				_focus_square.y = maxi(0, _focus_square.y - 1)
				queue_redraw()
			KEY_ENTER, KEY_SPACE:
				_activate_square(_focus_square)


func _activate_square(square: Vector2i) -> void:
	if not BoardCoordsRef.is_on_board(square):
		return
	if not selected_piece_id.is_empty() and _selected_moves.has(square):
		var selected_piece = world.pieces_by_id.get(selected_piece_id, null)
		if selected_piece != null:
			action_requested.emit(selected_piece_id, square, selected_piece.is_temporal)
		return
	var piece = _selectable_piece_at(square)
	if piece == null:
		clear_selection()
		return
	selected_piece_id = piece.piece_id
	_selected_moves = world.legal_moves_by_piece.get(piece.piece_id, []).duplicate()
	selection_changed.emit(selected_piece_id)
	queue_redraw()


func _selectable_piece_at(square: Vector2i):
	var piece = world.get_primary_piece_at(square)
	if piece == null:
		return null
	if piece.side != &"white" or world.status != &"playing":
		return null
	return piece


func _square_at(local_position: Vector2) -> Vector2i:
	var board_rect := _board_rect()
	if not board_rect.has_point(local_position):
		return Vector2i(-1, -1)
	var cell := board_rect.size.x / float(BoardCoordsRef.BOARD_SIZE)
	var file_index := int((local_position.x - board_rect.position.x) / cell)
	var display_row := int((local_position.y - board_rect.position.y) / cell)
	return Vector2i(file_index, BoardCoordsRef.BOARD_SIZE - 1 - display_row)


func _board_rect() -> Rect2:
	var board_size := minf(size.x, size.y)
	return Rect2((size - Vector2(board_size, board_size)) * 0.5, Vector2(board_size, board_size))


func _square_rect(square: Vector2i, board_rect: Rect2, cell: float) -> Rect2:
	var display_row := BoardCoordsRef.BOARD_SIZE - 1 - square.y
	return Rect2(board_rect.position + Vector2(square.x * cell, display_row * cell), Vector2(cell, cell))


func _square_color(light: bool) -> Color:
	if high_contrast:
		return LIGHT_SQUARE_HIGH_CONTRAST if light else DARK_SQUARE_HIGH_CONTRAST
	return LIGHT_SQUARE if light else DARK_SQUARE
