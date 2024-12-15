extends Node3D
class_name Intersection


var cell: Vector2i
var level

@export var path: Path3D
@export var cell2area: Dictionary

func get_area_to_reach(next_cell):
	var cell_inters_local = next_cell - cell
	return get_node(cell2area[cell_inters_local])

func _ready() -> void:
	cell = ShellAi.get_closest_center(global_position)
