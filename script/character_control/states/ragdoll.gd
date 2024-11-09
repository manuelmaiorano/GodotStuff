extends LimboState


var player_controller
var animation_tree: AnimationTree

func _enter() -> void:
	var velocity = player_controller.velocity
	player_controller.player_model.get_node("Hips").linear_velocity = velocity
	schedule_impulse()
	player_controller.start_ragdoll()
	
	
func _exit() -> void:
	player_controller.global_position = player_controller.player_model.get_node("Hips").global_position

func schedule_impulse():
	await get_tree().create_timer(1.0).timeout
	var phbone = player_controller.player_model.get_node("Hips") as PhysicalBone3D
	phbone.apply_impulse(Vector3.UP*100)
