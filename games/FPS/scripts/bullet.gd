extends Node3D
class_name Bullet

@export var speed := 100.0
@export var ttl := 10.0 #s

@onready var raycast = $RayCast

func _ready():
	get_tree().create_timer(ttl, true, true).timeout.connect(_destroy)

func _physics_process(delta):
	position += transform.basis * Vector3(0, 0, -speed) * delta
	_check_collisions()

func _check_collisions():
	if raycast.is_colliding():
		_destroy()

func _destroy():
	queue_free()
