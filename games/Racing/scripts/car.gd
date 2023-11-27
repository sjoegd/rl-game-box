extends VehicleBody3D
class_name Car

signal finished(car: Car)
signal need_reset

var game: Game

@onready var center: Marker3D = $Center as Marker3D
@onready var nose: Marker3D = $Nose as Marker3D
@onready var camera: Camera3D = $CameraPivot/Camera as Camera3D
@onready var camera_pivot = $CameraPivot
@onready var controller: CarController = $AIController3D as CarController

@onready var camera_lookat: Vector3 = global_position

@export var steer: float = PI/4
@export var power: int = 300
@export var speed_limit: int = 100

var input_steer: float = 0
var input_power: float = 0

func init(_game: Game):
	game = _game

func _ready():
	center_of_mass = center.position
	controller.init(self)

func game_over():
	controller.done = true
	controller.needs_reset = true

func reset(grid_position: Marker3D):
	controller.reset()
	position = grid_position.position
	rotation = grid_position.rotation
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	steering = 0
	engine_force = 0
	reset_camera()

func reset_camera():
	camera_pivot.global_position = global_position
	camera_pivot.transform = transform
	camera_lookat = global_position
	camera.look_at(camera_lookat)

func _physics_process(delta):
	if controller.needs_reset:
		need_reset.emit()
		return
	handle_input(delta)
	handle_camera(delta)

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(speed_limit)

func handle_input(delta):
	if controller.heuristic == "human":
		input_steer = Input.get_axis("ui_right", "ui_left")
		input_power = Input.get_axis("ui_down", "ui_up")
	else:
		input_steer = controller.steer_action
		input_power = controller.power_action
	steering = move_toward(steering, input_steer * steer, delta * 2.5)
	engine_force = input_power * power

func handle_camera(delta):
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta*20.0)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta*5.0)
	if is_going_forward():
		camera_lookat = camera_lookat.lerp(global_position + linear_velocity, delta*5.0)
		camera.look_at(camera_lookat)

func get_speed() -> float:
	return (linear_velocity * Vector3(1, 0, 1)).length()

func get_angle_nose_to_position(pos: Vector3) -> float:
	var ignore_y = Vector3(1, 0, 1)
	var center_to_nose = (nose.global_position - global_position) * ignore_y
	var center_to_pos = (pos - global_position) * ignore_y
	return center_to_nose.signed_angle_to(center_to_pos, Vector3(0, 1, 0))

func is_going_forward() -> bool:
	return linear_velocity.dot(transform.basis.z) > 0

func is_going_to_position(pos: Vector3) -> bool:
	return linear_velocity.dot(pos - global_position) > 0 && is_going_forward()

func _on_finish_detected(_body):
	finished.emit(self)
