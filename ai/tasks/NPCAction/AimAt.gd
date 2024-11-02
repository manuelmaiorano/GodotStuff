@tool
extends BTAction

# Task parameters.
@export var position: BBVector3

# Called to generate a display name for the task (requires @tool).
func _generate_name() -> String:
	return "AimAt  %s  " % [position]


# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	agent.root.dispatch("aim")
	var current_trans = agent.transform
	agent.q_to = Quaternion(current_trans.looking_at(position, Vector3.UP, true).basis)
	return SUCCESS
