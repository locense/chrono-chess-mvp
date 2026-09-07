class_name FateLock
extends RefCounted

var piece_id := ""
var death_turn := 0
var source_event_id := ""
var cause: StringName = &"normal_capture"


func copy_lock() -> FateLock:
	var result := FateLock.new()
	result.piece_id = piece_id
	result.death_turn = death_turn
	result.source_event_id = source_event_id
	result.cause = cause
	return result


func to_dict() -> Dictionary:
	return {
		"piece_id": piece_id,
		"death_turn": death_turn,
		"source_event_id": source_event_id,
		"cause": String(cause),
	}

