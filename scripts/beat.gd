class_name Beat
extends Area3D

var cube: MeshInstance3D
var already_sliced := false
var speed := 8.0

func slice(cut_plane: Plane) -> void:
	if already_sliced: return
	
	var leftHalf = SlicedBeat.new()
	leftHalf.mesh = cube.mesh
	leftHalf.material_override = cube.material_override
	leftHalf.set_instance_shader_parameter("color", cube.get_instance_shader_parameter("color"))
	leftHalf.set_instance_shader_parameter("is_dot", cube.get_instance_shader_parameter("is_dot"))
	leftHalf.cut_plane = -cut_plane
	leftHalf.transform = transform
	leftHalf.velocity = basis * cut_plane.normal * -2.0
	
	var rightHalf = SlicedBeat.new()
	rightHalf.mesh = cube.mesh
	rightHalf.material_override = cube.material_override
	rightHalf.set_instance_shader_parameter("color", cube.get_instance_shader_parameter("color"))
	rightHalf.set_instance_shader_parameter("is_dot", cube.get_instance_shader_parameter("is_dot"))
	rightHalf.cut_plane = cut_plane
	rightHalf.transform = transform
	rightHalf.velocity = basis * cut_plane.normal * 2.0
	
	add_sibling(leftHalf)
	add_sibling(rightHalf)
	
	queue_free()
	already_sliced = true

func _physics_process(delta: float) -> void:
	position.z += speed * delta
