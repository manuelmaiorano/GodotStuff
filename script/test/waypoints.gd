extends Path3D

var waypoints: Array[Vector3]
var materials: Array[StandardMaterial3D]
@export var item_count = 30

func _ready() -> void:
	var offsets = []
	var points = curve.get_baked_points()

	for i in range(item_count):
		offsets.append(float(i) / float(item_count + 1))

	for offset_idx in range(offsets.size()):
		# Take our rough divide points and calculate the index position
		var idx = clamp(int(points.size() * offsets[offset_idx]), 0, points.size() - 1)
		var point = points[idx]
		waypoints.append(point)
		
		var waypoint_mesh = MeshInstance3D.new()
		waypoint_mesh.mesh = SphereMesh.new()
		var mat = StandardMaterial3D.new()
		waypoint_mesh.mesh.surface_set_material(0, mat)
		materials.append(mat)
		add_child(waypoint_mesh)
		waypoint_mesh.translate(point)
		
	
	
func get_closest_waypoint(pos: Vector3):
	var MIN_DIST = 8.0
	var MAX_DIST = 5.0
	
	var mind = INF
	var min_idx = 0
	materials[min_idx].albedo_color = Color.CHOCOLATE

	for idx in waypoints.size():
		var pt = waypoints[idx]
		var d = pos.distance_to(pt)
		
		if d < MIN_DIST:
			continue
		
		if d < mind:
			materials[min_idx].albedo_color = Color.WHITE
			min_idx = idx
			mind = d
			materials[idx].albedo_color = Color.CHOCOLATE
		
		
			
	return waypoints[min_idx]
	
	
