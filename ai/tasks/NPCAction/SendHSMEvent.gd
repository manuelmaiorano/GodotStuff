@tool
extends BTAction

# Task parameters.
@export var event_var: StringName = &"event_to_send"

# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	var event = blackboard.get_var(event_var)
	agent.root.dispatch(event)
	return SUCCESS
