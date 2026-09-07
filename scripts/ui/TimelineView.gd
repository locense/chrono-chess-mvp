extends Control

signal rewind_target_selected(target_turn: int)

const NODE_WIDTH := 76.0
const NODE_RADIUS := 16.0
const ACTIVE_COLOR := Color("4FB6D1")
const AVAILABLE_COLOR := Color("D7A64D")
const ARCHIVED_COLOR := Color("5B6368")
const LOCK_COLOR := Color("D84B87")

var level = null
var state: GameState = null
var world: WorldView = null
var preview_turn := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 132)
	tooltip_text = "Timeline: select an earlier gold node to preview a rewind."
	queue_redraw()


func set_session(next_level, next_state: GameState, next_world: WorldView) -> void:
	level = next_level
	state = next_state
	world = next_world
	queue_redraw()


func set_preview_turn(turn: int) -> void:
	preview_turn = turn
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("171D20"), true)
	if level == null or state == null:
		return
	var max_turn := _max_visible_turn()
	var baseline_y := size.y * 0.53
	var start_x := 30.0
	var last_center := Vector2.ZERO
	for turn in range(max_turn + 1):
		var center := Vector2(start_x + NODE_WIDTH * turn + NODE_WIDTH * 0.5, baseline_y)
		if turn > 0:
			draw_line(last_center, center, Color("657075"), 2.0)
		last_center = center
		var color := _node_color(turn)
		draw_circle(center, NODE_RADIUS, color)
		draw_arc(center, NODE_RADIUS, 0.0, TAU, 18, Color("EAF0EE"), 1.5, true)
		if turn == state.focus_turn:
			draw_arc(center, NODE_RADIUS + 6.0, 0.0, TAU, 22, Color("E3B858"), 2.0, true)
		if turn == preview_turn:
			draw_arc(center, NODE_RADIUS + 10.0, 0.0, TAU, 22, Color("2FC4B1"), 2.0, true)
		_draw_label("T%02d" % turn, center + Vector2(-23.0, 40.0), 46.0, 14, Color("EAF0EE"))
		_draw_turn_markers(turn, center)
	_draw_label("TIME TRACE", Vector2(18.0, 24.0), 120.0, 13, Color("AFC0BD"))
	if preview_turn >= 0:
		_draw_label("Preview", Vector2(size.x - 86.0, 24.0), 72.0, 13, Color("2FC4B1"))


func _gui_input(event: InputEvent) -> void:
	if level == null or state == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target := _turn_at(get_local_mouse_position())
		if target >= 0 and _can_rewind_to(target):
			rewind_target_selected.emit(target)


func _max_visible_turn() -> int:
	var result := maxi(state.focus_turn, level.start_focus_turn)
	for event in state.archived_future_events:
		result = maxi(result, event.absolute_turn + 1)
	for event in state.current_events:
		result = maxi(result, event.absolute_turn + 1)
	return result


func _node_color(turn: int) -> Color:
	if _is_archived(turn):
		return ARCHIVED_COLOR
	if _can_rewind_to(turn):
		return AVAILABLE_COLOR
	if turn == state.focus_turn:
		return ACTIVE_COLOR
	return Color("465156")


func _can_rewind_to(turn: int) -> bool:
	return level.rewind_targets.has(turn) and turn < state.focus_turn and state.chronal_energy >= level.rewind_cost() and state.status == &"playing"


func _is_archived(turn: int) -> bool:
	for event in state.archived_future_events:
		# A timeline node represents the snapshot after its preceding event.
		if event.absolute_turn + 1 == turn:
			return true
	return false


func _draw_turn_markers(turn: int, center: Vector2) -> void:
	for piece_id in state.fate_locks:
		var lock: FateLock = state.fate_locks[piece_id]
		if lock.death_turn == turn:
			draw_circle(center + Vector2(13.0, -13.0), 4.0, LOCK_COLOR)


func _turn_at(position: Vector2) -> int:
	var max_turn := _max_visible_turn()
	var baseline_y := size.y * 0.53
	for turn in range(max_turn + 1):
		var center := Vector2(30.0 + NODE_WIDTH * turn + NODE_WIDTH * 0.5, baseline_y)
		if position.distance_to(center) <= 28.0:
			return turn
	return -1


func _draw_label(text: String, position: Vector2, width: float, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
