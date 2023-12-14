extends Node3D

@export var speed := 100.0
@export var damage := 12.5

@onready var mesh := $MeshInstance3D
@onready var ray := $RayCast3D
@onready var particles := $GPUParticles3D

var _player: Player
var collided := false

func init(player: Player):
	_player = player

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
		get_tree().create_timer(.25, true, true).connect("timeout", _on_alive_timeout)

func _damage_collider(collider):
	if collider.has_method("take_damage"):
		var kill = collider.take_damage(damage)
		if kill:
			_player.on_bullet_kill()
	collided = true

func _on_alive_timeout():
	queue_free()
