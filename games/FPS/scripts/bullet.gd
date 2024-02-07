extends Node3D
class_name Bullet

@export var speed := 75.0
@export var ttl := 10.0 #s
@export var damage := 20.0

@onready var mesh = $Mesh

var color: String
var player: Player

func init(_color: String, _player: Player):
	color = _color
	player = _player
	_update_color()

func _ready():
	get_tree().create_timer(ttl, true, true).timeout.connect(_destroy)

func _update_color():
	var material = mesh.get_active_material(0).duplicate()
	material.albedo_color = Color(color)
	mesh.set_surface_override_material(0, material)

func _physics_process(delta):
	position += transform.basis * Vector3(0, 0, -speed) * delta

func _destroy():
	queue_free()

func _on_area_body_entered(body):
	if body is Player:
		var kill = body.take_damage(damage)
		player.controller.give_reward("deal_damage", 1)
		if kill:
			player.on_bullet_kill(body)
	_destroy()
