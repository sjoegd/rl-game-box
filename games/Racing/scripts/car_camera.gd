extends Node3D
class_name CarCamera

@onready var cameras: Array = get_children()
@onready var camera: Camera3D = cameras[0] as Camera3D

var _car: Car
var mode := 0
var camera_lookat: Vector3 = Vector3.ZERO

func init(car: Car):
	_car = car
	camera_lookat = _car.global_position

func make_current():
	camera.make_current()

func is_current():
	return camera.current

func next_mode():
	var old_camera = camera
	mode = (mode + 1) % cameras.size()
	camera = cameras[mode]
	if old_camera.current:
		camera.make_current()

func reset():
	global_position = _car.global_position
	transform = _car.transform
	camera_lookat = _car.global_position
	camera.look_at(camera_lookat)

func update(delta: float):
	global_position = global_position.lerp(_car.global_position, delta * 20.0)
	transform = transform.interpolate_with(_car.transform, delta * 5.0)
	if _car.is_going_forward():
		camera_lookat = camera_lookat.lerp(_car.global_position + _car.linear_velocity, delta*5.0)
		camera.look_at(camera_lookat)

func get_car() -> Car:
	return _car
