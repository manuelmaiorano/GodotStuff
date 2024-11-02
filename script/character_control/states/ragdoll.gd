extends LimboState


var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	velocity = player_controller.velocity
	player_controller.player_model.get_node("Hips").linear_velocity = velocity
	player_controller.start_ragdoll()
	
func _exit() -> void:
	player_controller.global_position = player_controller.player_model.get_node("Hips").global_position
