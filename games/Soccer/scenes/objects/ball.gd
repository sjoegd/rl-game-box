class_name Ball
extends RigidBody2D

@export var max_angular_velocity: float = PI/2

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(_delta):
	angular_velocity = min(max_angular_velocity, angular_velocity)
	angular_velocity = max(-max_angular_velocity, angular_velocity)
