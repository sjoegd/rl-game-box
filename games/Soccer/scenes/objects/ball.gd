class_name Ball
extends RigidBody2D

@export var max_angular_velocity: float = PI/2

func _physics_process(_delta):
	angular_velocity = min(max_angular_velocity, angular_velocity)
	angular_velocity = max(-max_angular_velocity, angular_velocity)
