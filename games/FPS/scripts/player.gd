extends CharacterBody3D
class_name Player

@export var walk_speed := 7.5
@export var sprint_speed := 10.0
@export var jump_speed := 5.0
@export var color := "white"

# Head is the raycast since otherwise the "Exlude Parent" property wouldn't work.
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var gun = $Head/Camera/Gun as Gun
@onready var aim_endpoint = $Head/Camera/AimEndPoint
@onready var mesh = $Mesh

const sensitivity := 0.005
const gravity := 9.8

func init(_bullet_container: Node3D):
	gun.init(head, aim_endpoint, _bullet_container, color)

func _ready():
	_update_color()

func _update_color():
	var material = mesh.get_active_material(0)
	material.albedo_color = Color(color)
	mesh.set_surface_override_material(0, material)

func _unhandled_input(event):
	if not camera.current:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		head.rotate_x(-event.relative.y * sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-45), deg_to_rad(60))

func _physics_process(delta):
	
	if not camera.current:
		return
	
	if Input.is_action_pressed("shoot"):
		gun.shoot()
	
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
