extends Node3D
class_name Gun

@onready var gun_barrel_ray = $GunBarrelRay
@onready var gun_barrel_transform = gun_barrel_ray.transform
@onready var animation_player = $AnimationPlayer

var _player: Player
var bullet_scene := load("res://scenes/bullet.tscn")
var bullet_instance

func init(player: Player):
	_player = player

func shoot_bullet(look_at_vec: Vector3, container: Node3D, delta_pos: Vector3):
	gun_barrel_ray.look_at(look_at_vec)
	animation_player.play("shoot")
	bullet_instance = bullet_scene.instantiate()
	bullet_instance.position = gun_barrel_ray.global_position + delta_pos
	bullet_instance.transform.basis = gun_barrel_ray.global_transform.basis
	bullet_instance.init(_player)
	container.add_child(bullet_instance)

func can_shoot() -> bool:
	return not animation_player.is_playing()
