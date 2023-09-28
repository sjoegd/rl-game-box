class_name Ball
extends RigidBody2D

@export var max_angular_velocity: float = PI/2
@export var max_linear_velocity: float = 1000

func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(_delta):
	angular_velocity = min(max_angular_velocity, angular_velocity)
	angular_velocity = max(-max_angular_velocity, angular_velocity)
	
func _integrate_forces(state):	
	if state.linear_velocity.length() > max_linear_velocity:
		state.linear_velocity = max_linear_velocity * state.linear_velocity.normalized()
