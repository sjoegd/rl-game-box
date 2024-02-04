extends RigidBody3D
class_name Ball

signal player_collision(player: Player)

@export var linear_speed_limit := 30.0
@export var angular_speed_limit := PI*3

@onready var base_transform := transform

func reset():
	transform = base_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.limit_length(linear_speed_limit)
	state.angular_velocity = state.angular_velocity.limit_length(angular_speed_limit)
	_check_player_collisions(state)

func _check_player_collisions(state: PhysicsDirectBodyState3D):
	for c in state.get_contact_count():
		var collider = state.get_contact_collider_object(c).get_parent()
		if collider is Player:
			player_collision.emit(collider)
