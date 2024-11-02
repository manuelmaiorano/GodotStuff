extends CharacterBody3D

const CAMERA_CONTROLLER_ROTATION_SPEED := 3.0
const CAMERA_MOUSE_ROTATION_SPEED := 0.001
# A minimum angle lower than or equal to -90 breaks movement if the player is looking upward.
const CAMERA_X_ROT_MIN := deg_to_rad(-89.9)
const CAMERA_X_ROT_MAX := deg_to_rad(70)

# Release aiming if the mouse/gamepad button was held for longer than 0.4 seconds.
# This works well for trackpads and is more accessible by not making long presses a requirement.
# If the aiming button was held for less than 0.4 seconds, keep aiming until the aiming button is pressed again.
const AIM_HOLD_THRESHOLD = 0.4


# If `true`, the aim button was toggled checked by a short press (instead of being held down).
var toggled_aim := false

# The duration the aiming button was held for (in seconds).
var aiming_timer := 0.0

# Mouse capture
var is_capturing := false

@export var running = 0.0
# Synchronized controls
@export var aiming := false
@export var shoot_target := Vector3()
@export var motion := Vector2()


# Camera
@onready var camera_animation : AnimationPlayer = $CameraBase/Animation
@onready var camera_base : Node3D = $CameraBase
@onready var camera_rot : Node3D = $CameraBase/CameraRot
@onready var camera_camera : Camera3D = $CameraBase/CameraRot/SpringArm3D/Camera3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


const DIRECTION_INTERPOLATE_SPEED = 1
const MOTION_INTERPOLATE_SPEED = 10
const ROTATION_INTERPOLATE_SPEED = 10

const MIN_AIRBORNE_TIME = 0.7
const JUMP_SPEED = 5

@onready var root: LimboHSM = $Root
@onready var falling: LimboState = $Root.find_child("Falling")
@onready var gun_strafe: LimboState = $Root.find_child("GunStrafe")
@onready var standing: LimboState = $Root.find_child("Standing")
@onready var not_falling: LimboState = $Root.find_child("NotFalling")
@onready var driving: LimboState = $Root.find_child("Driving")
@onready var seated: LimboState = $Root.find_child("Seated")
@onready var ragdoll: LimboState = $Root.find_child("Ragdoll")
@onready var sword: LimboState = $Root.find_child("Sword")
@onready var hostage: LimboState = $Root.find_child("Hostage")


@onready var initial_position = transform.origin
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * ProjectSettings.get_setting("physics/3d/default_gravity_vector")

@onready var player_model: Node3D = %GeneralSkeleton

var airborne_time = 100
@export var controlled_by_player = true
@onready var animation_tree = $AnimationTree
var rag = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_hsm()
	
	camera_camera.current = false
	$DetectStuff.area_entered.connect(_on_hit)
	
	if not controlled_by_player:
		return
	
	is_capturing = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	camera_camera.make_current()
	
func initialize_hsm():
	not_falling.add_transition(standing, gun_strafe, "aim")
	not_falling.add_transition(gun_strafe, standing, "stop_aim")
	not_falling.add_transition(standing, sword, "start_sword")
	not_falling.add_transition(sword, standing, "stop_sword")
	not_falling.add_transition(standing, seated, "sit")
	not_falling.add_transition(seated, standing, "stand")
	not_falling.add_transition(standing, hostage, "start_hostage")
	not_falling.add_transition(hostage, standing, "stop_hostage")
	
	root.add_transition(not_falling, ragdoll, "start_ragdoll")
	root.add_transition(ragdoll, not_falling, "stop_ragdoll")

	root.add_transition(not_falling, falling, "fall")
	root.add_transition(falling, not_falling, "land")
	root.add_transition(not_falling, driving, "enter_car")
	root.add_transition(driving, not_falling, "exit_car")
	
	setup_hsm_node(standing)
	setup_hsm_node(gun_strafe)
	setup_hsm_node(falling)
	setup_hsm_node(driving)
	setup_hsm_node(seated)
	setup_hsm_node(ragdoll)
	setup_hsm_node(sword)
	setup_hsm_node(hostage)
	
	root.initialize(self)
	root.set_active(true)

