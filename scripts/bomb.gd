class_name Bomb
extends Sliceable

@onready var explode_particles: CPUParticles3D = $ExplodeParticles

func slice(_cut_plane: Plane, controller: XRController3D) -> void:
	explode_particles.reparent(get_parent())
	explode_particles.emitting = true
	
	var slice_sound: AudioStreamPlayer3D = $Slice
	slice_sound.reparent(get_parent())
	slice_sound.play()
	if controller:
		controller.trigger_haptic_pulse("haptic", 15.0, 1.0, 0.25, 0.0)
	
	visible = false
	queue_free()
