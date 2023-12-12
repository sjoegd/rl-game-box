extends CharacterBody3D
class_name Player

signal needs_reset

@export var color := "red"
@export var speed := 10.0
@export var rotation_speed := PI*2
@export var jump_strength := 8.0
@export var gravity := 20.0

@onready var body := $Body
@onready var controller := $Controller as PlayerController

var _game: Game

var input_jump := false
var input_rotate := 0.0
var input_straight := 0.0
var input_side := 0.0

var human_override := false

func init(game: Game):
	_game = game

func _ready():
	set_color(color)
	controller.init(self)

func set_color(_color: String):
	var hex = Utility.color_to_hex(_color)
	var mesh = $Body/Mesh as MeshInstance3D
	var material = mesh.get_active_material(0) as StandardMaterial3D
	material = material.duplicate()
	material.set("albedo_color", Color(hex))
	mesh.set_surface_override_material(0, material)

func game_over():
	controller.needs_reset = true
	controller.done = true

func reset(_transform: Transform3D):
	zero_input()
	transform = _transform
	velocity = Vector3.ZERO
	body.global_transform = global_transform
	body.linear_velocity = velocity
	body.angular_velocity = Vector3.ZERO
	controller.reset()
	controller.done = false

func _physics_process(delta: float):
	
	if controller.needs_reset:
		needs_reset.emit()
		return
	
	handle_input()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif input_jump:
		velocity.y = jump_strength
	
	transform.basis = transform.basis.rotated(
		Vector3(0, 1, 0), input_rotate*rotation_speed*delta
	)

	var direction = (
		transform.basis * Vector3(input_side, 0, input_straight)
	).normalized()*speed
	
	velocity.x = direction.x 
	velocity.z = direction.z 
	
	body.global_transform = global_transform
	body.linear_velocity = velocity
	
	move_and_slide()

func zero_input():
	input_jump = false
	input_rotate = 0.0
	input_straight = 0.0
	input_side = 0.0

func handle_input():
	zero_input()
	if (controller.heuristic == "human" or human_override) and $Camera.current:
		input_jump = Input.is_action_just_pressed("jump")
		input_rotate = Input.get_axis("right_rotate", "left_rotate")
		input_straight = Input.get_axis("forward", "backward")
		input_side = Input.get_axis("left", "right")*0.75
	else:
		input_jump = bool(controller.action_jump)
		input_rotate = controller.action_rotate
		input_straight = controller.action_forward - controller.action_backward
		input_side = (controller.action_left - controller.action_right)*0.75
