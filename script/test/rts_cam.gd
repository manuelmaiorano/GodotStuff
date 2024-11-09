extends Camera3D

# Camera settings
@export var zoom_speed = 2.0
@export var pan_speed = 0.1
@export var min_zoom_distance = 2.0
@export var max_zoom_distance = 50.0

# Internal variables
var distance_from_target = 10.0
var target_position = Vector3.ZERO

func _ready():
	# Set initial camera position based on target position and distance
	update_camera_position()

func _input(event):
	# Zoom in/out with mouse scroll
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Right-click dragging to pan
		pan_camera(event.relative)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(zoom_speed)

func zoom_camera(amount):
	# Adjust distance, clamped between min and max distances
	distance_from_target = clamp(distance_from_target + amount, min_zoom_distance, max_zoom_distance)
	update_camera_position()

func pan_camera(relative_motion):
	# Pan the camera by moving the target position based on mouse movement
	var pan_offset = -transform.basis.x * relative_motion.x * pan_speed
	pan_offset += -transform.basis.y * relative_motion.y * pan_speed
	target_position += pan_offset
	update_camera_position()

func update_camera_position():
	# Update the camera position based on the target position and zoom distance
	var direction = (transform.origin - target_position).normalized()
	transform.origin = target_position + direction * distance_from_target
	look_at(target_position)
