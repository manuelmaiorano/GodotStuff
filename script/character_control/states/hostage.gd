extends LimboState

var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	orientation = player_controller.player_model.global_transform
	orientation.origin = Vector3() 
	animation_tree.set("parameters/Transition/transition_request", "hostage")
	animation_tree["parameters/hostage/playback"].travel("idle_villain")

func _setup() -> void:
	add_event_handler("stopping_hostage", _on_stop)
	
func _update(delta: float) -> void:
	
	var root_motion = Transform3D(animation_tree.get_root_motion_rotation(), animation_tree.get_root_motion_position())
	
	velocity = Vector3()
	#if motion.length() < 0.001:
		#return
		
	orientation *= root_motion
	
	var h_velocity = orientation.origin / delta
	
	velocity.x = h_velocity.x
	velocity.z = h_velocity.z
	velocity.y = h_velocity.y
	if velocity.length() > 10:
		pass

	orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed).
	orientation = orientation.orthonormalized() # Orthonormalize orientation.
		
func _on_stop():
	animation_tree["parameters/hostage/playback"].travel("release_villain")
	schedule_stop_event()
	return true
	
	
func schedule_stop_event():
	await animation_tree.animation_finished
	dispatch("stop_hostage")
