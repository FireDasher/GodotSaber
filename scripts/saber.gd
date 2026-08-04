extends RayCast3D

var saber_tip := Vector3.ZERO
var past_saber_tip := Vector3.ZERO
@onready var controller: XRController3D = get_parent()
@onready var tipMarker: Marker3D = $Tip
@onready var sound: AudioStreamPlayer = $SliceSound
@onready var bomb_sound: AudioStreamPlayer = $BombSound

func _physics_process(_delta: float) -> void:
	past_saber_tip = saber_tip
	saber_tip = tipMarker.global_position
	if is_colliding():
		var area := get_collider()
		if area is Beat:
			var cut_plane := Plane(global_position, saber_tip, past_saber_tip).normalized() # global plane
			var local_cut_plane := Plane(area.mesh.global_basis.inverse() * cut_plane.normal, area.mesh.to_local(cut_plane.normal * cut_plane.d)) # convert to local space
			
			area.slice(Plane.PLANE_YZ if saber_tip == past_saber_tip else local_cut_plane)
			sound.play()
			controller.trigger_haptic_pulse("haptic", 20.0, 0.75, 0.1, 0.0)
		elif area is Bomb:
			area.slice()
			bomb_sound.play()
			controller.trigger_haptic_pulse("haptic", 15.0, 1.0, 0.25, 0.0)

func _on_right_controller_button_pressed(button_name: String) -> void:
	if button_name == "by_button":
		get_tree().reload_current_scene()
