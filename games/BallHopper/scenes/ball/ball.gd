extends RigidBody2D
class_name Ball

@export var speed: float = 700

func _ready():
	linear_velocity = Vector2(randf_range(-1, 1), randf_range(0.25, 1)) * speed

func _physics_process(_delta):
	linear_velocity = linear_velocity.normalized() * speed
