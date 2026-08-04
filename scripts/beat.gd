class_name Beat
extends Movement

func slice(cut_plane: Plane) -> void:
	if already_sliced: return
	
	var leftHalf = SlicedBeat.new()
	leftHalf.mesh = mesh.mesh
	leftHalf.material_override = mesh.material_override
	leftHalf.set_instance_shader_parameter("color", mesh.get_instance_shader_parameter("color"))
	leftHalf.set_instance_shader_parameter("is_dot", mesh.get_instance_shader_parameter("is_dot"))
	leftHalf.cut_plane = -cut_plane
	leftHalf.transform = transform
	leftHalf.velocity = basis * cut_plane.normal * -2.0
	
	var rightHalf = SlicedBeat.new()
	rightHalf.mesh = mesh.mesh
	rightHalf.material_override = mesh.material_override
	rightHalf.set_instance_shader_parameter("color", mesh.get_instance_shader_parameter("color"))
	rightHalf.set_instance_shader_parameter("is_dot", mesh.get_instance_shader_parameter("is_dot"))
	rightHalf.cut_plane = cut_plane
	rightHalf.transform = transform
	rightHalf.velocity = basis * cut_plane.normal * 2.0
	
	add_sibling(leftHalf)
	add_sibling(rightHalf)
	
	queue_free()
	already_sliced = true
