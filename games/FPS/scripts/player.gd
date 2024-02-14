extends CharacterBody3D
class_name Player

signal death
signal kill(player: Player, killed: Player)
signal needs_reset

@export var walk_speed := 7.5
@export var sprint_speed := 10.0
@export var jump_speed := 5.0
@export var color := "white"
@export var base_hp := 100.0
@export var player_override := false
@export var is_main_player := false

# Head is the raycast since otherwise the "Exlude Parent" property wouldn't work.
@onready var head = $Head
@onready var camera = $Head/Camera
@onready var gun = $Head/Camera/GunHolder/Gun as Gun
@onready var aim_endpoint = $Head/Camera/AimEndPoint
@onready var mesh = $Mesh/Body
@onready var collision_shape = $CollisionShape
@onready var controller := $Head/PlayerController as PlayerController
@onready var animation_player = $AnimationPlayer

const sensitivity := 0.001
const gravity := 9.8

var hp := base_hp
var is_alive := true

var game: Game

var input_shoot := 0.0
var input_sprint := 0.0
var input_left := 0.0
var input_right := 0.0
var input_forward := 0.0
var input_backward := 0.0
var input_rotate_x := 0.0
var input_rotate_y := 0.0

var mouse_event_queue = []

func init(_game: Game, _bullet_container: Node3D):
	game = _game
	gun.init(head, aim_endpoint, _bullet_container, color, self)
	controller.init(self)

func game_over():
	controller.done = true
	controller.needs_reset = true

func reset():
	controller.reset()

func _ready():
	_update_color()

func _update_color():
	var material = mesh.get_active_material(0).duplicate()
	material.albedo_color = Color(color)
	mesh.set_surface_override_material(0, material)

func _unhandled_input(event):
	if _allow_human_input() and event is InputEventMouseMotion:
		mouse_event_queue.append(event)

func _physics_process(delta):
		
	if controller.needs_reset:
		needs_reset.emit()

	if not is_alive:
		return
	
	_zero_input()
	_handle_input()

	rotate_y(input_rotate_x)
	head.rotate_x(input_rotate_y)
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-45), deg_to_rad(60))
	gun.sway_gun(Vector2(input_rotate_x, input_rotate_y))
	
	if input_shoot:
		gun.shoot()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var speed = walk_speed
	if is_on_floor() and input_sprint:
		speed = sprint_speed
	
	var input_dir = Vector2(input_right - input_left, input_backward - input_forward)
	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()*speed
	
	if is_on_floor():
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = lerp(velocity.x, direction.x, delta*5)
		velocity.z = lerp(velocity.z, direction.z, delta*5)
	
	move_and_slide()

func _zero_input():
	input_shoot = 0.0
	input_sprint = 0.0
	input_left = 0.0
	input_right = 0.0
	input_forward = 0.0
	input_backward = 0.0
	input_rotate_x = 0.0
	input_rotate_y = 0.0

func _handle_input():
	if _allow_human_input():
		input_shoot = float(Input.is_action_pressed("shoot"))
		input_sprint = float(Input.is_action_pressed("sprint"))
		input_left = float(Input.is_action_pressed("left"))
		input_right = float(Input.is_action_pressed("right"))
		input_forward = float(Input.is_action_pressed("forward"))
		input_backward = float(Input.is_action_pressed("backward"))
		for event in mouse_event_queue:
			input_rotate_x += (-event.relative.x * sensitivity)
			input_rotate_y += (-event.relative.y * sensitivity)
		mouse_event_queue.clear()
	else:
		input_shoot = controller.action_shoot
		input_sprint = controller.action_sprint
		input_left = controller.action_left
		input_right = controller.action_right
		input_forward = controller.action_forward
		input_backward = controller.action_backward
		input_rotate_x = controller.action_rotate_x * 0.15
		input_rotate_y = controller.action_rotate_y * 0.15

func on_bullet_kill(player: Player):
	kill.emit(self, player)

func take_damage(damage: float):
	if hp <= 0:
		return false
	hp -= damage
	controller.give_reward("take_damage", 1)
	animation_player.play("hit")
	if hp <= 0:
		_die()
		return true
	return false

func _die():
	animation_player.play("RESET")
	collision_shape.disabled = true
	visible = false
	hp = 0
	is_alive = false
	death.emit()

func spawn(_transform: Transform3D):
	transform = _transform
	collision_shape.disabled = false
	visible = true
	hp = base_hp
	is_alive = true

func _allow_human_input():
	return (controller.heuristic == "human" or player_override) and camera.current 
