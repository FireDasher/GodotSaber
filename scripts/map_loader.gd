extends Node3D

@onready var music: AudioStreamPlayer = $Music
var preloaded_beat := preload("res://Scenes/beat.tscn")
var preloaded_bomb := preload("res://Scenes/bomb.tscn")
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0])

var bpm: float
var stb: float # Seconds To Beats
var bts: float # Beats To Seconds
var note_stack: Array[Note] = []
var left_color := Vector3(0.784, 0.078, 0.078)
var right_color := Vector3(0.188, 0.596, 1.000)

var note_jump_movement_speed: float
var half_jump_duration: float

func _ready() -> void:
	load_zip("ost/finalbosschan.zip", 4)

enum NoteColor {LEFT, RIGHT, BOMB}

class Note:
	var beat: float
	var line: int
	var layer: int
	var color: NoteColor
	var direction: int
	# Boilerplate
	static func note(a: float, b: int, c: int, d: NoteColor, e: int) -> Note: var x:=Note.new();x.beat=a;x.line=b;x.layer=c;x.color=d;x.direction=e;return x
	static func bomb(a: float, b: int, c: int) -> Note: var x:=Note.new();x.beat=a;x.line=b;x.layer=c;x.color=NoteColor.BOMB;return x

func load_note_stack_v3(data: Dictionary) -> void:
	for note in data["colorNotes"]:
		note_stack.append(Note.note(
			note.get("b", 0.0), # beat
			note.get("x", 0), # x position
			note.get("y", 0), # y position
			NoteColor.RIGHT if note.get("c", 0) == 1 else NoteColor.LEFT, # color
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
				NoteColor.RIGHT if type == 1 else NoteColor.LEFT, # color
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
	music.stream = get_audio_stream_from_buffer(song_bytes)
	music.play()
	
	# get beetmap
	var beatmap_info: Dictionary = info["_difficultyBeatmapSets"][0]["_difficultyBeatmaps"][difficulty]
	var beatmap: Dictionary = JSON.parse_string(zip.read_file(beatmap_info["_beatmapFilename"]).get_string_from_utf8())
	
	# converts seconds to beats
	bpm = info["_beatsPerMinute"]
	stb = bpm / 60.0
	bts = 60.0 / bpm
	note_jump_movement_speed = beatmap_info.get("_noteJumpMovementSpeed", 10.0)
	var njsb_offset: float = beatmap_info.get("_noteJumpStartBeatOffset", 0.5)
	
	# weird half-jump-duration calculation
	var jt := 4.0
	while note_jump_movement_speed * bts * jt > 18.0: jt /= 2.0
	jt += njsb_offset
	if jt < 0.25: jt = 0.25
	
	half_jump_duration = jt

	# load notes with support for different versions
	if beatmap.get("_version", "false").begins_with("2."):
		load_note_stack_v2(beatmap)
	elif beatmap.get("version", "false").begins_with("3."):
		load_note_stack_v3(beatmap)
	
	note_stack.sort_custom(func (a: Note, b: Note) -> bool: return a.beat > b.beat) # Ensures correct order
	
	# initiate materials
	left_color = Vector3(0.784, 0.078, 0.078)
	right_color = Vector3(0.188, 0.596, 1.000)
	
	var saber_shader: Shader = load("res://shaders/saber.gdshader")
	var handle_shader: Shader = load("res://shaders/handle.gdshader")
	
	$Player/LeftController/LeftSaber/Beam.material_override = make_colored_shader_material(saber_shader, left_color)
	$Player/LeftController/LeftSaber/Handle.material_override = make_colored_shader_material(handle_shader, left_color)
	$Player/RightController/RightSaber/Beam.material_override = make_colored_shader_material(saber_shader, right_color)
	$Player/RightController/RightSaber/Handle.material_override = make_colored_shader_material(handle_shader, right_color)

func _physics_process(_delta: float) -> void:
	if not music.playing: return
	var cbeat := music.get_playback_position() * stb
	var tbeat := cbeat + half_jump_duration
	while not note_stack.is_empty() and note_stack[-1].beat <= tbeat:
		var note: Note = note_stack.pop_back()
		var beat: Node3D
		if note.color == NoteColor.BOMB:
			beat = preloaded_bomb.instantiate()
		else:
			beat = preloaded_beat.instantiate()
			beat.rotation.z = CUBE_ROTATIONS[note.direction]
			beat.cube = beat.get_node("Cube")
			if note.color == NoteColor.RIGHT:
				beat.cube.set_instance_shader_parameter("color", right_color)
			elif note.color == NoteColor.LEFT:
				beat.cube.set_instance_shader_parameter("color", left_color)
			if note.direction == 8:
				beat.cube.set_instance_shader_parameter("is_dot", true)
		
		# commom
		beat.speed = note_jump_movement_speed
		beat.position = Vector3(note.line *0.6-0.9, note.layer *0.6+0.8, (cbeat - note.beat) * (note_jump_movement_speed * bts))
		var anim: AnimationPlayer = beat.get_node("AnimationPlayer")
		anim.speed_scale = stb*0.5
		anim.current_animation = &"spawn"
		add_child(beat)
