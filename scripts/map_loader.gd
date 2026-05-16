extends Node3D

var preloaded_beat := preload("res://Scenes/beat.tscn")
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0])

func _ready() -> void:
	load_zip("songs/BeatSaber.zip", 3)

class Note:
	var beat: float
	var line: int
	var layer: int
	var color: bool # false = Left, true = Right
	var direction: int
	# Boilerplate
	static func note(a: float, b: int, c: int, d: int, e: int) -> Note:var x := Note.new();x.beat = a;x.line = b;x.layer = c;x.color = d;x.direction = e;return x

func load_note_stack_v3(data: Array) -> Array[Note]:
	var note_stack: Array[Note] = []
	for note in data:
		note_stack.append(Note.note(
			note.get("b", 0.0), # beat
			note.get("x", 0), # x position
			note.get("y", 0), # y position
			note.get("c", 0) == 1, # color
			note.get("d", 0), # direction
		))
	return note_stack

func load_note_stack_v2(data: Array) -> Array[Note]:
	var note_stack: Array[Note] = []
	for note in data:
		var type: int = note.get("_type", 0);
		if type == 0 or type == 1:
			note_stack.append(Note.note(
				note.get("_time", 0.0), # time
				note.get("_lineIndex", 0), # x position
				note.get("_lineLayer", 0), # y position
				type == 1, # color
				note.get("_cutDirection", 0), # direction
			))
	return note_stack

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

func make_colored_shader_material(shader: Shader, color: Vector3) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("color", color)
	return material

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
	$Music.stream = get_audio_stream_from_buffer(song_bytes)
	$Music.play()
	
	# speed in m/s
	var speed: float = info["_beatsPerMinute"] * 0.016666666666666667 * 4.0
	
	# get beetmap
	var beatmap_info: Dictionary = info["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"][difficulty]
	var beatmap: Dictionary = JSON.parse_string(zip.read_file(beatmap_info["_beatmapFilename"]).get_string_from_utf8())

	# load notes with support for different versions
	var stack: Array[Note]
	if beatmap.get("_version", "false").begins_with("2."):
		stack = load_note_stack_v2(beatmap["_notes"])
	elif beatmap.get("version", "false").begins_with("3."):
		stack = load_note_stack_v3(beatmap["colorNotes"])
	
	# initiate materials
	var left_color := Vector3(0.784, 0.078, 0.078)
	var right_color := Vector3(0.188, 0.596, 1.000)
	
	var beat_shader: Shader = load("res://shaders/beat.gdshader")
	var saber_shader: Shader = load("res://shaders/saber.gdshader")
	var handle_shader: Shader = load("res://shaders/handle.gdshader")
	
	var left_material := make_colored_shader_material(beat_shader, left_color)
	var right_material := make_colored_shader_material(beat_shader, right_color)
	
	$Player/LeftController/LeftSaber/Beam.material_override = make_colored_shader_material(saber_shader, left_color)
	$Player/LeftController/LeftSaber/Handle.material_override = make_colored_shader_material(handle_shader, left_color)
	$Player/RightController/RightSaber/Beam.material_override = make_colored_shader_material(saber_shader, right_color)
	$Player/RightController/RightSaber/Handle.material_override = make_colored_shader_material(handle_shader, right_color)
	
	# instantiate notes
	for note in stack:
		var beat: Beat = preloaded_beat.instantiate()
		beat.speed = speed
		beat.position = Vector3(note.line *0.6-0.9, note.layer *0.6+0.8, note.beat * -4.0)
		beat.rotation.z = CUBE_ROTATIONS[note.direction]
		beat.cube = beat.get_node("Cube")
		if note.color:
			beat.cube.material_override = right_material
		else:
			beat.cube.material_override = left_material
		if note.direction == 8:
			beat.cube.set_instance_shader_parameter("is_dot", true)
		add_child(beat)
