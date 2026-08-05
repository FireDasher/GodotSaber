extends RayCast3D

var saber_tip := Vector3.ZERO
var past_saber_tip := Vector3.ZERO
@onready var controller: XRController3D = get_parent()
@onready var tipMarker: Marker3D = $Tip
@export var is_right: bool

func _physics_process(_delta: float) -> void:
	if Map.autoplay: return
	past_saber_tip = saber_tip
	saber_tip = tipMarker.global_position
	if is_colliding():
		var area: Node = get_collider().get_parent()
		if (area) and (area is Sliceable) and (not area.already_sliced):
			area.already_sliced = true
			
			var world_cut_plane := Plane(global_position, saber_tip, past_saber_tip).normalized()
			var cut_plane := Plane(area.mesh.global_basis.inverse() * world_cut_plane.normal, area.mesh.to_local(world_cut_plane.normal * world_cut_plane.d))
			if saber_tip == past_saber_tip:
				cut_plane = Plane.PLANE_YZ
			
			area.slice(cut_plane, controller)

func _on_right_controller_button_pressed(button_name: String) -> void:
	if button_name == "by_button":
		get_tree().current_scene.reload()
