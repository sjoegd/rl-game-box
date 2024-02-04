extends Node3D
class_name Gun

@onready var fire_point = $FirePoint as Marker3D
@onready var bullet_scene = preload("res://scenes/bullet.tscn")

var head_aim: RayCast3D
var aim_endpoint: Marker3D

func init(_head_aim: RayCast3D, _aim_endpoint: Marker3D):
	head_aim = _head_aim
	aim_endpoint = _aim_endpoint

func shoot(bullet_container: Node3D):
	var aim_point = _get_aim_point()
	var bullet = bullet_scene.instantiate() as Bullet
	bullet_container.add_child(bullet)
	bullet.global_position = fire_point.global_position
	bullet.look_at(aim_point)

func _get_aim_point():
	if head_aim.is_colliding():
		return head_aim.get_collision_point()
	return aim_endpoint.global_position
