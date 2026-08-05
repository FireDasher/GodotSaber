class_name Beat
extends Sliceable

func slice(cut_plane: Plane, controller: XRController3D) -> void:
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
	
	get_parent().add_child(leftHalf)
	get_parent().add_child(rightHalf)
	
	var slice_sound: AudioStreamPlayer3D = $Slice
	slice_sound.reparent(get_parent())
	slice_sound.play()
	if controller:
		controller.trigger_haptic_pulse("haptic", 20.0, 0.75, 0.05, 0.0)
	
	visible = false
	queue_free()

func _ready() -> void:
	super()
	# if left then left saber collides with good hitbox and right saber collides with bad hitbox
	# if right then right saber collides with good hitbox and left saber collides with bad hitbox
	$GoodHitbox.collision_layer = 2 if note.color == Note.Type.LEFT else 4
	$BadHitbox.collision_layer = 4 if note.color == Note.Type.LEFT else 2
