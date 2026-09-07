class_name GameState
extends RefCounted

var level_id := ""
var focus_turn := 0
var active_side: StringName = &"white"
var current_events: Array = []
var archived_future_events: Array = []
var fate_locks: Dictionary = {}
var temporal_states: Dictionary = {}
var chronal_energy := 0
var white_actions_used := 0
var status: StringName = &"playing"
var next_event_serial := 0


func deep_copy() -> GameState:
	var result := GameState.new()
	result.level_id = level_id
	result.focus_turn = focus_turn
	result.active_side = active_side
	for event in current_events:
		result.current_events.append(event.copy_event())
	for event in archived_future_events:
		result.archived_future_events.append(event.copy_event())
	for key in fate_locks:
		result.fate_locks[key] = fate_locks[key].copy_lock()
	for key in temporal_states:
		result.temporal_states[key] = temporal_states[key].copy_state()
	result.chronal_energy = chronal_energy
	result.white_actions_used = white_actions_used
	result.status = status
	result.next_event_serial = next_event_serial
	return result

