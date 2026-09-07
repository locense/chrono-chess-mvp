extends SceneTree

const LevelLoaderRef = preload("res://scripts/content/LevelLoader.gd")
const GameReducerRef = preload("res://scripts/rules/GameReducer.gd")
const WorldResolverRef = preload("res://scripts/rules/WorldResolver.gd")
const BoardCoordsRef = preload("res://scripts/domain/BoardCoords.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	_run("test_level_data_contract", Callable(self, "test_level_data_contract"))
	_run("test_level_01_load_and_rewind", Callable(self, "test_level_01_load_and_rewind"))
	_run("test_level_01_solution_wins", Callable(self, "test_level_01_solution_wins"))
	_run("test_level_01_direct_capture_fails", Callable(self, "test_level_01_direct_capture_fails"))
	print("TEST SUMMARY: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run(name: String, test: Callable) -> void:
	var result = test.call()
	if result is String and not result.is_empty():
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
	return ""
