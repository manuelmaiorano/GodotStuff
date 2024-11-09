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
	
	player_controller.do_root_motion(delta)
	player_controller.update_velocity()
		
func _on_stop():
	animation_tree["parameters/hostage/playback"].travel("release_villain")
	schedule_stop_event()
	return true
	
	
func schedule_stop_event():
	await animation_tree.animation_finished
	dispatch("stop_hostage")
