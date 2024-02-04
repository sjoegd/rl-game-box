extends CharacterBody3D
class_name Player

signal needs_reset

@export var mass := 2.0
@export var speed := 15.0
@export var jump_speed := 7.5
@export var rotate_speed := 2*PI
@export var fast_rotate_multiplier := 1.5
@export var dash_speed := 50.0
@export var dash_period := 0.075 #s
@export var dash_cooldown := 1 #s
@export var color := "lightblue"
@export var number := 1

@onready var controller = $PlayerController
@onready var rigid_collider = $RigidCollider
@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var mesh := $RigidCollider/Mesh
@onready var base_transform = transform

var gravity := 9.8 * mass

var can_dash := true
var is_dashing := false

var input_left := 0.0
var input_right := 0.0
var input_up := 0.0
var input_down := 0.0
var input_rotate := 0.0
var input_dash := 0.0

func _ready():
	controller.init(self)
	_update_rigid_collider()
	_update_color(color)

func _update_color(c: String):
	var _color = Color(c)
	var material = mesh.get_active_material(0).duplicate()
	material.albedo_color = _color
	mesh.set_surface_override_material(0, material)

func game_over():
	controller.done = true
	controller.needs_reset = true

func reset():
	transform = base_transform
	velocity = Vector3.ZERO
	camera_holder.reset()
	controller.reset()

func _physics_process(delta):
	
	if controller.needs_reset:
		needs_reset.emit()
		return
	
	_zero_input()
	_handle_input()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if not is_dashing:
		rotate_y(input_rotate*rotate_speed*delta)
		
		var input_dir = Vector2(input_right-input_left, input_down-input_up)
		var direction = (
			transform.basis * Vector3(input_dir.x/2, 0, input_dir.y)
		).normalized()*speed
		
		velocity.x = direction.x
		velocity.z = direction.z
		
		if can_dash and input_dash:
			_start_dash()
			var direction_basis = transform.basis * Vector3.FORWARD
			if direction:
				direction_basis = direction/speed
			velocity.x = direction_basis.x * dash_speed
			velocity.z = direction_basis.z * dash_speed
	
	move_and_slide()
	_update_rigid_collider()
	_update_camera_holder(delta)

func _zero_input():
	input_left = 0.0
	input_right = 0.0
	input_up = 0.0
	input_down = 0.0
	input_rotate = 0.0
	input_dash = 0.0

func _handle_input():
	if controller.heuristic == "human" and camera.current:
		input_left = float(Input.is_action_pressed("left"))
		input_right = float(Input.is_action_pressed("right"))
		input_up = float(Input.is_action_pressed("up"))
		input_down = float(Input.is_action_pressed("down"))
		input_rotate = float(Input.is_action_pressed("rotate_left")) - float(Input.is_action_pressed("rotate_right"))
		input_dash = float(Input.is_action_just_pressed("dash"))
	else:
		input_left = controller.action_left
		input_right = controller.action_right
		input_up = controller.action_up
		input_down = controller.action_down
		input_rotate = controller.action_rotate
		input_dash = controller.action_dash

func _start_dash():
	can_dash = false
	is_dashing = true
	get_tree().create_timer(dash_period, true, true).timeout.connect(_on_dash_end)

func _on_dash_end():
	is_dashing = false
	get_tree().create_timer(dash_cooldown, true, true).timeout.connect(_on_dash_recharge)

func _on_dash_recharge():
	can_dash = true

func _update_rigid_collider():
	rigid_collider.global_transform = global_transform
	rigid_collider.linear_velocity = velocity
	rigid_collider.angular_velocity = Vector3.ZERO

func _update_camera_holder(delta):
	camera_holder.global_position = lerp(camera_holder.global_position, global_position, delta*20)
	var current_camera_rotation = camera_holder.transform.basis.get_rotation_quaternion()
	var target_camera_rotation = transform.basis.get_rotation_quaternion()
	var smooth_rotation = current_camera_rotation.slerp(target_camera_rotation, delta*10)
	camera_holder.global_rotation = smooth_rotation.get_euler()
