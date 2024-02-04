extends CharacterBody3D
class_name Player

@export var walk_speed := 7.5
@export var sprint_speed := 10.0
@export var jump_speed := 5.0

const sensitivity := 0.005
const gravity := 9.8

# Head is the raycast since otherwise the "Exlude Parent" property wouldn't work.
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var gun = $Head/Camera/Gun as Gun
@onready var aim_endpoint = $Head/Camera/AimEndPoint

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gun.init(head, aim_endpoint)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-45), deg_to_rad(60))

func _physics_process(delta):
	
	if Input.is_action_pressed("shoot"):
		gun.shoot(get_parent())
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_speed
	
	var speed = walk_speed
	if is_on_floor() and Input.is_action_pressed("sprint"):
		speed = sprint_speed
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()*speed
	
	if is_on_floor():
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = lerp(velocity.x, direction.x, delta*5)
		velocity.z = lerp(velocity.z, direction.z, delta*5)
	
	move_and_slide()
