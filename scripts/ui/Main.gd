extends Control

const BoardViewRef = preload("res://scripts/ui/BoardView.gd")
const TimelineViewRef = preload("res://scripts/ui/TimelineView.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")
const TemporalResolverRef = preload("res://scripts/rules/TemporalResolver.gd")
const MarkTexture = preload("res://assets/placeholder/chronal_mark.svg")

const BG := Color("101517")
const PANEL := Color("1B2326")
const PANEL_ALT := Color("222C2F")
const BORDER := Color("405154")
const TEXT := Color("EDF1EB")
const MUTED := Color("A9B8B4")
const CYAN := Color("2FC4B1")
const GOLD := Color("D7A64D")
const MAGENTA := Color("D84B87")
const RED := Color("D66652")

var board = null
var timeline = null
var level_select = null
var title_label = null
var status_label = null
var energy_label = null
var message_label = null
var inspector_title = null
var inspector_body = null
var undo_button = null
var rewind_button = null
var rewind_bar = null
var rewind_description = null
var confirm_rewind_button = null
var result_layer = null
var result_title = null
var result_body = null
var next_button = null
var _pending_rewind_turn := -1
var _last_saved_win_key := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_interface()
	var session = _session()
	session.world_changed.connect(_on_world_changed)
	session.action_rejected.connect(_on_action_rejected)
	_start_level("chapter_01_level_01")


func _unhandled_key_input(event: InputEvent) -> void:
	if _pending_rewind_turn < 0 or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_cancel_rewind_preview()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	column.add_child(_build_header())
	var workspace := HBoxContainer.new()
	workspace.name = "Workspace"
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation", 10)
	column.add_child(workspace)
	workspace.add_child(_build_tool_rail())
	var board_frame := PanelContainer.new()
	board_frame.name = "BoardFrame"
	board_frame.add_theme_stylebox_override("panel", _panel_style(Color("151C1F"), BORDER, 4))
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(board_frame)
	var aspect := AspectRatioContainer.new()
	aspect.name = "BoardAspect"
	aspect.ratio = 1.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_child(aspect)
	board = BoardViewRef.new()
	board.name = "BoardView"
	aspect.add_child(board)
	board.action_requested.connect(_on_board_action_requested)
	board.selection_changed.connect(_on_selection_changed)
	board.rewind_hotkey_requested.connect(_open_default_rewind)
	board.undo_hotkey_requested.connect(_undo_action)
	board.cancel_requested.connect(_cancel_rewind_preview)
	workspace.add_child(_build_inspector())
	var timeline_frame := PanelContainer.new()
	timeline_frame.name = "TimelineFrame"
	timeline_frame.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 4))
	timeline_frame.custom_minimum_size = Vector2(0, 132)
	column.add_child(timeline_frame)
	timeline = TimelineViewRef.new()
	timeline.name = "TimelineView"
	timeline_frame.add_child(timeline)
	timeline.rewind_target_selected.connect(_open_rewind_preview)
	rewind_bar = _build_rewind_bar()
	column.add_child(rewind_bar)
	_build_result_overlay()


