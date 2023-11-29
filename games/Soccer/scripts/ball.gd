extends RigidBody3D
class_name Ball

@export var speed_limit := 50
@export var angular_speed_limit := PI

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(speed_limit)
	state.angular_velocity = state.angular_velocity.limit_length(angular_speed_limit)
