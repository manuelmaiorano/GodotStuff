extends LimboState

var orientation = Transform3D()
var velocity = Vector3()
var player_controller
var animation_tree: AnimationTree
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * ProjectSettings.get_setting("physics/3d/default_gravity_vector")

func _enter() -> void:
	orientation = player_controller.player_model.global_transform
	velocity = player_controller.velocity
	animation_tree.set("parameters/Transition/transition_request", "fall")
	
func _update(delta: float) -> void:
	player_controller.handle_gravity(delta)
	player_controller.update_velocity()