func _build_header() -> Control:
	var header := PanelContainer.new()
	header.name = "Header"
	header.custom_minimum_size = Vector2(0, 54)
	header.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)
	var mark := TextureRect.new()
	mark.texture = MarkTexture
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(38, 38)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	var name_stack := VBoxContainer.new()
	name_stack.custom_minimum_size = Vector2(178, 0)
	row.add_child(name_stack)
	var brand := Label.new()
	brand.text = "CHRONO CHESS"
	brand.add_theme_font_size_override("font_size", 18)
	brand.add_theme_color_override("font_color", TEXT)
	name_stack.add_child(brand)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", MUTED)
	name_stack.add_child(title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	status_label = _compact_label("", CYAN)
	status_label.custom_minimum_size = Vector2(116, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status_label)
	energy_label = _compact_label("", GOLD)
	energy_label.custom_minimum_size = Vector2(98, 0)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(energy_label)
	level_select = OptionButton.new()
	level_select.name = "LevelSelect"
	level_select.add_item("Level 1: A Missed Line")
	level_select.set_item_metadata(0, "chapter_01_level_01")
	level_select.add_item("Level 2: Locked Fate")
	level_select.set_item_metadata(1, "chapter_01_level_02")
	level_select.tooltip_text = "Choose a Chapter 1 puzzle."
	_style_button(level_select)
	level_select.item_selected.connect(_on_level_selected)
	row.add_child(level_select)
	undo_button = Button.new()
	undo_button.text = "Undo"
	undo_button.tooltip_text = "Undo the last confirmed move or rewind."
	_style_button(undo_button)
	undo_button.pressed.connect(_undo_action)
	row.add_child(undo_button)
	var retry := Button.new()
	retry.text = "Retry"
	retry.tooltip_text = "Restore the authored starting timeline."
	_style_button(retry)
	retry.pressed.connect(_retry_level)
	row.add_child(retry)
	return header


func _build_tool_rail() -> Control:
	var rail := PanelContainer.new()
	rail.name = "ToolRail"
	rail.custom_minimum_size = Vector2(92, 0)
	rail.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 4))
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	rail.add_child(buttons)
	rewind_button = Button.new()
	rewind_button.text = "Rewind"
	rewind_button.tooltip_text = "Select an earlier timeline node. Shortcut: R."
	_style_button(rewind_button, true)
	rewind_button.pressed.connect(_open_default_rewind)
	buttons.add_child(rewind_button)
	var clear := Button.new()
	clear.text = "Clear"
	clear.tooltip_text = "Clear the current board selection. Escape also cancels a rewind preview."
	_style_button(clear)
	clear.pressed.connect(func(): board.clear_selection())
	buttons.add_child(clear)
	var rail_spacer := Control.new()
	rail_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	buttons.add_child(rail_spacer)
	var rule_label := _compact_label("RULES", MUTED)
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(rule_label)
	return rail


func _build_inspector() -> Control:
	var panel := PanelContainer.new()
	panel.name = "Inspector"
	panel.custom_minimum_size = Vector2(286, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_ALT, BORDER, 4))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var heading := _compact_label("INSPECTOR", CYAN)
	heading.add_theme_font_size_override("font_size", 12)
	column.add_child(heading)
	inspector_title = Label.new()
	inspector_title.add_theme_font_size_override("font_size", 18)
	inspector_title.add_theme_color_override("font_color", TEXT)
	inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inspector_title)
	inspector_body = Label.new()
	inspector_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_body.add_theme_font_size_override("font_size", 14)
	inspector_body.add_theme_color_override("font_color", MUTED)
	inspector_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(inspector_body)
	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 13)
	message_label.add_theme_color_override("font_color", GOLD)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message_label)
	return panel


func _build_rewind_bar() -> Control:
	var panel := PanelContainer.new()
	panel.name = "RewindConfirmBar"
	panel.add_theme_stylebox_override("panel", _panel_style(Color("243033"), CYAN, 4))
	panel.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	rewind_description = Label.new()
	rewind_description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewind_description.add_theme_color_override("font_color", TEXT)
	rewind_description.add_theme_font_size_override("font_size", 14)
	rewind_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(rewind_description)
	var cancel := Button.new()
	cancel.text = "Cancel"
	_style_button(cancel)
	cancel.pressed.connect(_cancel_rewind_preview)
	row.add_child(cancel)
	confirm_rewind_button = Button.new()
	confirm_rewind_button.text = "Confirm"
	_style_button(confirm_rewind_button, true)
	confirm_rewind_button.pressed.connect(_confirm_rewind)
	row.add_child(confirm_rewind_button)
	return panel


func _build_result_overlay() -> void:
	result_layer = Control.new()
	result_layer.name = "ResultDialog"
	result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	result_layer.z_index = 10
	result_layer.visible = false
	add_child(result_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.05, 0.06, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(390, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_ALT, GOLD, 4))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 26)
	result_title.add_theme_color_override("font_color", TEXT)
	column.add_child(result_title)
	result_body = Label.new()
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body.add_theme_font_size_override("font_size", 15)
	result_body.add_theme_color_override("font_color", MUTED)
	column.add_child(result_body)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	var retry := Button.new()
	retry.text = "Retry"
	_style_button(retry)
	retry.pressed.connect(_retry_level)
	actions.add_child(retry)
	next_button = Button.new()
	next_button.text = "Next"
	_style_button(next_button, true)
	next_button.pressed.connect(_next_level)
	actions.add_child(next_button)


func _start_level(level_id: String) -> void:
	_pending_rewind_turn = -1
	_last_saved_win_key = ""
	result_layer.hide()
	var result: Dictionary = _session().start_level(level_id)
	if not bool(result["ok"]):
		_set_message(str(result["error"]), RED)
		return
	_select_level_in_menu(level_id)
	_set_message(str(_session().level.tutorial.get("enter", "")), GOLD)


