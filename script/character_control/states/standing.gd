extends LimboState

var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _setup() -> void:
	add_event_handler("hit", _on_hit)
	add_event_handler("jump", _on_jump)
	add_event_handler("pick", _on_pick)
	add_event_handler("punch", _on_punch)
	
func _enter() -> void:
	animation_tree.set("parameters/Transition/transition_request", "walk")

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
	
	# Convert orientation to quaternions for interpolating rotation.
	var target = camera_x * motion.x + camera_z * motion.y if controlled_by_player else Vector3(motion.x, 0, motion.y)
	if target.length() > 0.001:
		var q_from = orientation.basis.get_rotation_quaternion()
		var use_nod_front = false if controlled_by_player else true
		var q_to = Transform3D().looking_at(target, Vector3.UP, use_nod_front).basis.get_rotation_quaternion()
		# Interpolate current rotation with desired one.
		orientation.basis = Basis(q_from.slerp(q_to, delta * player_controller.ROTATION_INTERPOLATE_SPEED))
	
	animation_tree["parameters/blendWalk/blend_position"] = Vector2(motion.length(), player_controller.running)
	
	
	
	var root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())
	
	velocity = Vector3()
	#if motion.length() < 0.001:
		#return
		
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity.y = h_velocity.y
	

	orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed).
	orientation = orientation.orthonormalized() # Orthonormalize orientation.


func _on_hit():
	pass
	
func _on_pick():
	animation_tree["parameters/pick/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	#player_controller.pick_up(object)
	return true


func _on_throw(object):
	animation_tree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	player_controller.throw(object)
	return true
	
func _on_jump():
	animation_tree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	return true
	
func _on_punch():
	animation_tree["parameters/punch/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	return true
	
func _on_kick():
	animation_tree["parameters/punch/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	return true
