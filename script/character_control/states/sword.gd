extends LimboState


var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree.set("parameters/Transition/transition_request", "sword")
	add_event_handler("slash", _on_slash)

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

	animation_tree["parameters/blend_sword/blend_position"] = Vector2(motion.x, -motion.y)
	
	
	var root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())
	
	velocity = Vector3()
	
		
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity.y = h_velocity.y
	

	orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed).
	orientation = orientation.orthonormalized() # Orthonormalize orientation.
	
	
func _on_slash():
	if randf() > 0.5:
		animation_tree["parameters/slash/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		animation_tree["parameters/slash2/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

	return false