func _on_world_changed(_view) -> void:
	_refresh_from_session()


func _refresh_from_session() -> void:
	var session = _session()
	if session.level == null or session.state == null or session.world == null:
		return
	board.set_interaction_enabled(_pending_rewind_turn < 0 and session.state.status == &"playing")
	board.set_world(session.world)
	timeline.set_session(session.level, session.state, session.world)
	timeline.set_preview_turn(_pending_rewind_turn)
	title_label.text = "CHAPTER %d  |  %s" % [session.level.chapter, session.level.title]
	energy_label.text = "Energy %d" % session.state.chronal_energy
	status_label.text = _status_text(session.state.status, session.state.active_side)
	status_label.add_theme_color_override("font_color", _status_color(session.state.status))
	undo_button.disabled = not session.can_undo()
	rewind_button.disabled = session.state.status != &"playing" or session.state.chronal_energy < session.level.rewind_cost()
	if _pending_rewind_turn < 0:
		_update_inspector()
	if session.state.status != &"playing":
		_show_result(session.state.status)


func _on_selection_changed(piece_id: String) -> void:
	if piece_id.is_empty():
		_update_inspector()
		return
	var session = _session()
	var piece = session.world.pieces_by_id.get(piece_id, null)
	if piece == null:
		return
	if piece.is_temporal:
		var temporal = session.state.temporal_states.get(piece_id, null)
		board.set_selected_moves(TemporalResolverRef.new().legal_moves(session.world, temporal))
	else:
		board.set_selected_moves(session.world.legal_moves_by_piece.get(piece_id, []))
	_update_inspector()


func _on_board_action_requested(piece_id: String, destination: Vector2i, is_temporal: bool) -> void:
	if _pending_rewind_turn >= 0:
		_cancel_rewind_preview()
		return
	var session = _session()
	var result: Dictionary = session.request_temporal_move(piece_id, destination) if is_temporal else session.request_move(piece_id, destination)
	if bool(result["ok"]):
		board.clear_selection()
		_set_message("")
		_handle_terminal_result()


func _open_default_rewind() -> void:
	var session = _session()
	if session.level == null:
		return
	for target in session.level.rewind_targets:
		if int(target) < session.state.focus_turn:
			_open_rewind_preview(int(target))
			return
	_set_message("No earlier rewind node is available.", RED)


func _open_rewind_preview(target_turn: int) -> void:
	var session = _session()
	if session.state.chronal_energy < session.level.rewind_cost() or target_turn >= session.state.focus_turn:
		_set_message("That rewind is not currently available.", RED)
		return
	_pending_rewind_turn = target_turn
	var preview_state: GameState = session.state.deep_copy()
	preview_state.focus_turn = target_turn
	var preview_world = WorldResolverRef.new().resolve(session.level, preview_state)
	board.set_interaction_enabled(false)
	board.set_world(preview_world)
	timeline.set_preview_turn(target_turn)
	rewind_description.text = "Return to T%02d for %d energy. T%02d-T%02d will become archived future." % [target_turn, session.level.rewind_cost(), target_turn + 1, session.state.focus_turn]
	confirm_rewind_button.disabled = false
	rewind_bar.show()
	_update_inspector(preview_world)


func _confirm_rewind() -> void:
	if _pending_rewind_turn < 0:
		return
	var target_turn := _pending_rewind_turn
	# GameSession emits world_changed synchronously, so clear preview state first.
	_pending_rewind_turn = -1
	rewind_bar.hide()
	var result: Dictionary = _session().request_rewind(target_turn)
	if bool(result["ok"]):
		board.set_interaction_enabled(true)
		_refresh_from_session()
		_set_message("Timeline rewritten. Archived events remain inspectable.", CYAN)
	else:
		_pending_rewind_turn = target_turn
		rewind_bar.show()
		board.set_interaction_enabled(false)
		_set_message(str(result["error"]), RED)


func _cancel_rewind_preview() -> void:
	if _pending_rewind_turn < 0:
		board.clear_selection()
		return
	_pending_rewind_turn = -1
	rewind_bar.hide()
	board.set_interaction_enabled(true)
	_refresh_from_session()


func _undo_action() -> void:
	_cancel_rewind_preview()
	var result: Dictionary = _session().undo()
	if bool(result["ok"]):
		_set_message("Restored the previous confirmed state.", CYAN)
	else:
		_set_message(str(result["error"]), RED)


