extends Node3D
class_name ShellVehicle

signal waypoint_reached
signal area_reached


# Target position and rotation
@export var target_position: Vector3 = Vector3.ZERO
@export var target_height: float
@export var target_rotation: Quaternion = Quaternion.IDENTITY
@export var target_path: Path3D
@export var area_to_reach: Area3D = null

@export var my_area: Area3D

# Speed for movement and rotation
@export var move_speed: float = 5.0
@export var rotate_speed: float = 2.0

enum MODE {WAIT, FOLLOW_TARGET, FOLLOW_PATH}

var mode_before_wait
var mode = MODE.WAIT

func _ready() -> void:
	my_area.area_entered.connect(on_my_area_entered)
	my_area.area_exited.connect(on_my_area_exited)


func on_my_area_entered(area: Area3D):
	if area == area_to_reach:
		area_reached.emit()
		return
	
	if area.get_collision_layer_value(1):
		var vec_to = global_transform.origin.direction_to(area.global_transform.origin)
		if vec_to.dot(global_transform.basis.z) > 0:
			return
		mode_before_wait = mode
		mode = MODE.WAIT

func on_my_area_exited(area: Area3D):
	if area.get_collision_layer_value(1):
		mode = mode_before_wait

func _physics_process(delta: float) -> void:
	match mode:
		MODE.WAIT:
			return
		MODE.FOLLOW_TARGET:
			global_position = global_position.lerp(target_position, move_speed * delta)

			var current_rotation: Quaternion = global_transform.basis.get_rotation_quaternion()
			var new_rotation: Quaternion = current_rotation.slerp(target_rotation, rotate_speed * delta)
			global_transform.basis = Basis(new_rotation)
			if target_position.distance_squared_to(global_position) < 0.01:
				waypoint_reached.emit()
			
		MODE.FOLLOW_PATH:
			var offset = get_offset_for_next_waypoint()
			var transform_on_curve =  target_path.global_transform * target_path.curve.sample_baked_with_rotation(offset)

			global_position = global_position.lerp(transform_on_curve.origin, move_speed * delta)

			var current_rotation: Quaternion = global_transform.basis.get_rotation_quaternion()
			var new_rotation: Quaternion = current_rotation.slerp(transform_on_curve.basis.get_rotation_quaternion(),
				rotate_speed * delta)
			global_transform.basis = Basis(new_rotation)

func set_target_position(point: Vector3):
	mode = MODE.FOLLOW_TARGET
	target_position = point


func set_target_rotation(quat: Quaternion):
	mode = MODE.FOLLOW_TARGET
	target_rotation = quat


func set_path(path: Path3D):
	mode = MODE.FOLLOW_PATH
	target_path = path

func set_area_to_reach(area: Area3D):
	area_to_reach = area

func set_target_height(height: float):
	target_height = height


func get_offset_for_next_waypoint():
	var waypoints = target_path.curve.get_baked_points()
	var MIN_DIST = 7.0
	
	var mind = INF
	var min_idx = 0

	for idx in waypoints.size():
		var waypoint = target_path.global_transform * waypoints[idx]
		var d = global_position.distance_to(waypoint)
		
		if d < MIN_DIST:
			continue
		
		var normalized_vec_to_waypoint = (waypoint-global_position).normalized()
		if normalized_vec_to_waypoint.dot(global_transform.basis.z)  < 0.5:
			continue
		
		if d < mind:
			min_idx = idx
			mind = d
	
	var offset = target_path.curve.get_closest_offset(waypoints[min_idx])
	return offset
