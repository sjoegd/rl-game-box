extends Node3D
class_name CarCamera

@onready var cameras: Array = get_children()
@onready var camera: Camera3D = cameras[0] as Camera3D

var _car: Car
var _mode := 0
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
	_mode = (_mode + 1) % cameras.size()
	camera = cameras[_mode]
	if old_camera.current:
		camera.make_current()

func reset():
	global_position = _car.global_position
	transform = _car.transform
	camera_lookat = _car.global_position
	if camera.name == "ThirdPerson":
		camera.look_at(camera_lookat)

func update(delta: float):
	global_position = global_position.lerp(_car.global_position, delta * 20.0)
	transform = transform.interpolate_with(_car.transform, delta * 5.0)
	if _car.is_going_forward() and camera.name == "ThirdPerson" :
		camera_lookat = camera_lookat.lerp(_car.global_position + _car.linear_velocity, delta*5.0)
		camera.look_at(camera_lookat)

func get_car() -> Car:
	return _car

func get_mode() -> int:
	return _mode

func set_mode(mode: int) -> void:
	_mode = mode
	camera = cameras[_mode]
