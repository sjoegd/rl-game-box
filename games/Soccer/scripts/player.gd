extends CharacterBody3D
class_name Player

signal needs_reset

@export var walk_speed := 15.0
@export var sprint_speed := 20.0
@export var rotate_speed := 2*PI
@export var color := "white"
@export var number := 1

@onready var controller = $PlayerController
@onready var rigid_collider = $RigidCollider
@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var mesh := $RigidCollider/Mesh
@onready var base_transform = transform

var input_left := 0.0
var input_right := 0.0
var input_up := 0.0
var input_down := 0.0
var input_rotate := 0.0
var input_sprint := 0.0

var human_override := false
var is_sprinting := false

var game: Game

func init(_game: Game):
	game = _game
	controller.init(self)

func _ready():
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
	_update_camera_holder(0, true)
	_update_rigid_collider()
	controller.reset()

func _physics_process(delta):
	
	if controller.needs_reset:
		needs_reset.emit()
		return
	
	_zero_input()
	_handle_input()
		
	rotate_y(input_rotate*rotate_speed*delta)
	
	var speed := walk_speed
	is_sprinting = bool(input_sprint)
	if is_sprinting:
		speed = sprint_speed
	
	var input_dir = Vector2(input_right-input_left, input_down-input_up)
	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()*speed
	
	velocity.x = direction.x
	velocity.z = direction.z
	
	move_and_slide()
	_update_rigid_collider()
	_update_camera_holder(delta)

func _zero_input():
	input_left = 0.0
	input_right = 0.0
	input_up = 0.0
	input_down = 0.0
	input_rotate = 0.0
	input_sprint = 0.0

func _handle_input():
	if (controller.heuristic == "human" or human_override) and camera.current:
		input_left = float(Input.is_action_pressed("left"))
		input_right = float(Input.is_action_pressed("right"))
		input_up = float(Input.is_action_pressed("up"))
		input_down = float(Input.is_action_pressed("down"))
		input_rotate = float(Input.is_action_pressed("rotate_left")) - float(Input.is_action_pressed("rotate_right"))
		input_sprint = float(Input.is_action_pressed("sprint"))
	else:
		input_left = controller.action_left
		input_right = controller.action_right
		input_up = controller.action_up
		input_down = controller.action_down
		input_rotate = controller.action_rotate_left - controller.action_rotate_right
		input_sprint = controller.action_sprint

func _update_rigid_collider():
	rigid_collider.global_transform = global_transform
	rigid_collider.linear_velocity = velocity
	rigid_collider.angular_velocity = Vector3.ZERO

func _update_camera_holder(delta, instant = false):
	camera_holder.global_position = lerp(camera_holder.global_position, global_position, delta*20)
	var current_camera_rotation = camera_holder.transform.basis.get_rotation_quaternion()
	var target_camera_rotation = transform.basis.get_rotation_quaternion()
	var smooth_rotation = current_camera_rotation.slerp(target_camera_rotation, delta*10)
	camera_holder.global_rotation = smooth_rotation.get_euler()
	if instant:
		camera_holder.global_position = global_position
		camera_holder.global_rotation = global_rotation
