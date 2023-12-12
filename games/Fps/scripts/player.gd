extends CharacterBody3D

@export var sensitivity := 0.01
@export var speed := 10.0
@export var jump_speed := 6.25
@export var gravity := 15.0

@export var base_fov := 90.0
@export var fov_change := 0.5

@onready var camera := $Camera
@onready var camera_origin: Vector3 = $Camera.transform.origin

const bob_freq := 1.0
const bob_amp := 0.08
var t_bob := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(45))

func _physics_process(delta):
	
	# GRAVITY / JUMP
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed
	
	# DIRECTIONAL INPUT
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()*speed
	
	if is_on_floor():
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = lerp(velocity.x, direction.x, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z, delta * 3.0)
	
	# HEAD BOB
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = camera_origin + _head_bob(t_bob)
	
	# FOV
	var v_speed = clamp(velocity.length(), 0, speed)
	var target_fov = base_fov + (fov_change * v_speed)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _head_bob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq/2) * bob_amp
	return pos
