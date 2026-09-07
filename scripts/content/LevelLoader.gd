class_name LevelLoader
extends RefCounted

const PieceStateRef = preload("res://scripts/domain/PieceState.gd")
const MoveEventRef = preload("res://scripts/domain/MoveEvent.gd")
const LevelDefinitionRef = preload("res://scripts/domain/LevelDefinition.gd")


func load_by_id(level_id: String) -> LevelDefinition:
	return load_level("res://content/levels/%s.json" % level_id)


func load_level(path: String) -> LevelDefinition:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to read level: %s" % path)
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Level JSON must be an object: %s" % path)
		return null
	return _parse_definition(parsed, path)


func _parse_definition(data: Dictionary, source: String) -> LevelDefinition:
	var level := LevelDefinitionRef.new()
	level.id = str(data.get("id", ""))
	level.version = int(data.get("version", 0))
	level.title = str(data.get("title", ""))
	level.chapter = int(data.get("chapter", 0))
	level.rules = data.get("rules", {}).duplicate(true)
	level.start_focus_turn = int(data.get("start_focus_turn", 0))
	level.chronal_energy = int(data.get("chronal_energy", 0))
	level.white_action_budget = int(data.get("white_action_budget", 0))
	for target_turn in data.get("rewind_targets", []):
		level.rewind_targets.append(int(target_turn))
	level.scripts = data.get("scripts", []).duplicate(true)
	level.victory = data.get("victory", {}).duplicate(true)
	level.tutorial = data.get("tutorial", {}).duplicate(true)
	level.expected_solution = data.get("expected_solution", []).duplicate(true)
	var initial_position: Dictionary = data.get("initial_position", {})
	level.initial_side = StringName(str(initial_position.get("side_to_move", "white")))
	for piece_data in initial_position.get("pieces", []):
		var piece = PieceStateRef.from_dict(piece_data)
		level.initial_pieces.append(piece)
	for event_data in data.get("preplayed_events", []):
		var event = MoveEventRef.from_dict(event_data)
		level.preplayed_events.append(event)
	if not _validate(level, source):
		return null
	return level


func _validate(level: LevelDefinition, source: String) -> bool:
	if level.id.is_empty() or level.version < 1:
		push_error("Invalid level header: %s" % source)
		return false
	if level.initial_pieces.is_empty():
		push_error("Level has no pieces: %s" % source)
		return false
	var seen_ids: Dictionary = {}
	for piece in level.initial_pieces:
		if piece.piece_id.is_empty() or seen_ids.has(piece.piece_id) or not BoardCoords.is_on_board(piece.square):
			push_error("Invalid or duplicate piece in %s" % source)
			return false
		seen_ids[piece.piece_id] = true
	for event in level.preplayed_events:
		if event.event_id.is_empty() or not seen_ids.has(event.actor_id):
			push_error("Invalid preplayed event in %s" % source)
			return false
		if not BoardCoords.is_on_board(event.from_square) or not BoardCoords.is_on_board(event.to_square):
			push_error("Invalid event square in %s" % source)
			return false
	if level.start_focus_turn < 0 or level.chronal_energy < 0 or level.white_action_budget < 1:
		push_error("Invalid numeric constraint in %s" % source)
		return false
	return true
