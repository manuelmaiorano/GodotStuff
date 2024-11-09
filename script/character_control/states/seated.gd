extends LimboState

var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	
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
	
	player_controller.do_root_motion(delta)
	player_controller.update_velocity()

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
