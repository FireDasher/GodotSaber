class_name Bomb
extends Area3D

@onready var explode_particles: CPUParticles3D = $ExplodeParticles
var speed := 8.0

func slice() -> void:
	explode_particles.reparent(get_parent())
	explode_particles.emitting = true
	queue_free()

func _process(delta: float) -> void:
	position.z += speed * delta
	if position.z > 2.0:
		queue_free()
