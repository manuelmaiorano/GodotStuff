extends LimboState


var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree.set("parameters/Transition/transition_request", "strafe")
	add_event_handler("jump", _on_jump)
	add_event_handler("shoot", _on_shoot)

func _update(delta: float) -> void:
	var q_from = orientation.basis.get_rotation_quaternion()
	var q_to
	if player_controller.controlled_by_player:
		q_to = player_controller.get_camera_base_quaternion() 
	else:
		q_to = player_controller.q_to
		
	var motion = player_controller.motion
		
	# Interpolate current rotation with desired one.
	orientation.basis = Basis(q_from.slerp(q_to, delta * player_controller.ROTATION_INTERPOLATE_SPEED))

	animation_tree["parameters/strafe/blend_position"] = Vector2(motion.x, -motion.y)
	
	
	var root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())
	
	velocity = Vector3()
	if motion.length() < 0.001:
		return
		
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity.y = h_velocity.y
	

	orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed).
	orientation = orientation.orthonormalized() # Orthonormalize orientation.
	
func _on_shoot():
	player_controller.shoot()
	
func _on_jump():
	animation_tree["parameters/strafeJump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
