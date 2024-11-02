@tool
extends BTAction

# Task parameters.
@export var position: BBVector3

# Called to generate a display name for the task (requires @tool).
func _generate_name() -> String:
	return "Goto  %s  " % [position]

func _enter() -> void:
	agent.set_movement_target(position)

# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	var navigation_completed = agent.navigation_agent.is_navigation_finished()
	if not navigation_completed:
		return RUNNING
	if navigation_completed and agent.global_position.distance_to(position) > 1.0:
		return FAILURE
	return SUCCESS
