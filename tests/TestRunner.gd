extends SceneTree

const LevelLoaderRef = preload("res://scripts/content/LevelLoader.gd")
const GameReducerRef = preload("res://scripts/rules/GameReducer.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")
const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")
const StateHasherRef = preload("res://scripts/rules/StateHasher.gd")
const GameSessionRef = preload("res://scripts/autoload/GameSession.gd")
const SaveServiceRef = preload("res://scripts/persistence/SaveService.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	_run("test_level_data_contract", Callable(self, "test_level_data_contract"))
	_run("test_level_01_load_and_rewind", Callable(self, "test_level_01_load_and_rewind"))
	_run("test_level_01_solution_wins", Callable(self, "test_level_01_solution_wins"))
	_run("test_level_01_direct_capture_fails", Callable(self, "test_level_01_direct_capture_fails"))
	_run("test_level_02_preplayed_capture_creates_fate_lock", Callable(self, "test_level_02_preplayed_capture_creates_fate_lock"))
	_run("test_level_02_rewind_restores_knight_as_echo", Callable(self, "test_level_02_rewind_restores_knight_as_echo"))
	_run("test_level_02_fate_lock_removes_repositioned_knight", Callable(self, "test_level_02_fate_lock_removes_repositioned_knight"))
	_run("test_level_02_solution_wins", Callable(self, "test_level_02_solution_wins"))
	_run("test_replay_hash_is_deterministic", Callable(self, "test_replay_hash_is_deterministic"))
	_run("test_temporal_rook_persists_through_rewind", Callable(self, "test_temporal_rook_persists_through_rewind"))
	_run("test_reality_overlap_freezes_and_blocks_entry", Callable(self, "test_reality_overlap_freezes_and_blocks_entry"))
	_run("test_temporal_enemy_king_overlap_wins", Callable(self, "test_temporal_enemy_king_overlap_wins"))
	_run("test_temporal_allied_king_overlap_is_rejected", Callable(self, "test_temporal_allied_king_overlap_is_rejected"))
	_run("test_temporal_capture_removes_projection_without_fate_lock", Callable(self, "test_temporal_capture_removes_projection_without_fate_lock"))
	_run("test_overlap_releases_after_fate_echo_vanishes", Callable(self, "test_overlap_releases_after_fate_echo_vanishes"))
	_run("test_temporal_move_without_script_returns_control", Callable(self, "test_temporal_move_without_script_returns_control"))
	_run("test_scripted_temporal_capture_removes_projection", Callable(self, "test_scripted_temporal_capture_removes_projection"))
	_run("test_preplayed_temporal_capture_removes_projection", Callable(self, "test_preplayed_temporal_capture_removes_projection"))
	_run("test_undo_restores_confirmed_rewind", Callable(self, "test_undo_restores_confirmed_rewind"))
	_run("test_profile_save_round_trip", Callable(self, "test_profile_save_round_trip"))
	print("TEST SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run(name: String, test: Callable) -> void:
	var result = test.call()
	if typeof(result) != TYPE_STRING:
		_failed += 1
		push_error("FAIL %s: test did not return a String" % name)
		return
	if not result.is_empty():
		_failed += 1
		push_error("FAIL %s: %s" % [name, result])
		return
	_passed += 1
	print("PASS %s" % name)


func test_level_data_contract() -> String:
	var loader = LevelLoaderRef.new()
	var level_one = loader.load_by_id("chapter_01_level_01")
	var level_two = loader.load_by_id("chapter_01_level_02")
	if level_one == null or level_two == null:
		return "both level files must load"
	if level_one.start_focus_turn != 2 or level_one.preplayed_events.size() != 2:
		return "level one timeline contract changed"
	if level_two.start_focus_turn != 2 or level_two.preplayed_events.size() != 2:
		return "level two timeline contract changed"
	if level_one.rewind_cost() != 1 or level_two.rewind_cost() != 1:
		return "MVP rewind cost must stay fixed at one"
	if level_one.temporal_enabled() or level_two.temporal_enabled():
		return "temporal demo rules must not alter the two authored puzzles"
	return ""


func test_level_01_load_and_rewind() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_01")
	var reducer = GameReducerRef.new()
	var resolver = WorldResolverRef.new()
	var state = reducer.create_initial_state(level)
	var view = resolver.resolve(level, state)
	if state.focus_turn != 2 or state.chronal_energy != 1:
		return "level one must begin at T02 with one energy"
	if view.pieces_by_id["white_king_h1"].square != BoardCoordsRef.from_algebraic("h2"):
		return "preplayed white king move was not replayed"
	if view.pieces_by_id["black_rook_b4"].square != BoardCoordsRef.from_algebraic("a4"):
		return "preplayed black rook move was not replayed"
	var current_rook_moves: Array = view.legal_moves_by_piece["white_rook_a1"]
	if current_rook_moves.has(BoardCoordsRef.from_algebraic("a8")):
		return "a8 must be blocked at T02"
	var result: Dictionary = reducer.try_rewind(level, state, 0)
	if not str(result["error"]).is_empty():
		return "rewind unexpectedly failed: %s" % str(result["error"])
	var rewound: GameState = result["state"]
	var rewound_view = resolver.resolve(level, rewound)
	if rewound.chronal_energy != 0 or rewound.current_events.size() != 0 or rewound.archived_future_events.size() != 2:
		return "rewind must spend energy and archive both preplayed events"
	if rewound.focus_turn != 0 or rewound.active_side != &"white" or state.current_events.size() != 2:
		return "rewind must create an independent white-to-move T00 state"
	if rewound.archived_future_events[0].event_id != "l01_t00_white_king_h2" or rewound.archived_future_events[1].event_id != "l01_t01_black_rook_a4":
		return "archived future events must preserve their authored order"
	if rewound_view.pieces_by_id["white_king_h1"].square != BoardCoordsRef.from_algebraic("h1"):
		return "rewind must restore the T00 white king square"
	if not rewound_view.legal_moves_by_piece["white_rook_a1"].has(BoardCoordsRef.from_algebraic("a8")):
		return "a8 must be legal after returning to T00"
	return ""


func test_level_01_solution_wins() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_01")
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	state = reducer.try_rewind(level, state, 0)["state"]
	var result: Dictionary = reducer.try_move(level, state, "white_rook_a1", BoardCoordsRef.from_algebraic("a8"))
	if not str(result["error"]).is_empty():
		return "the authored solution move was rejected"
	if result["state"].status != &"won" or result["view"].status != &"won":
		return "capturing the target king at T00 must win"
	return ""


func test_level_01_direct_capture_fails() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_01")
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	var result: Dictionary = reducer.try_move(level, state, "white_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if not str(result["error"]).is_empty():
		return "the direct black rook capture should be legal"
	if result["state"].status != &"lost":
		return "spending the only action without victory must lose"
	if result["view"].pieces_by_id.has("black_rook_b4"):
		return "the direct move must actually capture the black rook on a4"
	var rewind_after_loss: Dictionary = reducer.try_rewind(level, result["state"], 0)
	if str(rewind_after_loss["error"]).is_empty():
		return "a finished failure state must require retry instead of rewind"
	return ""


func test_level_02_preplayed_capture_creates_fate_lock() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_02")
	var reducer = GameReducerRef.new()
	var resolver = WorldResolverRef.new()
	var state = reducer.create_initial_state(level)
	var view = resolver.resolve(level, state)
	if not state.fate_locks.has("white_knight_c3"):
		return "the preplayed bishop capture must create the knight fate lock"
	if state.fate_locks["white_knight_c3"].death_turn != 1:
		return "the knight fate lock must remain anchored at T01"
	if view.pieces_by_id.has("white_knight_c3"):
		return "the knight must not be visible at the T02 entry snapshot"
	if view.pieces_by_id["black_bishop_b5"].square != BoardCoordsRef.from_algebraic("e2"):
		return "the preplayed bishop capture must end on e2"
	return ""


func test_level_02_rewind_restores_knight_as_echo() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_02")
	var reducer = GameReducerRef.new()
	var resolver = WorldResolverRef.new()
	var state = reducer.create_initial_state(level)
	var result: Dictionary = reducer.try_rewind(level, state, 0)
	if not str(result["error"]).is_empty():
		return "level two rewind must be available"
	state = result["state"]
	var view = resolver.resolve(level, state)
	var knight = view.pieces_by_id.get("white_knight_c3", null)
	if knight == null or knight.square != BoardCoordsRef.from_algebraic("c3"):
		return "rewind must restore the knight at c3"
	if not knight.is_fate_echo or state.chronal_energy != 0:
		return "rewound knight must be an echo and consume the only energy"
	return ""


func test_level_02_fate_lock_removes_repositioned_knight() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_02")
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	state = reducer.try_rewind(level, state, 0)["state"]
	var result: Dictionary = reducer.try_move(level, state, "white_knight_c3", BoardCoordsRef.from_algebraic("d5"))
	if not str(result["error"]).is_empty():
		return "a legal alternate knight move was rejected"
	var next: GameState = result["state"]
	if next.focus_turn != 2 or next.active_side != &"white":
		return "the black response must settle synchronously before returning control"
	if result["view"].pieces_by_id.has("white_knight_c3"):
		return "the knight must vanish after T01 even on a rewritten path"
	if result["view"].pieces_by_id["black_bishop_b5"].square != BoardCoordsRef.from_algebraic("c6"):
		return "the deterministic black response must move the bishop to c6"
	return ""


func test_level_02_solution_wins() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_02")
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	state = reducer.try_rewind(level, state, 0)["state"]
	var knight_result: Dictionary = reducer.try_move(level, state, "white_knight_c3", BoardCoordsRef.from_algebraic("a4"))
	if not str(knight_result["error"]).is_empty():
		return "the authored knight capture was rejected"
	var rook_result: Dictionary = reducer.try_move(level, knight_result["state"], "white_rook_a1", BoardCoordsRef.from_algebraic("a8"))
	if not str(rook_result["error"]).is_empty():
		return "the opened rook capture was rejected"
	if rook_result["state"].status != &"won" or rook_result["view"].status != &"won":
		return "capturing the king at T02 must win level two"
	return ""


func test_replay_hash_is_deterministic() -> String:
	var level = LevelLoaderRef.new().load_by_id("chapter_01_level_02")
	var first_hash := _solve_level_two_hash(level)
	var second_hash := _solve_level_two_hash(level)
	if first_hash.is_empty() or first_hash != second_hash:
		return "the same solution must yield the same world hash"
	return ""


func _solve_level_two_hash(level) -> String:
	var reducer = GameReducerRef.new()
	var resolver = WorldResolverRef.new()
	var hasher = StateHasherRef.new()
	var state = reducer.create_initial_state(level)
	state = reducer.try_rewind(level, state, 0)["state"]
	state = reducer.try_move(level, state, "white_knight_c3", BoardCoordsRef.from_algebraic("a4"))["state"]
	state = reducer.try_move(level, state, "white_rook_a1", BoardCoordsRef.from_algebraic("a8"))["state"]
	return hasher.hash_world(state, resolver.resolve(level, state))


func test_temporal_rook_persists_through_rewind() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a1", &"white", &"rook", "a1", true),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	var reducer = GameReducerRef.new()
	var resolver = WorldResolverRef.new()
	var state = reducer.create_initial_state(level)
	var moved: Dictionary = reducer.try_temporal_move(level, state, "temporal_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if not str(moved["error"]).is_empty():
		return "a clear temporal rook move was rejected"
	var rewound: Dictionary = reducer.try_rewind(level, moved["state"], 0)
	if not str(rewound["error"]).is_empty():
		return "temporal move must remain rewindable by the ordinary timeline"
	var view = resolver.resolve(level, rewound["state"])
	var rook = view.pieces_by_id.get("temporal_rook_a1", null)
	if rook == null or rook.square != BoardCoordsRef.from_algebraic("a4"):
		return "temporal rook position must not be restored by rewind"
	return ""


func test_reality_overlap_freezes_and_blocks_entry() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a1", &"white", &"rook", "a1", true),
		_piece("white_knight_b2", &"white", &"knight", "b2"),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_bishop_a4", &"black", &"bishop", "a4"),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	var result: Dictionary = reducer.try_temporal_move(level, state, "temporal_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if not str(result["error"]).is_empty():
		return "temporal rook should be able to create an overlap"
	var view = result["view"]
	if not view.overlaps.has("a4") or not view.frozen_piece_ids.has("black_bishop_a4"):
		return "temporal/ordinary co-occupancy must create a frozen overlap"
	if not view.legal_moves_by_piece["black_bishop_a4"].is_empty():
		return "the ordinary piece inside an overlap must be frozen"
	if view.legal_moves_by_piece["white_knight_b2"].has(BoardCoordsRef.from_algebraic("a4")):
		return "ordinary pieces must not enter an overlap square"
	return ""


func test_temporal_enemy_king_overlap_wins() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a1", &"white", &"rook", "a1", true),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_king_a8", &"black", &"king", "a8"),
	])
	var state = GameReducerRef.new().create_initial_state(level)
	var result: Dictionary = GameReducerRef.new().try_temporal_move(level, state, "temporal_rook_a1", BoardCoordsRef.from_algebraic("a8"))
	if not str(result["error"]).is_empty() or result["view"].status != &"won":
		return "temporal projection onto the enemy king must win immediately"
	return ""


func test_temporal_allied_king_overlap_is_rejected() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a1", &"white", &"rook", "a1", true),
		_piece("white_king_a4", &"white", &"king", "a4"),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	var state = GameReducerRef.new().create_initial_state(level)
	var result: Dictionary = GameReducerRef.new().try_temporal_move(level, state, "temporal_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if str(result["error"]).is_empty():
		return "a temporal move onto the allied king must be rejected before mutation"
	if state.focus_turn != 0 or state.temporal_states["temporal_rook_a1"].square != BoardCoordsRef.from_algebraic("a1"):
		return "a rejected temporal move must not mutate its source state"
	return ""


func test_temporal_capture_removes_projection_without_fate_lock() -> String:
	var level = _temporal_level([
		_piece("white_rook_a1", &"white", &"rook", "a1"),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("temporal_rook_a4", &"black", &"rook", "a4", true),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	var reducer = GameReducerRef.new()
	var state = reducer.create_initial_state(level)
	var result: Dictionary = reducer.try_move(level, state, "white_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if not str(result["error"]).is_empty():
		return "ordinary rook should be able to capture an exposed temporal rook"
	if result["state"].temporal_states["temporal_rook_a4"].alive:
		return "capturing a temporal piece must remove its global projection"
	if result["state"].fate_locks.has("temporal_rook_a4"):
		return "temporal captures must not create ordinary fate locks"
	if result["view"].pieces_by_id.has("temporal_rook_a4"):
		return "dead temporal rook must not appear in the resolved world"
	return ""


func test_overlap_releases_after_fate_echo_vanishes() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a4", &"white", &"rook", "a4", true),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_bishop_a4", &"black", &"bishop", "a4"),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	level.rules["fate_locks_enabled"] = true
	var state = GameReducerRef.new().create_initial_state(level)
	var lock := FateLock.new()
	lock.piece_id = "black_bishop_a4"
	lock.death_turn = 0
	lock.source_event_id = "fixture"
	state.fate_locks[lock.piece_id] = lock
	var resolver = WorldResolverRef.new()
	var before = resolver.resolve(level, state)
	if not before.overlaps.has("a4") or not before.pieces_by_id["black_bishop_a4"].is_fate_echo:
		return "fate echo should maintain the overlap before its death turn passes"
	state.focus_turn = 1
	var after = resolver.resolve(level, state)
	if after.overlaps.has("a4") or after.pieces_by_id.has("black_bishop_a4"):
		return "overlap must release when the fate echo vanishes"
	return ""


func test_temporal_move_without_script_returns_control() -> String:
	var level = _temporal_level([
		_piece("temporal_rook_a1", &"white", &"rook", "a1", true),
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	var state = GameReducerRef.new().create_initial_state(level)
	var result: Dictionary = GameReducerRef.new().try_temporal_move(level, state, "temporal_rook_a1", BoardCoordsRef.from_algebraic("a4"))
	if not str(result["error"]).is_empty() or result["state"].active_side != &"white":
		return "a temporal move without a black script must return control to white"
	return ""


func test_scripted_temporal_capture_removes_projection() -> String:
	var level = _temporal_level([
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_rook_h4", &"black", &"rook", "h4"),
		_piece("temporal_rook_a4", &"black", &"rook", "a4", true),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	level.scripts = [{
		"script_id": "fixture_black_captures_temporal",
		"after_white_turn": 0,
		"event": {"actor": "black_rook_h4", "side": "black", "kind": "temporal_capture", "from": "h4", "to": "a4", "captured_piece_id": "temporal_rook_a4"},
	}]
	var state = GameReducerRef.new().create_initial_state(level)
	var result: Dictionary = GameReducerRef.new().try_move(level, state, "white_king_h1", BoardCoordsRef.from_algebraic("h2"))
	if not str(result["error"]).is_empty():
		return "fixture white move was rejected"
	if result["state"].temporal_states["temporal_rook_a4"].alive:
		return "scripted temporal capture must update the temporal layer"
	if result["view"].pieces_by_id.has("temporal_rook_a4"):
		return "scripted temporal capture must remove all temporal projections"
	return ""


func test_preplayed_temporal_capture_removes_projection() -> String:
	var level = _temporal_level([
		_piece("white_king_h1", &"white", &"king", "h1"),
		_piece("black_rook_h4", &"black", &"rook", "h4"),
		_piece("temporal_rook_a4", &"black", &"rook", "a4", true),
		_piece("black_king_h8", &"black", &"king", "h8"),
	])
	level.preplayed_events = [
		_event("fixture_white_wait", 0, "white_king_h1", &"white", &"move", "h1", "h2"),
		_event("fixture_black_captures_temporal", 1, "black_rook_h4", &"black", &"temporal_capture", "h4", "a4", "temporal_rook_a4"),
	]
	level.start_focus_turn = 2
	var state = GameReducerRef.new().create_initial_state(level)
	var view = WorldResolverRef.new().resolve(level, state)
	if state.temporal_states["temporal_rook_a4"].alive or view.pieces_by_id.has("temporal_rook_a4"):
		return "preplayed temporal capture must remove the global projection"
	return ""


func _temporal_level(pieces: Array) -> LevelDefinition:
	var level := LevelDefinition.new()
	level.id = "temporal_rules_fixture"
	level.initial_pieces = pieces
	level.initial_side = &"white"
	level.start_focus_turn = 0
	level.chronal_energy = 1
	level.white_action_budget = 2
	level.rewind_targets = [0]
	level.victory = {"target_king_id": "black_king_a8", "turn_window": [0, 8]}
	level.rules = {
		"puzzle_capture_king": true,
		"fate_locks_enabled": false,
		"temporal_enabled": true,
		"overlap_enabled": true,
		"rewind_cost": 1,
	}
	return level


func _piece(piece_id: String, side: StringName, role: StringName, square: String, is_temporal := false) -> PieceState:
	var piece := PieceState.new()
	piece.piece_id = piece_id
	piece.side = side
	piece.role = role
	piece.square = BoardCoordsRef.from_algebraic(square)
	piece.is_temporal = is_temporal
	return piece


func _event(event_id: String, absolute_turn: int, actor: String, side: StringName, kind: StringName, from_square: String, to_square: String, captured_piece_id := "") -> MoveEvent:
	var event := MoveEvent.new()
	event.event_id = event_id
	event.absolute_turn = absolute_turn
	event.actor_id = actor
	event.side = side
	event.kind = kind
	event.from_square = BoardCoordsRef.from_algebraic(from_square)
	event.to_square = BoardCoordsRef.from_algebraic(to_square)
	event.captured_piece_id = captured_piece_id
	return event


func test_undo_restores_confirmed_rewind() -> String:
	var session = GameSessionRef.new()
	var started: Dictionary = session.start_level("chapter_01_level_01")
	if not bool(started["ok"]):
		return "session could not start level one"
	var rewound: Dictionary = session.request_rewind(0)
	if not bool(rewound["ok"]) or not session.can_undo():
		return "confirmed rewind must become undoable"
	var undone: Dictionary = session.undo()
	if not bool(undone["ok"]):
		return "undo unexpectedly failed"
	if session.state.focus_turn != 2 or session.state.chronal_energy != 1 or session.state.current_events.size() != 2:
		return "undo must restore the complete pre-rewind state"
	if session.can_undo():
		return "undo stack should be empty after restoring its only memento"
	session.free()
	return ""


func test_profile_save_round_trip() -> String:
	var service = SaveServiceRef.new()
	var profile_path := "user://chrono_chess_test_profile.json"
	var temporary_path := "user://chrono_chess_test_profile.tmp"
	var backup_path := "user://chrono_chess_test_profile.bak"
	service.configure_paths(profile_path, temporary_path, backup_path)
	_remove_if_present(profile_path)
	_remove_if_present(temporary_path)
	_remove_if_present(backup_path)
	var saved: Dictionary = service.mark_level_complete("chapter_01_level_02", 2)
	if not bool(saved["ok"]):
		return "profile save failed: %s" % str(saved["error"])
	var loaded := service.load_profile()
	if not loaded["completed_level_ids"].has("chapter_01_level_02"):
		return "saved completed level was not restored"
	if int(loaded["best_white_actions"].get("chapter_01_level_02", 0)) != 2:
		return "saved best action count was not restored"
	_remove_if_present(profile_path)
	_remove_if_present(temporary_path)
	_remove_if_present(backup_path)
	service.free()
	return ""


func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
