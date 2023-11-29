extends CharacterBody3D
class_name Player

const SPEED = 25
const ROTATE_SPEED = PI*1.5
const JUMP_VELOCITY = 50

@export var mass = .375
@export var color := "red"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	set_color(color)

func set_color(c: String):
	$RigidBody/Mesh.get_node(c.capitalize()).visible = true

func _physics_process(delta):
	
	$RigidBody.global_transform = global_transform
	
	velocity.y -= gravity * mass
	if is_on_floor():
		var jump = Input.get_action_strength("ui_accept")
		velocity.y = JUMP_VELOCITY * jump
	
	var input_straight = Input.get_axis("forward", "backward")
	var input_side = Input.get_axis("left", "right")
	var input_rotate = Input.get_axis("turn_right", "turn_left")
	
	if (input_straight or input_side) and name == "Player1":
		var direction = Vector3(
			(sin(rotation.y)*input_straight)+(cos(-rotation.y)*input_side),
			0,
			(cos(rotation.y)*input_straight)+(sin(-rotation.y)*input_side)
		).normalized()*SPEED
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if input_rotate and name == "Player1":
		rotate(Vector3(0, 1, 0), input_rotate * ROTATE_SPEED * delta)
	
	$RigidBody.linear_velocity = velocity
	
	move_and_slide()

func is_grounded() -> bool:
	var query = PhysicsRayQueryParameters3D.create(position + Vector3.UP, position + (Vector3.DOWN*0.01))
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		return true
	return false
