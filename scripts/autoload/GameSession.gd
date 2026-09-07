extends Node

signal world_changed(view)
signal action_rejected(message: String)

const LevelLoaderRef = preload("res://scripts/content/LevelLoader.gd")
const GameReducerRef = preload("res://scripts/rules/GameReducer.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")

var level = null
var state: GameState = null
var world: WorldView = null
var _undo_stack: Array = []

var _loader = LevelLoaderRef.new()
var _reducer = GameReducerRef.new()
var _resolver = WorldResolverRef.new()


func start_level(level_id: String) -> Dictionary:
	level = _loader.load_by_id(level_id)
	if level == null:
		return {"ok": false, "error": "Unable to load the requested puzzle."}
	state = _reducer.create_initial_state(level)
	_undo_stack.clear()
	_refresh_world()
	return {"ok": true, "error": ""}


func retry_level() -> Dictionary:
	if level == null:
		return {"ok": false, "error": "No puzzle is active."}
	state = _reducer.create_initial_state(level)
	_undo_stack.clear()
	_refresh_world()
	return {"ok": true, "error": ""}


func request_move(actor_id: String, destination: Vector2i) -> Dictionary:
	if state == null:
		return _rejected("No puzzle is active.")
	var result: Dictionary = _reducer.try_move(level, state, actor_id, destination)
	return _apply_result(result)


func request_temporal_move(temporal_id: String, destination: Vector2i) -> Dictionary:
	if state == null:
		return _rejected("No puzzle is active.")
	var result: Dictionary = _reducer.try_temporal_move(level, state, temporal_id, destination)
	return _apply_result(result)


func request_rewind(target_turn: int) -> Dictionary:
	if state == null:
		return _rejected("No puzzle is active.")
	var result: Dictionary = _reducer.try_rewind(level, state, target_turn)
	result["view"] = _resolver.resolve(level, result["state"])
	return _apply_result(result)


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func undo() -> Dictionary:
	if _undo_stack.is_empty():
		return _rejected("There is no confirmed action to undo.")
	state = _undo_stack.pop_back()
	_refresh_world()
	return {"ok": true, "error": "", "state": state, "view": world}


func _apply_result(result: Dictionary) -> Dictionary:
	var error := str(result.get("error", ""))
	if not error.is_empty():
		return _rejected(error)
	_undo_stack.append(state.deep_copy())
	state = result["state"]
	world = result.get("view", _resolver.resolve(level, state))
	world_changed.emit(world)
	return {"ok": true, "error": "", "state": state, "view": world}


func _rejected(message: String) -> Dictionary:
	action_rejected.emit(message)
	return {"ok": false, "error": message, "state": state, "view": world}


func _refresh_world() -> void:
	world = _resolver.resolve(level, state)
	world_changed.emit(world)

