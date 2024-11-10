@tool
extends BTAction

# Task parameters.
@export var position_var: StringName = &"position_to_reach"
var position: Vector3



func _enter() -> void:
	position = blackboard.get_var(position_var)
	var _agent = agent as CharacterController
	_agent.set_movement_target(position)

# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	var navigation_completed = agent.navigation_agent.is_navigation_finished()
	if not navigation_completed:
		return RUNNING
	if navigation_completed and agent.global_position.distance_to(position) > 1.0:
		return FAILURE
	agent.set_movement_target(agent.global_position)
	return SUCCESS
