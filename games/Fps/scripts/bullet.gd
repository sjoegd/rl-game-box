extends Node3D

@export var speed := 40.0
@export var damage := 5.0

@onready var mesh := $MeshInstance3D
@onready var ray := $RayCast3D
@onready var particles := $GPUParticles3D

var collided := false

func _ready():
	get_tree().create_timer(10.0, true, true).connect("timeout", _on_alive_timeout)

func _physics_process(delta):
	if collided:
		return
	
	translate(Vector3(0, 0, -speed)*delta)
	
	if ray.is_colliding():
		_damage_collider(ray.get_collider())
		mesh.visible = false
		particles.emitting = true
		get_tree().create_timer(1.0, true, true).connect("timeout", _on_alive_timeout)

func _damage_collider(collider):
	if collider.has_method("take_damage"):
		collider.take_damage(damage)
	collided = true

func _on_alive_timeout():
	queue_free()