func _retry_level() -> void:
	_pending_rewind_turn = -1
	rewind_bar.hide()
	result_layer.hide()
	var result: Dictionary = _session().retry_level()
	if bool(result["ok"]):
		_set_message("Authored timeline restored.", GOLD)


func _next_level() -> void:
	var current_id: String = _session().level.id
	if current_id == "chapter_01_level_01":
		_start_level("chapter_01_level_02")
	else:
		result_layer.hide()
		_set_message("Both Chapter 1 puzzles are complete.", CYAN)


func _on_level_selected(index: int) -> void:
	_start_level(str(level_select.get_item_metadata(index)))


func _handle_terminal_result() -> void:
	var session = _session()
	if session.state.status != &"playing":
		_show_result(session.state.status)


func _show_result(status: StringName) -> void:
	var session = _session()
	if status == &"won":
		result_title.text = "Timeline Secured"
		result_title.add_theme_color_override("font_color", CYAN)
		result_body.text = session.world.winning_reason
		var save_key := "%s:%d" % [session.level.id, session.state.white_actions_used]
		if _last_saved_win_key != save_key:
			var saved: Dictionary = _save_service().mark_level_complete(session.level.id, session.state.white_actions_used)
			_last_saved_win_key = save_key
			if not bool(saved["ok"]):
				_set_message("Completion could not be saved: %s" % str(saved["error"]), RED)
	else:
		result_title.text = "Timeline Closed"
		result_title.add_theme_color_override("font_color", RED)
		result_body.text = session.world.winning_reason if not session.world.winning_reason.is_empty() else "No actions remain on this path."
	next_button.visible = status == &"won"
	result_layer.show()


func _update_inspector(preview_world = null) -> void:
	var session = _session()
	var display_world = preview_world if preview_world != null else session.world
	if _pending_rewind_turn >= 0:
		inspector_title.text = "T%02d Preview" % _pending_rewind_turn
		inspector_body.text = "Energy remains persistent. Fate locks and temporal pieces do not rewind. The board shows the candidate historical snapshot."
		return
	var selected_id: String = board.get_selected_piece_id()
	if not selected_id.is_empty() and display_world.pieces_by_id.has(selected_id):
		var piece = display_world.pieces_by_id[selected_id]
		inspector_title.text = "%s %s" % [String(piece.side).capitalize(), String(piece.role).capitalize()]
		var lines: Array = ["Square: %s" % BoardCoords.to_algebraic(piece.square)]
		if piece.is_fate_echo:
			var lock: FateLock = session.state.fate_locks.get(piece.piece_id, null)
			if lock != null:
				lines.append("Fate echo: vanishes after T%02d" % lock.death_turn)
		if piece.is_temporal:
			lines.append("Temporal projection: persistent across history")
		if display_world.frozen_piece_ids.has(piece.piece_id):
			lines.append("Frozen by a reality overlap")
		inspector_body.text = "\n".join(lines)
		return
	inspector_title.text = "Capture the target king"
	var target := str(session.level.victory.get("target_king_id", ""))
	inspector_body.text = "Target: %s\nEnergy is permanent across rewinds.\n\n%s" % [target, str(session.level.tutorial.get("enter", ""))]
	if not display_world.explanations.is_empty():
		inspector_body.text += "\n\n" + "\n".join(display_world.explanations)


func _on_action_rejected(message: String) -> void:
	_set_message(message, RED)


func _set_message(message: String, color: Color = GOLD) -> void:
	message_label.text = message
	message_label.add_theme_color_override("font_color", color)


func _status_text(status: StringName, side: StringName) -> String:
	if status == &"won":
		return "WON"
	if status == &"lost":
		return "LOST"
	return "WHITE TO ACT" if side == &"white" else "SCRIPTING"


func _status_color(status: StringName) -> Color:
	if status == &"won":
		return CYAN
	if status == &"lost":
		return RED
	return TEXT


func _select_level_in_menu(level_id: String) -> void:
	for index in range(level_select.item_count):
		if str(level_select.get_item_metadata(index)) == level_id:
			level_select.select(index)
			return


func _session():
	return get_node("/root/GameSession")


func _save_service():
	return get_node("/root/SaveService")


func _compact_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	return label


func _style_button(button: BaseButton, accent := false) -> void:
	button.custom_minimum_size = Vector2(0, 32)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(Color("293438") if accent else Color("20292C"), CYAN if accent else BORDER, 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color("344448") if accent else Color("293438"), CYAN, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("1C5552") if accent else Color("172124"), GOLD if accent else CYAN, 3))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("182023"), Color("2D3A3D"), 3))


func _panel_style(background: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
