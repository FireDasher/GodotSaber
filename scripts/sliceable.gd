class_name Sliceable
extends Node3D

var mesh: MeshInstance3D
var already_sliced := false
var note: Note

func _ready() -> void:
	position = Vector3(note.line *0.6-0.9, note.layer *0.6+0.8, Map.hjp + Map.BEAT_WARMUP_POSITION - Map.SWORD_OFFSET)
	rotation.z = Map.CUBE_ROTATIONS[note.direction]

func _process(_delta: float) -> void:
	var offset := Map.time - note.time + Map.hjd
	var t := offset / (Map.hjd * 2.0)
	var toff := note.time - Map.time - Map.hjd - Map.BEAT_WARMUP_TIME
	if toff <= -Map.BEAT_WARMUP_TIME:
		var head_offset := Map.camera.position.z
		position.z = lerp(Map.hjp - Map.SWORD_OFFSET + head_offset * minf(1.0, t*2.0), -Map.hjp - Map.SWORD_OFFSET + head_offset, t)
	else:
		position.z = Map.hjp + Map.BEAT_WARMUP_POSITION + Map.BEAT_WARMUP_SPEED * -toff - Map.SWORD_OFFSET
