@tool
extends BTAction

## Shows or hides a node and returns SUCCESS.
## Returns FAILURE if the node is not found.

# Task parameters.
@export var node_path: NodePath


# Called each time this task is ticked (aka executed).
func _tick(p_delta: float) -> Status:
	var node: Node3D = agent.get_tree().get_first_node_in_group(&"markers")
	if is_instance_valid(node):
		blackboard.set_var(&"position_to_reach", node.global_position)
		return SUCCESS
	return FAILURE
