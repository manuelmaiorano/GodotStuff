extends Node3D
class_name DockStation


var building: StringName
var cell: Vector2i = Vector2i.ZERO

@onready var final_transform = $dock_position.global_transform
var level: int = 0

func _ready() -> void:
	cell = ShellAi.get_closest_center(global_position)
