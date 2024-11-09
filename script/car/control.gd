extends VehicleBody3D


const STEER_SPEED = 1.5
const STEER_LIMIT = 0.4
const BRAKE_STRENGTH = 2.0

@export var engine_force_value := 40.0
@export var controlled_by_player = false
@onready var camera_3d: Camera3D = $CameraBase/Camera3D
@export var path_to_follow : PathFollow3D

var previous_speed := linear_velocity.length()
var _steer_target := 0.0

#@onready var desired_engine_pitch: float = $EngineSound.pitch_scale
func _ready() -> void:
	camera_3d.current = false
	camera_3d.set_physics_process(false)
	if controlled_by_player:
		camera_3d.current = true
		camera_3d.set_physics_process(true)

func _physics_process(delta: float):
	var acceleration = 0.0
	var brake = 0.0
	var is_acceleratig = false
	var is_braking = false
	if controlled_by_player:
		_steer_target = Input.get_axis(&"move_right", &"move_left")
		_steer_target *= STEER_LIMIT
		is_acceleratig = Input.is_action_pressed(&"move_forward")
		is_braking =  Input.is_action_pressed(&"move_back")
		acceleration = Input.get_action_strength(&"move_forward")
		brake = Input.get_action_strength(&"move_back")
		
	else:
		var look_ahead_distance = path_to_follow.global_position.distance_to(global_position)
		var L = 2.0
		var target_velocity = path_to_follow.velocitykmh
		
		var _acceleration = 0.05 * (target_velocity - linear_velocity.length())
		acceleration = _acceleration
		brake = _acceleration
		is_acceleratig = _acceleration > 0
		is_braking = _acceleration < 0
		
		var diff = path_to_follow.global_position - global_position
		var alpha = -diff.signed_angle_to(transform.basis.z, Vector3.UP)
		_steer_target = atan(2*L*sin(alpha)/look_ahead_distance)
		if look_ahead_distance < 0.3:
			_steer_target = 0
		_steer_target = clampf(_steer_target, -STEER_LIMIT, STEER_LIMIT)

	
	var fwd_mps := (linear_velocity * transform.basis).x

	# Engine sound simulation (not realistic, as this car script has no notion of gear or engine RPM).
	#desired_engine_pitch = 0.05 + linear_velocity.length() / (engine_force_value * 0.5)
	# Change pitch smoothly to avoid abrupt change on collision.
	#$EngineSound.pitch_scale = lerpf($EngineSound.pitch_scale, desired_engine_pitch, 0.2)

	if abs(linear_velocity.length() - previous_speed) > 1.0:
		# Sudden velocity change, likely due to a collision. Play an impact sound to give audible feedback,
		# and vibrate for haptic feedback.
		#$ImpactSound.play()
		Input.vibrate_handheld(100)
		for joypad in Input.get_connected_joypads():
			Input.start_joy_vibration(joypad, 0.0, 0.5, 0.1)

	# Automatically accelerate when using touch controls (reversing overrides acceleration).
	if DisplayServer.is_touchscreen_available() or is_acceleratig:
		# Increase engine force at low speeds to make the initial acceleration faster.
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = clampf(engine_force_value * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = engine_force_value

		if not DisplayServer.is_touchscreen_available():
			# Apply analog throttle factor for more subtle acceleration if not fully holding down the trigger.
			engine_force *= acceleration
	else:
		engine_force = 0.0

	if is_braking:
		# Increase engine force at low speeds to make the initial reversing faster.
		var speed := linear_velocity.length()
		if speed < 5.0 and not is_zero_approx(speed):
			engine_force = -clampf(engine_force_value * BRAKE_STRENGTH * 5.0 / speed, 0.0, 100.0)
		else:
			engine_force = -engine_force_value * BRAKE_STRENGTH

		# Apply analog brake factor for more subtle braking if not fully holding down the trigger.
		engine_force *= brake

	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)

	previous_speed = linear_velocity.length()
