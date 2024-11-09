@tool
extends Path3D

@export var spawn_node: Node3D
# export + setget is a bootleg approach of creating a "button" in the inspector for tool scripts
@export_range(0, 1000) var item_count = 1:
	set(value):
		if Engine.is_editor_hint():
			item_count = value
			spawn_item()
	get:
		return item_count

func spawn_item():
	var offsets = []
	# points holds the list of baked points that define our smooth curve
	# we sample this, and the associated up vectors, to spawn objects along it
	var points = curve.get_baked_points()
	var upvectors = curve.get_baked_up_vectors()

	# Wipe anything we previously created before continuing
	for child in spawn_node.get_children():
		child.free()
	# A rough way of dividing up the road. Not perfect.
	for i in range(item_count):
		offsets.append(float(i) / float(item_count + 1))

	for offset_idx in range(offsets.size()):
		# Take our rough divide points and calculate the index position
		var idx = clamp(int(points.size() * offsets[offset_idx]), 0, points.size() - 1)
		var point = points[idx]
		var upVector = upvectors[idx]

		# Create a new Node3D to hold our item and translate it to the point position identified
		var item = Node3D.new()
		item.name = "item_" + str(offset_idx)
		spawn_node.add_child(item)
		item.translate(point)

		# Here's something I made earlier. Load it and add it to our item holder
		var dominopiece = preload("res://dominopiece.tscn").instantiate()
		dominopiece.name = "dominopiece"
		item.add_child(dominopiece)

		# Translate our item by a given offset relative to the path point.
		# In this case I know the road is exactly 0.1 units wide, so I translate 0.05 units on the 'x' axis (relative to our item holder)
		# which moves the item to the center of the road
		dominopiece.translate(Vector3(0.05, 0.0, 0.0))

		# Bootleg method of aligning objects to the road's upvector
		if idx + 1 < points.size() - 1:
			item.look_at(points[idx + 1], upVector)
		else:
			item.look_at(points[idx - 1], upVector)

		# Make item holder and item show up in the editor scene tree
		item.set_owner(get_tree().get_edited_scene_root())
		dominopiece.set_owner(get_tree().get_edited_scene_root())
