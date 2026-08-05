extends Node

const BEAT_WARMUP_SPEED: float = 200.0
const BEAT_WARMUP_TIME: float = 0.3
const BEAT_WARMUP_POSITION: float = -BEAT_WARMUP_SPEED * BEAT_WARMUP_TIME
const SWORD_OFFSET: float = 0.9
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0]) # you can't have const packed arrays for some reason

var bpm: float

var note_stack: Array[Note] = []
var left_color := Vector3(0.784, 0.078, 0.078)
var right_color := Vector3(0.188, 0.596, 1.000)
var music_stream: AudioStream

## Note Jump movement Speed
var njs: float
## Half Jump Duration
var hjd: float
## Half Jump Position
var hjp: float

#-- Config --#
var autoplay: bool = false

#-- Runtime Data --#

var time: float
var camera: Node3D

func load_note_stack_v3(data: Dictionary) -> void:
	for note in data["colorNotes"]:
		note_stack.append(Note.note(
			note.get("b", 0.0), # beat
			note.get("x", 0), # x position
			note.get("y", 0), # y position
			Note.Type.RIGHT if note.get("c", 0) == 1 else Note.Type.LEFT, # color
			note.get("d", 0), # direction
		))
	for bomb in data["bombNotes"]:
		note_stack.append(Note.bomb(
			bomb.get("b", 0.0),
			bomb.get("x", 0),
			bomb.get("y", 0),
		))

func load_note_stack_v2(data: Dictionary) -> void:
	for note in data["_notes"]:
		var type: int = note.get("_type", 0);
		if type == 0 or type == 1: # Note
			note_stack.append(Note.note(
				note.get("_time", 0.0), # time
				note.get("_lineIndex", 0), # x position
				note.get("_lineLayer", 0), # y position
				Note.Type.RIGHT if type == 1 else Note.Type.LEFT, # color
				note.get("_cutDirection", 0), # direction
			))
		elif type == 3: # Bomb
			note_stack.append(Note.bomb(
				note.get("_time", 0.0), # time
				note.get("_lineIndex", 0), # x position
				note.get("_lineLayer", 0), # y position
			))

func get_audio_stream_from_buffer(bytes: PackedByteArray) -> AudioStream:
	if bytes.size() < 4:
		return null

	# Check for WAV (Starts with "RIFF")
	if bytes.slice(0, 4).get_string_from_ascii() == "RIFF":
		return AudioStreamWAV.load_from_buffer(bytes)

	# Check for MP3 (Starts with "ID3" or sync frame 0xFFFB/0xFFF3)
	if bytes.slice(0, 3).get_string_from_ascii() == "ID3" or (bytes[0] == 0xFF and (bytes[1] & 0xF0) == 0xF0):
		return AudioStreamMP3.load_from_buffer(bytes)

	# Check for OGG (Starts with "OggS")
	if bytes.slice(0, 4).get_string_from_ascii() == "OggS":
		return AudioStreamOggVorbis.load_from_buffer(bytes)

	push_error("Unknown audio format")
	return null

func load_zip(zip_path: String, difficulty: int) -> void:
	var zip := ZIPReader.new()
	if zip.open(zip_path) != OK:
		print("Failed to parse song!!!")
		return
	
	# Load the Info.dat file
	var info: Dictionary = JSON.parse_string(zip.read_file("Info.dat").get_string_from_utf8())
	
	# 4.0 not support yet
	if not ("_version" in info and info["_version"] == "2.0.0" or info["_version"] == "2.1.0"):
		print("Invalid version")
		return
	
	# load song
	var song_bytes := zip.read_file(info["_songFilename"])
	music_stream = get_audio_stream_from_buffer(song_bytes)
	
	# get beetmap
	var beatmap_info: Dictionary = info["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"][difficulty]
	var beatmap: Dictionary = JSON.parse_string(zip.read_file(beatmap_info["_beatmapFilename"]).get_string_from_utf8())
	
	# converts seconds to beats
	bpm = info["_beatsPerMinute"]
	njs = beatmap_info.get("_noteJumpMovementSpeed", 10.0)
	var njsb_offset: float = beatmap_info.get("_noteJumpStartBeatOffset", 0.5)
	
	# weird half-jump-duration calculation
	var bts := 60.0 / bpm
	var jt = 4.0
	while njs * bts * jt > 18.0: jt /= 2.0
	jt += njsb_offset
	if jt < 0.25: jt = 0.25
	
	hjd = bts * jt
	hjp = -hjd * njs

	# load notes with support for different versions
	if beatmap.get("_version", "false").begins_with("2."):
		load_note_stack_v2(beatmap)
	elif beatmap.get("version", "false").begins_with("3."):
		load_note_stack_v3(beatmap)
	
	note_stack.sort_custom(func (a: Note, b: Note) -> bool: return a.time < b.time) # Ensures correct order
	
	#print("bpm: %f, njs: %f, hjd: %f, hjp: %f" % [bpm, njs, hjd, hjp])
