@tool
extends BTAction


# Task parameters.
@export var position_var: StringName = &"position_to_reach"
var position: Vector3


# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	position = blackboard.get_var(position_var)
	var current_trans = agent.transform
	agent.q_to = Quaternion(current_trans.looking_at(position, Vector3.UP, true).basis)
	return SUCCESS
