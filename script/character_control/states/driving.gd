extends LimboState


var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree
var current_car

func _on_enter_car(car):
	pass
	

func _on_exit_car(car):
	pass

func _update(delta: float) -> void:
	var camera_basis : Basis 
	var controlled_by_player = player_controller.controlled_by_player
	if controlled_by_player:
		camera_basis = player_controller.get_camera_rotation_basis()
	else:
		camera_basis = Basis(orientation.basis)
		
	var camera_z := camera_basis.z
	var camera_x := camera_basis.x
	
	camera_z.y = 0
	camera_z = camera_z.normalized()
	camera_x.y = 0
	camera_x = camera_x.normalized()
	
	var motion = player_controller.motion
	
	var target = camera_x * motion.x + camera_z * motion.y if controlled_by_player else Vector3(motion.x, 0, motion.y)
	current_car.set_motion(motion)
	player_controller.global_position = current_car.global_position
