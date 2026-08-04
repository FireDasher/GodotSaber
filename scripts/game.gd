extends Node3D

@onready var music: AudioStreamPlayer = $Music
var preloaded_beat := preload("res://scenes/beat.tscn")
var preloaded_bomb := preload("res://scenes/bomb.tscn")
var CUBE_ROTATIONS := PackedFloat64Array([PI, 0.0, -TAU*0.25, TAU*0.25, -TAU*0.375, TAU*0.375, -TAU*0.125, TAU*0.125, 0.0])
var index := 0

func _ready() -> void:
	Map.camera = $Player/Camera
	Map.load_zip("ost/DarkSide.zip", 2)
	music.stream = Map.music_stream
	music.play()

#func make_colored_shader_material(shader: Shader, color: Vector3) -> ShaderMaterial:
	#var material := ShaderMaterial.new()
	#material.shader = shader
	#material.set_shader_parameter("color", color)
	#return material

func _process(_delta: float) -> void:
	if not music.playing: return
	Map.time = music.get_playback_position()
	while index < Map.note_stack.size() and Map.note_stack[index].time <= Map.time + Map.hjd + 0.5:
		var note: Note = Map.note_stack[index]
		var beat: Movement
		if note.color == Note.Type.BOMB:
			beat = preloaded_bomb.instantiate()
		else:
			beat = preloaded_beat.instantiate()
			beat.rotation.z = CUBE_ROTATIONS[note.direction]
			beat.mesh = beat.get_node("Cube")
			if note.color == Note.Type.RIGHT:
				beat.mesh.set_instance_shader_parameter("color", Map.right_color)
			elif note.color == Note.Type.LEFT:
				beat.mesh.set_instance_shader_parameter("color", Map.left_color)
			if note.direction == 8:
				beat.mesh.set_instance_shader_parameter("is_dot", true)
		
		# commom
		beat.note = note
		add_child(beat)
		index += 1
