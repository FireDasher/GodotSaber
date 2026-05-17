class_name SlicedBeat
extends MeshInstance3D

var velocity := Vector3.ZERO
var animation := 0.0
var cut_plane: Plane = Plane.PLANE_YZ

func _process(delta: float) -> void:
	position += velocity * delta
	velocity.y -= 9.81 * delta
	animation += delta # fade away
	set_instance_shader_parameter(&"cut_plane", Vector4(cut_plane.x, cut_plane.y, cut_plane.z, cut_plane.d + animation*animation))
	if animation > 1.0:
		queue_free() # note has fully faded away
