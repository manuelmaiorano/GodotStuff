extends LimboState

var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	orientation = player_controller.player_model.global_transform
	orientation.origin = Vector3() 
	animation_tree.set("parameters/Transition/transition_request", "sit")

func _setup() -> void:
	add_event_handler("sit", _on_sit)
	add_event_handler("standing", _on_stand)
	
func _on_sit():
	#animation_tree.set("parameters/Transition/transition_request", "sit")
	#
	#var sit_position: Transform3D = object.get_node("SitPosition").global_transform
	#player_controller.global_position.x = sit_position.origin.x
	#player_controller.global_position.z = sit_position.origin.z
	#orientation.basis = sit_position.basis
	
	return false

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
		
func _on_stand():
	animation_tree["parameters/sit/playback"].travel("sit_to_stand")
	schedule_stand_event()
	return true
	
func _on_hit():
	#oneshot
	return false
	
func schedule_stand_event():
	await animation_tree.animation_finished
	dispatch("stand")
