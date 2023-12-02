extends CharacterBody3D
class_name Player

signal needs_reset

@export var mass = .375
@export var color := "red"

@onready var camera := $Camera as Camera3D
@onready var controller := $Controller as PlayerController

const SPEED := 25.0
const DASH_SPEED := 35.0
const ROTATE_SPEED := PI*1.5
const JUMP_VELOCITY := 45.0
const MOUSE_SENS := 0.05
const DASH_DURATION := 0.2
const DASH_COOLDOWN := 0.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _game: Game

var can_dash = true
var movement_locked = false

var input_straight := 0.0
var input_side := 0.0
var input_rotate := 0.0
var input_jump := 0.0
var input_dash := false

func init(game: Game):
	_game = game

func _ready():
	set_color(color)
	controller.init(self)

func set_color(c: String):
	$RigidBody/Mesh.get_node(c.capitalize()).visible = true

func game_over():
	controller.done = true
	controller.needs_reset = true

func reset(_transform: Transform3D):
	transform = _transform
	velocity = Vector3.ZERO
	movement_locked = false
	can_dash = true
	controller.reset()

func _physics_process(delta):
	if controller.needs_reset:
		needs_reset.emit()
		return
	handle_input()
	handle_movement(delta)

func handle_input():
	input_straight = 0
	input_side = 0
	input_rotate = 0
	input_jump = 0
	input_dash = false
	if controller.heuristic == "human" and camera.current:
		input_straight = Input.get_axis("forward", "backward")
		input_side = Input.get_axis("left", "right")*0.5
		input_jump = Input.get_action_strength("jump")
		input_dash = Input.is_action_just_pressed("dash") and can_dash
		if _game.can_get_mouse_input():
			var mouse_x_movement := _game.get_mouse_x_movement()
			input_rotate = -MOUSE_SENS * mouse_x_movement
	else:
		input_straight = controller.action_straight
		input_side = controller.action_side
		input_rotate = controller.action_rotate
		input_jump = controller.action_jump
		input_dash = bool(controller.action_dash) and can_dash

func handle_movement(delta):
	
	if not movement_locked:
		# Y Movement
		velocity.y -= gravity * mass
		if is_on_floor():
			velocity.y = JUMP_VELOCITY * input_jump
		
		# XZ Movement
		if input_straight or input_side:
			var direction = Vector2(
				(sin(rotation.y)*input_straight)+(cos(-rotation.y)*input_side),
				(cos(rotation.y)*input_straight)+(sin(-rotation.y)*input_side)
			).normalized()*SPEED
			velocity.x = direction.x
			velocity.z = direction.y
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# Rotation
		rotate(Vector3(0, 1, 0), input_rotate * ROTATE_SPEED * delta)

	# Dash
	if input_dash and is_on_floor():
		can_dash = false
		movement_locked = true
		var dash_direction = Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		if velocity.x or velocity.z:
			dash_direction = velocity * Vector3(1, 0, 1)
		velocity = dash_direction.normalized()*DASH_SPEED
		get_tree().create_timer(DASH_DURATION, true, true).connect("timeout", _on_dash_end)
	
	# Rigid Body
	$RigidBody.global_transform = global_transform
	$RigidBody.linear_velocity = velocity
	
	move_and_slide()
	
	# Ensure player never goes under the ground
	if position.y < 0:
		position.y = 0

func _on_dash_end():
	movement_locked = false
	get_tree().create_timer(DASH_COOLDOWN, true, true).connect("timeout", _on_dash_cooldown_end)

func _on_dash_cooldown_end():
	can_dash = true

func get_enemy_team():
	return "red" if color == "blue" else "blue"
