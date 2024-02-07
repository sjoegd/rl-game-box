extends Node3D
class_name Bullet

@export var speed := 100.0
@export var ttl := 10.0 #s

@onready var raycast = $RayCast
@onready var mesh = $Mesh

var color: String

func _ready():
	get_tree().create_timer(ttl, true, true).timeout.connect(_destroy)

func set_color(_color: String):
	color = _color
	_update_color()

func _update_color():
	var material = mesh.get_active_material(0)
	material.albedo_color = Color(color)
	mesh.set_surface_override_material(0, material)

func _physics_process(delta):
	position += transform.basis * Vector3(0, 0, -speed) * delta
	_check_collisions()

func _check_collisions():
	if raycast.is_colliding():
		_destroy()

func _destroy():
	queue_free()
