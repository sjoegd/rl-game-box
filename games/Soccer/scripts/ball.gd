extends RigidBody3D
class_name Ball

@export var linear_speed_limit := 50.0
@export var angular_speed_limit := PI*3

@onready var base_transform := transform

func reset():
	transform = base_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(linear_speed_limit)
	state.angular_velocity = state.angular_velocity.limit_length(angular_speed_limit)
