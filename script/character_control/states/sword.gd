extends LimboState

var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	animation_tree.set("parameters/Transition/transition_request", "sword")
	add_event_handler("slash", _on_slash)

func _update(delta: float) -> void:
	var orientation = player_controller.orientation
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

	player_controller.handle_gravity(delta)
	player_controller.update_orientation(orientation)
	player_controller.do_root_motion(delta)
	player_controller.update_velocity()
	
	
func _on_slash():
	if randf() > 0.5:
		animation_tree["parameters/slash/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		animation_tree["parameters/slash2/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

	return false
