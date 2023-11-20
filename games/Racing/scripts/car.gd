extends VehicleBody3D

@onready var center: Marker3D = $Center as Marker3D
@onready var camera: Camera3D = $CameraPivot/Camera as Camera3D
@onready var camera_pivot = $CameraPivot

@export var steer: float = PI/4
@export var power: int = 300
@export var max_speed: int = 100

@onready var camera_lookat: Vector3 = global_position

func _ready():
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = center.position

func _physics_process(delta):
	handle_input(delta)
	handle_camera(delta)

func handle_input(delta):
	steering = move_toward(steering, Input.get_axis("ui_right", "ui_left") * steer, delta * 2.5)
	engine_force = Input.get_axis("ui_down", "ui_up") * power

func handle_camera(delta):
	if not camera.current:
		return
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta*20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta*5.0)
	if linear_velocity.dot(transform.basis.z) > 0:
		camera_lookat = camera_lookat.lerp(global_position + linear_velocity, delta*5.0)
		camera.look_at(camera_lookat)