func setup_hsm_node(node):
	node.player_controller = self
	node.animation_tree = animation_tree
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var _motion
	if controlled_by_player:
		_motion = Vector2(
				Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
				Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
	else:
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		var vector_to: Vector3 = global_position.direction_to(next_path_position).normalized()
		_motion = Vector2(vector_to.x, vector_to.z)
	
	motion = motion.lerp(_motion, MOTION_INTERPOLATE_SPEED * delta)
	
	if controlled_by_player:
		handle_player_input(delta)
	
	if transform.origin.y < -40:
		transform.origin = initial_position
		
	airborne_time += delta
	if is_on_floor():
		if airborne_time > 0.2:
			root.dispatch("land")
			
		airborne_time = 0

	var on_air = airborne_time > 0.2
	if on_air:
		if (velocity.y <0): 
			root.dispatch("fall")
		velocity += gravity * delta
	
	var state = root.get_leaf_state()
	velocity.x = state.velocity.x
	velocity.z = state.velocity.z
	var orientation = state.orientation
	
	if not rag:
		update_velocity()
	update_orientation(orientation)
	
func update_velocity():
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()

func update_orientation(orientation):
	player_model.global_transform.basis = orientation.basis
	
func handle_player_input(delta):
	
	var camera_move = Vector2(
			Input.get_action_strength("view_right") - Input.get_action_strength("view_left"),
			Input.get_action_strength("view_up") - Input.get_action_strength("view_down"))
			
	var camera_speed_this_frame = delta * CAMERA_CONTROLLER_ROTATION_SPEED
	if aiming:
		camera_speed_this_frame *= 0.5
		
	rotate_camera(camera_move * camera_speed_this_frame)
	
	var current_aim = false
	# Keep aiming if the mouse wasn't held for long enough.
	if Input.is_action_just_released("aim") and aiming_timer <= AIM_HOLD_THRESHOLD:
		current_aim = true
		toggled_aim = true
	else:
		current_aim = toggled_aim or Input.is_action_pressed("aim")
		if Input.is_action_just_pressed("aim"):
			toggled_aim = false

	if current_aim:
		aiming_timer += delta
	else:
		aiming_timer = 0.0

	if aiming != current_aim:
		aiming = current_aim
		if aiming:
			camera_animation.play("shoot")
			root.dispatch("aim")
		else:
			camera_animation.play("far")
			root.dispatch("stop_aim")
	
	if Input.is_action_pressed("shoot"):
		root.dispatch("shoot")
		root.dispatch("slash")
		#evaulate shoot_target
		#var ray_from = camera_camera.project_ray_origin(ch_pos)
		#var ray_dir = camera_camera.project_ray_normal(ch_pos)
#
		#var col = get_parent().get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_from + ray_dir * 1000, 0b11, [self]))
		#if col.is_empty():
			#shoot_target = ray_from + ray_dir * 1000
		#else:
			#shoot_target = col.position
	var _running = Input.is_action_pressed("sprint")
	running = lerpf(running, _running, MOTION_INTERPOLATE_SPEED * delta)
	if Input.is_action_just_pressed("punch"):
		root.dispatch("punch")
	if Input.is_action_just_pressed("jump"):
		root.dispatch("jump")
	if Input.is_action_just_pressed("interact"):
		root.dispatch("pick")
	if Input.is_action_just_pressed("action_1"):
		root.dispatch("sit")
	if Input.is_action_just_pressed("action_2"):
		root.dispatch("standing")
	if Input.is_action_just_pressed("action_3"):
		root.dispatch("start_ragdoll")
	if Input.is_action_just_pressed("action_4"):
		root.dispatch("start_sword")
	if Input.is_action_just_pressed("action_5"):
		root.dispatch("stop_sword")
	if Input.is_action_just_pressed("action_6"):
		root.dispatch("start_hostage")
	if Input.is_action_just_pressed("action_7"):
		root.dispatch("stopping_hostage")

func start_ragdoll():
	%GeneralSkeleton.physical_bones_start_simulation()
	$MainCollider.disabled = true
	schedule_ragdoll_end()
	rag = true

func schedule_ragdoll_end():
	await get_tree().create_timer(10.0).timeout
	%GeneralSkeleton.physical_bones_stop_simulation()
	
	$MainCollider.disabled = false
	root.dispatch("stop_ragdoll")
	rag = false

func shoot():
	pass
	#var shoot_origin = shoot_from.global_transform.origin
	#var shoot_dir = (agent_input.shoot_target - shoot_origin).normalized()
#
	#var bullet = preload("res://scenes/props/weapons/bullet.tscn").instantiate()
	#get_parent().add_child(bullet, true)
	#bullet.global_transform.origin = shoot_origin
	## If we don't rotate the bullets there is no useful way to control the particles ..
	#bullet.look_at(shoot_origin + shoot_dir, Vector3.UP)
	#bullet.add_collision_exception_with(self)
	#shoot.rpc()
	

func _input(event):
	if not controlled_by_player:
		return
	# Make mouse aiming speed resolution-independent
	# (required when using the `canvas_items` stretch mode).
	var scale_factor: float = min(
			(float(get_viewport().size.x) / get_viewport().get_visible_rect().size.x),
			(float(get_viewport().size.y) / get_viewport().get_visible_rect().size.y)
	)

	if event is InputEventMouseMotion:
		var camera_speed_this_frame = CAMERA_MOUSE_ROTATION_SPEED
		if aiming:
			camera_speed_this_frame *= 0.75
		rotate_camera(event.relative * camera_speed_this_frame * scale_factor)
	
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()

func _on_hit(area):
	if area != $LeftHand/HandCollider:
		root.dispatch("start_radgoll")

func rotate_camera(move):
	camera_base.rotate_y(-move.x)
	# After relative transforms, camera needs to be renormalized.
	camera_base.orthonormalize()
	camera_rot.rotation.x = clamp(camera_rot.rotation.x + move.y, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)

func get_aim_rotation():
	var camera_x_rot = clamp(camera_rot.rotation.x, CAMERA_X_ROT_MIN, CAMERA_X_ROT_MAX)
	# Change aim according to camera rotation.
	if camera_x_rot >= 0: # Aim up.
		return -camera_x_rot / CAMERA_X_ROT_MAX
	else: # Aim down.
		return camera_x_rot / CAMERA_X_ROT_MIN

func get_camera_base_quaternion() -> Quaternion:
	return camera_base.global_transform.basis.get_rotation_quaternion()

func get_camera_rotation_basis() -> Basis:
	return camera_rot.global_transform.basis

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or \
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2(1280, 720))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
