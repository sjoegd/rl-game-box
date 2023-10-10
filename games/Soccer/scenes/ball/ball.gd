extends RigidBody2D
class_name Ball

@export var max_velocity: float = 550.0

func _physics_process(_delta):
	if linear_velocity.length() > max_velocity:
		linear_velocity = linear_velocity.normalized() * max_velocity
