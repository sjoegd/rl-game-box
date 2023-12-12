extends VehicleBody3D
class_name Car

signal finished(car: Car)
signal needs_reset
signal collision_with_static(car: Car)

var game: Game

var human_overwrite := false

@onready var center: Marker3D = $Center as Marker3D
@onready var nose: Marker3D = $Nose as Marker3D
@onready var camera: CarCamera = $Camera as CarCamera
@onready var controller: CarController = $Controller as CarController

@export var steer: float = PI/4
@export var power: int = 300
@export var speed_limit: int = 100
@export var color: String = "blue"

var input_steer: float = 0
var input_power: float = 0

func init(_game: Game):
	game = _game

func _ready():
	center_of_mass = center.position
	set_color(color)
	controller.init(self)
	camera.init(self)

func set_color(c: String):
	var material = $Mesh.mesh.get("surface_1/material").duplicate(true)
	material.albedo_color = Color(c)
	$Mesh.set_surface_override_material(1, material)

func game_over():
	controller.done = true
	controller.needs_reset = true

func move_to_grid_position(grid_position: Marker3D):
	position = grid_position.position
	rotation = grid_position.rotation
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	steering = 0
	engine_force = 0

func reset(grid_position: Marker3D):
	controller.reset()
	move_to_grid_position(grid_position)
	camera.reset()

func _physics_process(delta):
	if controller.needs_reset:
		needs_reset.emit()
		return
	handle_input(delta)
	camera.update(delta)

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(speed_limit)
	check_collisions(state)

func handle_input(delta):
	if (controller.heuristic == "human" or human_overwrite) and camera.is_current():
		input_steer = Input.get_axis("ui_right", "ui_left")
		input_power = Input.get_axis("ui_down", "ui_up")
	else:
		input_steer = controller.steer_action
		input_power = controller.power_action
	steering = move_toward(steering, input_steer * steer, delta * 2.5)
	engine_force = input_power * power

func check_collisions(state: PhysicsDirectBodyState3D):
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider is GridMap:
			collision_with_static.emit(self)

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
