class_name Bomb
extends Movement

@onready var explode_particles: CPUParticles3D = $ExplodeParticles

func slice() -> void:
	explode_particles.reparent(get_parent())
	explode_particles.emitting = true
	queue_free()
