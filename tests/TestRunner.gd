extends SceneTree

const LevelLoaderRef = preload("res://scripts/content/LevelLoader.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	_run("test_level_data_contract", Callable(self, "test_level_data_contract"))
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
