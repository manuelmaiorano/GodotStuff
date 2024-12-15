extends Node
class_name ShellAi

const CELL_SIZE = 120
const ROAD_OFFSET = 20
const FLOOR_HEIGHT = 100

const SN = Vector2(0, 1)
const WE = Vector2(1, 0)

enum DirectionType {GO_STRAIGHT, MERGE, INTERSECTION, EXIT}

class Direction:
	var type: DirectionType
	var cell: Vector2i
	var point_to_reach: Vector3
	var direction: Vector2i
	var from: Vector2i
	var to: Vector2i
	var intersection: Intersection
	var dock_station: DockStation
	var level: int
	
var intersection: Array[Intersection]

var cell_to_intersections = {}
var cell_to_docks = {}


var astar_grid: AStarGrid2D

func _ready() -> void:
	build_grid()
	cell_to_docks[$dock_station.cell] = $dock_station
	cell_to_docks[$dock_station2.cell] = $dock_station2
	cell_to_intersections[$intersection.cell] = $intersection
	schedule_shell_path()

func schedule_shell_path():
	var shell = $shell
	var shell2 = $shell2
	var dock1 = $dock_station
	var dock2 = $dock_station2
	var directions = get_directions(dock1, dock2)
	var directions2 = get_directions(dock2, dock1)
	follow_directions(shell, directions)
	follow_directions(shell2, directions2)


func build_grid():
	astar_grid = AStarGrid2D.new()
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.region = Rect2i(Vector2i.ONE * -32, Vector2i.ONE * 64)
	astar_grid.update()
	astar_grid.set_point_solid(Vector2i(0, 0))
	astar_grid.set_point_solid(Vector2i(0, -1))
	astar_grid.set_point_solid(Vector2i(3, 0))
	astar_grid.set_point_solid(Vector2i(2, 0))
	astar_grid.set_point_solid(Vector2i(1, 0))


static func get_closest_center(vec: Vector3):
	var vec_translated = vec + Vector3(1, 0, 1) * CELL_SIZE/2
	var snapped_pos = vec_translated.snapped(Vector3.ONE * CELL_SIZE) - Vector3(1, 0, 1) * CELL_SIZE/2
	
	return convert_to_grid(snapped_pos)

#center to grid
static func convert_to_grid(vec: Vector3):
	var cell = Vector2i.ZERO
	cell.x = int(floor(vec.x/CELL_SIZE))
	cell.y = int(floor(vec.z/CELL_SIZE))
	return cell

#grid to center
func convert_to_3d(vec: Vector2i, level: int):
	var vec_ = vec * CELL_SIZE
	return Vector3(vec_.x, level * FLOOR_HEIGHT, vec_.y) + Vector3(1, 0, 1) * CELL_SIZE/2

func get_target_transform_for_merge(cell: Vector2i, direction: Vector2, level: int):
	var position = convert_to_3d(cell, level)

	if direction.dot(SN) > 0:
		position.x -=  ROAD_OFFSET
	elif direction.dot(SN) < 0:
		position.x +=  ROAD_OFFSET

	if direction.dot(WE) > 0:
		position.z +=  ROAD_OFFSET
	elif direction.dot(WE) < 0:
		position.z -=  ROAD_OFFSET

	var transform = Transform3D().looking_at(Vector3(direction.x, 0, direction.y), Vector3.UP, true)
	transform.origin = position
	return transform


func search_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	return astar_grid.get_id_path(from, to)
	
	
func get_directions(from: DockStation, to: DockStation) -> Array[Direction]:
	var directions: Array[Direction] = []
	var cell_from = from.cell
	var cell_to = to.cell

	var cell_path = search_path(cell_from, cell_to)

	var initial_direction = cell_path[1] - cell_path[0]

	var instruction_initial = Direction.new()
	instruction_initial.type = DirectionType.MERGE
	instruction_initial.cell = cell_path[0]
	instruction_initial.direction = initial_direction
	instruction_initial.level = from.level
	instruction_initial.dock_station = from
	directions.append(instruction_initial)

	var point_to_reach: Vector2i

	for idx in cell_path.size():
		if idx == 0:
			continue
		point_to_reach = cell_path[idx]
		if cell_to_intersections.has(cell_path[idx]):
			var instruction = Direction.new()
			instruction.type = DirectionType.GO_STRAIGHT
			instruction.cell = cell_path[idx]
			instruction.level = from.level
			instruction.direction = cell_path[idx] - cell_path[idx-1] 
			instruction.point_to_reach = convert_to_3d(point_to_reach, from.level)
			instruction.intersection = cell_to_intersections[cell_path[idx]]
			instruction.from = cell_path[idx-1]
			directions.append(instruction)

			var instruction_intersection = Direction.new()
			instruction_intersection.type = DirectionType.INTERSECTION
			instruction_intersection.cell = cell_path[idx]
			instruction_intersection.intersection = cell_to_intersections[cell_path[idx]]
			instruction_intersection.from = cell_path[idx-1]
			instruction_intersection.to = cell_path[idx+1]
			instruction_intersection.level = from.level
			directions.append(instruction_intersection)
		
		if cell_to_docks.has(cell_path[idx]):
			var instruction = Direction.new()
			instruction.type = DirectionType.GO_STRAIGHT
			instruction.cell = cell_path[idx]
			instruction.level = from.level
			instruction.direction = cell_path[idx] - cell_path[idx-1] 
			instruction.point_to_reach = convert_to_3d(point_to_reach, from.level)
			directions.append(instruction)

			var instruction_dock = Direction.new()
			instruction_dock.type = DirectionType.EXIT
			instruction_dock.cell = cell_path[idx]
			instruction_dock.dock_station = cell_to_docks[cell_path[idx]]
			instruction_dock.level = to.level
			directions.append(instruction_dock)
		

	return directions


func follow_directions(shell: ShellVehicle, directions: Array[Direction]):
	for direction in directions:
		match direction.type:
			DirectionType.GO_STRAIGHT:
				var transform = get_target_transform_for_merge(direction.cell, 
					direction.direction, direction.level)
				shell.set_target_position(transform.origin)
				shell.set_target_rotation(transform.basis.get_rotation_quaternion())
				if direction.intersection:
					var area_next = direction.intersection.get_area_to_reach(direction.from)
					shell.set_area_to_reach(area_next)
					await shell.area_reached
				else:
					await shell.waypoint_reached
			DirectionType.MERGE:
				var transform = get_target_transform_for_merge(direction.cell, 
					direction.direction, direction.level)
				shell.set_target_position(transform.origin)
				shell.set_target_rotation(transform.basis.get_rotation_quaternion())
				await shell.waypoint_reached
			DirectionType.INTERSECTION:
				shell.set_target_height(direction.level * FLOOR_HEIGHT)
				shell.set_path(direction.intersection.path)
				var area_next = direction.intersection.get_area_to_reach(direction.to)
				shell.set_area_to_reach(area_next)
				await shell.area_reached
			DirectionType.EXIT:
				shell.set_target_height(direction.level * FLOOR_HEIGHT)
				var final_transform = direction.dock_station.final_transform
				shell.set_target_rotation(final_transform.basis.get_rotation_quaternion())
				shell.set_target_position(final_transform.origin)
				await  shell.waypoint_reached
	
	shell.stop()
		
