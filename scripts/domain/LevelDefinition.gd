class_name LevelDefinition
extends RefCounted

var id := ""
var version := 1
var title := ""
var chapter := 1
var initial_side: StringName = &"white"
var initial_pieces: Array = []
var preplayed_events: Array = []
var start_focus_turn := 0
var chronal_energy := 0
var white_action_budget := 0
var rewind_targets: Array = []
var scripts: Array = []
var victory: Dictionary = {}
var tutorial: Dictionary = {}
var expected_solution: Array = []
var rules: Dictionary = {}


func rewind_cost() -> int:
	return int(rules.get("rewind_cost", 1))


func fate_locks_enabled() -> bool:
	return bool(rules.get("fate_locks_enabled", false))


func temporal_enabled() -> bool:
	return bool(rules.get("temporal_enabled", false))


func overlap_enabled() -> bool:
	return bool(rules.get("overlap_enabled", false))

