extends RigidBody3D
class_name Ball

signal ball_touch(player: Player)

@export var speed_limit := 50
@export var angular_speed_limit := PI

func reset(_transform: Transform3D):
	transform = _transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(speed_limit)
	state.angular_velocity = state.angular_velocity.limit_length(angular_speed_limit)
	check_ball_touches(state)

func check_ball_touches(state: PhysicsDirectBodyState3D):
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider.get_parent() is Player:
			ball_touch.emit(collider.get_parent())
