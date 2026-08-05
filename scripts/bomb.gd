class_name Bomb
extends Sliceable

@onready var explode_particles: CPUParticles3D = $ExplodeParticles

func slice() -> void:
	if already_sliced: return
	explode_particles.reparent(get_parent())
	explode_particles.emitting = true
	already_sliced = true
	queue_free()
