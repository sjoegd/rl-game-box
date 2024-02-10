extends CharacterBody3D
class_name Player

signal needs_reset

@export var base_color := "white"
@export var tagger_color := "red"
@export var player_override := false
@export var tag_cooldown := 1.0#s

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var mesh = $Mesh
@onready var tag_area = $Head/TagArea
@onready var controller = $Head/Camera/PlayerController as PlayerController
@onready var color := base_color

const walk_speed := 7.5
const sprint_speed := 10.0
const jump_speed := 5.0
const sensitivity := 0.001
const gravity := 9.8

var game: Game

var is_tagger := false
var can_tag := false

var input_sprint := 0.0
var input_jump := 0.0
var input_left := 0.0
var input_right := 0.0
var input_forward := 0.0
var input_backward := 0.0
var input_rotate_x := 0.0
var input_rotate_y := 0.0

var mouse_event_queue = []

func init(_game: Game):
	game = _game
	controller.init(self)

func reset():
	controller.reset()
	set_collision_layer_value(4, false)
	can_tag = false
	is_tagger = false
	color = base_color
	_update_color()

func spawn(_spawn: Transform3D):
	transform = _spawn

func _ready():
	_update_color()

func _update_color():
	var material = mesh.get_active_material(0).duplicate()
	material.albedo_color = Color(color)
	mesh.set_surface_override_material(0, material)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_event_queue.append(event)

func _physics_process(delta):
	
	if controller.needs_reset:
		controller.done = true
		needs_reset.emit()
		return
	
	_zero_input()
	_handle_input()

	rotate_y(input_rotate_x)
	head.rotate_x(input_rotate_y)
	head.rotation.x = clamp(head.rotation.x, deg_to_rad(-45), deg_to_rad(60))
		
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif input_jump:
		velocity.y = jump_speed
	
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
	input_sprint = 0.0
	input_jump = 0.0
	input_left = 0.0
	input_right = 0.0
	input_forward = 0.0
	input_backward = 0.0
	input_rotate_x = 0.0
	input_rotate_y = 0.0

func _handle_input():
	if (controller.heuristic == "human" or player_override) and camera.current:
		input_sprint = float(Input.is_action_pressed("sprint"))
		input_jump = float(Input.is_action_pressed("jump"))
		input_left = float(Input.is_action_pressed("left"))
		input_right = float(Input.is_action_pressed("right"))
		input_forward = float(Input.is_action_pressed("forward"))
		input_backward = float(Input.is_action_pressed("backward"))
		for event in mouse_event_queue:
			input_rotate_x += (-event.relative.x * sensitivity)
			input_rotate_y += (-event.relative.y * sensitivity)
		mouse_event_queue.clear()
	else:
		input_sprint = controller.action_sprint
		input_jump = controller.action_jump
		input_left = controller.action_left
		input_right = controller.action_right
		input_forward = controller.action_forward
		input_backward = controller.action_backward
		input_rotate_x = controller.action_rotate_x * 0.15
		input_rotate_y = controller.action_rotate_y * 0.15

func _make_enemy_tagger(enemy: Player):
	if enemy == self or not can_tag:
		return
	enemy.make_tagger()
	release_tagger()

func make_tagger():
	controller.give_reward("became_tagger", 1.0)
	set_collision_layer_value(4, true)
	is_tagger = true
	can_tag = false
	get_tree().create_timer(tag_cooldown, true, true).timeout.connect(_allow_tag)
	color = tagger_color
	_update_color()

func release_tagger():
	controller.give_reward("lost_tagger", 1.0)
	set_collision_layer_value(4, false)
	is_tagger = false
	color = base_color
	_update_color()

func _allow_tag():
	can_tag = true

func _on_tag_area_body_detected(body):
	if is_tagger and body is Player:
		_make_enemy_tagger(body)
