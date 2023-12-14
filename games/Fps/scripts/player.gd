extends CharacterBody3D
class_name Player

signal death(player: Player)
signal got_kill(player: Player)

@export var sensitivity := 0.005
@export var speed := 10.0
@export var jump_speed := 6.25
@export var gravity := 15.0

@export var base_fov := 90.0
@export var fov_change := 0.5

@onready var camera := $Camera
@onready var camera_origin: Vector3 = $Camera.transform.origin
@onready var gun := $Camera/Hand/Gun as Gun
@onready var vision_ray := $Camera/VisionRay
@onready var vision_marker := $Camera/VisionMarker

const bob_freq := 1.0
const bob_amp := 0.08
var t_bob := 0.0

var _game: Game

var _health := 100.0

var input_straight := 0
var input_side := 0
var input_jump := false
var input_shoot := false
var input_rotate_x := 0
var input_rotate_y := 0

var unhandled_motion_events := []

func init(game: Game):
	_game = game

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	gun.init(self)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		unhandled_motion_events.append(event)

func _physics_process(delta):
	# INPUT
	_handle_input()
	
	# GRAVITY / JUMP
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif input_jump:
		velocity.y = jump_speed
	
	# DIRECTIONAL INPUT
	var input_dir = Vector2(input_side, input_straight)
	var direction = (
		transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	).normalized()*speed
	
	if is_on_floor():
		velocity.x = direction.x
		velocity.z = direction.z
	else:
		velocity.x = lerp(velocity.x, direction.x, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z, delta * 3.0)
	
	# ROTATION INPUT
	rotate_y(input_rotate_y*sensitivity)
	camera.rotate_x(input_rotate_x*sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(45))
	
	# FOV / CAMERA
	var v_speed = clamp(velocity.length(), 0, speed)
	var target_fov = base_fov + (fov_change * v_speed)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# SHOOT
	if input_shoot and gun.can_shoot():
		var look_at_vec = vision_marker.global_position
		if vision_ray.is_colliding():
			look_at_vec = vision_ray.get_collision_point()
		gun.shoot_bullet(
			look_at_vec,
			_game.get_bullet_container(),
			velocity*delta
		)
	
	# MOVE
	move_and_slide()
	
	# HEAD BOB
	if is_on_floor():
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = camera_origin + _head_bob(t_bob)

func _handle_input():
	_zero_input()
	if not _is_death() and camera.current:
		input_straight = Input.get_axis("forward", "backward")
		input_side = Input.get_axis("left", "right")
		input_jump = Input.is_action_just_pressed("jump")
		input_shoot = Input.is_action_pressed("shoot")
		for motion_event in unhandled_motion_events:
			input_rotate_y += -motion_event.relative.x
			input_rotate_x += -motion_event.relative.y
	unhandled_motion_events.clear()

func _zero_input():
	input_straight = 0
	input_side = 0
	input_jump = false
	input_shoot = false
	input_rotate_x = 0
	input_rotate_y = 0

func _head_bob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	return pos

func _is_death() -> bool:
	return _health <= 0

func take_damage(damage: float) -> bool:
	if _is_death():
		return false
	_health -= damage
	if _health <= 0:
		_die()
		return true
	return false

func _die():
	_health = 0
	collision_layer = 0
	visible = false
	death.emit(self)

func _respawn():
	_health = 100
	collision_layer = 1
	visible = true

func on_bullet_kill():
	got_kill.emit(self)
