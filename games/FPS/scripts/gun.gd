extends Node3D
class_name Gun

@onready var fire_point = $FirePoint as Marker3D
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var animation_player = $AnimationPlayer as AnimationPlayer

var head_aim: RayCast3D
var aim_endpoint: Marker3D
var bullet_container: Node3D
var color: String
var player: Player

func init(
	_head_aim: RayCast3D, 
	_aim_endpoint: Marker3D, 
	_bullet_container: Node3D, 
	_color: String,
	_player: Player
):
	head_aim = _head_aim
	aim_endpoint = _aim_endpoint
	bullet_container = _bullet_container
	color = _color
	player = _player

func _physics_process(delta):
	$"..".position.x = lerp($"..".position.x, 0.0, delta*5.0)
	$"..".position.y = lerp($"..".position.y, 0.0, delta*5.0)

func sway_gun(sway: Vector2):
	$"..".position.x -= sway.x * 0.1
	$"..".position.y += sway.y * 0.1

func shoot():
	if animation_player.is_playing():
		return
	animation_player.play("shoot")

func _shoot_bullet():
	var aim_point = _get_aim_point()
	var bullet = bullet_scene.instantiate() as Bullet
	bullet_container.add_child(bullet)
	bullet.init(color, player)
	bullet.global_position = fire_point.global_position
	bullet.look_at(aim_point)

func _get_aim_point():
	if head_aim.is_colliding():
		return head_aim.get_collision_point()
	return aim_endpoint.global_position

func is_aiming_at_enemy():
	if head_aim.is_colliding():
		return head_aim.get_collider() is Player
	return false

func is_aiming_at_ground():
	if head_aim.is_colliding():
		return head_aim.get_collider().get_collision_layer_value(2)
	return false

func is_aiming_at_nothing():
	return not head_aim.is_colliding()
