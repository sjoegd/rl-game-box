extends CharacterBody3D
class_name Player

const SPEED = 25
const DASH_SPEED = 45
const ROTATE_SPEED = PI*1.5
const JUMP_VELOCITY = 50

@export var mass = .375
@export var color := "red"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_dash = true
var movement_locked = false

var input_straight := 0.0
var input_side := 0.0
var input_rotate := 0.0
var input_jump := 0.0
var input_dash := false

func _ready():
	set_color(color)

func set_color(c: String):
	$RigidBody/Mesh.get_node(c.capitalize()).visible = true

func _physics_process(delta):
	handle_input()
	handle_movement(delta)

func handle_input():
	input_straight = Input.get_axis("forward", "backward")
	input_side = Input.get_axis("left", "right")
	input_rotate = Input.get_axis("turn_right", "turn_left")
	input_jump = Input.get_action_strength("jump")
	input_dash = Input.is_action_just_pressed("dash") and can_dash

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
	if input_dash:
		can_dash = false
		movement_locked = true
		velocity = Vector3(-sin(rotation.y), 0, -cos(rotation.y)).normalized()*DASH_SPEED
		get_tree().create_timer(.15, true, true).connect("timeout", _on_dash_end)
	
	# Rigid Body
	$RigidBody.global_transform = global_transform
	$RigidBody.linear_velocity = velocity
	
	move_and_slide()

func _on_dash_end():
	movement_locked = false
	get_tree().create_timer(.5, true, true).connect("timeout", _on_dash_cooldown_end)

func _on_dash_cooldown_end():
	can_dash = true
