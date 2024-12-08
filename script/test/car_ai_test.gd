extends Node


class Road:
	var from: Intersection
	var to: Intersection
	var path: Path3D

enum ItersectionType {FOUR_WAY, THREE_WAY, ROUNDABOUT}

class Intersection:
	var name: StringName
	var occupied: bool
	var type: ItersectionType
	var semaphores: Array[IntersectionSemaphore]
	var waypoints: Array[Vector3]

class Place:
	var name: StringName
	
class RoadGraph:
	pass


enum DirectionType {GO_STRAIGHT, TURN_AT_INTERSECTION, GO_TO_WAYPOINT}
class Directions:
	var type: DirectionType
	var road: Road
	var intersection: Intersection
	var intersection_waypoint_id: int
	var waypoint: Vector3
	var path_to_follow: Path3D
	

var graph: RoadGraph

func find_path(graph: RoadGraph, from: Place, to: Place):
	pass

func move_car(car: CarController, from: Place, to: Place):
	var directions: Array[Directions] = find_path(graph, from, to)
	
	for direction in directions:
		match  direction.type:
			DirectionType.GO_STRAIGHT:
				car.control_mode = CarController.ControlMode.FOLLOW_PATH
				car.path_to_follow = direction.path_to_follow
				await car.path_ended
			DirectionType.TURN_AT_INTERSECTION:
				car.control_mode = CarController.ControlMode.WAYPOINT
				var semaphore = direction.intersection.semaphores[direction.intersection.intersection_waypoint_id]
				if semaphore.state == IntersectionSemaphore.SEMAPHORE_STATE.RED:
					await semaphore.turned
				var next_waypoint = direction.intersection.waypoints[direction.intersection.intersection_waypoint_id]
				car.next_waypoint = next_waypoint
				await car.waypoint_reached
			DirectionType.GO_TO_WAYPOINT:
				car.control_mode = CarController.ControlMode.WAYPOINT
				car.next_waypoint = direction.waypoint
				await car.waypoint_reached
